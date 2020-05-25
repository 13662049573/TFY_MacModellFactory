//
//  NSString+methods.m
//  TFY_DataModelFactory
//
//  Created by tiandengyou on 2020/5/6.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "NSString+methods.h"

#import <AppKit/AppKit.h>

@implementation NSString (methods)

- (NSDictionary *)tfy_toJsonDict{
    
    NSString *str = self;
    if (!str || str.length == 0)  return nil;
    
    str = [str stringByReplacingOccurrencesOfString:@"，" withString:@","];
    str = [str stringByReplacingOccurrencesOfString:@"“" withString:@""];
    
    NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) return nil;
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    return jsonDict;
}


@end

@implementation NSDictionary (methods)

- (NSString *)tfy_toJsonString{
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    if (!jsonData) return @"";

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
