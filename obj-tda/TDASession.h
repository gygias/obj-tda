//
//  TDASession.h
//  obj-tda
//
//  Created by david on 4/3/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDAOrder.h"
#import "TDAQuote.h"
#import "TDAPriceHistory.h"

@interface TDASession : NSObject
{
    NSString *_source;
    NSArray *_accountIDs;
}

- (BOOL)loginWithUser:(NSString *)user pass:(NSString *)pass source:(NSString *)source version:(NSString *)version;
- (BOOL)keepAlive;
- (BOOL)logoff;

// account
- (BOOL)getBalancesAndPositions;

// info
- (TDAQuote *)getQuote:(NSString *)symbol;
- (TDAPriceHistory *)getPriceHistory:(NSString *)symbol
                                    :(IntervalType)interval
                                    :(int)duration
                                    :(PeriodType)periodType
                                    :(int)period
                                    :(NSDate *)startDate
                                    :(NSDate *)endDate
                                    :(BOOL)extended;

// orders
- (BOOL)submitOrder:(TDAOrder *)order;
- (BOOL)cancelOrder:(TDAOrder *)order;

@end
