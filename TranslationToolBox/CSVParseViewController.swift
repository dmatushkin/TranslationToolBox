//
//  CSVParseViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 21/10/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Cocoa
import SwiftSoup

class TranslationReport {
    let emptyTranslations: [String]
    let keysNotInTranslation: [String]

    init(emptyTranslations: [String], keysNotInTranslation: [String]) {
        self.emptyTranslations = emptyTranslations
        self.keysNotInTranslation = keysNotInTranslation
    }
}

class CSVParseViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    override func value(forKeyPath keyPath: String) -> Any? {
        if keyPath == "self.sourceRow" {
            return self.sourceRow
        }
        if keyPath == "self.targetRow" {
            return targetRow
        }
        return nil
    }
    
    override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        if keyPath == "self.sourceRow", let val = value as? Int {
            self.sourceRow = val
        }
        if keyPath == "self.targetRow", let val = value as? Int {
            self.targetRow = val
        }
    }

    @IBOutlet weak var sourceStepper: NSStepper!
    @IBOutlet weak var targetStepper: NSStepper!
    @IBOutlet weak var sourceLabel: NSTextField!
    @IBOutlet weak var targetLabel: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    var dataURL: URL!
    var translationURL: URL!
    var toolboxController: ToolboxViewController!
    
    var sourceRow: Int = 0 {
        didSet {
            self.sourceLabel.stringValue = "Source \(self.sourceRow)"
        }
    }
    var targetRow: Int = 1 {
        didSet {
            self.targetLabel.stringValue = "Target \(self.targetRow)"
            self.tableView.selectColumnIndexes(IndexSet(integer: self.targetRow), byExtendingSelection: false)
        }
    }
    
    private var data:[[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sourceLabel.stringValue = "Source \(self.sourceRow)"
        self.targetLabel.stringValue = "Target \(self.targetRow)"
        if var str = try? String(contentsOf: self.dataURL).replacingOccurrences(of: "\\n", with: " ") {
            while str.contains("  ") {
                str = str.replacingOccurrences(of: "  ", with: " ")                
            }
            let lines = str.components(separatedBy: CharacterSet.newlines)
            if let firstLine = lines.first {
                let headers = firstLine.split(separator: Character(Unicode.Scalar(9)!), maxSplits: Int.max, omittingEmptySubsequences: false)
                let existingColumns = self.tableView.tableColumns
                for column in existingColumns {
                    self.tableView.removeTableColumn(column)
                }
                for (idx, header) in headers.enumerated() {
                    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("tablecolumn_\(idx)"))
                    column.headerCell.stringValue = String(header)
                    self.tableView.addTableColumn(column)
                }
            }
            for line in lines {
                let cells = line.split(separator: Character(Unicode.Scalar(9)!), maxSplits: Int.max, omittingEmptySubsequences: false).map({String($0)})
                if cells.count > 0 && cells.filter({$0.count > 0}).count > 0 {
                    self.data.append(cells)
                }
            }
            self.tableView.reloadData()
            self.tableView.selectColumnIndexes(IndexSet(integer: self.targetRow), byExtendingSelection: false)
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
    
    @IBAction func doneAction(_ sender: Any) {
        do {
            var translationData: [String: String] = [:]
            for line in self.data {
                if line.count > self.sourceRow && line.count > self.targetRow {
                    translationData[line[self.sourceRow]] = line[self.targetRow]
                }
            }
            let data = try String(contentsOf: self.translationURL, encoding: .utf8)
            let xml = try SwiftSoup.parse(data, "", Parser.xmlParser())
            let allKeys = try xml.getElementsByTag("source").compactMap({try? $0.text()})
            var emptyKeys: [String] = []
            let units = try xml.getElementsByTag("trans-unit")
            for unit in units {
                if let source = try unit.getElementsByTag("source").first()?.text() {
                    if let translation = translationData[source] {
                        if let target = try unit.getElementsByTag("target").first() {
                            try target.text(translation)
                        } else {
                            try unit.appendElement("target").text(translation)
                        }
                    } else {
                        if let replacement = Levenshtein.closest(source: source, destination: Array(translationData.keys)), self.confirm(source: source, replacement: replacement), let translation = translationData[replacement] {
                                if let target = try unit.getElementsByTag("target").first() {
                                    try target.text(translation)
                                } else {
                                    try unit.appendElement("target").text(translation)
                                }
                        } else if ((try? unit.getElementsByTag("target").first()?.text())??.count ?? 0) == 0  {
                            if !emptyKeys.contains(source) {
                                emptyKeys.append(source)
                            }
                        }
                    }
                }
            }
            let result = try xml.html().postformat()
            try result.write(to: self.translationURL, atomically: true, encoding: .utf8)
            //self.dismiss(self)
            self.performSegue(withIdentifier: "translationReportSegue", sender: TranslationReport(emptyTranslations: emptyKeys, keysNotInTranslation: translationData.keys.filter({!allKeys.contains($0)})))
        } catch {
            self.fileParseError(message: error.localizedDescription)
        }
    }
    
    private func fileParseError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to parse file"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Close")
        alert.runModal()
    }
    
    private func confirm(source: String, replacement: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Key not found"
        alert.informativeText = "Key \"\(source)\" not found in translation, use \"\(replacement)\" instead?"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        let response = alert.runModal()
        return response.rawValue == 1000
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "translationReportSegue", let controller = segue.destinationController as? TranslationReportViewController, let report = sender as? TranslationReport {
            controller.keysNotInTranslationData = report.keysNotInTranslation
            controller.missingTranslationsData = report.emptyTranslations
        }
    }
}
