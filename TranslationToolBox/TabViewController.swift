//
//  TabViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 21/10/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Cocoa

class TabViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func setTranslationUrl(url: URL) {
        if let controller = self.tabViewItems.compactMap({$0.viewController as? ToolboxViewController}).first {
            self.selectedTabViewItemIndex = 1
            controller.loadTranslation(url: url)
        }
    }
}
