//
//  ExtractionViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 22/02/2019.
//  Copyright © 2019 Dmitry Matyushkin. All rights reserved.
//

import Cocoa
import SwiftSoup

class TranslationPair: Equatable {
    let source: String
    let target: String

    init(source: String, target: String) {
        self.source = source
        self.target = target
    }
    
    static func == (lhs: TranslationPair, rhs: TranslationPair) -> Bool {
        return lhs.source == rhs.source && lhs.target == rhs.target
    }
}

class ExtractionViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView: NSTableView!
    
    var translationUrl: URL?
    
    private var data:[[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.becomeFirstResponder()
        let existingColumns = self.tableView.tableColumns
        for column in existingColumns {
            self.tableView.removeTableColumn(column)
        }
        for (idx, header) in ["Source", "Target"].enumerated() {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("tablecolumn_\(idx)"))
            column.headerCell.stringValue = header
            self.tableView.addTableColumn(column)
        }
        if let url = self.translationUrl {
            do {
                let data = try String(contentsOf: url, encoding: .utf8)
                let xml = try SwiftSoup.parse(data, "", Parser.xmlParser())
                let units = try xml.getElementsByTag("trans-unit")
                var pairs: [TranslationPair] = []
                for unit in units {
                    if let source = try unit.getElementsByTag("source").first()?.text(), let target = try unit.getElementsByTag("target").first()?.text() {
                        let pair = TranslationPair(source: source, target: target)
                        if !pairs.contains(pair) {
                            pairs.append(pair)
                        }
                    }
                }
                pairs.sort(by: {$0.source < $1.source})
                self.data = pairs.map({[$0.source, $0.target]})
                self.tableView.reloadData()
            } catch {
                NSAlert.showError(title: "Unable to parse file", message: error.localizedDescription)
            }
        } else {
            NSAlert.showError(title: "Unable to parse file", message: "URL is empty")
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let idx = tableColumn?.identifier.rawValue, let str = idx.components(separatedBy: "_").last, let col = Int(str) {
            let rowData = self.data[row]
            if col < rowData.count {
                return rowData[col]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
        
    @IBAction func copy(_ sender: Any?){
        var textToDisplayInPasteboard = ""
        let rows = self.tableView.selectedRowIndexes
        let columns = self.tableView.selectedColumnIndexes
        if rows.count > 0 {
            for rowIndex in rows {
                var line = ""
                if textToDisplayInPasteboard.count > 0 {
                    textToDisplayInPasteboard.append("\n")
                }
                for cellData in self.data[rowIndex] {
                    if line.count > 0 {
                        line.append(" -> ")
                    }
                    line.append(cellData)
                }
                textToDisplayInPasteboard.append(line)
            }
        }
        if columns.count > 0 {
            for lineData in self.data {
                if textToDisplayInPasteboard.count > 0 {
                    textToDisplayInPasteboard.append("\n")
                }
                var line = ""
                for columnIndex in columns {
                    let cellData = lineData[columnIndex]
                    if line.count > 0 {
                        line.append(" -> ")
                    }
                    line.append(cellData)
                }
                textToDisplayInPasteboard.append(line)
            }
        }
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(textToDisplayInPasteboard, forType: NSPasteboard.PasteboardType.string)
    }
}
