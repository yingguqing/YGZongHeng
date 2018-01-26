//
//  CommonUtil.swift
//  YGZongHeng
//
//  Created by wurw on 2017/12/25.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit
import QuartzCore
import Alamofire
import Security

let documentPath = NSHomeDirectory() + "/Documents"
let ScreenWidth = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height
class YGUtil {
    
    //MARK: 显示输入解密ket和iv的弹出框
    static func showInputAlertView() {
        guard "a".encrypt != "jA==" else {return}
        let alertController = UIAlertController(title: "提示", message: "请输入解密的key和iv", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addTextField {(textField: UITextField!) -> Void in
            textField.placeholder = "输入key"
        }
        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = "输入iv"
        }
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (action) in
            if let key = alertController.textFields?.first?.text,
                let iv = alertController.textFields?.last?.text {
                YGUtil.saveCrypt(key: key, iv: iv)
                guard "a".encrypt != "jA==" else {return}
            }
            self.showInputAlertView()
        }
        alertController.addAction(okAction)
        topViewController.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: 获取最顶层的ViewController
    static var topViewController:UIViewController {
        var result:UIViewController
        var window = UIApplication.shared.keyWindow
        if window?.window?.windowLevel != UIWindowLevelNormal {
            let windows = UIApplication.shared.windows
            for tmpWin in windows {
                if tmpWin.windowLevel == UIWindowLevelNormal {
                    window = tmpWin
                }
            }
        }
        let frontView = window?.subviews.first
        let nextResponder = frontView?.next
        if nextResponder is UIViewController {
            result = nextResponder as! UIViewController
        } else {
            result = (window?.rootViewController!)!
        }
        return result
    }
    
    //MARK: 显示信息的弹出框
    static func showAlertViewWith(message:String?) {
        guard message?.isEmpty == false else {
            return
        }
        let alertView = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertView.addAction(UIAlertAction.init(title: "确定", style: UIAlertActionStyle.cancel, handler: nil))
        alertView.show(topViewController, sender: nil)
    }
    
    //返回button所在的UITableViewCell
    static func superUITableViewCell(of: UIView) -> UITableViewCell? {
        for view in sequence(first: of.superview, next: { $0?.superview }) {
            if let cell = view as? UITableViewCell {
                return cell
            }
        }
        return nil
    }
    
    static func getKeychainQuery(service: String) -> NSMutableDictionary {
        return NSMutableDictionary(dictionary:
            [kSecClass: kSecClassGenericPassword,
             kSecAttrService: "com.yingguqing.YGZongHeng",
             kSecAttrAccount: service,
             kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock])
    }
    
    static func saveKeychain(service: String, data: Any) {
        let keychainQuery = self.getKeychainQuery(service: service)
        SecItemDelete(keychainQuery)
        keychainQuery.addEntries(from: [kSecValueData: NSKeyedArchiver.archivedData(withRootObject: data)])
        SecItemAdd(keychainQuery, nil)
    }
    
    static func loadKeychain(service: String) -> Any? {
        let keychainQuery = self.getKeychainQuery(service: service)
        keychainQuery.addEntries(from: [kSecReturnData: kCFBooleanTrue])
        keychainQuery.addEntries(from: [kSecMatchLimit: kSecMatchLimitOne])
        var keyData : AnyObject? = nil
        if SecItemCopyMatching(keychainQuery, &keyData) == noErr {
            let ret = NSKeyedUnarchiver.unarchiveObject(with: keyData as! Data)
            return ret
        } else {
            return nil
        }
    }
    
    //MARK: 保存加解密的key和iv
    static func saveCrypt(key:String,iv:String) {
        saveKeychain(service: AESKey, data: key)
        saveKeychain(service: AESIV, data: iv)
    } 
    
    //MARK: 读取保存的加解密的key和iv
    static func loadCrypt() -> Dictionary<String,String>? {
        if let key = loadKeychain(service: AESKey) as? String,
            let iv = loadKeychain(service: AESIV) as? String {
            return [AESKey:key, AESIV:iv]
        }
        return nil
    }
    
}

// 图片保存路径
let ImageSavePath:String = {
    let path = documentPath.appending(pathComponent: "BookImage")
    if path.fileIsExists == false {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("创建目录失败 \(error.localizedDescription)")
        }
    }
    return path
}()

var ImageDownloadArray = [String]()
let ImageCheckQueue = DispatchQueue.global()

extension UIImageView {
    private struct ImageDownloadStruct {
        static var isBlurEffect:Bool?
    }
    var isBlurEffect:Bool {
        get {
            if let temp = objc_getAssociatedObject(self, &ImageDownloadStruct.isBlurEffect) as? Bool {
                return temp
            }else{
                let temp = false
                objc_setAssociatedObject(self, &ImageDownloadStruct.isBlurEffect, temp, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
                return temp
            }
        }
        set{
            objc_setAssociatedObject(self, &ImageDownloadStruct.isBlurEffect, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    //MARK: 图片下载完成后收到的通知
    @objc fileprivate func imageFinishWith(noti:Notification) {
        if let userInfo = noti.userInfo {
            if let image = userInfo["Image"] as? UIImage {
                showImageWith(image: image)
            }
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    //MARK: 显示图片
    func showImageWith(url:String) {
        showImageWith(url: url, isBlurEffect: false)
    }
    
    /// 显示图片
    /// - parameter url: 图片url
    /// - parameter isBlurEffect: 是否模糊图片
    func showImageWith(url:String, isBlurEffect:Bool) {
        guard url.isEmpty == false else {return}
        self.isBlurEffect = isBlurEffect
        let urlMd5 = url.md5()
        let path = ImageSavePath.appending(pathComponent: urlMd5)
        var isNeedDownload = true
        if let data = try? Data.init(contentsOf: path.toFileURL!) {
            var image = UIImage.init(data: data)
            if image != nil {
                isNeedDownload = false
            } else if self.image != nil {
                image = self.image
            } else {
                image = #imageLiteral(resourceName: "Recommend_Book") //默认图片
            }
            showImageWith(image: image) // 显示图片
        }
        if isNeedDownload { // 需要下载图片
            NotificationCenter.default.addObserver(self, selector: #selector(imageFinishWith(noti:)), name: NSNotification.Name.init(urlMd5), object: nil)
            ImageCheckQueue.sync {// 本地没有图片,在线程里查看是否有下载任务
                if ImageDownloadArray.contains(urlMd5) == false {
                    ImageDownloadArray.append(urlMd5)
                    downloadImageWith(url: url)
                }
            }
        }
    }
    
    //MARK: 下载图片
    fileprivate func downloadImageWith(url:String) {
        let urlMd5 = url.md5()
        let destination:DownloadRequest.DownloadFileDestination = { _, response in
            let fileURL = ImageSavePath.appending(pathComponent: urlMd5).toFileURL
            //两个参数表示如果有同名文件则会覆盖，如果路径中文件夹不存在则会自动创建
            return (fileURL!, [.removePreviousFile, .createIntermediateDirectories])
        }
        //开始下载
        Alamofire.download(url, to: destination).responseData { (response) in
            if let data = response.result.value,
                let image = UIImage(data:data) {
                NotificationCenter.default.post(name: NSNotification.Name.init(urlMd5), object: nil, userInfo: ["Image":image])
                ImageCheckQueue.sync {
                    if let index = ImageDownloadArray.index(of: urlMd5) {
                        ImageDownloadArray.remove(at: index)
                    }
                }
            }
        }
    }
    
    fileprivate func showImageWith(image:UIImage?) {
        guard (image != nil) else {return self.image = nil}
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.15, animations: {
                if self.isBlurEffect {
                    self.image =  image?.applyDarkEffect()
                } else {
                    self.image =  image
                }
            })
        }
    }
}


extension CALayer {
    var borderUIColor:UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        get {
            if let color = self.borderColor {
                return UIColor.init(cgColor: color)
            }
            return UIColor.white
        }
    }
}

