//
//  YGBookView.swift
//  YGZongHeng
//
//  Created by wurw on 2017/12/26.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit

class YGBookView: UIView {
    @IBOutlet weak var ivBackground: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lbBookName: UILabel!
    @IBOutlet weak var lbAuthorName: UILabel!
    @IBOutlet weak var lbCategoryName: UILabel!
    @IBOutlet weak var lbTotalWord: UILabel!
    @IBOutlet weak var lbUpdateTime: UILabel!
    @IBOutlet weak var lbBookDescription: UILabel!
    @IBOutlet weak var descriptionLayoutHeight: NSLayoutConstraint!
    @IBOutlet weak var viewWidthLayout: NSLayoutConstraint!
    var bookData:BookEntity?
    
    static func showBookInfoWith(bookId:String) {
        guard bookId.isEmpty == false else {
            return
        }
        let bookView = YGBookView.createView(fromNibName: "YGBookView")
        bookView?.viewWidthLayout.constant = ScreenWidth - 20
        bookView?.frame = UIScreen.main.bounds
        bookView?.cleanAllData()
        bookView?.showInWindow()
        bookView?.bookDataWith(bookId: bookId)
    }
    
    private func bookDataWith(bookId:String) {
        cleanAllData()
        if let data = YGDBManager.default.queryBookWith(bookId: bookId) {
            self.bookData = data
            showBookInfoWith(data: data)
        }
        YGNoticeManager.default.showWait(time: YGNoticeManager.longTime, autoClear: false)
        YGNetwork.default.detailDataWith(bookId: bookId) { [weak self] (response) in
            if let result = response.data {
                if result is BookEntity {
                    let item = result as! BookEntity
                    if self?.bookData != nil {
                        self?.bookData?.updateWith(data: item)
                        YGDBManager.default.updateBookWith(data: item)
                    } else {
                        self?.bookData = item
                        YGDBManager.default.insertBookWith(data: item)
                    }
                    self?.showBookInfoWith(data: item)
                }
            } else if let error = response.error {
                YGNoticeManager.default.showText(text: error, time: 5, autoClear: true)
            }
            YGNoticeManager.default.clearWait()
        }
    }
    
    private func cleanAllData() {
        self.bookData = nil
        DispatchQueue.main.async {
            let image = #imageLiteral(resourceName: "Recommend_Book")
            self.imageView.image = image
            self.lbBookName.text = ""
            self.lbAuthorName.text = ""
            self.lbCategoryName.text = ""
            self.lbTotalWord.text = ""
            self.lbUpdateTime.text = ""
            self.lbBookDescription.text = ""
            self.ivBackground.image = image.applyDarkEffect()
        }
    }
    
    private func showBookInfoWith(data:BookEntity) {
        imageView.showImageWith(url: data.coverUrl)
        ivBackground.showImageWith(url: data.coverUrl, isBlurEffect: true)
        DispatchQueue.main.async {
            self.lbBookName.text = data.bookName
            self.lbAuthorName.text = "作者：" + data.authorName
            self.lbCategoryName.text = "风格：" + data.categoryName
            self.lbTotalWord.text = "字数：" + data.formatTotalWord
            self.lbUpdateTime.text = "最近更新：" + data.updateTime
            self.lbBookDescription.text = "　　" + data.bookDescription
            let height = data.bookDescription.textHeigh(font: self.lbBookDescription.font, width: self.lbBookDescription.frame.width) + 30
            self.descriptionLayoutHeight.constant = min(height, ScreenHeight - 270)
        }
    }
    
    //MARK: 关闭
    @IBAction func closeViewAction(_ sender: Any) {
        self.hide()
    }
    
    //MARK: 添加到书架
    @IBAction func addToShelf(_ sender: Any) {
        bookData?.addToShelf()
        YGNotification.postNotification(notification: .AddBook, object: bookData, userInfo: nil)
        self.hide()
    }
    
    //MARK: 下载小说
    @IBAction func downloadBookAction(_ sender: Any) {
        bookData?.addToShelf()
        bookData?.downloadBook()
        YGNotification.postNotification(notification: .AddBook, object: bookData, userInfo: nil)
        self.hide()
    }
}

