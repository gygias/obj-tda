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
        self.status = New;
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

- (BOOL)_updateStatus:(NSXMLDocument *)statusXML
{
    BOOL okay = YES;
    NSError *error = nil;
    NSArray *nodes = [statusXML nodesForXPath:@"//display-status" error:&error];
    if ( [nodes count] != 1 ) {
        NSLog(@"error: %ld display status for order %@",[nodes count],self.orderID);
        return NO;
    }
    
    NSString *displayStatus = [[nodes lastObject] stringValue];
    if ( [displayStatus isEqualToString:@"Open"] )
        self.status = Open;
    else if ( [displayStatus isEqualToString:@"Filled"] )
        self.status = Filled;
    else if ( [displayStatus isEqualToString:@"Expired"] )
        self.status = Expired;
    else if ( [displayStatus isEqualToString:@"Pending"] )
        self.status = Pending;
    else if ( [displayStatus isEqualToString:@"Pending Cancel"] )
        self.status = PendingCancel;
    else if ( [displayStatus isEqualToString:@"Canceled"] )
        self.status = Canceled;
    else if ( [displayStatus isEqualToString:@"Pending Replace"] )
        self.status = PendingReplace;
    else if ( [displayStatus isEqualToString:@"Replaced"] )
        self.status = Replaced;
    else if ( [displayStatus isEqualToString:@"Received"] )
        self.status = Received;
    else if ( [displayStatus isEqualToString:@"Review/Release"] )
        self.status = ReviewRelease;
    else {
        NSLog(@"*** warning: unknown display status for %@: %@",self.orderID,displayStatus);
        okay = NO;
    }
    
    nodes = [statusXML nodesForXPath:@"//cancelable" error:&error];
    if ( [nodes count] != 1 ) {
        NSLog(@"error: %ld cancelable for order %@",[nodes count],self.orderID);
        okay = NO;
    }
    
    self.cancelable = [[[nodes lastObject] stringValue] boolValue];
    
    nodes = [statusXML nodesForXPath:@"//editable" error:&error];
    if ( [nodes count] != 1 ) {
        NSLog(@"error: %ld cancelable for order %@",[nodes count],self.orderID);
        okay = NO;
    }
    
    self.editable = [[[nodes lastObject] stringValue] boolValue];
    
    NSLog(@"updated order %@ - %@: %@cancelable, %@editable, %@",self.orderID,self.orderString,self.cancelable?@"":@"non-",self.editable?@"":@"non-",displayStatus);
    
    return okay;
}

@end
