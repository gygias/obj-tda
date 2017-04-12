//
//  TDABalances.h
//  obj-tda
//
//  Created by david on 4/11/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDABalances : NSObject

+ (TDABalances *)balancesWithXMLNode:(NSXMLNode *)node;

@property BOOL isDayTrader;
@property int roundTrips;

@property double cashInitial;
@property double cashCurrent;
@property double cashChange;

@property double accountInitial;
@property double accountCurrent;
@property double accountChange;

@property double stockBuyingPower;
@property double optionBuyingPower;
@property double dayBuyingPower;
@property double availableFundsForTrading;

@end
