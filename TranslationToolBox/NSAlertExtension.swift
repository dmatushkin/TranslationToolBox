//
//  NSAlertExtension.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 22/02/2019.
//  Copyright © 2019 Dmitry Matyushkin. All rights reserved.
//

import Cocoa

extension NSAlert {
    
    class func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Close")
        alert.runModal()
    }
}
