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
#define QuoteURL "https://apis.tdameritrade.com/apps/100/Quote?source=%@&symbol=%@"
#define ETURL "https://apis.tdameritrade.com/apps/100/EquityTrade?source=%@&orderstring=%@"
#define CURL "https://apis.tdameritrade.com/apps/100/OrderCancel?source=%@&orderid=%@" // account id optional
#define PHURL "https://apis.tdameritrade.com/apps/100/PriceHistory?source=%@&requestidentifiertype=SYMBOL"
#define KAURL "https://apis.tdameritrade.com/apps/KeepAlive?source=%@"
#define OSURL "https://apis.tdameritrade.com/apps/100/OrderStatus?source=%@"
#define OCURL "https://apis.tdameritrade.com/apps/200/OptionChain?source=%@&symbol=%@&quotes=true"

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
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
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

- (BOOL)keepAlive
{
    NSString *urlString = [NSString stringWithFormat:@KAURL,_source];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSData *data = nil;
    BOOL okay = [self _submitRequest:req :&data :NO];
    if ( ! okay ) {
        NSLog(@"keep alive failed");
        return NO;
    } else if ( ! data ) {
        NSLog(@"keep alive nil data");
        return NO;
    }
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ( ! [string isEqualToString:@"LoggedOn"] ) {
        NSLog(@"keep alive failed: '%@'",string);
        return NO;
    }
    
    return YES;
}

- (BOOL)logoff
{
    NSString *urlString = [NSString stringWithFormat:@LogoffURL,_source];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"LoggedOut"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSLog(@"logoff successful");
    return YES;
}

- (BOOL)getBalancesAndPositions:(TDABalances **)outBalances :(NSArray **)outPositions
{
    NSString *urlString = [NSString stringWithFormat:@BandPURL,_source];
    urlString = [urlString stringByAppendingString:@"&suppressquotes=true"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    // optional account id specifier, type, etc.
    //NSString *bodyString = [NSString stringWithFormat:@"accountid=%@&type=%@&suppressquotes=%@&altBalanceFormat=%@",accountID,type,suppressQuotes?@"true":@"false",altBalanceFormat?@"true":@"false"];
    //NSData *body = [NSData dataWithBytes:[bodyString UTF8String] length:strlen([bodyString UTF8String])];
    //[req setHTTPMethod:@"POST"];
    //[req setHTTPBody:body];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
    NSArray *balancessXML = [responseXML nodesForXPath:@"//balance" error:&error];
    if ( ! balancessXML || [balancessXML count] != 1 ) {
        NSLog(@"failed to parse accounts[%ld]: %@",[balancessXML count],error);
        return NO;
    }
    
    NSXMLNode *balancesXML = [balancessXML lastObject];
    TDABalances *balances = [TDABalances balancesWithXMLNode:balancesXML];
    if ( ! balances ) {
        NSLog(@"failed to initialize balances from xml: %@",balancesXML);
        return NO;
    }
    
    NSMutableArray *positions = [NSMutableArray new];
    {
        NSError *error = nil;
        NSXMLNode *positionsXML = [[responseXML nodesForXPath:@"//positions" error:&error] firstObject];
        for ( NSXMLNode *aPositionTypeXML in positionsXML.children ) {
            if ( [@[ @"account-id", @"error" ] containsObject:aPositionTypeXML.name] )
                continue;
            
            for ( NSXMLNode *aPositionXML in aPositionTypeXML.children ) {
                //NSLog(@"%@: %@",aPositionTypeXML.name,aPositionXML);
                TDAPosition *aPosition = [TDAPosition positionWithXMLNode:aPositionXML];
                if ( ! aPosition ) {
                    NSLog(@"failed to initialize position from xml: %@",aPositionXML);
                    return NO;
                } else
                    [positions addObject:aPosition];
            }
        }
    }
    
    *outPositions = positions;
    *outBalances = balances;
    NSLog(@"get b&p successful");
    return YES;
}

- (TDAQuote *)getQuote:(NSString *)symbol
{
    NSString *urlString = [NSString stringWithFormat:@QuoteURL,_source,[symbol uppercaseString]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
    NSArray *quotes = [responseXML nodesForXPath:@"//quote-list/quote" error:&error];
    if ( [quotes count] != 1 ) {
        NSLog(@"error: quotes %lu",[quotes count]);
        return nil;
    }
    
    NSArray *errors = [[quotes lastObject] nodesForXPath:@"//error" error:&error];
    if ( [[[errors lastObject] stringValue] length] ) {
        NSLog(@"error: quote error '%@",[[errors lastObject] stringValue]);
        return nil;
    }
    
    TDAQuote *quote = [TDAQuote quoteWithXMLNode:[quotes lastObject] forOptionChain:NO forOptionPartWithSymbol:nil];
    return quote;
}

- (TDAPriceHistory *)getPriceHistory:(NSString *)symbol
                                    :(IntervalType)interval
                                    :(int)duration
                                    :(PeriodType)periodType
                                    :(int)period
                                    :(NSDate *)startDate
                                    :(NSDate *)endDate
                                    :(BOOL)extended
{
    NSString *urlString = [NSString stringWithFormat:@PHURL,_source];
    
    // multiple symbols in one request with comma-space. "foo, bar"
    urlString = [urlString stringByAppendingFormat:@"&requestvalue=%@",[symbol uppercaseString]];
    
    switch(interval) {
        case MinuteInterval:
            if ( duration != 1 && duration != 5 && duration != 10 && duration != 15 && duration != 30 ) {
                NSLog(@"invalid duration %d for minute interval",duration);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&intervaltype=MINUTE"];
            break;
        case DayInterval:
            if ( duration != 1 ) {
                NSLog(@"invalid duration %d for day interval",duration);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&intervaltype=DAILY"];
            break;
        case WeekInterval:
            if ( duration != 1 ) {
                NSLog(@"invalid duration %d for week interval",duration);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&intervaltype=WEEKLY"];
            break;
        case MonthInterval:
            if ( duration != 1 ) {
                NSLog(@"invalid duration %d for month interval",duration);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&intervaltype=MONTHLY"];
            break;
        default:
            NSLog(@"invalid interval type");
            return nil;
    }
    urlString = [urlString stringByAppendingFormat:@"&intervalduration=%d",duration];
    
    switch(periodType) {
        case DayPeriod:
            if ( ( period < 1 || period > 5 ) && period != 10 ) {
                NSLog(@"invalid day period %d",period);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&periodtype=DAY"];
            break;
        case MonthPeriod:
            if ( ( period < 1 || period > 3 ) && period != 6 ) {
                NSLog(@"invalid month period %d",period);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&periodtype=MONTH"];
            break;
        case YearPeriod:
            if ( ( period < 1 || period > 3 ) && period != 5 && period != 10 && period != 15 && period != 20 ) {
                NSLog(@"invalid year period %d",period);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&periodtype=YEAR"];
            break;
        case YTDPeriod:
            if ( period != 1 ) {
                NSLog(@"invalid ytd period %d",period);
                return nil;
            }
            urlString = [urlString stringByAppendingFormat:@"&periodtype=YTD"];
            break;
        default:
            NSLog(@"invalid period type");
            return nil;
    }
    urlString = [urlString stringByAppendingFormat:@"&period=%d",period];
    
    NSDateFormatter *dF = [NSDateFormatter new];
    dF.dateFormat = @"yyyyMMdd";
    if ( startDate )
        urlString = [urlString stringByAppendingFormat:@"&startdate=%@",[dF stringFromDate:startDate]];
    if ( endDate ) {
        if ( ! startDate ) {
            NSLog(@"invalid PH request: endDate requires startDate");
            return nil;
        }
        urlString = [urlString stringByAppendingFormat:@"&enddate=%@",[dF stringFromDate:endDate]];
    }
    
    urlString = [urlString stringByAppendingFormat:@"&extended=%d",extended];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSData *bytes = nil;
    BOOL okay = [self _submitRequest:req :&bytes :NO];
    if ( ! okay ) {
        NSLog(@"request failed: %@",bytes?[[NSString alloc] initWithBytes:[bytes bytes] + 2 length:[bytes length] - 2 encoding:NSUTF8StringEncoding]:@"(null)");
        return NO;
    }
    
    // failure indicated in http response code checked in _submitRequest:
    
    TDAPriceHistory *ph = [TDAPriceHistory new];
    ph.symbol = [symbol uppercaseString];
    ph.interval = interval;
    ph.duration = duration;
    ph.startDate = startDate;
    ph.endDate = endDate;
    ph.bytes = bytes;
    
    return ph;
}

- (TDAOptionChain *)getOptionChainForSymbol:(NSString *)symbol
{
    NSString *urlString = [NSString stringWithFormat:@OCURL,_source,[symbol uppercaseString]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
    NSArray *chainXML = [responseXML nodesForXPath:@"//option-chain-results" error:&error];
    if ( ! chainXML || [chainXML count] != 1 ) {
        NSLog(@"error: got %ld elements for option-chain-results",[chainXML count]);
        return nil;
    }
    
    TDAOptionChain *chain = [TDAOptionChain optionChainWithXMLNode:[chainXML firstObject]];
    if ( ! chain )
        NSLog(@"failed to initialize chain for %@ from xml: %@",symbol,chainXML);
    
    return chain;
}

- (BOOL)submitOrder:(TDAOrder *)order
{
    NSString *orderString = [order orderStringWithAccountID:[_accountIDs lastObject]];
    NSCharacterSet *escSet = [[NSCharacterSet characterSetWithCharactersInString:@"=~"] invertedSet];
    NSString *escapedOrder = [orderString stringByAddingPercentEncodingWithAllowedCharacters:escSet];
    NSString *urlString = [NSString stringWithFormat:@ETURL,_source,escapedOrder];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
    NSArray *nodes = [responseXML nodesForXPath:@"//order-wrapper/order/order-id" error:&error];
    if ( [nodes count] != 1 ) {
        NSLog(@"error: got %lu order ids:\n%@",[nodes count],responseXML);
        return NO;
    }
    
    order.orderID = [[nodes lastObject] stringValue];
    
    nodes = [responseXML nodesForXPath:@"//order-wrapper/orderstring" error:&error];
    if ( [nodes count] != 1 ) {
        NSLog(@"error: got %lu orderstrings:\n%@",[nodes count],responseXML);
        return NO;
    }
    
    order.orderString = [[nodes lastObject] stringValue];
    
    order.response = responseXML;
    order.status = Submitted;
    
    NSLog(@"submit order '%@' successful",order.orderID);
    return YES;
}

- (BOOL)getOrderStatus:(TDAOrder *)order
{
    if ( ! order.orderID ) {
        NSLog(@"can't check status of unsubmitted order %@",order);
        return NO;
    }
    
    NSString *urlString = [NSString stringWithFormat:@OSURL,_source];
    // order id is an optional filter
    urlString = [urlString stringByAppendingFormat:@"&orderid=%@",order.orderID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"order status request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"order status response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSError *error = nil;
    NSArray *orders = [responseXML nodesForXPath:@"//orderstatus-list/orderstatus" error:&error];
    if ( [orders count] != 1 ) {
        NSLog(@"error: %ld orders from status check",[orders count]);
        return NO;
    }
        
    [order _updateStatus:[orders lastObject]];
    
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
    
    NSXMLDocument *responseXML = nil;
    BOOL okay = [self _submitRequest:req :&responseXML :YES];
    if ( ! okay ) {
        NSLog(@"request failed");
        return NO;
    } else if ( ! responseXML ) {
        NSLog(@"response xml nil");
        return NO;
    }
    
    okay = [self _checkResult:responseXML :@"OK"];
    if ( ! okay ) {
        NSLog(@"%s: result not OK",__PRETTY_FUNCTION__);
        return NO;
    }
    
    NSLog(@"cancel order '%@' successful",order.orderID);
    return YES;
}

- (BOOL)_submitRequest:(NSURLRequest *)req :(id *)obj :(BOOL)xml
{
    __block BOOL okay = NO;
    //__block NSString *responseString;
    __block NSData *responseData = nil;
    __block NSURLResponse *response;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __unused NSURLSessionDataTask *sesTask = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response_, NSError * _Nullable error) {
        response = response_;
        responseData = data;
        NSLog(@"response[%ld]: %@",[data length],error);
        okay = ([(NSHTTPURLResponse *)response statusCode] == 200); // and response data includes "OK"
        dispatch_semaphore_signal(sem);
    }];
    [sesTask resume];
    
    dispatch_semaphore_wait(sem,DISPATCH_TIME_FOREVER);
    
    if ( ! xml )
        *obj = responseData;
    
    if ( ! okay ) {
        NSLog(@"request failed: %@",response);
        return NO;
    }
    
    if ( ! xml )
        return YES;
    
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
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
    
    *obj = responseXML;
    //NSLog(@"%@",responseXML);
    
    return YES;
}

- (BOOL)_checkResult:(NSXMLDocument *)xml :(NSString *)okString
{
    NSError *error = nil;
    NSArray *results = [xml nodesForXPath:@"//result" error:&error];
    if ( [results count] != 1 ) {
        NSLog(@"error: got %lu results:\n%@",[results count],xml);
        return NO;
    }
    
    if ( ! [[[results lastObject] stringValue] isEqualToString:okString] ) {
        NSLog(@"error: request result not 'ok':\n%@",xml);
        return NO;
    }
    
    return YES;
}

@end
