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
    
    TDABalances *balances = nil;
    NSArray *positions = nil;
    okay = [ses getBalancesAndPositions:&balances :&positions];
    XCTAssert(okay,@"get b&p failed");
    NSLog(@"balances: %@",balances);
    NSLog(@"positions:\n%@",positions);
    
    okay = [ses keepAlive];
    XCTAssert(okay,@"keep alive failed");
    
    NSString *symbol = @"chk";
    TDAOptionChain *chain = [ses getOptionChainForSymbol:symbol];
    XCTAssert(chain,@"failed to get option chain for %@",symbol);
    for ( TDAOptionDate *optionDate in chain.optionDates ) {
        NSLog(@"%@",optionDate);
    }
    
    symbol = @"aapl";
    TDAPriceHistory *ph = [ses getPriceHistory:symbol :MinuteInterval :5 :DayPeriod :10 :nil :nil :NO];
    XCTAssert(ph,@"price history failed");
    NSArray *prices = ph.prices;
    XCTAssert(prices,@"price history parse failed");
    XCTAssert([prices count] == 780,@"got %ld prices",[prices count]);
    NSLog(@"%@ prices 5 min / 10 days:",symbol);
    for ( TDAPrice *price in prices ) {
        //printf("%0.2f.. ",price.close);
        XCTAssert(price.close>100 && price.close<200,@"bogus price %0.2f",price.close);
    }
    
    TDAQuote *quote = [ses getQuote:@"jnug"];
    XCTAssert(quote,@"get quote failed");
    XCTAssert([quote.symbol isEqualToString:@"JNUG"],@"get quote failed");
    XCTAssert(quote.last > 0,@"get quote failed");
    XCTAssert(quote.last < 100,@"get quote failed");
    
#define TEST_ORDER
#ifdef TEST_ORDER
    TDAOrder *order = [TDAOrder new];
    order.symbol = @"aapl";
    order.action = Buy;
    order.type = LimitOrder;
    order.quantity = 100;
    order.price = 1.5;
    order.tif = DayTIF;
    
    okay = [ses submitOrder:order];
    XCTAssert(okay,@"submit order failed");
    
    if ( okay ) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        
        okay = [ses getOrderStatus:order];
        XCTAssert(okay,@"order status failed");
        XCTAssert(order.status == Open,@"order is not open");
        XCTAssert(order.editable,@"order is not editable");
        XCTAssert(order.cancelable,@"order is not cancelable");
        
        okay = [ses cancelOrder:order];
        XCTAssert(okay,@"cancel order failed");
    }
#endif
    
    okay = [ses logoff];
    XCTAssert(okay,@"logoff failed");
}

@end
