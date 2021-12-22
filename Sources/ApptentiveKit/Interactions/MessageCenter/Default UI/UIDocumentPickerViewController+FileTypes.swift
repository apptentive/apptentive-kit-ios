//
//  UIDocumentPickerViewController+FileTypes.swift
//  UIDocumentPickerViewController+FileTypes
//
//  Created by Luqmaan Khan on 11/11/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import PhotosUI
import UIKit

extension UIDocumentPickerViewController {

    @available(iOS 14.0, *)
    static var allUTTypes: [UTType] {
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

    static var allFileTypes: [String] {

        return [
            kUTTypeItem, kUTTypeContent, kUTTypeCompositeContent, kUTTypeMessage, kUTTypeContact, kUTTypeArchive, kUTTypeDiskImage, kUTTypeData, kUTTypeDirectory, kUTTypeResolvable, kUTTypeSymLink, kUTTypeExecutable, kUTTypeMountPoint, kUTTypeAliasFile,
            kUTTypeAliasRecord, kUTTypeURLBookmarkData, kUTTypeURL, kUTTypeFileURL, kUTTypeText, kUTTypePlainText, kUTTypeUTF8PlainText, kUTTypeUTF16ExternalPlainText, kUTTypeUTF16PlainText, kUTTypeDelimitedText, kUTTypeCommaSeparatedText,
            kUTTypeTabSeparatedText, kUTTypeUTF8TabSeparatedText, kUTTypeRTF, kUTTypeHTML, kUTTypeXML, kUTTypeSourceCode, kUTTypeAssemblyLanguageSource, kUTTypeCSource, kUTTypeObjectiveCSource, kUTTypeSwiftSource, kUTTypeCPlusPlusSource,
            kUTTypeObjectiveCPlusPlusSource, kUTTypeCHeader, kUTTypeCPlusPlusHeader, kUTTypeJavaSource, kUTTypeScript, kUTTypeAppleScript, kUTTypeOSAScript, kUTTypeOSAScriptBundle, kUTTypeJavaScript, kUTTypeShellScript, kUTTypePerlScript,
            kUTTypePythonScript, kUTTypeRubyScript, kUTTypePHPScript, kUTTypeJSON, kUTTypePropertyList, kUTTypeXMLPropertyList, kUTTypeBinaryPropertyList, kUTTypePDF, kUTTypeRTFD, kUTTypeFlatRTFD, kUTTypeTXNTextAndMultimediaData, kUTTypeWebArchive,
            kUTTypeImage, kUTTypeJPEG, kUTTypeJPEG2000, kUTTypeTIFF, kUTTypePICT, kUTTypeGIF, kUTTypePNG, kUTTypeQuickTimeImage, kUTTypeAppleICNS, kUTTypeBMP, kUTTypeICO, kUTTypeRawImage, kUTTypeScalableVectorGraphics, kUTTypeLivePhoto,
            kUTTypeAudiovisualContent, kUTTypeMovie, kUTTypeVideo, kUTTypeAudio, kUTTypeQuickTimeMovie, kUTTypeMPEG, kUTTypeMPEG2Video, kUTTypeMPEG2TransportStream, kUTTypeMP3, kUTTypeMPEG4, kUTTypeMPEG4Audio, kUTTypeAppleProtectedMPEG4Audio,
            kUTTypeAppleProtectedMPEG4Video, kUTTypeAVIMovie, kUTTypeAudioInterchangeFileFormat, kUTTypeWaveformAudio, kUTTypeMIDIAudio, kUTTypePlaylist, kUTTypeM3UPlaylist, kUTTypeFolder, kUTTypeVolume, kUTTypePackage, kUTTypeBundle, kUTTypePluginBundle,
            kUTTypeSpotlightImporter, kUTTypeQuickLookGenerator, kUTTypeXPCService, kUTTypeFramework, kUTTypeApplication, kUTTypeApplicationBundle, kUTTypeApplicationFile, kUTTypeUnixExecutable, kUTTypeWindowsExecutable, kUTTypeJavaClass,
            kUTTypeJavaArchive, kUTTypeSystemPreferencesPane, kUTTypeGNUZipArchive, kUTTypeBzip2Archive, kUTTypeZipArchive, kUTTypeSpreadsheet, kUTTypePresentation, kUTTypeDatabase, kUTTypeVCard, kUTTypeToDoItem, kUTTypeCalendarEvent, kUTTypeEmailMessage,
            kUTTypeInternetLocation, kUTTypeInkText, kUTTypeFont, kUTTypeBookmark, kUTType3DContent, kUTTypePKCS12, kUTTypeX509Certificate, kUTTypeElectronicPublication, kUTTypeLog,
        ].map { String($0) }
    }
}
