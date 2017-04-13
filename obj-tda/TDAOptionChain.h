//
//  TDAOptionChain.h
//  obj-tda
//
//  Created by david on 4/12/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDAQuote.h"

typedef enum {
    RealTime = 0,
    Delayed = 1
} QuotePunctuality;

@interface TDAOptionChain : NSObject

@property NSString *symbol;
@property TDAQuote *quote;
@property NSArray *optionDates;
@property QuotePunctuality punctuality;

+ (TDAOptionChain *)optionChainWithXMLNode:(NSXMLNode *)node;

@end

@interface TDAOptionPart : NSObject

+ (TDAOptionPart *)optionPartWithXML:(NSXMLNode *)node withType:(NSString *)type;

@property TDAQuote *quote;

@property NSString *optionSymbol;

@property int openInterest;
@property int multiplier;
@property int volume;

@property BOOL inTheMoney;
@property BOOL nearTheMoney;

@property double delta;
@property double gamma;
@property double theta;
@property double vega;
@property double rho;
@property double impliedVolatility;
@property double timeValueIndex;

@end

typedef enum {
    ShortDate,
    Weekly,
    Monthly,
    Quarterly,
    Regular,
    Leap
} OptionExpirationType;

@interface TDAOptionDate : NSObject

+ (TDAOptionDate *)optionDateWithXMLNode:(NSXMLNode *)node symbol:(NSString *)symbol;

@property NSString *symbol;
@property NSString *desc;
@property NSDate *date;
@property OptionExpirationType expirationType;
@property int daysToExpiration;

@property NSDictionary *putsByStrike; // TDAOptionPart
@property NSDictionary *callsByStrike; // TDAOptionPart

@property float strike;
@property BOOL isStandard;

@end
