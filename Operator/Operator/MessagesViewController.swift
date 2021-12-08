//
//  MessagesViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit
import MobileCoreServices

class MessagesViewController: UITableViewController, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @IBAction func cancelAttachmentText(sender: UIStoryboardSegue) {
        // do nothing, just dismiss.
    }

    @IBAction func sendAttachmentText(sender: UIStoryboardSegue) {
        guard let textViewController = sender.source as? TextViewController else {
            return assertionFailure("Expecting TextViewController")
        }

        self.apptentive.sendAttachment(textViewController.textField.text ?? "")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case [0,0]:
            self.apptentive.presentMessageCenter(from: self)
        case [1,1]:
            self.sendAttachmentImage()
        case [1,2]:
            self.sendAttachmentFile()
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func sendAttachmentImage() {
        let imagePicker = UIImagePickerController()

        imagePicker.delegate = self

        self.present(imagePicker, animated: true)
    }

    func sendAttachmentFile() {
        let filePicker = UIDocumentPickerViewController(documentTypes: allFileTypes, in: .import)
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
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }

    let allFileTypes = [kUTTypeItem, kUTTypeContent, kUTTypeCompositeContent, kUTTypeMessage, kUTTypeContact, kUTTypeArchive, kUTTypeDiskImage, kUTTypeData, kUTTypeDirectory, kUTTypeResolvable, kUTTypeSymLink, kUTTypeExecutable, kUTTypeMountPoint, kUTTypeAliasFile, kUTTypeAliasRecord, kUTTypeURLBookmarkData, kUTTypeURL, kUTTypeFileURL, kUTTypeText, kUTTypePlainText, kUTTypeUTF8PlainText, kUTTypeUTF16ExternalPlainText, kUTTypeUTF16PlainText, kUTTypeDelimitedText, kUTTypeCommaSeparatedText, kUTTypeTabSeparatedText, kUTTypeUTF8TabSeparatedText, kUTTypeRTF, kUTTypeHTML, kUTTypeXML, kUTTypeSourceCode, kUTTypeAssemblyLanguageSource, kUTTypeCSource, kUTTypeObjectiveCSource, kUTTypeSwiftSource, kUTTypeCPlusPlusSource, kUTTypeObjectiveCPlusPlusSource, kUTTypeCHeader, kUTTypeCPlusPlusHeader, kUTTypeJavaSource, kUTTypeScript, kUTTypeAppleScript, kUTTypeOSAScript, kUTTypeOSAScriptBundle, kUTTypeJavaScript, kUTTypeShellScript, kUTTypePerlScript, kUTTypePythonScript, kUTTypeRubyScript, kUTTypePHPScript, kUTTypeJSON, kUTTypePropertyList, kUTTypeXMLPropertyList, kUTTypeBinaryPropertyList, kUTTypePDF, kUTTypeRTFD, kUTTypeFlatRTFD, kUTTypeTXNTextAndMultimediaData, kUTTypeWebArchive, kUTTypeImage, kUTTypeJPEG, kUTTypeJPEG2000, kUTTypeTIFF, kUTTypePICT, kUTTypeGIF, kUTTypePNG, kUTTypeQuickTimeImage, kUTTypeAppleICNS, kUTTypeBMP, kUTTypeICO, kUTTypeRawImage, kUTTypeScalableVectorGraphics, kUTTypeLivePhoto, kUTTypeAudiovisualContent, kUTTypeMovie, kUTTypeVideo, kUTTypeAudio, kUTTypeQuickTimeMovie, kUTTypeMPEG, kUTTypeMPEG2Video, kUTTypeMPEG2TransportStream, kUTTypeMP3, kUTTypeMPEG4, kUTTypeMPEG4Audio, kUTTypeAppleProtectedMPEG4Audio, kUTTypeAppleProtectedMPEG4Video, kUTTypeAVIMovie, kUTTypeAudioInterchangeFileFormat, kUTTypeWaveformAudio, kUTTypeMIDIAudio, kUTTypePlaylist, kUTTypeM3UPlaylist, kUTTypeFolder, kUTTypeVolume, kUTTypePackage, kUTTypeBundle, kUTTypePluginBundle, kUTTypeSpotlightImporter, kUTTypeQuickLookGenerator, kUTTypeXPCService, kUTTypeFramework, kUTTypeApplication, kUTTypeApplicationBundle, kUTTypeApplicationFile, kUTTypeUnixExecutable, kUTTypeWindowsExecutable, kUTTypeJavaClass, kUTTypeJavaArchive, kUTTypeSystemPreferencesPane, kUTTypeGNUZipArchive, kUTTypeBzip2Archive, kUTTypeZipArchive, kUTTypeSpreadsheet, kUTTypePresentation, kUTTypeDatabase, kUTTypeVCard, kUTTypeToDoItem, kUTTypeCalendarEvent, kUTTypeEmailMessage, kUTTypeInternetLocation, kUTTypeInkText, kUTTypeFont, kUTTypeBookmark, kUTType3DContent, kUTTypePKCS12, kUTTypeX509Certificate, kUTTypeElectronicPublication, kUTTypeLog].map { String($0) }
}
