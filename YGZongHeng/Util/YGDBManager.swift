//
//  YGDBManager.swift
//  YGZongHeng
//
//  Created by wurw on 2018/1/9.
//  Copyright © 2018年 yingguqing. All rights reserved.
//

import UIKit
import SQLite

let TMBookId = Expression<String>("bookId")
let TMBookDescription = Expression<String>("bookDescription") // 介绍
let TMCoverUrl = Expression<String>("coverUrl") // 封面
let TMAuthorName = Expression<String>("authorName") // 作者
let TMBookName = Expression<String>("bookName")
let TMCategoryName = Expression<String>("categoryName") // 类型
let TMUpdateTime = Expression<String>("updateTime") // 更新时间
let TMTotalWord = Expression<String>("totalWord") // 总字数
let TMTxtChapterCount = Expression<String>("txtChapterCount") 
let TMShelf = Expression<Int64>("shelf")
let TMChapterId = Expression<Int64>("chapterId")
let TMChapterName = Expression<String>("chapterName")
let TMContent = Expression<String>("content")
let TMCreateTimeStr = Expression<String>("createTimeStr")
let TMTomeName = Expression<String>("tomeName")
let TMUpdateTimeStr = Expression<String>("updateTimeStr")
let TMWordNum = Expression<String>("wordNum")

class YGDBManager: NSObject {
    static let `default` = YGDBManager()
    
    let dbPath = documentPath.appending(pathComponent: "Book.db")
    lazy var db = try Connection(dbPath)
    lazy var tbBook = Table("Book")// 小说简介表
    lazy var tbChapter = Table("Chapter") // 小说章节表
    lazy var tbTest = Table("Test")
    
    private override init() {}
    
    //MARK: 检查数据库文件是否存在
    func checkDbFile() {
        do {
            //try FileManager.default.removeItem(atPath: dbPath)
            if dbPath.fileIsExists == false,
                let path = Bundle.main.url(forResource: "Book", withExtension: "db") {
                try FileManager.default.copyItem(at: path, to: dbPath.toFileURL!)
            }
        } catch let error as NSError {
            print("复制数据库出错 \(error.localizedDescription)")
        }
    }
    
    //MARK: 查询书架里的书
    func queryShelfBooks() -> Array<BookEntity> {
        let alice = tbBook.filter(TMShelf == 1)
        var array = Array<BookEntity>()
        if let books = try? db.prepare(alice) {
            for value in books {
                let item = BookEntity(row: value)
                array.append(item)
            }
        }
        return array;
    }
    
    //MARK: 根据小说id查询小说
    func queryBookWith(bookId:String) -> BookEntity? {
        let alice = tbBook.filter(TMBookId == bookId)
        if let books = try? db.prepare(alice) {
            for value in books {
                return BookEntity(row: value)
            }
        }
        return nil
    }
    
    //MARK: 插入一本小说简介到数据
    func insertBookWith(data:BookEntity) {
        let insert = tbBook.insert(data.dbData)
        do {
            try db.run(insert)
        } catch let error as NSError {
            print("插入数据失败 \(error.localizedDescription)")
        }
    }
    
    //MARK: 更新一本小说的简介数据
    func updateBookWith(data:BookEntity) {
        let alice = tbBook.filter(TMBookId == data.bookId)
        do {
            try db.run(alice.update(data.dbData))
        } catch let error as NSError {
            print("修改数据失败 \(error.localizedDescription)")
        }
    }
    
    //MARK: 批量插入小说章节数据
    func insertChapterWith(array:Array<ChapterEntity>) {
        do {
            try db.transaction(.deferred) {
                for value in array {
                    insertChapterWith(data: value)
                }
            }
        } catch let error as NSError {
            print("批量插入章节数据失败 \(error.localizedDescription)")
        }
    }
    
    //MARK: 插入一章小说章节数据
    func insertChapterWith(data:ChapterEntity) {
        let insert = tbChapter.insert(data.dbData)
        do {
            try db.run(insert)
        } catch let error as NSError {
            print("插入章节数据失败 \(error.localizedDescription)")
        }
    }
    
    //MARK: 根据小说id查询一本小说的所有章节数据
    func queryChapterWith(bookId:String) -> Array<ChapterEntity> {
        let alice = tbChapter.filter(TMBookId == bookId).order(TMChapterId.asc)
        var array = Array<ChapterEntity>()
        if let chapters = try? db.prepare(alice) {
            for value in chapters {
                let item = ChapterEntity(row: value)
                array.append(item)
            }
        }
        return array
    }
    
    //MARK: 根据小说id查询本地下载的章节的最大的章节id
    func queryChapterLastIdWith(bookId:String) -> String {
        let alice = tbChapter.filter(TMBookId == bookId).order(TMChapterId.desc).limit(1)
        if let chapters = try? db.prepare(alice) {
            for value in chapters {
                let id = value[TMChapterId]
                return String(id)
            }
        }
        return ""
    }
    
    //MARK: 根据小说id查询下载的章节数
    func queryChapterCountWith(bookId:String) -> Int {
        let alice = tbChapter.filter(TMBookId == bookId)
        if let count = try? db.scalar(alice.count) as Int {
            return count
        }
        return 0
    }
    
    //MARK: 根据小说id删除所有下载章节数据
    func deleteAllChapterWith(bookId:String) {
        let alice = tbChapter.filter(TMBookId == bookId)
        do {
            try db.run(alice.delete())
        } catch let error as NSError {
            print("删除章节数据失败 \(error.localizedDescription)")
        }
    }
}

extension BookEntity {
    var dbData:[SQLite.Setter] {
        return [TMBookId <- bookId,
                TMBookDescription <- bookDescription,
                TMCoverUrl <- coverUrl,
                TMAuthorName <- authorName,
                TMBookName <- bookName,
                TMCategoryName <- categoryName,
                TMTotalWord <- totalWord,
                TMUpdateTime <- updateTime,
                TMTxtChapterCount <- String(txtChapterCount),
                TMShelf <- isShelfBook ? 1 : 0]
    }
    
    convenience init(row:Row) {
        self.init()
        bookId = row[TMBookId]
        bookDescription = row[TMBookDescription]
        coverUrl = row[TMCoverUrl]
        authorName = row[TMAuthorName]
        bookName = row[TMBookName]
        categoryName = row[TMCategoryName]
        totalWord = row[TMTotalWord]
        updateTime = row[TMUpdateTime]
        isShelfBook = row[TMShelf] == 1
        let s = row[TMTxtChapterCount]
        if let count = Int(s) {
            txtChapterCount = count
        } else {
            txtChapterCount = 0
        }
        downloadChapter = YGDBManager.default.queryChapterCountWith(bookId: bookId)
    }
    
    func addToShelf() {
        isShelfBook = true
        YGDBManager.default.updateBookWith(data: self)
    }
    
    func removeToShelf() {
        isShelfBook = false
        YGDBManager.default.updateBookWith(data: self)
    }
    
}

extension ChapterEntity {
    
    var dbData:[SQLite.Setter] {
        return [TMBookId <- bookId,
                TMChapterId <- chapterId,
                TMChapterName <- chapterName,
                TMContent <- content,
                TMCreateTimeStr <- createTimeStr,
                TMTomeName <- tomeName,
                TMUpdateTimeStr <- updateTimeStr,
                TMWordNum <- wordNum]
    }
    
    convenience init(row:Row) {
        self.init()
        bookId = row[TMBookId]
        chapterId = row[TMChapterId]
        chapterName = row[TMChapterName]
        content = row[TMContent]
        createTimeStr = row[TMCreateTimeStr]
        tomeName = row[TMTomeName]
        updateTimeStr = row[TMUpdateTimeStr]
        wordNum = row[TMWordNum]
    }
}
