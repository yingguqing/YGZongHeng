//
//  BaseViewController.swift
//  YGZongHeng
//
//  Created by 影孤清 on 2017/12/26.
//  Copyright © 2017年 yingguqing. All rights reserved.
//

import UIKit
//com.sijiu.newgamebox
//com.yingguqing.YGZongHeng
let greenColor = UIColor(red: 52/255.0, green: 209/255.0, blue: 178/255.0, alpha: 1)
class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarItem.setTitleTextAttributes([NSAttributedStringKey.foregroundColor:greenColor], for: UIControlState.selected)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = self.title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
}
