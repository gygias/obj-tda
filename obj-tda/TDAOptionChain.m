//
//  TDAOptionChain.m
//  obj-tda
//
//  Created by david on 4/12/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDAOptionChain.h"

@implementation TDAOptionChain

+ (TDAOptionChain *)optionChainWithXMLNode:(NSXMLNode *)node
{
    TDAOptionChain *chain = [TDAOptionChain new];
    chain.quote = [TDAQuote quoteWithXMLNode:node forOptionChain:YES forOptionPartWithSymbol:nil];
    if ( ! chain.quote ) {
        NSLog(@"error parsing option chain quote");
        return nil;
    }
    
    NSError *error = nil;
    NSArray *xmls = [node nodesForXPath:@"symbol" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for symbol",[xmls count]);
        return nil;
    }
    chain.symbol = [[xmls firstObject] stringValue];
    
    xmls = [node nodesForXPath:@"quote-punctuality" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for quote-punctuality",[xmls count]);
        return nil;
    }
    NSString *quotePuncString = [[xmls firstObject] stringValue];
    if ( [quotePuncString isEqualToString:@"R"] )
        chain.punctuality = RealTime;
    else if ( [quotePuncString isEqualToString:@"D"] )
        chain.punctuality = Delayed;
    
    xmls = [node nodesForXPath:@"option-date" error:&error];
    if ( ! xmls || [xmls count] == 0 ) {
        NSLog(@"error: got %ld elements for option-date",[xmls count]);
        return nil;
    }
    
    NSMutableArray *optionDates = [NSMutableArray new];
    for ( NSXMLNode *anOptionDate in xmls ) {
        TDAOptionDate *optionDate = [TDAOptionDate optionDateWithXMLNode:anOptionDate symbol:chain.symbol];
        if ( ! optionDate ) {
            NSLog(@"error parsing option: %@",anOptionDate);
            return nil;
        }
        [optionDates addObject:optionDate];
    }
    
    chain.optionDates = optionDates;
    
    return chain;
}

@end

@implementation TDAOptionDate

+ (TDAOptionDate *)optionDateWithXMLNode:(NSXMLNode *)node symbol:(NSString *)symbol
{
    TDAOptionDate *optionDate = [TDAOptionDate new];
    optionDate.symbol = symbol;
    
    NSError *error = nil;
    NSArray *dates = [node nodesForXPath:@"date" error:&error];
    if ( ! dates || [dates count] != 1 ) {
        NSLog(@"error: got %ld elements for date",[dates count]);
        return nil;
    }
    NSDateFormatter *dF = [NSDateFormatter new];
    dF.dateFormat = @"yyyyMMdd";
    optionDate.date = [dF dateFromString:[[dates firstObject] stringValue]];
    
    NSArray *expires = [node nodesForXPath:@"expiration-type" error:&error];
    if ( ! expires || [expires count] != 1 ) {
        NSLog(@"error: got %ld elements for expires",[expires count]);
        return nil;
    }
    NSString *expiresString = [[expires firstObject] stringValue];
    if ( [expiresString isEqualToString:@"S"] )
        optionDate.expirationType = ShortDate;
    else if ( [expiresString isEqualToString:@"W"] )
        optionDate.expirationType = Weekly;
    else if ( [expiresString isEqualToString:@"M"] )
        optionDate.expirationType = Monthly;
    else if ( [expiresString isEqualToString:@"Q"] ) // undocumented
        optionDate.expirationType = Quarterly;
    else if ( [expiresString isEqualToString:@"R"] )
        optionDate.expirationType = Regular;
    else if ( [expiresString isEqualToString:@"L"] )
        optionDate.expirationType = Leap;
    else {
        NSLog(@"unknown expiration type: %@\n%@",expiresString,node);
        return nil;
    }
    
    NSArray *xmls = [node nodesForXPath:@"days-to-expiration" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for days-to-expiration",[xmls count]);
        return nil;
    }
    optionDate.daysToExpiration = [[[xmls firstObject] stringValue] intValue];
    
    xmls = [node nodesForXPath:@"option-strike" error:&error];
    if ( ! xmls || [xmls count] == 0 ) {
        NSLog(@"error: got %ld elements for option-strike",[xmls count]);
        return nil;
    }
    
    NSMutableDictionary *putsByStrike = [NSMutableDictionary new];
    NSMutableDictionary *callsByStrike = [NSMutableDictionary new];
    for ( NSXMLNode *optionStrikeXML in xmls ) {
        
        xmls = [optionStrikeXML nodesForXPath:@"strike-price" error:&error];
        if ( ! xmls || [xmls count] != 1 ) {
            NSLog(@"error: got %ld elements for strike-price",[xmls count]);
            return nil;
        }
        optionDate.strike = [[[xmls firstObject] stringValue] floatValue];
        
        xmls = [optionStrikeXML nodesForXPath:@"standard-option" error:&error];
        if ( ! xmls || [xmls count] != 1 ) {
            NSLog(@"error: got %ld elements for standard-option",[xmls count]);
            return nil;
        }
        optionDate.isStandard = [[[xmls firstObject] stringValue] boolValue];
        
        TDAOptionPart *put = [TDAOptionPart optionPartWithXML:optionStrikeXML withType:@"put"];
        if ( put ) {
            if ( [putsByStrike objectForKey:@(optionDate.strike)] ) {
                NSLog(@"error: already have a put for strike %0.2f: %@",optionDate.strike,optionStrikeXML);
                return nil;
            }
            [putsByStrike setObject:put forKey:@(optionDate.strike)];
        } else {
            NSLog(@"failed to parse put element: %@",optionStrikeXML);
            return nil;
        }
        
        TDAOptionPart *call = [TDAOptionPart optionPartWithXML:optionStrikeXML withType:@"call"];
        if ( call ) {
            if ( [callsByStrike objectForKey:@(optionDate.strike)] ) {
                NSLog(@"error: already have call for strike %0.2f: %@",optionDate.strike,optionStrikeXML);
                return nil;
            }
            [callsByStrike setObject:call forKey:@(optionDate.strike)];
        } else {
            NSLog(@"failed to parse call element: %@",optionStrikeXML);
            return nil;
        }
    }
    
    optionDate.putsByStrike = putsByStrike;
    optionDate.callsByStrike = callsByStrike;
    
    return optionDate;
}

- (NSString *)description
{
    NSDateFormatter *dF = [NSDateFormatter new];
    dF.dateFormat = @"YYYY-MM-dd";
    NSString *ymdDateString = [dF stringFromDate:self.date];
    
    NSArray *keys = self.callsByStrike.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        float a = [obj1 floatValue];
        float b = [obj2 floatValue];
        if ( a < b ) return NSOrderedAscending;
        else if ( a == b ) return NSOrderedSame;
        return NSOrderedDescending;
    }];
    
    NSString *expiryString = @"?";
    switch(self.expirationType) {
        case ShortDate:
            expiryString = @"ShortDate";
            break;
        case Weekly:
            expiryString = @"Weekly";
            break;
        case Monthly:
            expiryString = @"Monthly";
            break;
        case Quarterly:
            expiryString = @"Quarterly";
            break;
        case Regular:
            expiryString = @"Regular";
            break;
        case Leap:
            expiryString = @"Leap";
            break;
        default:
            break;
            
    }
    NSMutableString *desc = [NSMutableString stringWithFormat:@"%@ options for %@ expiring %@\n",expiryString,self.symbol,ymdDateString];
    for (NSString *key in keys) {
        TDAOptionPart *call = self.callsByStrike[key];
        TDAOptionPart *put = self.putsByStrike[key];
        [desc appendFormat:@"\t%@: call $%0.2f oI %d iV %0.2f x%d, put $%0.2f oI %d iV %0.2f x%d\n",key,call.quote.last,call.openInterest,call.impliedVolatility,call.multiplier,put.quote.last,put.openInterest,put.impliedVolatility,put.multiplier];
    }
    return desc;
}

@end

@implementation TDAOptionPart

+ (TDAOptionPart *)optionPartWithXML:(NSXMLNode *)node withType:(NSString *)type
{
    NSError *error = nil;
    NSArray *partXMLs = [node nodesForXPath:type error:&error];
    if ( ! partXMLs || [partXMLs count] != 1 ) {
        NSLog(@"error: got %ld elements for %@",[partXMLs count],type);
        return nil;
    }
    NSXMLNode *partXML = [partXMLs firstObject];
    
    NSArray *xmls = [partXML nodesForXPath:@"underlying-symbol" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for underlying-symbol",[xmls count]);
        return nil;
    }
    
    TDAOptionPart *part = [TDAOptionPart new];
    part.quote = [TDAQuote quoteWithXMLNode:partXML forOptionChain:YES forOptionPartWithSymbol:[[xmls firstObject] stringValue]];
    
    xmls = [partXML nodesForXPath:@"delta" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for delta",[xmls count]);
        return nil;
    }
    part.delta = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"gamma" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for gamma",[xmls count]);
        return nil;
    }
    part.gamma = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"theta" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for theta",[xmls count]);
        return nil;
    }
    part.theta = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"vega" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for vega",[xmls count]);
        return nil;
    }
    part.vega = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"rho" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for rho",[xmls count]);
        return nil;
    }
    part.rho = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"implied-volatility" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for implied-volatility",[xmls count]);
        return nil;
    }
    part.impliedVolatility = [[[xmls firstObject] stringValue] doubleValue];
    
    xmls = [partXML nodesForXPath:@"time-value-index" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for time-value-index",[xmls count]);
        return nil;
    }
    part.timeValueIndex = [[[xmls firstObject] stringValue] doubleValue];
    
    
    xmls = [partXML nodesForXPath:@"in-the-money" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for in-the-money",[xmls count]);
        return nil;
    }
    part.inTheMoney = [[[xmls firstObject] stringValue] boolValue];
    
    xmls = [partXML nodesForXPath:@"near-the-money" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for near-the-money",[xmls count]);
        return nil;
    }
    part.nearTheMoney = [[[xmls firstObject] stringValue] boolValue];
    
    xmls = [partXML nodesForXPath:@"option-symbol" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for option-symbol",[xmls count]);
        return nil;
    }
    part.optionSymbol = [[xmls firstObject] stringValue];
    
    xmls = [partXML nodesForXPath:@"open-interest" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for open-interest",[xmls count]);
        return nil;
    }
    part.openInterest = [[[xmls firstObject] stringValue] intValue];
    
    xmls = [partXML nodesForXPath:@"volume" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for volume",[xmls count]);
        return nil;
    }
    part.volume = [[[xmls firstObject] stringValue] intValue];
    
    xmls = [partXML nodesForXPath:@"multiplier" error:&error];
    if ( ! xmls || [xmls count] != 1 ) {
        NSLog(@"error: got %ld elements for multiplier",[xmls count]);
        return nil;
    }
    part.multiplier = [[[xmls firstObject] stringValue] intValue];
    
    return part;
}

@end
