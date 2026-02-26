//
//  ObjectiveCUnitTests.m
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 4/11/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@import ApptentiveKit;

@interface ObjectiveCUnitTests : XCTestCase

@property (nonatomic, strong) Apptentive *apptentive;

@end

@implementation ObjectiveCUnitTests

- (void)setUp {
    self.apptentive = Apptentive.shared;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEngage {
    BOOL result = [self.apptentive engage:<#(NSString * _Nonnull)#> fromViewController:<#(UIViewController * _Nullable)#>]
}

@end
