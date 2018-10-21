//
//  LoadTranslationViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 21/10/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Cocoa

class LoadTranslationViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func loadTranslationAction(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["xliff"]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin {[weak self] result in
            if result.rawValue == 1, let fileUrl = panel.url {
                if let controller = self?.parent as? TabViewController {
                    controller.setTranslationUrl(url: fileUrl)
                }
            }
        }
    }
}
