//
//  YGChapterLabel.swift
//  YGZongHeng
//
//  Created by wurw on 2018/1/2.
//  Copyright © 2018年 yingguqing. All rights reserved.
//

import UIKit

class YGChapterLabel: UILabel {

    var _bookId:String?
    var bookId:String {
        get {
            return _bookId != nil ? _bookId! : ""
        }
        set {
            if newValue != _bookId {
                _bookId = newValue
                removeNotification()
                addNotification()
            }
        }
    }
    var chapterNum:Int = 0
    var bookStatus:BookStatus = BookStatus.Default
    var endString:String {
        get {
            switch bookStatus {
            case .Default:
                return ""
            case .ReadyDownload:
                return "-准备"
            case .Downloading:
                return "..."
            case .DownloadFinished:
                return "-完成"
            case .DownloadFaild:
                return "-失败"
            }
        }
    }
    
    var bookItem:BookEntity? {
        get {
            return nil
        }
        set {
            if newValue != nil {
                bookId = newValue!.bookId
                bookStatus = newValue!.status
                chapterNum = newValue!.downloadChapter
                updataText()
            }
        }
    }
    
    func addNotification() {
        YGNotification.addObserver(observer: self, selector: #selector(updataStatusNotification(noti:)), notification: .DownloadBook)
        NotificationCenter.default.addObserver(self, selector: #selector(updaDownloadNum(noti:)), name: NSNotification.Name.init(rawValue: bookId), object: nil)
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func updaDownloadNum(noti:Notification) {
        if let obj = noti.object as? Int {
            chapterNum = obj
            updataText()
        }
    }
    
    @objc func updataStatusNotification(noti:Notification) {
        if let userInfo = noti.userInfo {
            if let bookId = userInfo["bookId"] as? String,
                bookId.isEmpty == false,
                _bookId == bookId,
                let status = userInfo["status"] as? BookStatus {
                bookStatus = status
                updataText()
            }
        }
    }
    
    func updataText() {
        DispatchQueue.main.async {
            if self.chapterNum > 0 {
                self.text = String(self.chapterNum) + "章" + self.endString
            } else {
                self.text = ""
            }
        }
    }
    
    deinit {
        removeNotification()
    }
}
