//
//  TDABalances.m
//  obj-tda
//
//  Created by david on 4/11/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDABalances.h"

@implementation TDABalances

+ (TDABalances *)balancesWithXMLNode:(NSXMLNode *)node
{
    TDABalances *balances = [TDABalances new];
    
    NSError *error = nil;
    balances.isDayTrader = [[[[node nodesForXPath:@"//day-trader" error:&error] firstObject] stringValue] boolValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.roundTrips = [[[[node nodesForXPath:@"//round-trips" error:&error] firstObject] stringValue] intValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    NSXMLNode *cbXML = [[node nodesForXPath:@"//cash-balance" error:&error] firstObject];
    if ( ! cbXML ) {
        NSLog(@"failed to parse cash balances: %@",error);
        return nil;
    }
    
    balances.cashInitial = [[[[cbXML nodesForXPath:@"initial" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.cashCurrent = [[[[cbXML nodesForXPath:@"current" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.cashChange = [[[[cbXML nodesForXPath:@"change" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    
    NSXMLNode *avXML = [[node nodesForXPath:@"//account-value" error:&error] firstObject];
    if ( ! avXML ) {
        NSLog(@"failed to parse cash balances: %@",error);
        return nil;
    }
    
    balances.accountInitial = [[[[avXML nodesForXPath:@"initial" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.accountCurrent = [[[[avXML nodesForXPath:@"current" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.accountChange = [[[[avXML nodesForXPath:@"change" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    
    balances.stockBuyingPower = [[[[node nodesForXPath:@"stock-buying-power" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.optionBuyingPower = [[[[node nodesForXPath:@"option-buying-power" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.dayBuyingPower = [[[[node nodesForXPath:@"day-trading-buying-power" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    balances.availableFundsForTrading = [[[[node nodesForXPath:@"available-funds-for-trading" error:&error] firstObject] stringValue] doubleValue];
    if ( error ) {
        NSLog(@"error parsing balances: %@",error);
        return nil;
    }
    
    return balances;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"account: $%0.2f, cash: $%0.2f, day: $%0.2f, available: $%0.2f",self.accountCurrent,self.cashCurrent,self.dayBuyingPower,self.availableFundsForTrading];
}

@end
