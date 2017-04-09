//
//  TDASession.h
//  obj-tda
//
//  Created by david on 4/3/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "TDAOrder.h"

@interface TDASession : NSObject
{
    NSString *_source;
    NSArray *_accountIDs;
}

- (BOOL)loginWithUser:(NSString *)user pass:(NSString *)pass source:(NSString *)source version:(NSString *)version;
- (BOOL)logoff;

- (BOOL)getBalancesAndPositions;

- (BOOL)submitOrder:(TDAOrder *)order;
- (BOOL)cancelOrder:(TDAOrder *)order;

@end
