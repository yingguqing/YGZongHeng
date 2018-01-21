//
//  BookEntity.swift
//  YGZongHeng
//
//  Created by wurw on 2017/12/25.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit

public enum BookStatus:Int {
    case Default = 0//未下载
    case ReadyDownload//准备下载
    case Downloading//下载中
    case DownloadFinished//下载成功
    case DownloadFaild//下载失败
    var statusText:String {
        get {
            switch self {
            case .Default:
                return ""
            case .ReadyDownload:
                return "准备下载"
            case .Downloading:
                return "正在下载..."
            case .DownloadFinished:
                return "已下载"
            case .DownloadFaild:
                return "下载失败"
            }
        }
    }
}

var downloadBookDic = Dictionary<String,BookEntity>()

let TxtFilePath:String = {// txt 文件保存路径
    let path = documentPath.appending(pathComponent: "txt")
    if path.fileIsExists == false {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("创建txt目录失败 \(error.localizedDescription)")
        }
    }
    return path
}()

class BookEntity: NSObject {
    var bookDescription:String = "" // 介绍
    var bookId:String = ""
    var coverUrl:String = "" // 封面URL
    var authorName:String = "" // 作者
    var bookName:String = ""
    var categoryName:String = "" // 类型
    var updateTime:String = "" // 更新时间
    var totalWord:String = "" // 总字数
    var downloadChapter:Int = 0 // 下载的章节数
    var txtChapterCount:Int = 0 // 生成txt的章节数
    var faildTimes:Int = 0 // 下载失败次数
    var isShelfBook:Bool = false // 是否添加到书架
    
    var formatTotalWord:String { // 格式化总字数
        get {
            if let total = Double(totalWord) {
                if total > 10000 {
                    return String(format:"%.2f万",total/10000)
                } else {
                    return totalWord
                }
            }
            return totalWord
        }
    }
    var status:BookStatus = BookStatus.Default // 小说下载状态
    var lastChapterId:String?//下载小说的最后一章的章节id
    var bookTxtPath:String {//txt 文件路径
        get {
            return TxtFilePath.appending(pathComponent: bookName + ".txt")
        }
    }
    
    override init() {
        super.init()
    }
    
    func updateWith(data:BookEntity) {
        if data.bookId.isEmpty == false && data.bookId == bookId {
            if bookDescription != data.bookDescription && data.bookDescription.isEmpty == false {
                bookDescription = data.bookDescription
            }
            if coverUrl != data.coverUrl && data.coverUrl.isEmpty == false {
                coverUrl = data.coverUrl
            }
            if authorName != data.authorName && data.authorName.isEmpty == false {
                authorName = data.authorName
            }
            if bookName != data.bookName && data.bookName.isEmpty == false {
                bookName = data.bookName
            }
            if categoryName != data.categoryName && data.categoryName.isEmpty == false {
                categoryName = data.categoryName
            }
            if totalWord != data.totalWord && data.totalWord.isEmpty == false {
                totalWord = data.totalWord
            }
            if updateTime != data.updateTime && data.updateTime.isEmpty == false {
                updateTime = data.updateTime
            }
        }
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(updaDownloadNum(noti:)), name: NSNotification.Name.init(rawValue: bookId), object: nil)
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: 更新下载章节数
    @objc func updaDownloadNum(noti:Notification) {
        if let obj = noti.object as? Int {
            downloadChapter = obj
        }
    }
    
    func createTextFileWith(block:@escaping (Bool)->()) {
        let dlCount = YGDBManager.default.queryChapterCountWith(bookId: bookId)
        guard dlCount > 0 else {
            YGNoticeManager.default.clearAll()
            YGNoticeManager.default.showNoticeWithText(type: NoticeType.Error, text: "小说不存在,请先下载...", time: YGNoticeManager.shortTime, autoClear: true)
            return
        }
        if dlCount == txtChapterCount {
            return block(true)
        }
        weak var weakSelf = self
        DispatchQueue.global().async {
            if let sself = weakSelf {
                let array = YGDBManager.default.queryChapterWith(bookId: sself.bookId)
                var text = String()
                for value in array {
                    text += value.chapterName + "\n" + value.content + "\n"
                }
                var isFinished = false
                do {
                    if sself.bookTxtPath.fileIsExists {
                        try FileManager.default.removeItem(atPath: sself.bookTxtPath)
                    }
                    try text.write(toFile: sself.bookTxtPath, atomically: true, encoding: String.Encoding.utf8)
                    sself.txtChapterCount = array.count
                    YGDBManager.default.updateBookWith(data: sself)
                    isFinished = true
                } catch let error as NSError {
                    isFinished = false
                    print("生成txt文件时出错 \(sself.bookName) \(error.localizedDescription)")
                }
                return block(isFinished)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension BookEntity {
    /// 小说下载
    func downloadBook() {
        DispatchQueue.global().async {
            [weak self] in
            if let wself = self,downloadBookDic[wself.bookId] == nil {//判断小说是否在下载中
                // 没有上一个章节id时,从本地下载的小说数据里获取
                if wself.lastChapterId == nil || wself.lastChapterId!.isEmpty {
                    wself.lastChapterId = YGDBManager.default.queryChapterLastIdWith(bookId: wself.bookId)
                    if wself.lastChapterId?.isEmpty == false {
                        wself.downloadChapter = YGDBManager.default.queryChapterCountWith(bookId: wself.bookId)
                    }
                    downloadBookDic[wself.bookId] = self
                }
                wself.downloadBookWith(cursor: wself.lastChapterId)
            }
        }
    }
    
    /// 下载总方法
    /// - parameter cursor:上一个章节id 为空获取小说第一章,有值则获取接下来的章节
    func downloadBookWith(cursor:String?) {
        if status != BookStatus.Downloading {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            YGNotification.postNotification(notification: .DownloadBook, object: nil, userInfo: ["bookId":bookId,"status":BookStatus.Downloading])
        }
        status = BookStatus.Downloading
        YGNetwork.default.downloadBookWith(bookId: bookId, cursor: cursor) { [weak self] (response) in
            if let result = response.data {
                if result is ChapterEntity || result is Array<ChapterEntity> {
                    DispatchQueue.global().async {
                        self?.saveBookWith(data: result)
                    }
                } else if result is String {
                    if let wself = self {
                        print("小说下载完成")
                        wself.status = BookStatus.DownloadFinished
                        wself.lastChapterId = ""
                        wself.checkDownloadFinish()
                        YGNotification.postNotification(notification: .DownloadBook, object: nil, userInfo: ["bookId":wself.bookId,"status":wself.status])
                    }
                }
            } else if let error = response.error {
                if let wself = self {
                    guard wself.checkDownloadFaild else {return}
                    print("小说下载失败: \(error)")
                    wself.bookDownloadFaild()
                }
            }
        }
    }
    
    //MARK: 小说下载失败，状态，数据设置
    func bookDownloadFaild() {
        self.checkDownloadFinish()
        self.lastChapterId = ""
        self.status = BookStatus.DownloadFaild
        YGNotification.postNotification(notification: .DownloadBook, object: nil, userInfo: ["bookId":self.bookId,"status":self.status])
    }
    
    var checkDownloadFaild:Bool {
        if faildTimes < 5 {// 还可以重试
            faildTimes += 1
            downloadBookWith(cursor: lastChapterId)
            return false
        }
        return true // 下载失败
    }
    
    func checkDownloadFinish() {
        downloadBookDic.removeValue(forKey: bookId)
        if downloadBookDic.count == 0 {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false// 关闭屏幕常亮
            }
        }
    }
    
    //MARK: 保存小说数据到数据库
    func saveBookWith(data:Any) {
        var chapterId = ""
        if let item = data as? ChapterEntity {
                YGDBManager.default.insertChapterWith(data: item)
                downloadChapter += 1
                chapterId = String(item.chapterId)
        } else if let chapterArray = data as? Array<ChapterEntity> {//多章
                if let maxItem = chapterArray.last {
                    chapterId = String(maxItem.chapterId)
                }
                YGDBManager.default.insertChapterWith(array: chapterArray)
                downloadChapter += chapterArray.count
        }
        if chapterId.isEmpty == false {//有数据
            lastChapterId = chapterId
            faildTimes = 0
            NotificationCenter.default.post(name: NSNotification.Name.init(bookId), object: downloadChapter)
        }
        if chapterId.isEmpty == false {// 有章节Id，就继续下载
            downloadBookWith(cursor: lastChapterId)
        } else {
            guard checkDownloadFaild else {return}
            print("小说下载失败: 章节内容为空,小说下载失败")
            bookDownloadFaild()
        }
    }
}

