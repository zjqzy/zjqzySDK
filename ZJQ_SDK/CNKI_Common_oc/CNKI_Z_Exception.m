//
//  NSUncaughtExceptionUtil.m
//


#import "CNKI_Z_Exception.h"

@interface CNKI_Z_Exception()


@end

@implementation CNKI_Z_Exception

static CNKI_Z_Exception *s_uncaughtException = nil;
+(CNKI_Z_Exception*)sharedInstance
{
    //单例
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_uncaughtException = [[super allocWithZone:nil] init];
        
    });
    return s_uncaughtException;
}
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Exception sharedInstance] ;
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Exception sharedInstance] ;
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [CNKI_Z_Exception sharedInstance];
}
-(void)dealloc
{
    //析构
#ifdef DEBUG
    NSLog(@"析构 %@", NSStringFromClass([self class]));
#endif
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

-(NSString*)description
{
    //描述
    NSString *strDesc=[NSString stringWithFormat:@"class=%@",[NSString stringWithUTF8String:object_getClassName(self)]];
    return strDesc;
}

- (id)init
{
    //单例 触发这里
	if ((self = [super init])) // Initialize
	{

	}
    
	return self;
}

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
#pragma mark - trigger
-(NSUncaughtExceptionHandler*)getHandler
{
    return NSGetUncaughtExceptionHandler();
}
-(void)initTest
{
    //绑定
    signal(SIGABRT,sighandler);
    signal(SIGBUS, sighandler);
    signal(SIGFPE, sighandler);
    
    //释放
    signal(SIGABRT, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGFPE, SIG_DFL);

}
void sighandler(int signal)
{
    // initTest
}
void UncaughtExceptionHandler(NSException *exception)
{
    //发生异常，则触发此函数
    NSArray *arrStack = [exception callStackSymbols];
    
    NSString *reason = [exception reason];
    
    NSString *name = [exception name];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *strNow = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *exceptionContent = [NSString stringWithFormat:@"\r\n\r\n=== 异常崩溃报告 === %@ ===\r\n\r\nname:\n%@\n\nreason:\n%@\n\ncallStackSymbols:\n%@\n\n\n\n",strNow,name,reason,[arrStack componentsJoinedByString:@"\n"]];
    
    NSString *logSaveFilePath=[NSString stringWithFormat:@"%@/Library/app_CrashLog.txt",NSHomeDirectory()];
    

    //追加写入文档
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logSaveFilePath];
    if (fileHandle)
    {
        //找到并定位到末尾位置(在此后追加文件)
        [fileHandle seekToEndOfFile];
        NSData *dataBuf = [exceptionContent dataUsingEncoding:NSUTF8StringEncoding];
        
        [fileHandle writeData:dataBuf];
        
        //关闭读写文件
        [fileHandle closeFile];
        
        NSLog(@"异常已加入Crash日志！！");
    }
    else
    {
        //覆盖写入文档
        if ([exceptionContent writeToFile:logSaveFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            NSLog(@"异常已写入Crash日志！！");
        }
    }

    
    //后续工作
    //除了可以选择写到应用下的某个文件，通过后续处理将信息发送到服务器等
    //还可以选择调用发送邮件的的程序，发送信息到指定的邮件地址
    //或者调用某个处理程序来处理这个信息
    
}
-(void)triggerWithHandler:(NSUncaughtExceptionHandler)handler1
{
    if (handler1) {
        NSSetUncaughtExceptionHandler(handler1);
    }
    else
    {
        NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    }
    
    
}
@end
