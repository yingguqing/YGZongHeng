//
//  YGPreferences.swift
//  YGZongHeng
//
//  Created by wurw on 2018/1/26.
//  Copyright © 2018年 yingguqing. All rights reserved.
//

import UIKit

class YGPreferences: NSObject {
    let plistPath = documentPath.appending(pathComponent: "YG.plist")
    static let `default`:YGPreferences = { 
        let p = YGPreferences()
        p.savePlist()
        return p
    }()
    
    // 下载链接：http://api1.zongheng.com/ios/recordDeviceId?bagType=-1&bookId=703968&screenW=750&screenH=1334
    var BookIdType:String = "bookId="//最后下载url里bookId，可能会变
    var DownloadType:String = "ios/recordDeviceId"//下载小说点击链接的标识，因为其他链接也会有bookid这个参数
    var ZongHengType:String = "zongheng.com"//用于过滤其他非纵横小说的链接，如果不想过滤，可以用*
    
    override init() {
        if let dic = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String,String> {
            for (key,value) in dic {
                if key == "BookIdType" {
                    BookIdType = value
                } else if key == "DownloadType" {
                    DownloadType = value
                } else if key == "ZongHengType" {
                    ZongHengType = value
                }
            }
        }
    }
    
    func savePlist() {
        guard plistPath.fileIsExists == false else {
            return
        }
        let dec = "参照下载链接：http://api1.zongheng.com/ios/recordDeviceId?bagType=-1&bookId=703968&screenW=750&screenH=1334\nBookIdType是最后下载url里bookId，可能会变\nDownloadType是下载小说点击链接的标识，因为其他链接也会有bookid这个参数\nZongHengType用于过滤其他非纵横小说的链接，如果不想过滤，可以用*"
        let dic:NSDictionary = ["BookIdType":BookIdType,"DownloadType":DownloadType,"ZongHengType":ZongHengType,"说明":dec]
        dic.write(toFile: plistPath, atomically: true)
    }
}
