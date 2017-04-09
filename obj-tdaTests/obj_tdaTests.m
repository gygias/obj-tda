//
//  obj_tdaTests.m
//  obj-tdaTests
//
//  Created by david on 4/3/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TDASession.h"
#import "TDAOrder.h"

@interface obj_tdaTests : XCTestCase

@end

@implementation obj_tdaTests

- (void)setUp {
    [super setUp];
    //self.continueAfterFailure = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    TDASession *ses = [TDASession new];
    BOOL okay = [ses loginWithUser:<#user#> pass:<#pass#> source:<#source#> version:<#version#>];
    XCTAssert(okay,@"login failed");
    //okay = [ses getBalancesAndPositions];
    //XCTAssert(okay,@"get b&p failed");
    
//#define TEST_ORDER
#ifdef TEST_ORDER
    TDAOrder *order = [TDAOrder new];
    order.symbol = @"dgaz";
    order.action = Buy;
    order.type = LimitOrder;
    order.quantity = 100;
    order.price = 2.5;
    order.tif = DayTIF;
    
    okay = [ses submitOrder:order];
    XCTAssert(okay,@"submit order failed");
    
    if ( okay ) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
        
        okay = [ses cancelOrder:order];
        XCTAssert(okay,@"cancel order failed");
    }
#endif
    
    okay = [ses logoff];
    XCTAssert(okay,@"logoff failed");
}

@end
