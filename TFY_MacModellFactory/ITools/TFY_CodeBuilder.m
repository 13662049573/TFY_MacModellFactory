//
//  TFY_CodeBuilder.m
//  TFY_DataModelFactory
//
//  Created by tiandengyou on 2020/5/6.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CodeBuilder.h"

#define kXMLParserTextNodeKey        (@"TFY_TXT")

@interface TFY_CodeBuilder ()<NSXMLParserDelegate>{
    NSMutableArray            *     _dictArr;             //存放字典数组
    NSMutableString           *     _contentTxt;          //存放当前解析内容文字
    NSError                   *     _error;               //存放错误信息
}
/// 接下来需要处理的 字典 key - value
@property (nonatomic, strong) NSMutableDictionary *handleDicts;
/*
 *  +(NSDictionary <NSString *, Class> *)tfy_ModelReplaceContainerElementClassMapper
 *   {
 *    return @{@"shadows" : [TFY_Shadow class],
 *               @"borders" : TFY_Border.class,
 *               @"attachments" : @"TFY_Attachment" };
 *   }
 */
@property (nonatomic, strong) NSMutableDictionary *tfy_modelPropertyGenericClassDicts;
/*
*  +(NSDictionary <NSString *,NSString *> *)tfy_ModelReplacePropertyMapper
*   {
*    return @{@"name"  : @"n",
*             @"page"  : @"p",
*             @"desc"  : @"ext.desc",
*             @"bookID": @[@"id", @"ID", @"book_id"]};
*   }
*/
@property (nonatomic, strong) NSMutableDictionary *tfy_modelPropertyMapper;

@property (nonatomic, strong) NSMutableString *hString;
@property (nonatomic, strong) NSMutableString *mString;

@end

@implementation TFY_CodeBuilder

- (instancetype)init {
    if (self = [super init]) {
        _config = [TFY_CodeBuilderConfig new];
        _error = [NSError new];
        _dictArr = [NSMutableArray new];
        _contentTxt = [NSMutableString new];
    }
    return self;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data{
    return [TFY_CodeBuilder dictionaryForXMLData:data options:0];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string{
    return [TFY_CodeBuilder dictionaryForXMLData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data options:(TFY_XMLParserOptions)options{
    TFY_CodeBuilder  *tfy_xmlParser = [TFY_CodeBuilder new];
   return [tfy_xmlParser startParserXML:data options:options];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string options:(TFY_XMLParserOptions)options{
    return [TFY_CodeBuilder dictionaryForXMLData:[string dataUsingEncoding:NSUTF8StringEncoding] options:options];
}

- (NSDictionary*)startParserXML:(NSData*)data options:(TFY_XMLParserOptions)options{
    [_dictArr addObject:[NSMutableDictionary new]];
    NSXMLParser  * xmlParser = [[NSXMLParser alloc]initWithData:data];
    xmlParser.delegate = self;
    xmlParser.shouldProcessNamespaces = (options & TFY_XMLParserOptionsProcessNamespaces);
    xmlParser.shouldReportNamespacePrefixes = (options & TFY_XMLParserOptionsReportNamespacePrefixes);
    xmlParser.shouldResolveExternalEntities = (options & TFY_XMLParserOptionsResolveExternalEntities);
    if([xmlParser parse]){
        [self XMLDataHandleEngine:_dictArr[0]];
        return _dictArr[0];
    }
    return nil;
}

- (void)XMLDataHandleEngine:(id)object{
    if([object isKindOfClass:[NSDictionary class]]){
        NSMutableDictionary * dict = object;
        NSInteger               count = dict.count;
        NSArray              * keyArr = [dict allKeys];
        for (NSInteger i = 0; i < count; i++) {
            NSString  * key = keyArr[i];
            id   subObject = dict[key];
            if([subObject isKindOfClass:[NSDictionary class]]){
                [self handleTopData:dict subDict:subObject index:i];
                [self XMLDataHandleEngine:subObject];
            }else if([subObject isKindOfClass:[NSArray class]]){
                [self XMLDataHandleEngine:subObject];
            }
        }
    }else if ([object isKindOfClass:[NSArray class]]){
        NSMutableArray * arrs = object;
        for (NSInteger i = 0; i < arrs.count; i++) {
            id subObject = arrs[i];
            [self XMLDataHandleEngine:subObject];
        }
    }
}

- (void)handleTopData:(NSMutableDictionary *)dict subDict:(NSDictionary*)subDict index:(NSInteger)index{
    NSArray  * subKeyArr = [subDict allKeys];
    NSArray  * keyArr = [dict allKeys];
    if(subKeyArr.count == 1 && [subKeyArr[0] isEqualToString:kXMLParserTextNodeKey]){
        [dict setObject:subDict[kXMLParserTextNodeKey] forKey:keyArr[index]];
    }else if(subKeyArr.count == 0){
        [dict setObject:@"" forKey:keyArr[index]];
    }
    
}
#pragma mark - NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    NSMutableDictionary  * parentDict = [_dictArr lastObject];
    NSMutableDictionary  * childDict = [NSMutableDictionary new];
    [childDict addEntriesFromDictionary:attributeDict];
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue){
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]]){
            //使用存在的数组
            array = (NSMutableArray *) existingValue;
        }else{
            //不存在创建数组
            array = [NSMutableArray new];
            [array addObject:existingValue];
            // 替换子字典用数组
            [parentDict setObject:array forKey:elementName];
        }
        // 添加一个新的子字典
        [array addObject:childDict];
    }else{
        // 不存在插入新元素
        [parentDict setObject:childDict forKey:elementName];
    }
    
    // 跟新数组
    [_dictArr addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    NSMutableDictionary *dictInProgress = [_dictArr lastObject];
    if (_contentTxt.length > 0){
        // 存储值
        NSString *valueTxt = [_contentTxt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(valueTxt.length){
            [dictInProgress setObject:[valueTxt mutableCopy] forKey:kXMLParserTextNodeKey];
            _contentTxt = [[NSMutableString alloc] init];
        }
    }
    // 移除当前
    [_dictArr removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [_contentTxt appendString:string];
    
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if(parseError){
        NSLog(@"TFY_CodeBuilder :%@",parseError);
    }
}



- (void)build_OC_withDict:(NSDictionary *)jsonDict complete:(BuildComplete)complete {
    
    NSMutableString *hString = [NSMutableString string];
    NSMutableString *mString = [NSMutableString string];

    [self handleDictValue:jsonDict key:@"" hString:hString mString:mString];
    
    if ([self.config.superClassName isEqualToString:@"NSObject"]) { // 默认
        [hString insertString:@"\n#import <Foundation/Foundation.h>\n\n" atIndex:0];
    } else {
        [hString insertString:[NSString stringWithFormat:@"\n#import \"%@.h\"\n\n",self.config.superClassName] atIndex:0];
    }
    
    [mString insertString:[NSString stringWithFormat:@"\n#import \"%@.h\"\n\n",self.config.rootModelName] atIndex:0];

    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *time = [dateFormatter stringFromDate:[NSDate date]];
    NSString *year = [[time componentsSeparatedByString:@"/"] firstObject];

    NSString *hCommentString = [NSString stringWithFormat:
                               @"//\n"
                                "//  %@.h\n"
                                "//  TFY_CodeBuilder\n"
                                "//\n"
                                "//  Created by %@ on %@.\n"
                                "//  Copyright © %@ TFY_CodeBuilder. All rights reserved.\n"
                                "//\n", self.config.rootModelName, self.config.authorName, time, year];
    
    NSString *mCommentString = [NSString stringWithFormat:
                               @"//\n"
                               "//  %@.m\n"
                               "//  TFY_CodeBuilder\n"
                               "//\n"
                               "//  Created by %@ on %@.\n"
                               "//  Copyright © %@ TFY_CodeBuilder. All rights reserved.\n"
                               "//\n", self.config.rootModelName, self.config.authorName, time, year];
    
    [hString insertString:hCommentString atIndex:0];
    [mString insertString:mCommentString atIndex:0];
    
    if (complete) {
        complete(hString, mString);
    }
}

- (void)handleDictValue:(NSDictionary *)dictValue key:(NSString *)key hString:(NSMutableString *)hString mString:(NSMutableString *)mString{
   
    if (key && key.length) { // sub model
        NSString *modelName = [self modelNameWithKey:key];
        [hString insertString:[NSString stringWithFormat:@"@class %@;\n", modelName] atIndex:0];
        [hString appendFormat:@"\n\n@interface %@ : %@\n\n", modelName ,self.config.superClassName];
        
        [mString appendFormat:@"\n\n@implementation %@\n\n", modelName];

    } else { // Root model
        [hString appendFormat:@"\n\n@interface %@ : %@\n\n", self.config.rootModelName ,self.config.superClassName];
        
        [mString appendFormat:@"\n\n@implementation %@\n\n", self.config.rootModelName];
    }
    
    if (![dictValue isKindOfClass:[NSDictionary class]]) {
        [hString appendFormat:@"\n@end\n\n"];
        [mString appendFormat:@"\n@end\n\n"];
        NSLog(@" handleDictValue (%@) error !!!!!!",dictValue);
        return;
    }
    
    [dictValue enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        
        if ([value isKindOfClass:[NSNumber class]]) {
            // NSNumber 类型
            [self handleNumberValue:value key:key hString:hString];
            
        } else if ([value isKindOfClass:[NSString class]]) {
            // NSString 类型
            if ([(NSString *)value length] > 12 && ![key isEqualToString:@"description"] && ![key hasPrefix:@"new"]) {
                [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",key,key, key];
            }
            else {
                if (self.config.jsonType == TFY_CodeBuilderJSONModelTypeNone) {
                    [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",key,value,key];
                } else {
                    [self handleIdValue:value key:key hString:hString];
                }
            }
            
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            // NSDictionary 类型
            NSString *modelName = [self modelNameWithKey:key];
            [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , strong) %@ *%@;\n",key,key, modelName, key];\
            
            NSString *propertyValue = [NSString stringWithFormat:@"%@", modelName];
            [self.tfy_modelPropertyGenericClassDicts setObject:propertyValue forKey:key];
            
            [self.handleDicts setObject:value forKey:key];
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            // NSArray 类型
            [self handleArrayValue:(NSArray *)value key:key hString:hString];
            
        } else {
            // 识别不出类型
            [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , strong) id %@;\n",key,key,key];
        }
    }];
    
    [hString appendFormat:@"\n@end\n\n"];

    if (self.config.jsonType == TFY_CodeBuilderJSONModelTypeTFY_Model) { // 适配TFY_Model
        
        /// 容器属性的通用类映射器。
        BOOL needLineBreak = NO;
        if (self.tfy_modelPropertyGenericClassDicts.count) {
            [mString appendFormat:@"+(NSDictionary <NSString *, Class> *)tfy_ModelReplaceContainerElementClassMapper"];
            [mString appendFormat:@"{\n     return @{"];
            [self.tfy_modelPropertyGenericClassDicts enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [mString appendFormat:@"@\"%@\" : %@.class,\n",key, obj];
            }];
            [mString appendFormat:@"     };"];
            [mString appendFormat:@"\n}\n"];
            needLineBreak = YES;
        }
        
        /// 自定义属性映射器。
        if (self.tfy_modelPropertyMapper.count) {
            if (needLineBreak) {
                [mString appendFormat:@"\n"];
            }
            [mString appendFormat:@"+(NSDictionary <NSString *,NSString *> *)tfy_ModelReplacePropertyMapper"];
            [mString appendFormat:@"{\n   return @{"];
            [self.tfy_modelPropertyMapper enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [mString appendFormat:@"@\"%@\" : @""\"%@\",\n",key, obj];
            }];
            [mString appendFormat:@"     };"];
            [mString appendFormat:@"\n}\n"];
        }
    }
    
    if (self.config.jsonType == TFY_CodeBuilderJSONModelTypeYYModel) {
        /// 容器属性的通用类映射器。
        BOOL needLineBreak = NO;
        if (self.tfy_modelPropertyGenericClassDicts.count) {
            [mString appendFormat:@"+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass"];
            [mString appendFormat:@"{\n     return @{"];
            [self.tfy_modelPropertyGenericClassDicts enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [mString appendFormat:@"@\"%@\" : %@.class,\n",key, obj];
            }];
            [mString appendFormat:@"     };"];
            [mString appendFormat:@"\n}\n"];
            needLineBreak = YES;
        }
        
        /// 自定义属性映射器。
        if (self.tfy_modelPropertyMapper.count) {
            if (needLineBreak) {
                [mString appendFormat:@"\n"];
            }
            [mString appendFormat:@"+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper"];
            [mString appendFormat:@"{\n   return @{"];
            [self.tfy_modelPropertyMapper enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [mString appendFormat:@"@\"%@\" : @""\"%@\",\n",key, obj];  //   **\"
            }];
            [mString appendFormat:@"     };"];
            [mString appendFormat:@"\n}\n"];
        }
    }
    
    if (key.length) {
        [self.handleDicts removeObjectForKey:key];
    }
    
    [mString appendFormat:@"\n@end\n\n"];
    
    [self.tfy_modelPropertyGenericClassDicts removeAllObjects];
    [self.tfy_modelPropertyMapper removeAllObjects];

    if (self.handleDicts.count) {
        NSString *firstKey = self.handleDicts.allKeys.firstObject;
        NSDictionary *firstObject = self.handleDicts[firstKey];
        [self handleDictValue:firstObject key:firstKey hString:hString mString:mString];
    }
}

- (void)handleIdValue:(NSString *)idValue key:(NSString *)key hString:(NSMutableString *)hString {
    
    if ([key isEqualToString:@"id"]) {
        [self.tfy_modelPropertyMapper setObject:@"id" forKey:@"itemId"];
        [hString appendFormat:@"////-- %@ : %@\n@property (nonatomic, assign) NSInteger %@;\n",idValue,idValue,@"itemId"];
    }
    else if ([key isEqualToString:@"description"]){
        [self.tfy_modelPropertyMapper setObject:@"description" forKey:@"desc"];
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",idValue,idValue,@"desc"];
    } else if ([key hasPrefix:@"new"]){
        NSString *valuekey = [key stringByReplacingOccurrencesOfString:@"new" withString:@"news"];
        [self.tfy_modelPropertyMapper setObject:key forKey:valuekey];
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",idValue,idValue,valuekey];
    } else {
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",key,idValue,key];
    }
}

- (void)handleArrayValue:(NSArray *)arrayValue key:(NSString *)key hString:(NSMutableString *)hString {
    
    if (arrayValue && arrayValue.count) {
        
        id firstObject = arrayValue.firstObject;
        
        if ([firstObject isKindOfClass:[NSString class]]) {
            // NSString 类型
            [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSArray <NSString *> *%@;\n",key,key, key];
            
        } else if ([firstObject isKindOfClass:[NSDictionary class]]) {
            // NSDictionary 类型
            NSString *modelName = [self modelNameWithKey:key];
            [self.handleDicts setObject:firstObject forKey:key];
            
            NSString *propertyValue = [NSString stringWithFormat:@"%@", modelName];
            [self.tfy_modelPropertyGenericClassDicts setObject:propertyValue forKey:key];
            
            [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSArray <%@ *> *%@;\n",key,key, modelName, key];
            
        } else if ([firstObject isKindOfClass:[NSArray class]]) {
           
            [self handleArrayValue:(NSArray *)firstObject key:key hString:hString];
            
        } else {
            
            [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSArray *%@;\n",key,key, key];
        }
    }
}

- (void)handleNumberValue:(NSNumber *)numValue key:(NSString *)key hString:(NSMutableString *)hString {
        
    const char *type = [numValue objCType];
    
    if (strcmp(type, @encode(char)) == 0 || strcmp(type, @encode(unsigned char)) == 0) {
        // char 字符串
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , copy) NSString *%@;\n",key,numValue,key];
        
    } else if (strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0) {
         // 浮点型
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , assign) CGFloat %@;\n",key,numValue,key];
    
    } else if (strcmp(type, @encode(BOOL)) == 0) {
         // 布尔值类型
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , assign) BOOL %@;\n",key,numValue,key];
        
    } else  {
        // int, long, longlong, unsigned int,unsigned longlong 类型
        [hString appendFormat:@"///-- %@ : %@\n@property (nonatomic , assign) NSInteger %@;\n",key,numValue,key];
    }
}

- (NSString *)modelNameWithKey:(NSString *)key
{
    NSString *firstCharacter = [key substringToIndex:1];
    if (firstCharacter) {
        firstCharacter = [firstCharacter uppercaseString];
    }
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstCharacter];
    if (![key hasPrefix:self.config.modelNamePrefix]) {
        key = [NSString stringWithFormat:@"%@%@",self.config.modelNamePrefix,key];
    }
    return [NSString stringWithFormat:@"%@Model",key];
}

- (void)generate_OC_File_withPath:(NSString *)filePath hString:(NSMutableString *)hString mString:(NSMutableString *)mString complete:(GenerateFileComplete)complete {
    if (hString.length && mString.length) {
        
        if (!filePath) {
            NSString *path = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES).lastObject;
            path = [path stringByAppendingPathComponent:@"TFY_CodeBuilderModelFiles"];
            NSLog(@"path = %@",path);
            BOOL isDir = NO;
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
            if (isExists && isDir) {
                filePath = path;
            } else {
                if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]) {
                    filePath = path;
                }
            }
        }
        
        NSString *fileNameH = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",self.config.rootModelName]];
        NSString *fileNameM = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",self.config.rootModelName]];
        BOOL retH = [hString writeToFile:fileNameH atomically:YES encoding:NSUTF8StringEncoding error:nil];
        BOOL retM = [mString writeToFile:fileNameM atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        if (complete) {
            complete(retH&&retM, filePath);
        }
    }
}

- (NSMutableDictionary *)handleDicts {
    if (!_handleDicts) {
        _handleDicts = [NSMutableDictionary new];
    }
    return _handleDicts;
}

- (NSMutableDictionary *)tfy_modelPropertyGenericClassDicts {
    if (!_tfy_modelPropertyGenericClassDicts) {
        _tfy_modelPropertyGenericClassDicts = [NSMutableDictionary new];
    }
    return _tfy_modelPropertyGenericClassDicts;
}

- (NSMutableDictionary *)tfy_modelPropertyMapper {
    if (!_tfy_modelPropertyMapper) {
        _tfy_modelPropertyMapper = [NSMutableDictionary new];
    }
    return _tfy_modelPropertyMapper;
}

@end

@implementation TFY_CodeBuilderConfig

- (instancetype)init {
    if (self = [super init]) {
        _superClassName = @"NSObject";
        _rootModelName = @"TFY_RootModel";
        _modelNamePrefix = @"TFY_";
        _authorName = @"田风有";
        _codeType = TFY_CodeBuilderCodeTypeOC;
        _jsonType = TFY_CodeBuilderJSONModelTypeNone;
    }
    return self;
}

@end
