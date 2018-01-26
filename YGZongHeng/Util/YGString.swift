//
//  UntitlString.swift
//  TextBookFromHtml
//
//  Created by 影孤清 on 2017/11/1.
//  Copyright © 2017年 影孤清. All rights reserved.
//

import UIKit
import CryptoSwift

let AESKey = "SaveAESKey"
let AESIV  = "SaveAESIV"

extension String {
    public func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    public func appending(pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
    
    //MARK: 删除后缀的文件名
    ///删除后缀的文件名
    var fileNameWithoutExtension:String {
        get {
            return ((self as NSString).lastPathComponent as NSString).deletingPathExtension
        }
    }
    
    //MARK: 获得文件的扩展类型（不带'.'）
    ///获得文件的扩展类型（不带'.'）
    var pathExtension:String {
        get {
            return (self as NSString).pathExtension
        }
    }
    
    //MARK: 从路径中获得完整的文件名（带后缀）
    ///从路径中获得完整的文件名（带后缀）
    var lastPathComponent:String {
        get {
            return (self as NSString).lastPathComponent
        }
    }
    //MARK: 删除最后一个后缀
    ///删除最后一个后缀 可以是整个文件名,可以是文件夹名
    var deletingLastPathComponent:String {
        get {
            return (self as NSString).deletingLastPathComponent
        }
    }
    
    //MARK:获得文件名（不带后缀）
    ///获得文件名（不带后缀）
    var deletingPathExtension:String {
        get {
            return (self as NSString).deletingPathExtension
        }
    }
    
    //MARK: 文件是否存在
    ///文件是否存在
    var fileIsExists:Bool {
        get {
            let mgr = FileManager.default
            if self.isEmpty == false {
                return mgr.fileExists(atPath: self)
            }
            return false
        }
    }
    
    var toFileURL:URL? {
        get {
            if self.isEmpty == false {
                return URL(fileURLWithPath: self)
            }
            return nil
        }
    }
    
    var toURL:URL? {
        get {
            if self.isEmpty == false {
                return toURL(isPercentEncoding: true)
            }
            return nil
        }
    }
    
    public func toURL(isPercentEncoding:Bool) -> URL? {
        if isPercentEncoding {// 是否进行url编码
            if self.isEmpty == false,
                let urlStr = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: urlStr)
            }
        } else {
            return URL(string: self)
        }
        return nil
    }
    
    var toURLRequest:URLRequest? {
        get {
            if let url = self.toURL(isPercentEncoding: true) {
                return URLRequest(url: url)
            }
            return nil
        }
    }
    
    var isEmailAddress:Bool {
        get {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            let emailTest:NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailTest.evaluate(with:self)
        }
    }
    
    var chineseInitials:String {
        get {
            if let str1 = self.applyingTransform(StringTransform.toLatin, reverse: false) {
                if let str2 = str1.applyingTransform(StringTransform.stripCombiningMarks, reverse: false) {
                    let pinyin = str2.capitalized
                    var headPinyinStr = ""
                    // 获取所有大写字母
                    for ch in pinyin {
                        if ch <= "Z" && ch >= "A" {
                            headPinyinStr.append(ch)
                        }
                    }
                    return headPinyinStr
                }
            }
            return ""
        }
    }
    
    private func validIndex(original: Int) -> String.Index {
        switch original {
        case ...startIndex.encodedOffset : return startIndex
        case endIndex.encodedOffset...   : return endIndex
        default                          : return index(startIndex, offsetBy: original)
        }
    }
    
    private func validStartIndex(original: Int) -> String.Index? {
        guard original <= endIndex.encodedOffset else { return nil }
        return validIndex(original:original)
    }
    
    private func validEndIndex(original: Int) -> String.Index? {
        guard original >= startIndex.encodedOffset else { return nil }
        return validIndex(original:original)
    }
    
    subscript(_ range: CountableRange<Int>) -> String {
        guard
            let startIndex = validStartIndex(original: range.lowerBound),
            let endIndex   = validEndIndex(original: range.upperBound),
            startIndex < endIndex
            else {
                return ""
        }
        return String(self[startIndex..<endIndex])
    }
    
    //使用正则表达式替换
    func regularReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, self.count), withTemplate: with)
    }
    
    //MARK: 判断是否是小数
    var isPurnFloat:Bool {
        get {
            let scan: Scanner = Scanner(string: self)
            var val:Float = 0
            return scan.scanFloat(&val) && scan.isAtEnd
        }
    }
    
    //MARK: 判断是否是整数
    var isPurnInt:Bool {
        get {
            let scan: Scanner = Scanner(string: self)
            var val:Int = 0
            return scan.scanInt(&val) && scan.isAtEnd
        }
    }
    
    //MARK: 对字符串加密
    var encrypt:String {
        if let dic = YGUtil.loadCrypt(),
            let key = dic[AESKey],
            let iv = dic[AESIV],
            let bytes = self.data(using: String.Encoding.utf8, allowLossyConversion: false)?.bytes {
            YGUtil.saveCrypt(key: key, iv: iv)
            do {//使用ChaCha20加密模式
                let chiper = try ChaCha20(key: key, iv: iv)
                let encrypted = try chiper.encrypt(bytes)
                return encrypted.toBase64()!
            } catch {
                print("加密失败")
            }
        }
        return ""
    }
    
    //MARK: 对字符串解密
    var decrypt:String {
        if let dic = YGUtil.loadCrypt(),
            let key = dic[AESKey],
            let iv = dic[AESIV] {
            do {//使用ChaCha20加密模式
                let chiper = try ChaCha20(key: key, iv: iv)
                let decrypted = try chiper.decrypt(Array.init(base64: self))
                return String(data: Data(decrypted), encoding: .utf8)!
            } catch {
                print("解密失败")
            }
        }
        return ""
    }
    
    //MARK: 计算文字高度（width最大宽度）
    func textHeigh(font:UIFont, width:CGFloat) -> CGFloat {
        let normalText: NSString = self as NSString
        let size = CGSize(width: width, height: 999999)
        let dic = [NSAttributedStringKey.font:font]
        let stringSize = normalText.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: dic, context:nil).size
        return stringSize.height
    }
    
    // 对象方法
    var getFileSize:UInt64 {
        get {
            var size: UInt64 = 0
            let fileManager = FileManager.default
            var isDir: ObjCBool = false
            let isExists = fileManager.fileExists(atPath: self, isDirectory: &isDir)
            // 判断文件存在
            if isExists {
                // 是否为文件夹
                if isDir.boolValue {
                    // 迭代器 存放文件夹下的所有文件名
                    let enumerator = fileManager.enumerator(atPath: self)
                    for subPath in enumerator! {
                        // 获得全路径
                        let fullPath = self.appending("/\(subPath)")
                        do {
                            let attr = try fileManager.attributesOfItem(atPath: fullPath)
                            size += attr[FileAttributeKey.size] as! UInt64
                        } catch  {
                            print(error.localizedDescription)
                        }
                    }
                } else {    // 单文件
                    do {
                        let attr = try fileManager.attributesOfItem(atPath: self)
                        size += attr[FileAttributeKey.size] as! UInt64
                        
                    } catch  {
                        print(error.localizedDescription)
                    }
                }
            }
            return size
        }
    }
}
