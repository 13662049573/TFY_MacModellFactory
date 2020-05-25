//
//  ViewController.m
//  TFY_DataModelFactory
//
//  Created by tiandengyou on 2020/5/6.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "ViewController.h"
#import "TFY_CodeBuilder.h"


static NSString *const LastInputURLCacheKey = @"LastInputURLCacheKey";
static NSString *const SuperClassNameCacheKey = @"SuperClassNameCacheKey";
static NSString *const ModelNamePrefixCacheKey = @"ModelNamePrefixCacheKey";
static NSString *const RootModelNameCacheKey = @"RootModelNameCacheKey";
static NSString *const AuthorNameCacheKey = @"AuthorNameCacheKey";
static NSString *const BuildCodeTypeCacheKey = @"BuildCodeTypeCacheKey";
static NSString *const SupportJSONModelTypeCacheKey = @"SupportJSONModelTypeCacheKey";
static NSString *const ShouldGenerateFileCacheKey = @"ShouldGenerateFileCacheKey";
static NSString *const GenerateFilePathCacheKey = @"GenerateFilePathCacheKey";

@interface ViewController ()<NSTextFieldDelegate>{
    NSTextField *_currentInputTF;
}
//请求格式选项
@property (weak) IBOutlet NSPopUpButton *reqTypeBtn;
//地址
@property (weak) IBOutlet NSTextField *urlTF;
//JSON展示框
@property (unsafe_unretained) IBOutlet NSTextView *jsonTextView;
//.h展示框
@property (unsafe_unretained) IBOutlet NSTextView *hTextView;
//.m展示框
@property (unsafe_unretained) IBOutlet NSTextView *mTextView;
//对象属性名称默认NSObject
@property (weak) IBOutlet NSTextField *superClassNameTF;
//模型头部名称
@property (weak) IBOutlet NSTextField *modelNamePrefixTF;
//模型名称
@property (weak) IBOutlet NSTextField *rootModelNameTF;
//作者名称
@property (weak) IBOutlet NSTextField *authorNameTF;
//语言选项
@property (weak) IBOutlet NSPopUpButton *codeTypeBtn;
//模型转化选项
@property (weak) IBOutlet NSPopUpButton *jsonTypeBtn;
//是否生成.H.M文件选项
@property (weak) IBOutlet NSButton *generateFileBtn;

@property (nonatomic, copy) NSString * outputFilePath;
@property (nonatomic, strong) TFY_CodeBuilder *builder;
@property (nonatomic, assign)NSInteger indexreq;
@end


@implementation ViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    [self loadUserLastInputContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self Thedefaultdata];
}
/**
 * 默认数据
 */
-(void)Thedefaultdata{
    self.indexreq = 0;
    [self.reqTypeBtn removeAllItems];
    [self.reqTypeBtn addItemsWithTitles:@[@"GET",@"POST"]];
    [self.reqTypeBtn setAction:@selector(reqTypehandlePopBtn:)];
    [self.reqTypeBtn selectItemAtIndex:0];
    
    [self.codeTypeBtn removeAllItems];
    [self.codeTypeBtn addItemsWithTitles:@[@"Objective-C",@"Swift"]];
    [self.codeTypeBtn setAction:@selector(codeTypehandlePopBtn:)];
    [self.codeTypeBtn selectItemAtIndex:0];
    
    [self.jsonTypeBtn removeAllItems];
    [self.jsonTypeBtn addItemsWithTitles:@[@"None",@"TFY_Model"]];
    [self.jsonTypeBtn setAction:@selector(jsonTypehandlePopBtn:)];
    [self.jsonTypeBtn selectItemAtIndex:0];
    
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:BuildCodeTypeCacheKey];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:SupportJSONModelTypeCacheKey];
}
/**
 * 解析URL方法
 */
- (IBAction)requestURLBtnClicked:(NSButton *)sender {
    NSLog(@"URL = %@",self.urlTF.stringValue);
    NSString *urlString = self.urlTF.stringValue;
    if (!urlString || urlString.length == 0)  return;
    __weak typeof(self) weakself = self;
    [self SessionDataTaskType:self.indexreq URLWithString:urlString Urldata:^(id x) {
        if (x!=nil) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:x options:NSJSONWritingPrettyPrinted error:nil];

            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            [weakself configJsonTextViewWith:jsonString textView:weakself.jsonTextView color:[NSColor greenColor]];
        }
    }];
}
/**
 * 转化
 */
- (IBAction)startMakeCode:(NSButton *)sender {
    [self Conversionmodel];
}

/**
 * .h .m 保存路径
 */
- (IBAction)chooseOutputFilePath:(NSButton *)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    NSInteger modal = [openPanel runModal];
    if (modal == NSModalResponseOK){
        NSURL *files = [[openPanel URLs] objectAtIndex:0];
        _outputFilePath = files.path;
        NSLog(@"chooseOutputFilePath: %@",_outputFilePath);
    }
}
/**
 * 选择请求模式
 */
- (void)reqTypehandlePopBtn:(NSPopUpButton *)popBtn {
    self.indexreq = popBtn.indexOfSelectedItem;
}
/**
 * 语言选项
 */
-(void)codeTypehandlePopBtn:(NSPopUpButton *)popBtn{
    if (popBtn.indexOfSelectedItem==1) {
        [self showAlertWithInfo:@"警告:SWift语言，还在开发者!!" style:NSAlertStyleWarning];
        return;
    }
    self.builder.config.codeType = popBtn.indexOfSelectedItem;
    [[NSUserDefaults standardUserDefaults] setInteger:popBtn.indexOfSelectedItem forKey:BuildCodeTypeCacheKey];
    [self Conversionmodel];
}
/**
 * 转化模型格式选项
 */
-(void)jsonTypehandlePopBtn:(NSPopUpButton *)popBtn{
    self.builder.config.jsonType = popBtn.indexOfSelectedItem;
    [[NSUserDefaults standardUserDefaults] setInteger:popBtn.indexOfSelectedItem forKey:SupportJSONModelTypeCacheKey];
    [self Conversionmodel];
}

/**
 * 字典转化模型
 */
-(void)Conversionmodel{
    NSString *jsonString = self.jsonTextView.textStorage.string;
    NSDictionary *jsonDict = [jsonString tfy_toJsonDict];
    BOOL isvalid = [NSJSONSerialization isValidJSONObject:jsonDict];
    if (!isvalid) {
        [self showAlertWithInfo:@"警告:不是一个有效的JSON !!" style:NSAlertStyleWarning];
        return;
    }
    [self saveUserInputContent];
    [self configJsonTextViewWith:jsonString textView:self.jsonTextView color:[NSColor greenColor]];
    __weak typeof(self) weakself = self;
    [self.builder build_OC_withDict:jsonDict complete:^(NSMutableString *hString, NSMutableString *mString) {
        NSColor *color = [NSColor colorWithHue:0.58 saturation:0.68 brightness:0.94 alpha:1.00];
        [weakself configJsonTextViewWith:hString textView:weakself.hTextView color:color];
        [weakself configJsonTextViewWith:mString textView:weakself.mTextView color:color];
        if (weakself.generateFileBtn.state == 1) {
            [self.builder generate_OC_File_withPath:weakself.outputFilePath hString:hString mString:mString complete:^(BOOL success, NSString *filePath) {
                if (success) {
                    [self showAlertWithInfo:[NSString stringWithFormat:@"生成文件路径在：%@",filePath] style:NSAlertStyleInformational];
                    weakself.outputFilePath = filePath;
                    [weakself saveUserInputContent];
                }
            }];
        }
    }];
}

/**
 * 0 GET 1 POST 请求方法
 */
-(void)SessionDataTaskType:(NSInteger)task URLWithString:(NSString *)string Urldata:(void (^)(id x))nextBlock{
    NSURL *url = [NSURL URLWithString:string];
    NSURLSessionDataTask *dataTask;
    NSURLSession *session = [NSURLSession sharedSession];
    if (task==0) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error == nil) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                nextBlock(dict);
            }
            else{
                [self configJsonTextViewWith:error.userInfo[@"NSLocalizedDescription"] textView:self.jsonTextView color:[NSColor greenColor]];
            }
        }];
    }
    if (task==1) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error==nil) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                nextBlock(dict);
            }
            else{
                [self configJsonTextViewWith:error.userInfo[@"NSLocalizedDescription"] textView:self.jsonTextView color:[NSColor greenColor]];
            }
        }];
    }
    [dataTask resume];
    [[NSUserDefaults standardUserDefaults] setObject:string forKey:LastInputURLCacheKey];
}

/**
 * 加载缓存
 */
- (void)loadUserLastInputContent {
    
    NSString *lastUrl = [[NSUserDefaults standardUserDefaults] objectForKey:LastInputURLCacheKey];
    if (lastUrl) [self.urlTF setStringValue:lastUrl];
    
    NSString *superClassName = [[NSUserDefaults standardUserDefaults] objectForKey:SuperClassNameCacheKey];
    if (superClassName) [self.superClassNameTF setStringValue:superClassName];
    
    NSString *modelNamePrefix = [[NSUserDefaults standardUserDefaults] objectForKey:ModelNamePrefixCacheKey];
    if (modelNamePrefix) [self.modelNamePrefixTF setStringValue:modelNamePrefix];
    
    NSString *rootModelName = [[NSUserDefaults standardUserDefaults] objectForKey:RootModelNameCacheKey];
    if (rootModelName) [self.rootModelNameTF setStringValue:rootModelName];
    
    NSString *authorName = [[NSUserDefaults standardUserDefaults] objectForKey:AuthorNameCacheKey];
    if (authorName) [self.authorNameTF setStringValue:authorName];
    
    [self.codeTypeBtn selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:BuildCodeTypeCacheKey]];

    [self.jsonTypeBtn selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:SupportJSONModelTypeCacheKey]];
    
    [self.generateFileBtn setState:[[NSUserDefaults standardUserDefaults] boolForKey:ShouldGenerateFileCacheKey]];
    
    NSString *outputFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:GenerateFilePathCacheKey];
    if (outputFilePath) _outputFilePath = outputFilePath;

}

/**
 * 保存缓存
 */
- (void)saveUserInputContent {
    
    NSString *superClassName = self.superClassNameTF.stringValue.length ? self.superClassNameTF.stringValue : @"NSObject";
    self.builder.config.superClassName = superClassName;
    [[NSUserDefaults standardUserDefaults] setObject:superClassName forKey:SuperClassNameCacheKey];
    
    NSString *modelNamePrefix = self.modelNamePrefixTF.stringValue.length ? self.modelNamePrefixTF.stringValue : @"TFY_";
    self.builder.config.modelNamePrefix = modelNamePrefix;
    [[NSUserDefaults standardUserDefaults] setObject:modelNamePrefix forKey:ModelNamePrefixCacheKey];
    
    NSString *rootModelName = self.rootModelNameTF.stringValue.length ? self.rootModelNameTF.stringValue : @"TFY_RootModel";
    self.builder.config.rootModelName = rootModelName;
    [[NSUserDefaults standardUserDefaults] setObject:rootModelName forKey:RootModelNameCacheKey];
    
    NSString *authorName = self.authorNameTF.stringValue.length ? self.authorNameTF.stringValue : @"田风有";
    self.builder.config.authorName = authorName;
    [[NSUserDefaults standardUserDefaults] setObject:authorName forKey:AuthorNameCacheKey];
    

    [[NSUserDefaults standardUserDefaults] setObject:_outputFilePath forKey:GenerateFilePathCacheKey];
    [[NSUserDefaults standardUserDefaults] setBool:self.generateFileBtn.state forKey:ShouldGenerateFileCacheKey];
}

/// _currentInputTF width
- (void)caculateInputContentWidth {
    if (_currentInputTF) {
        NSArray *constraints = _currentInputTF.constraints;
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        [attributes setObject:_currentInputTF.font forKey:NSFontAttributeName];
        CGFloat strWidth = [_currentInputTF.stringValue boundingRectWithSize:CGSizeMake(FLT_MAX, 22) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:attributes].size.width + 10;
        strWidth = MAX(strWidth, 114);
        [constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            if (constraint.firstAttribute == NSLayoutAttributeWidth) {
                constraint.constant = strWidth;
            }
        }];
    }
}

/// MARK: NSControlTextEditingDelegate
- (void)controlTextDidChange:(NSNotification *)obj{
    _currentInputTF = obj.object;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(caculateInputContentWidth) object:nil];
    [self performSelector:@selector(caculateInputContentWidth) withObject:nil afterDelay:.1f];
}

/**
 * 配置主要thred上的textView内容。
 */
- (void)configJsonTextViewWith:(NSString *)text textView:(NSTextView *)textView color:(NSColor *)color {
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text];
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView.textStorage setAttributedString:attrString];
        [textView.textStorage setFont:[NSFont systemFontOfSize:15]];
        [textView.textStorage setForegroundColor:color];
    });
}

- (void)showAlertWithInfo:(NSString *)info style:(NSAlertStyle)style{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:info];
    [alert setAlertStyle:style];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

/**
 * 懒加载
 */
- (TFY_CodeBuilder *)builder{
    if (!_builder) {
        _builder = [[TFY_CodeBuilder alloc] init];
    }
    return _builder;
}

@end
