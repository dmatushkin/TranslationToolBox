//
//  TranslationReportViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 21/10/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Cocoa

class TranslationReportViewController: NSViewController, NSTableViewDataSource {

    @IBOutlet weak var keysNotIntranslationTableView: NSTableView!
    @IBOutlet weak var missingTranslationsTableView: NSTableView!
    
    var keysNotInTranslationData: [String] = []
    var missingTranslationsData: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.keysNotIntranslationTableView {
            return self.keysNotInTranslationData.count
        } else {
            return self.missingTranslationsData.count
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableView == self.keysNotIntranslationTableView {
            return self.keysNotInTranslationData[row]
        } else {
            return self.missingTranslationsData[row]
        }
    }
}
