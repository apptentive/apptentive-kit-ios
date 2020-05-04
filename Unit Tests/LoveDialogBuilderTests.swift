//
//  LoveDialogBuilderTests.swift
//  ApptentiveUnitTests
//
//  Created by Apptentive on 3/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest
@testable import Apptentive

class LoveDialogBuilderTests: XCTestCase {
    
    func testBuildsDefaultConfiguration() {
        let expectedConfiguration = LoveDialogConfiguration(promptText: "Do you love us?", affirmativeText: "Yes", negativeText: "Not Yet")
        
        let defaultConfiguration = LoveDialogBuilder.defaultConfiguration(appName: "")
        
        XCTAssertEqual(expectedConfiguration, defaultConfiguration)
    }
    
    func testReturnsDefaultConfigurationTextIfBlank() {
        let defaultText = "foo"
        
        let blankText: String = " "
        let nonBlankText = LoveDialogBuilder.defaultIfBlank(blankText, to: defaultText)
        
        XCTAssertEqual(nonBlankText, defaultText)
    }
    
    func testReturnsCustomConfigurationTextIfValid() {
        let defaultText = "foo"
        
        let text: String = "bar"
        let validText = LoveDialogBuilder.defaultIfBlank(text, to: defaultText)
        
        XCTAssertEqual(validText, text)
    }
    
    func testBuildsLoveDialogWithMergedConfigurationOrder() {
        let configuration = LoveDialogConfiguration(promptText: "P", affirmativeText: "Y", negativeText: "N")
        
        guard let alertController = LoveDialogBuilder.loveDialog(with: configuration) as? UIAlertController else {
            return XCTFail("View controller is not an alert controller")
        }
        
        XCTAssertEqual(alertController.title, configuration.promptText)
        
        XCTAssertEqual(alertController.actions[0].title, configuration.affirmativeText)
        XCTAssertEqual(alertController.actions[1].title, configuration.negativeText)
    }
}
