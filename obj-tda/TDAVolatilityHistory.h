//
//  TDAVolatilityHistory.h
//  obj-tda
//
//  Created by david on 5/10/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Delta = 0,
    DeltaWithComposite = 1,
    Skew = 2
} SurfaceType;

@interface TDAVolatilityHistory : NSObject

@end
