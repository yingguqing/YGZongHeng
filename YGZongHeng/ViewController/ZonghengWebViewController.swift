//
//  ZonghengWebViewController.swift
//  YGZongHeng
//
//  Created by wurw on 2018/1/9.
//  Copyright © 2018年 yingguqing. All rights reserved.
//

import UIKit
import WebKit

class ZonghengWebViewController: BaseViewController,WKNavigationDelegate {
    @IBOutlet weak var bgView:UIView!
    var webView: WKWebView?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if webView == nil {
            webView = WKWebView(frame: bgView.frame)
            webView!.navigationDelegate = self
            let url = "https://m.zongheng.com"
            webView!.load(url.toURLRequest!)
            self.view.addSubview(webView!)
            YGNoticeManager.default.showWait(time: 0, autoClear: false)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        YGNoticeManager.default.clearAll()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        YGNoticeManager.default.clearAll()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString;
        let type = "bookid="
        if let _ = url?.range(of: type)?.lowerBound,
            let a = url?.components(separatedBy: "?"){
            for value in a {
                if let _ = value.range(of: type)?.lowerBound {
                    let aa = value.components(separatedBy: "&")
                    for value in aa {
                        if value.hasPrefix(type) {
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
