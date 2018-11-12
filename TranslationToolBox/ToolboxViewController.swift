//
//  ToolboxViewController.swift
//  TranslationToolBox
//
//  Created by Dmitry Matyushkin on 21/10/2018.
//  Copyright © 2018 Dmitry Matyushkin. All rights reserved.
//

import Cocoa
import SwiftSoup

extension String {
    
    func postformat() -> String {
        return self.replacingOccurrences(of: "target>\n\\s*", with: "target>", options: .regularExpression).replacingOccurrences(of: "\n\\s*</target", with: "</target", options: .regularExpression).replacingOccurrences(of: "\\s*</target", with: "</target", options: .regularExpression).replacingOccurrences(of: "note>\n\\s*", with: "note>", options: .regularExpression).replacingOccurrences(of: "\n\\s*</note", with: "</note", options: .regularExpression).replacingOccurrences(of: "\\s*</note", with: "</note", options: .regularExpression)
    }
}

class ToolboxViewController: NSViewController {

    private var translationUrl: URL?
    @IBOutlet weak var languageTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Toolbox controller loaded")
    }
    
    func loadTranslation(url: URL) {
        print("loading translation")
        self.translationUrl = url
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let xml = try SwiftSoup.parse(data, "", Parser.xmlParser())
            if let file = try xml.getElementsByTag("file").first() {
                self.languageTextField.stringValue = try file.attr("target-language")
            }
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
    
    @IBAction func clearFileAction(_ sender: Any) {
        if let url = self.translationUrl {
            do {
                let data = try String(contentsOf: url, encoding: .utf8)
                let xml = try SwiftSoup.parse(data, "", Parser.xmlParser())
                let targets = try xml.getElementsByTag("target")
                for tag in targets {
                    try tag.text("")
                }
                let result = try xml.html()
                try result.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                self.fileParseError(message: error.localizedDescription)
            }            
        } else {
            self.fileParseError(message: "URL is empty")
        }
    }
    
    @IBAction func setLanguageAction(_ sender: Any) {
        if let url = self.translationUrl {
            do {
                let data = try String(contentsOf: url, encoding: .utf8)
                let xml = try SwiftSoup.parse(data, "", Parser.xmlParser())
                let files = try xml.getElementsByTag("file")
                for tag in files {
                    try tag.attr("target-language", self.languageTextField.stringValue)
                }
                let result = try xml.html().postformat()
                try result.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                self.fileParseError(message: error.localizedDescription)
            }
        } else {
            self.fileParseError(message: "URL is empty")
        }
    }
    
    @IBAction func applyCSVAction(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["tsv"]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin {[weak self] result in
            if result.rawValue == 1, let fileUrl = panel.url {
                self?.performSegue(withIdentifier: "parseCSVSegue", sender: fileUrl)
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "parseCSVSegue", let controller = segue.destinationController as? CSVParseViewController, let url = sender as? URL {
            controller.dataURL = url
            controller.toolboxController = self
            controller.translationURL = self.translationUrl
        }
    }
}
