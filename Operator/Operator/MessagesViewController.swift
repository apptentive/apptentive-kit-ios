//
//  MessagesViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import ApptentiveKit

class MessagesViewController: UITableViewController, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, CustomDataDataSourceDelegate {
    var observation: NSKeyValueObservation?

    var customData = CustomData()

    @IBOutlet weak var openMessageCenterCell: UITableViewCell!
    @IBOutlet weak var unreadMessageCountLabel: UILabel!

    @IBAction func cancelAttachmentText(sender: UIStoryboardSegue) {
        // do nothing, just dismiss.
    }

    @IBAction func sendAttachmentText(sender: UIStoryboardSegue) {
        guard let textViewController = sender.source as? TextViewController else {
            return assertionFailure("Expecting TextViewController")
        }

        self.apptentive.sendAttachment(textViewController.textField.text ?? "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUnreadCount(to: self.apptentive.unreadMessageCount)

        self.observation = self.apptentive.observe(\.unreadMessageCount, options: [.new]) { [weak self] _, _ in
            guard let self = self else { return }
            Task {
                await self.updateUnreadCount(to: self.apptentive.unreadMessageCount)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.prompt = self.customData.keys.count > 0 ? "Message Center will be presented with Custom Data" : nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.observation?.invalidate()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case [0,0]:
            if self.customData.keys.count > 0 {
                self.apptentive.presentMessageCenter(from: self, with: self.customData)
                self.customData = CustomData()
            } else {
                self.apptentive.presentMessageCenter(from: self)
            }
        case [1,1]:
            self.sendAttachmentImage()
        case [1,2]:
            self.sendAttachmentFile()
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if !self.isEditing {
            Task {
                let label = UILabel()

                do {
                    let canShow = try await self.apptentive.canShowMessageCenter()
                    label.text = canShow ? "✅" : "❎"
                } catch let error {
                    label.text = "❌"
                    print("Error during canShowMessageCenter: \(error.localizedDescription)")
                }

                label.sizeToFit()
                tableView.cellForRow(at: indexPath)?.accessoryView = label
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMessageCenterCustomData" {
            guard let customDataViewController = segue.destination as? CustomDataViewController else {
                fatalError("Custom data segue should lead to custom data view controller")
            }

            let dataSource = CustomDataDataSource(self.apptentive)
            dataSource.customData = self.customData
            dataSource.delegate = self

            customDataViewController.dataSource = dataSource
        }
    }

    
    func sendAttachmentImage() {
        let imagePicker = UIImagePickerController()

        imagePicker.delegate = self

        self.present(imagePicker, animated: true)
    }

    func sendAttachmentFile() {
        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: allFileTypes)
        filePicker.delegate = self
        present(filePicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true)

        if let data = try? Data(contentsOf: url) {
            self.apptentive.sendAttachment(data, mediaType: mimeType(for: url))
        } else {
            print("Unable to send file data!")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        picker.dismiss(animated: true)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            self.apptentive.sendAttachment(image)
        } else {
            print("Unable to find picked image!")
        }
    }
    
    func mimeType(for url: URL) -> String {
        return UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }

    private func updateUnreadCount(to value: Int) {
        self.unreadMessageCountLabel.text = String(value)
    }

    let allFileTypes = [
        UTType.item, UTType.content, UTType.compositeContent, UTType.message, UTType.contact, UTType.archive, UTType.diskImage, UTType.data, UTType.directory, UTType.resolvable, UTType.executable, UTType.mountPoint, UTType.aliasFile,
        UTType.urlBookmarkData, UTType.url, UTType.fileURL, UTType.text, UTType.plainText, UTType.utf8PlainText, UTType.utf16ExternalPlainText, UTType.utf16PlainText, UTType.delimitedText, UTType.commaSeparatedText, UTType.tabSeparatedText,
        UTType.utf8TabSeparatedText, UTType.rtf, UTType.html, UTType.xml, UTType.sourceCode, UTType.assemblyLanguageSource, UTType.cSource, UTType.objectiveCSource, UTType.swiftSource, UTType.cPlusPlusSource, UTType.objectiveCPlusPlusSource,
        UTType.cHeader, UTType.cPlusPlusHeader, UTType.script, UTType.appleScript, UTType.osaScript, UTType.osaScriptBundle, UTType.javaScript, UTType.shellScript, UTType.perlScript, UTType.pythonScript, UTType.rubyScript, UTType.phpScript,
        UTType.json, UTType.propertyList, UTType.xmlPropertyList, UTType.binaryPropertyList, UTType.pdf, UTType.rtfd, UTType.flatRTFD, UTType.webArchive, UTType.image, UTType.jpeg, UTType.tiff, UTType.gif, UTType.png, UTType.bmp, UTType.ico,
        UTType.rawImage, UTType.livePhoto, UTType.movie, UTType.video, UTType.audio, UTType.quickTimeMovie, UTType.mpeg, UTType.mpeg2Video, UTType.mpeg2TransportStream, UTType.mp3, UTType.mpeg4Audio, UTType.appleProtectedMPEG4Audio,
        UTType.appleProtectedMPEG4Video, UTType.folder, UTType.volume, UTType.package, UTType.bundle, UTType.pluginBundle, UTType.spotlightImporter, UTType.quickLookGenerator, UTType.xpcService, UTType.framework, UTType.application,
        UTType.applicationBundle, UTType.unixExecutable, UTType.systemPreferencesPane, UTType.spreadsheet, UTType.presentation, UTType.database, UTType.vCard, UTType.toDoItem, UTType.calendarEvent, UTType.emailMessage, UTType.internetLocation,
        UTType.font, UTType.bookmark, UTType.pkcs12, UTType.x509Certificate, UTType.log,
    ]
}
