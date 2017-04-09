//
//  TDASession.m
//  obj-tda
//
//  Created by david on 4/3/17.
//  Copyright © 2017 combobulated. All rights reserved.
//

#import "TDASession.h"

#define LoginURL "https://apis.tdameritrade.com/apps/300/LogIn?source=%@&version=%@"
#define LogoffURL "https://apis.tdameritrade.com/apps/100/LogOut?source=%@"
#define BandPURL "https://apis.tdameritrade.com/apps/100/BalancesAndPositions?source=%@"
#define ETURL "https://apis.tdameritrade.com/apps/100/EquityTrade?source=%@&orderstring=%@"
#define CURL "https://apis.tdameritrade.com/apps/100/OrderCancel?source=%@&orderid=%@" // account id optional

@implementation TDASession

- (BOOL)loginWithUser:(NSString *)user pass:(NSString *)pass source:(NSString *)source version:(NSString *)version
{
    NSString *urlString = [NSString stringWithFormat:@LoginURL,source,version];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSString *bodyString = [NSString stringWithFormat:@"userid=%@&password=%@",user,pass];
    NSData *body = [NSData dataWithBytes:[bodyString UTF8String] length:strlen([bodyString UTF8String])];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSXMLDocument *responseXML = [self _submitRequest:req];
    if ( ! responseXML ) {
        NSLog(@"nil response from cancel");
        return NO;
    }
    
    NSError *error = nil;
    NSArray *results = [responseXML nodesForXPath:@"//result" error:&error];
    if ( ! results ) {
        NSLog(@"failed to parse login result: %@: %@",error,responseXML);
        return NO;
    }
    
    if ( ! [[[results lastObject] stringValue] isEqualToString:@"OK"] ) {
        NSLog(@"error: login: ? %@",[[results lastObject] stringValue]);
        return NO;
    }
    
    NSArray *accountIDsXML = [responseXML nodesForXPath:@"//xml-log-in/accounts/account/account-id" error:&error];
    if ( ! accountIDsXML ) {
        NSLog(@"failed to parse accounts: %@",error);
        return NO;
    }
    
    NSMutableArray *accountIDs = [NSMutableArray array];
    for( NSXMLNode *aA in accountIDsXML ) {
        NSString *a = [aA stringValue];
        if ( a ) {
            NSLog(@"adding account '%@'",a);
            [accountIDs addObject:a];
        }
    }
    
    _accountIDs = accountIDs;
    _source = source;
    NSLog(@"logged in as '%@'",source);
    
    return YES;
}

- (BOOL)logoff
{
    NSString *urlString = [NSString stringWithFormat:@LogoffURL,_source];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = [self _submitRequest:req];
    if ( ! responseXML ) {
        NSLog(@"nil response from cancel");
        return NO;
    }
    
    NSError *error = nil;
    NSArray *results = [responseXML nodesForXPath:@"//result" error:&error];
    if ( ! results ) {
        NSLog(@"failed to parse logoff result: %@",error);
        return NO;
    }
    
    if ( ! [[[results lastObject] stringValue] isEqualToString:@"LoggedOut"] ) {
        NSLog(@"error: logoff: ? %@",responseXML);
        return NO;
    }
    
    NSLog(@"logoff successful");
    return YES;
}

- (BOOL)getBalancesAndPositions
{
    NSString *urlString = [NSString stringWithFormat:@BandPURL,_source];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    // optional account id specifier, type, etc.
    //NSString *bodyString = [NSString stringWithFormat:@"accountid=%@&type=%@&suppressquotes=%@&altBalanceFormat=%@",accountID,type,suppressQuotes?@"true":@"false",altBalanceFormat?@"true":@"false"];
    //NSData *body = [NSData dataWithBytes:[bodyString UTF8String] length:strlen([bodyString UTF8String])];
    //[req setHTTPMethod:@"POST"];
    //[req setHTTPBody:body];
    
    NSXMLDocument *responseXML = [self _submitRequest:req];
    if ( ! responseXML ) {
        NSLog(@"nil response from cancel");
        return NO;
    }
    
    NSError *error = nil;
    NSArray *results = [responseXML nodesForXPath:@"//result" error:&error];
    if ( [results count] != 1 ) {
        NSLog(@"error: results != 1 on b&p");
        return NO;
    }
    
    if ( ! [[[results lastObject] stringValue] isEqualToString:@"OK"] ) {
        NSLog(@"error: b&p result: %@",[[results lastObject] stringValue]);
        return NO;
    }
    
    NSLog(@"get b&p successful");
    return YES;
}

- (BOOL)submitOrder:(TDAOrder *)order
{
    NSString *orderString = [order orderStringWithAccountID:[_accountIDs lastObject]];
    NSCharacterSet *escSet = [[NSCharacterSet characterSetWithCharactersInString:@"=~"] invertedSet];
    NSString *escapedOrder = [orderString stringByAddingPercentEncodingWithAllowedCharacters:escSet];
    NSString *urlString = [NSString stringWithFormat:@ETURL,_source,escapedOrder];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = [self _submitRequest:req];
    if ( ! responseXML ) {
        NSLog(@"nil response from cancel");
        return NO;
    }
    
    NSError *error = nil;
    
#warning check 'result'
    
    NSArray *orderIDs = [responseXML nodesForXPath:@"//order-wrapper/order/order-id" error:&error];
    if ( [orderIDs count] != 1 ) {
        NSLog(@"error: got %lu order ids",[orderIDs count]);
        return NO;
    }
    
    order.orderID = [[orderIDs lastObject] stringValue];
    order.response = responseXML;
    
    NSLog(@"submit order '%@' successful",order.orderID);
    return YES;
}

- (BOOL)cancelOrder:(TDAOrder *)order
{
    if ( ! order.orderID ) {
        NSLog(@"error: order %@ has no ID, was it submitted?",order);
        return NO;
    }
    
    NSString *urlString = [NSString stringWithFormat:@CURL,_source,order.orderID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = [self _submitRequest:req];
    if ( ! responseXML ) {
        NSLog(@"nil response from cancel");
        return NO;
    }
    
    NSError *error = nil;
    NSArray *results = [responseXML nodesForXPath:@"//result" error:&error];
    if ( [results count] != 1 ) {
        NSLog(@"error: got %lu results on cancel",[results count]);
        return NO;
    }
    
    if ( ! [[[results lastObject] stringValue] isEqualToString:@"OK"] ) {
        NSLog(@"cancel order failed");
        return NO;
    }
    
    NSLog(@"cancel order '%@' successful",order.orderID);
    return YES;
}

- (NSXMLDocument *)_submitRequest:(NSURLRequest *)req
{
    __block BOOL okay = NO;
    __block NSString *responseString;
    __block NSURLResponse *response;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __unused NSURLSessionDataTask *sesTask = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response_, NSError * _Nullable error) {
        response = response_;
        responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"response[%ld]: %@",[data length],error);
        okay = ([(NSHTTPURLResponse *)response statusCode] == 200); // and response data includes "OK"
        dispatch_semaphore_signal(sem);
    }];
    [sesTask resume];
    
    dispatch_semaphore_wait(sem,DISPATCH_TIME_FOREVER);
    
    if ( ! okay ) {
        NSLog(@"request failed: %@",response);
        return NO;
    }
    if ( ! responseString ) {
        NSLog(@"request got nil response string: %@",response);
        return NO;
    }
    
    NSError *error = nil;
    NSXMLElement *responseRoot = [[NSXMLElement alloc] initWithXMLString:responseString error:&error];
    if ( ! responseRoot ) {
        NSLog(@"failed to parse cancel response: %@",error);
        return NO;
    }
    NSXMLDocument *responseXML = [NSXMLDocument documentWithRootElement:responseRoot];
    if ( ! responseXML ) {
        NSLog(@"failed to create response document");
        return NO;
    }
    
    return responseXML;
}

@end
