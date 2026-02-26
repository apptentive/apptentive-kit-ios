//
//  ObjectiveCTests.m
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 3/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import ApptentiveKit;

@interface ObjectiveCTests : XCTestCase

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) NSString *signature;
@property (strong, nonatomic) NSURL *serverURL;

@end

@implementation ObjectiveCTests

- (void)setUp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    self.key = [bundle objectForInfoDictionaryKey:@"APPTENTIVE_API_KEY"];
    self.signature = [bundle objectForInfoDictionaryKey:@"APPTENTIVE_API_SIGNATURE"];
    self.serverURL = [NSURL URLWithString:[bundle objectForInfoDictionaryKey:@"APPTENTIVE_API_BASE_URL"]];
}

- (void)testRegisterWithConfiguration {
    ApptentiveConfiguration *configuration = [ApptentiveConfiguration configurationWithApptentiveKey:self.key apptentiveSignature:self.signature];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    configuration.logLevel = ApptentiveLogLevelDebug;
    configuration.shouldSanitizeLogMessages = true;
    configuration.baseURL = [NSURL URLWithString:@"https://example.com"];
    configuration.distributionName = @"Test Distro";
    configuration.distributionVersion = @"1.2.3";

    XCTAssertEqualObjects(configuration.apptentiveKey, self.key);
    XCTAssertEqualObjects(configuration.apptentiveSignature, self.signature);
    XCTAssertEqual(configuration.logLevel, ApptentiveLogLevelDebug);
    XCTAssertEqual(configuration.shouldSanitizeLogMessages, true);
    XCTAssertEqual(configuration.distributionName, @"Test Distro");
    XCTAssertEqual(configuration.distributionVersion, @"1.2.3");

    Apptentive.shared.theme = 0;

    [Apptentive.shared registerWithConfiguration:configuration completion:^(BOOL success){}];
#pragma clang diagnostic pop
}

- (void)testCustomData {
    Apptentive.shared.personName = @"Testy McTestface";
    Apptentive.shared.personEmailAddress = @"test@example.com";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Just make sure this compiles.
    [Apptentive.shared addCustomPersonDataBool:false withKey:@"false"];
    [Apptentive.shared addCustomPersonDataString:@"foo" withKey:@"bar"];
    [Apptentive.shared addCustomPersonDataNumber:@42 withKey:@"the_answer"];
    [Apptentive.shared removeCustomPersonDataWithKey:@"false"];

    [Apptentive.shared addCustomDeviceDataBool:true withKey:@"true"];
    [Apptentive.shared addCustomDeviceDataString:@"fizz" withKey:@"buzz"];
    [Apptentive.shared addCustomDeviceDataNumber:@70 withKey:@"nice + 1"];
    [Apptentive.shared removeCustomDeviceDataWithKey:@"true"];
#pragma clang diagnostic pop

    XCTAssertEqualObjects(Apptentive.shared.personName, @"Testy McTestface");
    XCTAssertEqualObjects(Apptentive.shared.personEmailAddress, @"test@example.com");
}

- (void)testEngage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Engage completion"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [Apptentive.shared engage:@"event" fromViewController:nil completion:^(BOOL success) {
        [expectation fulfill];
    }];
#pragma clang diagnostic pop

    [self waitForExpectations:@[expectation] timeout:2.0];
}

@end
