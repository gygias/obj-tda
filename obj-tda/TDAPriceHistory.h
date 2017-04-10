//
//  TDAPriceHistory.h
//  obj-tda
//
//  Created by david on 4/9/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MinuteInterval = 0,
    DayInterval = 1,
    WeekInterval = 2,
    MonthInterval = 3
} IntervalType;

typedef enum {
    DayPeriod = 0,
    MonthPeriod = 1,
    YearPeriod = 2,
    YTDPeriod = 3
} PeriodType;

@interface TDAPriceHistory : NSObject

@property NSString *symbol;
@property IntervalType interval;
@property int duration;
@property NSDate *startDate;
@property NSDate *endDate;
@property BOOL extended;

@property NSData *bytes;
@property (readonly) NSArray *prices;

@end

@interface TDAPrice : NSObject
@property float open;
@property float close;
@property float high;
@property float low;
@property int volume;
@property NSDate *date;
@end
