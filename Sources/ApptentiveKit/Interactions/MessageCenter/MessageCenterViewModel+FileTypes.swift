//
//  MessageCenterViewModel+FileTypes.swift
//  MessageCenterViewModel+FileTypes
//
//  Created by Luqmaan Khan on 11/11/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import PhotosUI
import UIKit

extension MessageCenterViewModel {
    var allUTTypes: [UTType] {
        return [
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
}
