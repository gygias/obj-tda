//
//  TDAOrder.h
//  obj-tda
//
//  Created by david on 4/8/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Buy = 0,
    Sell = 1,
    SellShort = 2,
    BuyToCover = 3
} TDAOrderAction;

typedef enum {
    MarketOrder = 0,
    LimitOrder = 1,
    StopOrder = 2,
    StopLimitOrder = 3
} TDAOrderType;

typedef enum {
    DayTIF = 0,
    GTCTIF = 1,
    GTCExtTIF = 2
} TimeInForce;

@interface TDAOrder : NSObject

@property NSString *symbol;
@property TDAOrderAction action;
@property TDAOrderType type;
@property int quantity;
@property float price;
@property TimeInForce tif;

// volatile
@property NSString *orderID;
@property NSXMLDocument *response;
@property BOOL executed;

// synthesized
@property float estimatedCost;

- (NSString *)orderStringWithAccountID:(NSString *)accountID;

@end
