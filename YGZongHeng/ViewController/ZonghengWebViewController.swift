//
//  ZonghengWebViewController.swift
//  YGZongHeng
//
//  Created by 影孤清 on 2018/1/9.
//  Copyright © 2018年 yingguqing. All rights reserved.
//

import UIKit
import WebKit

class ZonghengWebViewController: BaseViewController,WKNavigationDelegate {
    
    @IBOutlet weak var bgView:UIView!
    var webView: WKWebView = WKWebView()
    lazy var pre = YGPreferences.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        self.view.addSubview(webView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if webView.url == nil {
            let url = "https://m.zongheng.com"
            webView.load(url.toURLRequest!)
            YGNoticeManager.default.showWait(time: 0, autoClear: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let frame = bgView.frame
        webView.frame = frame
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        YGNoticeManager.default.clearAll()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        YGNoticeManager.default.clearAll()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        if pre.ZongHengType != "*" {// 非*过滤其他地址跳转
            guard url?.range(of: pre.ZongHengType)?.lowerBound != nil else {
                return decisionHandler(.cancel)
            }
        }
        let type = pre.BookIdType
        if let _ = url?.range(of: pre.DownloadType)?.lowerBound,// 有下载小说关键字段
            let _ = url?.range(of: type)?.lowerBound, // 存在bookId字段
            let a = url?.components(separatedBy: "?") {// 可以用？切分
            for value in a {
                if let _ = value.range(of: type)?.lowerBound {//取带bookid那一段
                    let aa = value.components(separatedBy: "&")
                    for value in aa {
                        if value.hasPrefix(type) {//参数以bookid开头那一条
                            let bookId = value[type.count..<value.count]
                            YGBookView.showBookInfoWith(bookId: bookId)
                            return decisionHandler(.cancel)
                        }
                    }
                }
            }
        }
        decisionHandler(.allow)
    }

}
