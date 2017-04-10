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

typedef enum {
    New = 0,
    Submitted = 1, // sent, remote status not yet known
    Open = 2,
    Expired = 3,
    PartialFilled = 4,
    Filled = 5,
    Pending = 6,
    PendingCancel = 7,
    Canceled = 8,
    PendingReplace = 9,
    Replaced = 10,
    Received = 11,
    ReviewRelease = 12 // manual review
} OrderStatus;

@interface TDAOrder : NSObject

@property NSString *symbol;
@property TDAOrderAction action;
@property TDAOrderType type;
@property int quantity;
@property float price;
@property TimeInForce tif;

// volatile
@property NSString *orderID;
@property OrderStatus status;
@property BOOL cancelable;
@property BOOL editable;
@property NSXMLDocument *response;

// debug
@property NSString *orderString;

// synthesized
@property float estimatedCost;

- (NSString *)orderStringWithAccountID:(NSString *)accountID;

- (BOOL)_updateStatus:(NSXMLDocument *)statusXML;

@end
