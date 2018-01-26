//
//  FirstViewController.swift
//  YGZongHeng
//
//  Created by wurw on 2017/12/25.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit

let userAccountPath = documentPath.appending(pathComponent: "BookListData")

class BookShelfViewController: BaseViewController,UIDocumentInteractionControllerDelegate {
    lazy var bookArray:Array<BookEntity> = Array<BookEntity>()
    @IBOutlet weak var tableView: UITableView!
    var documentController:UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAllBookList()
        tableView.tableFooterView = UIView() 
        YGNotification.addObserver(observer: self, selector: #selector(addBookNotification(noti:)), notification: .AddBook)
        YGNotification.addObserver(observer: self, selector: #selector(updataStatusNotification(noti:)), notification: .DownloadBook)
        //YGNotification.addObserver(observer: self, selector: #selector(reloadData), notification: .ReloadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        YGUtil.showInputAlertView()
    }
    
    func loadAllBookList() {
        bookArray = YGDBManager.default.queryShelfBooks()
        reloadData()
    }
    
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func updataStatusNotification(noti:Notification) {
        if let userInfo = noti.userInfo {
            if let bookId = userInfo["bookId"] as? String,
                bookId.isEmpty == false,
                let status = userInfo["status"] as? BookStatus {
                for value in bookArray {
                    if bookId == value.bookId && value.status != status {
                        value.status = status
                    }
                }
            }
        }
        reloadData()
    }
    
    @objc func addBookNotification(noti:Notification) {
        if let obj = noti.object,
            obj is BookEntity {
            let book = obj as! BookEntity
            guard book.bookId.isEmpty == false else {
                return
            }
            var tempValue:BookEntity?
            for value in bookArray {
                if value.bookId == book.bookId {
                    tempValue = value
                    break
                }
            }
            if tempValue == nil {
                bookArray.insert(book, at: 0)
                book.addNotification()
            } else if let index = bookArray.index(of: tempValue!) {
                // 如果存在这本小说,则将小说移动到第一个
                bookArray.remove(at: index)
                bookArray.insert(tempValue!, at: 0)
            }
            reloadData()
        }
    }
    
    //MARK: 从书架移除小说
    func removeBookFromShelfWith(row:Int) {
        guard row > -1 && row < bookArray.count else {
            return
        }
        deleteDownloadBookWith(row: row)
        let item = bookArray.remove(at: row)
        item.removeToShelf()
        item.removeNotification()
    }
    
    //MARK: 删除下载的小说文件
    func deleteDownloadBookWith(row:Int) {
        guard row > -1 && row < bookArray.count else {
            return
        }
        let item = bookArray[row]
        do {
            let mag = FileManager.default
            YGDBManager.default.deleteAllChapterWith(bookId: item.bookId)
            if item.bookTxtPath.fileIsExists {
                try mag.removeItem(atPath: item.bookTxtPath)
                item.txtChapterCount = 0
                YGDBManager.default.updateBookWith(data: item)
            }
            item.downloadChapter = 0
            item.lastChapterId = ""
            reloadData()
        } catch let error as NSError {
            print("删除小说出错: \(error.localizedDescription)")
        }
    }
    
    func shareTextWith(book:BookEntity) {
        if book.status == .Downloading {
            YGNoticeManager.default.showText(text: "小说还在下载中。。。", time: YGNoticeManager.longTime, autoClear: true)
        } else {
            YGNoticeManager.default.showWait(time: 0, autoClear: false)
            book.createTextFileWith(block: { [weak self] (finished) in
                if finished {
                    self?.showShareControllerWith(filePath: book.bookTxtPath)
                }
            })
        }
    }
    
    func showShareControllerWith(filePath:String) {
        DispatchQueue.main.async {
            self.documentController = UIDocumentInteractionController(url: filePath.toFileURL!)
            self.documentController?.uti = "public.plain-text"
            self.documentController?.delegate = self
            self.documentController?.presentOpenInMenu(from: CGRect.zero, in: self.view, animated: true)
        }
    }
    
    func documentInteractionControllerWillPresentOpenInMenu(_ controller: UIDocumentInteractionController) {
        // 延时3秒关闭
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
            YGNoticeManager.default.clearWait()
        })
    }
}

extension BookShelfViewController:UITableViewDelegate,UITableViewDataSource {
    
    @objc func showBookDetailWith(sender:UIButton) {
        if let cell = YGUtil.superUITableViewCell(of: sender),
            let indexPath = tableView.indexPath(for: cell) {
            let item = bookArray[indexPath.row]
            YGBookView.showBookInfoWith(bookId: item.bookId)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = bookArray[indexPath.row]
        shareTextWith(book: item)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actionArr = [UITableViewRowAction]()
        let remAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "移除") { (action, indexPath) in
            self.removeBookFromShelfWith(row: indexPath.row)
            tableView.isEditing = false
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
        actionArr.append(remAction)
        let item = bookArray[indexPath.row]
        var hasFile = false
        if item.downloadChapter > 0 {
            let delAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "删除") { (action, indexPath) in
                self.deleteDownloadBookWith(row: indexPath.row)
                tableView.isEditing = false
            }
            delAction.backgroundColor = UIColor.blue
            actionArr.append(delAction)
            hasFile = true
        }
        let title = hasFile ? "更新" : "下载"
        let duAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: title) { (action, indexPath) in
            tableView.isEditing = false
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            item.downloadBook()
        }
        duAction.backgroundColor = UIColor.green
        actionArr.append(duAction)
        return actionArr
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 146
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "BookCell")
        if cell == nil {
            cell = Bundle.main.loadNibNamed("BookCell", owner: self, options: nil)?.last as? UITableViewCell
            let button = cell!.viewWithTag(8) as! UIButton
            button.addTarget(self, action: #selector(showBookDetailWith(sender:)), for: UIControlEvents.touchUpInside)
        }
        let item = bookArray[indexPath.row]
        let imageView = cell?.viewWithTag(1) as! UIImageView
        imageView.showImageWith(url: item.coverUrl)
        let lbBookName = cell?.viewWithTag(2) as! UILabel
        lbBookName.text = item.bookName
        let lbBookDec = cell?.viewWithTag(3) as! UILabel
        lbBookDec.text = item.bookDescription.replacingOccurrences(of: "\r\n", with: "")
        let lbUserName = cell?.viewWithTag(4) as! UILabel
        lbUserName.text = item.authorName
        let lbCategoryName = cell?.viewWithTag(5) as! UILabel
        lbCategoryName.text = "  " + item.categoryName + "  "
        let lbStatus = cell?.viewWithTag(6) as! YGChapterLabel
        lbStatus.bookItem = item
        let activity = cell?.viewWithTag(7) as! UIActivityIndicatorView
        if item.status == BookStatus.Downloading {
            activity.startAnimating()
            activity.isHidden = false
        } else {
            activity.stopAnimating()
            activity.isHidden = true
        }
        return cell!
    }
}

