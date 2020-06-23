//
//  TFY_CodeBuilder.h
//  TFY_DataModelFactory
//
//  Created by tiandengyou on 2020/5/6.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+methods.h"

typedef NS_ENUM(NSInteger, TFY_CodeBuilderCodeType) {
    TFY_CodeBuilderCodeTypeOC = 0,
    TFY_CodeBuilderCodeTypeSwift =1,
    TFY_CodeBuilderCodeTypeJava =3,
};

typedef NS_ENUM(NSInteger, TFY_CodeBuilderJSONModelType) {
    TFY_CodeBuilderJSONModelTypeNone = 0,
    TFY_CodeBuilderJSONModelTypeTFY_Model = 1,
    TFY_CodeBuilderJSONModelTypeYYModel = 2,
};

typedef NS_ENUM(NSInteger, TFY_XMLParserOptions) {
    TFY_XMLParserOptionsProcessNamespaces           = 1 << 0,
    TFY_XMLParserOptionsReportNamespacePrefixes     = 1 << 1,
    TFY_XMLParserOptionsResolveExternalEntities     = 1 << 2,
};

@class TFY_CodeBuilderConfig;

NS_ASSUME_NONNULL_BEGIN

@interface TFY_CodeBuilder : NSObject

typedef void (^BuildComplete)(NSMutableString *hString, NSMutableString *mString);

typedef void (^GenerateFileComplete)(BOOL success, NSString *filePath);

@property (nonatomic, strong) TFY_CodeBuilderConfig *config;

- (void)build_OC_withDict:(NSDictionary *)jsonDict complete:(BuildComplete)complete;

- (void)generate_OC_File_withPath:(NSString *)filePath
                          hString:(NSMutableString *)hString
                          mString:(NSMutableString *)mString
                         complete:(GenerateFileComplete)complete;

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string;
+ (NSDictionary *)dictionaryForXMLData:(NSData *)data options:(TFY_XMLParserOptions)options;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string options:(TFY_XMLParserOptions)options;

@end

@interface TFY_CodeBuilderConfig : NSObject

/// model继承类名... default "NSObject"
@property (nonatomic, copy) NSString *superClassName;
/// root model name ... default "NSRootModel"
@property (nonatomic, copy) NSString *rootModelName;
/// model name prefix  ... default "NS"
@property (nonatomic, copy) NSString *modelNamePrefix;
/// authorName  ... default "TFY_CodeBuilder"
@property (nonatomic, copy) NSString *authorName;
/// support OC/Swift/Java   ...default "OC"
@property (nonatomic, assign) TFY_CodeBuilderCodeType codeType;
/// support YYModel/MJExtension/None   ...default "None"
@property (nonatomic, assign) TFY_CodeBuilderJSONModelType jsonType;

@end

NS_ASSUME_NONNULL_END
