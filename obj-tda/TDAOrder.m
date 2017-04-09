//
//  TDAOrder.m
//  obj-tda
//
//  Created by david on 4/8/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDAOrder.h"

#define INVALID_ORDER (-1);

@implementation TDAOrder

- (id)init
{
    if ( self = [super init] ) {
        self.action = INVALID_ORDER;
        self.type = INVALID_ORDER;
        self.tif = INVALID_ORDER;
        self.price = INVALID_ORDER;
        self.quantity = INVALID_ORDER;
    }
    return self;
}

- (NSString *)orderStringWithAccountID:(NSString *)accountID {
    
    NSMutableString *orderString = [NSMutableString string];
    
    [orderString appendFormat:@"accountid=%@~symbol=%@~action=",accountID,[self.symbol uppercaseString]]; // XXXXXXX
    switch(self.action) {
        case Buy:
            [orderString appendFormat:@"buy"];
            break;
        case Sell:
            [orderString appendFormat:@"sell"];
            break;
        case SellShort:
            [orderString appendFormat:@"sellshort"];
            break;
        case BuyToCover:
            [orderString appendFormat:@"buytocover"];
            break;
        default:
            NSLog(@"invalid order action");
            return NO;
    }
    
    [orderString appendFormat:@"~expire="];
    switch(self.tif) {
        case DayTIF:
            [orderString appendFormat:@"day"];
            break;
        case GTCTIF:
            [orderString appendFormat:@"gtc"];
            break;
        case GTCExtTIF:
            [orderString appendFormat:@"gtc_ext"];
            break;
        default:
            NSLog(@"invalid order tif");
            return NO;
    }
    
    [orderString appendFormat:@"~ordtype="];
    switch(self.type) {
        case MarketOrder:
            [orderString appendFormat:@"market"];
            break;
        case LimitOrder:
            [orderString appendFormat:@"limit"];
            break;
        case StopOrder:
            [orderString appendFormat:@"stop_market"];
            break;
        case StopLimitOrder:
            [orderString appendFormat:@"stop_limit"];
            break;
        default:
            NSLog(@"invalid order type");
            return nil;
    }
    
    if ( self.type == LimitOrder || self.type == StopLimitOrder )
        [orderString appendFormat:@"~price=%0.2f",self.price];
    
    [orderString appendFormat:@"~quantity=%d",self.quantity];
    
    return orderString;
}

@end
