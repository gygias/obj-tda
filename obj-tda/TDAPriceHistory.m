//
//  TDAPriceHistory.m
//  obj-tda
//
//  Created by david on 4/9/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDAPriceHistory.h"

@implementation TDAPriceHistory

- (float)ntohfloat:(const float)inFloat
{
    float retVal;
    char *floatToConvert = ( char* ) & inFloat;
    char *returnFloat = ( char* ) & retVal;
    
    // swap the bytes into a temporary buffer
    returnFloat[0] = floatToConvert[3];
    returnFloat[1] = floatToConvert[2];
    returnFloat[2] = floatToConvert[1];
    returnFloat[3] = floatToConvert[0];
    
    return retVal;
}

- (NSArray *)prices
{
    const uint8_t *bytesPtr = [self.bytes bytes];
    
    int32_t symbolCount = ntohl(((int32_t *)bytesPtr)[0]);
    if ( symbolCount != 1 ) {
        NSLog(@"invalid symbol count %u",symbolCount);
        return nil;
    }
    
    bytesPtr += 4;
    int16_t symbolLen = ntohs(((int16_t *)bytesPtr)[0]);
    bytesPtr += 2;
    NSString *symbol = [[NSString alloc] initWithBytes:bytesPtr length:symbolLen encoding:NSUTF8StringEncoding];
    if ( ! [symbol isEqualToString:self.symbol] ) {
        NSLog(@"symbols don't match");
        return nil;
    }
    
    bytesPtr += symbolLen;
    uint8_t error = ((uint8_t *)bytesPtr)[0];
    bytesPtr++;
    if ( error ) {
        uint16_t errorLen = ntohs(((uint16_t *)bytesPtr)[0]);
        bytesPtr += 2;
        NSString *error = [[NSString alloc] initWithBytes:bytesPtr length:errorLen encoding:NSUTF8StringEncoding];
        NSLog(@"error from ph byte stream: %@",error);
        return nil;
    }
    
    int32_t barCount = ntohl(((int32_t *)bytesPtr)[0]);
    bytesPtr += 4;
    
    if ( 4 != sizeof(float) ) {
        NSLog(@"error: float is not 4 bytes on this system");
        return nil;
    }
    
    NSMutableArray *prices = [NSMutableArray arrayWithCapacity:barCount];
    for (uint32_t i = 0; i < barCount; i++) {
        
        TDAPrice *price = [TDAPrice new];
        price.close = [self ntohfloat:((float *)bytesPtr)[0]];
        price.high = [self ntohfloat:((float *)bytesPtr)[1]];
        price.low = [self ntohfloat:((float *)bytesPtr)[2]];
        price.open = [self ntohfloat:((float *)bytesPtr)[3]];
        price.volume = [self ntohfloat:((float *)bytesPtr)[4]] * 100;
        bytesPtr += 20;
        price.date = [NSDate dateWithTimeIntervalSince1970:ntohll(((uint64_t *)bytesPtr)[0])];
        bytesPtr += 8;
        [prices addObject:price];
    }
    
    uint16_t terminator = ntohs(((uint16_t *)bytesPtr)[0]);
    if ( terminator != 0xFFFF ) {
        NSLog(@"error: ph bytes terminator: %02x",terminator);
        return nil;
    }
    
    return prices;
}

@end

@implementation TDAPrice
@end
