//
//  ChapterEntity.swift
//  YGZongHeng
//
//  Created by wurw on 2017/12/26.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit

class ChapterEntity: NSObject {
    var bookId:String = ""
    var chapterId:Int64 = 0
    var chapterName:String = ""
    var content:String = ""
    var createTimeStr:String = ""
    var tomeName:String = ""
    var updateTimeStr:String = ""
    var wordNum:String = ""
    
    override init() {
        super.init()
    }
}
