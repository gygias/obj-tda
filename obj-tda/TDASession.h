//
//  TDASession.h
//  obj-tda
//
//  Created by david on 4/3/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <obj-tda/TDAOrder.h>
#import <obj-tda/TDAQuote.h>
#import <obj-tda/TDAPriceHistory.h>
#import <obj-tda/TDABalances.h>
#import <obj-tda/TDAPosition.h>
#import <obj-tda/TDAOptionChain.h>

@interface TDASession : NSObject
{
    NSString *_source;
    NSArray *_accountIDs;
}

- (BOOL)loginWithUser:(NSString *)user pass:(NSString *)pass source:(NSString *)source version:(NSString *)version;
- (BOOL)keepAlive;
- (BOOL)logoff;

// account
- (BOOL)getBalancesAndPositions:(TDABalances **)outBalances :(NSArray **)outPositions;

// info
- (TDAQuote *)getQuote:(NSString *)symbol;
- (NSMutableArray *)getQuotes:(NSArray *)symbols;
- (TDAPriceHistory *)getPriceHistory:(NSString *)symbol
                                    :(IntervalType)interval
                                    :(int)duration
                                    :(PeriodType)periodType
                                    :(int)period
                                    :(NSDate *)startDate
                                    :(NSDate *)endDate
                                    :(BOOL)extended;
- (TDAOptionChain *)getOptionChainForSymbol:(NSString *)symbol;

// orders
- (BOOL)submitOrder:(TDAOrder *)order;
- (BOOL)getOrderStatus:(TDAOrder *)order;
- (BOOL)cancelOrder:(TDAOrder *)order;

@end
