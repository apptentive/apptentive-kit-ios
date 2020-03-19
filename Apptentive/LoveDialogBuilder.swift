//
//  LoveDialogBuilder.swift
//  Apptentive
//
//  Created by Apptentive on 3/4/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import UIKit

public struct LoveDialogConfiguration: Equatable {
    public let promptText: String
    public let affirmativeText: String
    public let negativeText: String
    
    public init(promptText: String = "", affirmativeText: String = "", negativeText: String = "") {
        self.promptText = promptText
        self.affirmativeText = affirmativeText
        self.negativeText = negativeText
    }
}

struct LoveDialogBuilder {
    static func build(with configuration: LoveDialogConfiguration, appName: String) -> UIViewController {
        let defaultConfiguration = Self.defaultConfiguration(appName: appName)
        let mergedConfiguration = Self.mergedConfiguration(defaultConfiguration: defaultConfiguration, configuration: configuration)
        
        let loveDialog = Self.loveDialog(with: mergedConfiguration)
        
        return loveDialog
    }
    
    static func mergedConfiguration(defaultConfiguration: LoveDialogConfiguration, configuration: LoveDialogConfiguration) -> LoveDialogConfiguration {
        
        let mergedConfiguration = LoveDialogConfiguration(
            promptText: Self.defaultIfBlank(configuration.promptText, to: defaultConfiguration.promptText),
            affirmativeText: Self.defaultIfBlank(configuration.affirmativeText, to: defaultConfiguration.affirmativeText),
            negativeText: Self.defaultIfBlank(configuration.negativeText, to: defaultConfiguration.negativeText)
        )
        
        return mergedConfiguration
    }
    
    static func defaultConfiguration(appName: String) -> LoveDialogConfiguration {
        let validAppName = Self.defaultIfBlank(appName, to: "us")
        let promptText = "Do you love \(validAppName)?"
        let result = LoveDialogConfiguration(promptText: promptText, affirmativeText: "Yes", negativeText: "Not Yet")
        
        return result
    }
    
    static func defaultIfBlank(_ text: String, to defaultText: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return defaultText
        }
        
        return text
    }
    
    static func loveDialog(with configuration: LoveDialogConfiguration) -> UIViewController {
        let alertController = UIAlertController(title: configuration.promptText, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: configuration.affirmativeText, style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: configuration.negativeText, style: .default, handler: nil))
        
        return alertController
    }
}
