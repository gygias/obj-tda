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
    
    NSMutableArray *options = [NSMutableArray new];
    for ( NSXMLNode *anOptionDate in xmls ) {
        TDAOption *option = [TDAOption optionWithXMLNode:anOptionDate symbol:chain.symbol];
        if ( ! option ) {
            NSLog(@"error parsing option: %@",anOptionDate);
            return nil;
        }
        [options addObject:option];
    }
    
    chain.options = options;
    
    return chain;
}

@end

@implementation TDAOption

+ (TDAOption *)optionWithXMLNode:(NSXMLNode *)node symbol:(NSString *)symbol
{
    TDAOption *option = [TDAOption new];
    option.symbol = symbol;
    
    NSError *error = nil;
    NSArray *dates = [node nodesForXPath:@"date" error:&error];
    if ( ! dates || [dates count] != 1 ) {
        NSLog(@"error: got %ld elements for date",[dates count]);
        return nil;
    }
    NSDateFormatter *dF = [NSDateFormatter new];
    dF.dateFormat = @"YYYYMMDD";
    option.date = [dF dateFromString:[[dates firstObject] stringValue]];
    
    NSArray *expires = [node nodesForXPath:@"expiration-type" error:&error];
    if ( ! expires || [expires count] != 1 ) {
        NSLog(@"error: got %ld elements for expires",[expires count]);
        return nil;
    }
    NSString *expiresString = [[expires firstObject] stringValue];
    if ( [expiresString isEqualToString:@"S"] )
        option.expirationType = ShortDate;
    else if ( [expiresString isEqualToString:@"W"] )
        option.expirationType = Weekly;
    else if ( [expiresString isEqualToString:@"M"] )
        option.expirationType = Monthly;
    else if ( [expiresString isEqualToString:@"Q"] ) // undocumented
        option.expirationType = Quarterly;
    else if ( [expiresString isEqualToString:@"R"] )
        option.expirationType = Regular;
    else if ( [expiresString isEqualToString:@"L"] )
        option.expirationType = Leap;
    else {
        NSLog(@"unknown expiration type: %@\n%@",expiresString,node);
        return nil;
    }
    
    NSArray *daysToExpirations = [node nodesForXPath:@"days-to-expiration" error:&error];
    if ( ! daysToExpirations || [daysToExpirations count] != 1 ) {
        NSLog(@"error: got %ld elements for days-to-expiration",[daysToExpirations count]);
        return nil;
    }
    option.daysToExpiration = [[[daysToExpirations firstObject] stringValue] intValue];
    
    NSArray *optionStrikesXML = [node nodesForXPath:@"option-strike" error:&error];
    if ( ! optionStrikesXML || [optionStrikesXML count] == 0 ) {
        NSLog(@"error: got %ld elements for option-strike",[optionStrikesXML count]);
        return nil;
    }
    
    for ( NSXMLNode *optionStrikeXML in optionStrikesXML ) {
        
        NSArray *strikePrices = [optionStrikeXML nodesForXPath:@"strike-price" error:&error];
        if ( ! strikePrices || [strikePrices count] != 1 ) {
            NSLog(@"error: got %ld elements for strike-price",[strikePrices count]);
            return nil;
        }
        option.strike = [[[daysToExpirations firstObject] stringValue] floatValue];
        
        NSArray *standardOptions = [optionStrikeXML nodesForXPath:@"standard-option" error:&error];
        if ( ! standardOptions || [standardOptions count] != 1 ) {
            NSLog(@"error: got %ld elements for standard-option",[standardOptions count]);
            return nil;
        }
        option.isStandard = [[[standardOptions firstObject] stringValue] boolValue];
        
        option.put = [TDAOptionPart optionPartWithXML:optionStrikeXML withType:@"put"];
        option.call = [TDAOptionPart optionPartWithXML:optionStrikeXML withType:@"call"];
    }
    
    return option;
}

- (NSString *)description
{
    NSDateFormatter *dF = [NSDateFormatter new];
    dF.dateFormat = @"YYYY-mm-dd";
    NSString *ymdDateString = [dF stringFromDate:self.date];
    return [NSString stringWithFormat:@"%@ @ %0.2f x%d exp %@: call $%0.2f oI %d iV %0.2f, put $%0.2f oI %d iV %0.2f",self.symbol,self.strike,self.put.multiplier,ymdDateString,self.call.quote.last,self.call.openInterest,self.call.impliedVolatility,self.put.quote.last,self.put.openInterest,self.put.impliedVolatility];
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
