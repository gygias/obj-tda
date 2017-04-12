//
//  TDAPosition.h
//  obj-tda
//
//  Created by david on 4/11/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LongPosition = 0,
    ShortPosition = 1
} PositionType;

typedef enum {
    PutOption = 0,
    CallOption = 1
} OptionType;

@interface TDAPosition : NSObject

+ (TDAPosition *)positionWithXMLNode:(NSXMLNode *)node;

@property NSString *symbol;
@property NSString *desc;
@property NSString *assetType;
@property PositionType positionType;
@property float quantity;
@property float averagePrice;
@property float currentValue;
@property float lastClose;

// documented but server returns empty elements
@property BOOL isOption;
//@property OptionType optionType;
//@property NSString *underlyingSymbol;

@property NSString *error;

@end
