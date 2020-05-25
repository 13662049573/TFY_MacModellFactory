//
//  NSString+methods.h
//  TFY_DataModelFactory
//
//  Created by tiandengyou on 2020/5/6.
//  Copyright © 2020 田风有. All rights reserved.
//
#import <AppKit/AppKit.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (methods)

- (NSDictionary *)tfy_toJsonDict;

@end

@interface NSDictionary (methods)

- (NSString *)tfy_toJsonString;

@end

NS_ASSUME_NONNULL_END
