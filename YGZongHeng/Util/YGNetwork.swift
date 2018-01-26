//
//  YGNetwork.swift
//  YGZongHeng
//
//  Created by 影孤清 on 2017/12/25.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

public struct YGHttpDefaultResponse {
    public let data: Any? // 数据结果
    public let error: String? // 错误信息
    public let url:String? //请求链接
    public init(data: Any? = nil, error: Any? = nil, url: Any? = nil) {
        self.data = data
        
        if let error = error as? NSError {
            self.error = error.localizedDescription
        } else if let error = error as? Error {
            self.error = error.localizedDescription
        } else if let error = error as? String {
            self.error = error
        } else {
            self.error = nil
        }
        
        if let url = url as? URL {
            self.url = url.absoluteString
        } else if let url = url as? String {
            self.url = url
        } else {
            self.url = nil
        }
    }
}

class YGNetwork: NSObject {
    
    public static let `default` = YGNetwork()
    private let salt:String = "jJ9YQpNAua7WEIQjlT/DAA==".decrypt
    private let head:String = "hdMfUMxe8/jDQJhszWeQXoQ0MJkKd3gfyMDErkqkT9E/q1NNMg==".decrypt
    private override init() {}
    
    //MARK: 拼接完整url
    /// 拼接完整url
    /// - parameter dic: 请求参数
    func fetchUrlParamWith(dic:Dictionary<String,String>) -> URL? {
        let apiKey = "f573bf3066"
        let urlHead = head + apiKey
        let sortDic = dic.sorted { (str1, str2) -> Bool in
            return str1.0 < str2.0
        }
        var urlString = ""
        var sign = salt + "api_key" + apiKey
        for (key, value) in sortDic {
            urlString += "&" + key + "=" + value
            sign += key + value
        }
        sign += salt
        urlString = urlHead + urlString + "&sig=" + sign.md5()
        return urlString.toURL
    }
    
    //MARK: 网络GET请求
    func getHttpRequest(url: URL?, finished: @escaping (_ result: JSON?, _ error: String? ) -> Void) {
        guard url != nil else {return finished(nil, "请求链接错误")}
        Alamofire.request(url!).response { response in
            do {
                let json = try JSON(data: response.data!)
                finished(json, nil)
            } catch let error as NSError {
                print("解析JSON数据出错 \(error.localizedDescription)")
                finished(nil, "解析JSON数据出错 \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: 网络POST请求
    func postHttpRequest(url: String, parameters: [String : AnyObject]?, finished: @escaping (_ result: JSON?, _ error: String? ) -> Void) {
        guard url.isEmpty == false else {return finished(nil, "请求链接为空")}
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { (response) in
            do {
                let json = try JSON(data: response.data!)
                finished(json, nil)
            } catch let error as NSError {
                print("解析JSON数据出错 \(error.localizedDescription)")
                finished(nil, "解析JSON数据出错 \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: 介绍
    /// 介绍
    /// - parameter bookId: 小说id
    /// - parameter completionHandler: 结果回调
    func detailDataWith(bookId:String, completionHandler: @escaping (YGHttpDefaultResponse) -> Void) {
        guard bookId.isEmpty == false else {
            let response = YGHttpDefaultResponse(error: "小说ID不能为空")
            return completionHandler(response)
        }
        //介绍
        //http://api.zongheng.com/rest?api_key=f573bf3066&book_id=688697&method=book&sig=EF463F32297C7319A683652D8E0BC28E
        let dic = ["book_id":bookId , "method":"book"]
        let url = fetchUrlParamWith(dic: dic)
        getHttpRequest(url: url) { (data, error) in
            guard error == nil else {
                let response = YGHttpDefaultResponse(error: error, url: url)
                return completionHandler(response)
            }
            if let json = data {
                if json.type == .dictionary {
                    let value = json["result"]
                    let item = BookEntity(json: value)
                    let response = YGHttpDefaultResponse(data: item, url: url)
                    return completionHandler(response)
                }
            }
            print("从网络获取数据失败  \(String(describing: url))")
            let response = YGHttpDefaultResponse(error: "从网络获取数据失败", url: url)
            return completionHandler(response)
        }
    }
    
    
    //MARK: 下载小说
    /// 下载小说
    /// - parameter bookId: 小说id
    /// - parameter cursor: 上一章节id
    /// - parameter pageSize: 获取小说章节数
    /// - parameter completionHandler: 结果回调
    func downloadBookWith(bookId:String, cursor:String?, pageSize:String = "100", completionHandler: @escaping (YGHttpDefaultResponse) -> Void) {
        guard bookId.isEmpty == false else {
            let response = YGHttpDefaultResponse(error: "小说ID不能为空")
            return completionHandler(response)
        }
        var dic:Dictionary<String,String>
        if cursor?.isEmpty == false {
            //剩下的章节cursor是上次获取的最后一章的chapterId
            //http://api.zongheng.com/rest?api_key=f573bf3066&book_id=458842&cursor=7642906&method=chapter.list&pageSize=15&sig=B9BD7E971008D5544E8B47AB2560D5D1
            dic = ["book_id":bookId , "method":"chapter.list" , "cursor" : cursor! , "pageSize" : pageSize]
        } else {
            //第一次获取
            //http://api.zongheng.com/rest?api_key=f573bf3066&book_id=458842&method=chapter.first&sig=E64ED73607F04185F0CC39D9E24A6AB7
            dic = ["book_id":bookId , "method":"chapter.first"]
        }
        let url = fetchUrlParamWith(dic: dic)
        getHttpRequest(url: url) { (data, error) in
            guard error == nil else {
                let response = YGHttpDefaultResponse(error: error, url: url)
                return completionHandler(response)
            }
            if let json = data {
                let code = json["code"].intValue
                if code == 200 {
                    if json.type == .dictionary {
                        let result = json["result"]
                        if result.type == .dictionary {//第一章数据
                            let item = ChapterEntity(json: result)
                            item.bookId = bookId
                            let response = YGHttpDefaultResponse(data: item, url: url)
                            return completionHandler(response)
                        } else if result.type == .array {//接下来章节数据
                            var chapterArray:Array<ChapterEntity> = Array<ChapterEntity>() // 章节数据
                            for i in 0..<result.count {
                                let item = ChapterEntity(json: result[i])
                                item.bookId = bookId
                                chapterArray.append(item)
                            }
                            let response = YGHttpDefaultResponse(data: chapterArray, url: url)
                            return completionHandler(response)
                        }
                        return
                    }
                } else if code == 405 {
                    let response = YGHttpDefaultResponse(data: "没有更多章节数据", url: url)
                    return completionHandler(response)
                }
                
            }
            print("从网络获取数据失败  \(String(describing: url))")
            let response = YGHttpDefaultResponse(error: "从网络获取数据失败", url: url)
            return completionHandler(response)
        }
    }
    
    //MARK: 搜索小说
    /// 搜索小说
    /// - parameter query: 搜索内容
    /// - parameter page:  结果页码
    /// - parameter completionHandler: 结果回调
    func searchBookWith(query:String, page:Int, completionHandler: @escaping (YGHttpDefaultResponse) -> Void) {
        guard query.isEmpty == false else {
            let response = YGHttpDefaultResponse(error: "搜索内容不能为空")
            return completionHandler(response)
        }
        //http://api.zongheng.com/rest?api_key=f573bf3066&field=all&method=search&pageNum=1&query=%E5%85%83%E5%B0%8A&sig=3C2A2577275BCADE291C38B22DA1A81D
        let dic = ["field" : "all" , "method":"search" , "pageNum" : String(page) , "query" : query]
        let url = fetchUrlParamWith(dic: dic)
        getHttpRequest(url: url) { (data, error) in
            guard error == nil else {
                let response = YGHttpDefaultResponse(error: error, url: url)
                return completionHandler(response)
            }
            if let json = data {
                if json.type == .dictionary {
                    let result = json["result"]
                    let pageList = result["pageList"]
                    if pageList.type == .array {
                        let count = pageList.count
                        if count > 0 {
                            var booksArray:Array<BookEntity> = Array<BookEntity>()
                            for i in 0..<count {
                                let value = pageList[i]
                                let item = BookEntity(json: value)
                                booksArray.append(item)
                            }
                            let response = YGHttpDefaultResponse(data: booksArray, url: url)
                            return completionHandler(response)
                        }
                        let response = YGHttpDefaultResponse(data: "没有查询到数据", url: url)
                        return completionHandler(response)
                    }
                    let response = YGHttpDefaultResponse(error: "数据失败", url: url)
                    return completionHandler(response)
                }
            }
            print("从网络获取数据失败  \(String(describing: url))")
            let response = YGHttpDefaultResponse(error: "从网络获取数据失败", url: url)
            return completionHandler(response)
        } 
    }
}

extension BookEntity {
    
    convenience init(json:JSON) {
        self.init()
        bookDescription = json["description"].stringValue
        bookDescription = bookDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        bookId = json["bookId"].stringValue
        coverUrl = json["coverUrl"].stringValue
        if coverUrl.hasPrefix("http") == false {
            coverUrl = "http://static.zongheng.com/upload/s_image" + coverUrl
        }
        authorName = json["authorName"].stringValue
        bookName = json["bookName"].stringValue
        categoryName = json["categoryName"].stringValue
        totalWord = json["totalWord"].stringValue
        updateTime = json["updateTime"].stringValue
        if updateTime.count > 10 {
            updateTime = updateTime[0..<10]
        }
    }
}

extension ChapterEntity {
    
    convenience init(json:JSON) {
        self.init()
        chapterId = json["chapterId"].int64Value
        chapterName = json["chapterName"].stringValue
        content = json["content"].stringValue
        content = content.replacingOccurrences(of: "</p>", with: "\n")
        content = content.replacingOccurrences(of: "<p>", with: "　　")
        content = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        createTimeStr = json["createTimeStr"].stringValue
        tomeName = json["tomeName"].stringValue
        updateTimeStr = json["updateTimeStr"].stringValue
        wordNum = json["wordNum"].stringValue
    }
}
