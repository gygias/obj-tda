//
//  TDAPosition.m
//  obj-tda
//
//  Created by david on 4/11/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDAPosition.h"

@implementation TDAPosition

+ (TDAPosition *)positionWithXMLNode:(NSXMLNode *)node
{
    TDAPosition *aPosition = [TDAPosition new];
    
    NSError *error = nil;
    NSString *errorString = [[[node nodesForXPath:@"error" error:&error] firstObject] stringValue];
    if ( [errorString length] > 0 ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.symbol = [[[node nodesForXPath:@"security/symbol" error:&error] firstObject] stringValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.desc = [[[node nodesForXPath:@"security/description" error:&error] firstObject] stringValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.assetType = [[[node nodesForXPath:@"security/asset-type" error:&error] firstObject] stringValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    NSString *positionTypeString = [[[node nodesForXPath:@"position-type" error:&error] firstObject] stringValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    } else if ( [positionTypeString isEqualToString:@"LONG"] )
        aPosition.positionType = LongPosition;
    else if ( [positionTypeString isEqualToString:@"SHORT"] )
        aPosition.positionType = ShortPosition;
    else {
        NSLog(@"error: unknown position type: '%@':\n%@",positionTypeString,node);
        return nil;
    }
    
    aPosition.quantity = [[[[node nodesForXPath:@"quantity" error:&error] firstObject] stringValue] floatValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.averagePrice = [[[[node nodesForXPath:@"average-price" error:&error] firstObject] stringValue] floatValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.currentValue = [[[[node nodesForXPath:@"current-value" error:&error] firstObject] stringValue] floatValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    aPosition.lastClose = [[[[node nodesForXPath:@"close-price" error:&error] firstObject] stringValue] floatValue];
    if ( error ) {
        NSLog(@"position error: %@",error);
        return nil;
    }
    
    if ( [aPosition.assetType isEqualToString:@"O"] ) {
        aPosition.isOption = YES;
        
        // documented but server returns empty elements
        /*NSString *optionTypeString = [[[node nodesForXPath:@"put-call" error:&error] firstObject] stringValue];
         if ( [optionTypeString isEqualToString:@"P"] )
         aPosition.optionType = PutOption;
         else if ( [optionTypeString isEqualToString:@"C"] )
         aPosition.optionType = CallOption;
         else {
         NSLog(@"error: unknown option type: '%@':\n%@",optionTypeString,node);
         continue;
         }
         aPosition.underlyingSymbol = [[[node nodesForXPath:@"underlying-symbol" error:&error] firstObject] stringValue];*/
    }
    
    return aPosition;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@ %@%0.1f @ %0.2f = %0.2f",self.symbol,self.assetType,self.positionType==LongPosition?@"+":@"-",self.quantity,self.averagePrice,self.currentValue];
}

@end
