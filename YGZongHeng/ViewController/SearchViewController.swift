//
//  SearchViewController.swift
//  YGZongHeng
//
//  Created by 影孤清 on 2017/12/26.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit
import ESPullToRefresh

let searHistoryPath = documentPath.appending(pathComponent: "SearHistoryData")

class SearchViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var isShowSearch = false
    lazy var datas:Array<String> = Array<String>()
    lazy var results:Array<BookEntity> = Array<BookEntity>()
    var page = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        var footer: ESRefreshProtocol & ESRefreshAnimatorProtocol
        footer = ESRefreshFooterAnimator.init(frame: CGRect.zero)
        self.tableView.es.addInfiniteScrolling(animator: footer) { [weak self] in
            self?.loadMore()
        }
        self.tableView.refreshIdentifier = "搜索"
        self.tableView.expiredTimeInterval = 20.0
        loadSearchHistoryData()
    }
    
    func loadSearchHistoryData() {
        isShowSearch = false
        if let arr = NSKeyedUnarchiver.unarchiveObject(withFile: searHistoryPath) {
            datas += arr as! Array<String>
        }
        tableView.reloadData()
    }
    
    func searchBookWith(text:String?,isSaveHistory:Bool) {
        if let text = text, text.isEmpty == false {
            showNoticeWait()
            if isSaveHistory {
                if datas.contains(text),
                    let index = datas.index(of: text){
                    datas.remove(at: index)
                }
                datas.insert(text, at: 0)
                NSKeyedArchiver.archiveRootObject(datas, toFile: searHistoryPath)
            }
            datas.removeAll()
            results.removeAll()
            tableView.reloadData()
            page = 1
            httpDataWith(text: text)
        }
    }
    
    func loadMore() {
        if let text = searchBar.text {
            page += 1
            YGNoticeManager.default.showWait(time: 1, autoClear: false)
            httpDataWith(text: text)
        } else {
            self.tableView.es.noticeNoMoreData()
        }
    }
    
    func httpDataWith(text:String) {
        YGNetwork.default.searchBookWith(query: text, page: page) { [weak self](response) in
            if let result = response.data {
                if let wself = self {
                    DispatchQueue.main.async {
                        if result is Array<BookEntity> {
                            let ar = result as! Array<BookEntity>
                            wself.results += ar
                            wself.tableView.reloadData()
                            if wself.page > 1 {
                                wself.tableView.es.stopLoadingMore()
                            }
                        } else {
                            if wself.page > 1 {
                                wself.page -= 1
                            }
                            wself.tableView.es.noticeNoMoreData()
                        }
                        wself.clearWaitNotice()
                    }
                }
            } else if let error = response.error {
                if let wself = self {
                    DispatchQueue.main.async {
                        wself.clearWaitNotice()
                        YGNoticeManager.default.showText(text: error, time: 5, autoClear: true)
                        if wself.page > 1 {
                            wself.page -= 1
                        }
                        wself.tableView.es.stopPullToRefresh()
                        wself.tableView.es.noticeNoMoreData()
                    }
                }
            }
        }
    }
}

extension SearchViewController:UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBookWith(text: searchBar.text, isSaveHistory: true)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        isShowSearch = true
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isShowSearch = false
        searchBar.setShowsCancelButton(false, animated: true)
        self.view.endEditing(true)
        searchBar.text = nil
        loadSearchHistoryData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isShowSearch {
            return nil
        } else {
            return "历史记录"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isShowSearch {
            let item = results[indexPath.row]
            YGBookView.showBookInfoWith(bookId: item.bookId)
        } else {
            let text = datas[indexPath.row]
            searchBar.text = text
            isShowSearch = true
            searchBookWith(text: text, isSaveHistory: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowSearch {
            return results.count
        } else {
            return datas.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isShowSearch {
            return 146
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowSearch {
            var cell = tableView.dequeueReusableCell(withIdentifier: "SearchBookCell")
            if cell == nil {
                cell = Bundle.main.loadNibNamed("SearchBookCell", owner: self, options: nil)?.last as? UITableViewCell
            }
            let item = results[indexPath.row]
            let imageView = cell?.viewWithTag(1) as! UIImageView
            imageView.showImageWith(url: item.coverUrl)
            let lbBookName = cell?.viewWithTag(2) as! UILabel
            lbBookName.text = item.bookName
            let lbAuthorName = cell?.viewWithTag(3) as! UILabel
            lbAuthorName.text = "作者：" + item.authorName
            let lbCategoryName = cell?.viewWithTag(4) as! UILabel
            lbCategoryName.text = "风格：" + item.categoryName
            let lbTotalWord = cell?.viewWithTag(5) as! UILabel
            lbTotalWord.text = "字数：" + item.formatTotalWord
            let lbUpdateTime = cell?.viewWithTag(6) as! UILabel
            lbUpdateTime.text = "最近更新：" + item.updateTime
            return cell!
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell")
            if cell == nil {
                cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "SearchCell")
            }
            cell?.textLabel?.text = datas[indexPath.row]
            return cell!
        }
    }
}
