//
//  zhuIOSLib.m
//


#import "CNKI_Z_Lib.h"
#import <fcntl.h>
#include <iconv.h>  
#import <netdb.h>
#import <zconf.h>
#import <zlib.h>

#import <sys/stat.h>
#import <sys/xattr.h>   //文件属性
#import <sys/param.h>
#import <sys/mount.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <mach-o/dyld.h> 

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>   // iOS DES加密

#import <QuartzCore/QuartzCore.h>

#import "CNKI_Z_GTMBase64.h"


#define FileHashDefaultChunkSizeForReadingData 1024*8 // 8K

@implementation CNKI_Z_Lib
static CNKI_Z_Lib *s_lib = nil;
+(CNKI_Z_Lib*)sharedInstance
{
    //单例
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_lib = [[super allocWithZone:nil] init];
    });
    return s_lib;
}
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Lib sharedInstance] ;
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Lib sharedInstance] ;
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [CNKI_Z_Lib sharedInstance];
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
	if ((self = [super init])) // Initialize
	{

	}
	return self;
}

void zhuDrawContent(CGContextRef myContext,
                   CFDataRef data,
                   CGRect rect)
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(data);
    CGImageRef image = CGImageCreateWithJPEGDataProvider(dataProvider,
                                                         NULL,
                                                         NO,
                                                         kCGRenderingIntentDefault);
    CGContextDrawImage(myContext, rect, image);
    
    CGDataProviderRelease(dataProvider);
    CGImageRelease(image);
}

void zhuCreatePDFFile (CFDataRef data,
                      CGRect pageRect,
                      const char *filepath,
                      CFStringRef password)
{
    CGContextRef pdfContext;
    CFStringRef path;
    CFURLRef url;
    CFDataRef boxData = NULL;
    CFMutableDictionaryRef myDictionary = NULL;
    CFMutableDictionaryRef pageDictionary = NULL;
    
    path = CFStringCreateWithCString (NULL, filepath,
                                      kCFStringEncodingUTF8);
    url = CFURLCreateWithFileSystemPath (NULL, path,
                                         kCFURLPOSIXPathStyle, 0);
    CFRelease (path);
    myDictionary = CFDictionaryCreateMutable(NULL,
                                             0,
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(myDictionary,
                         kCGPDFContextTitle,
                         CFSTR("Photo from iPrivate Album"));
    CFDictionarySetValue(myDictionary,
                         kCGPDFContextCreator,
                         CFSTR("iPrivate Album"));
    if (password) {
        CFDictionarySetValue(myDictionary, kCGPDFContextUserPassword, password);
        CFDictionarySetValue(myDictionary, kCGPDFContextOwnerPassword, password);
    }
    //创建PDF
    pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary);
    CFRelease(myDictionary);
    CFRelease(url);
    //内容
    pageDictionary = CFDictionaryCreateMutable(NULL,
                                               0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    boxData = CFDataCreate(NULL,(const UInt8 *)&pageRect, sizeof (CGRect));
    CFDictionarySetValue(pageDictionary, kCGPDFContextMediaBox, boxData);
    CGPDFContextBeginPage (pdfContext, pageDictionary);
    zhuDrawContent(pdfContext,data,pageRect);
    CGPDFContextEndPage (pdfContext);
    
    CGContextRelease (pdfContext);
    CFRelease(pageDictionary);
    CFRelease(boxData);
}

-(void)zhuImageToPDFFileWithSrc:(NSData *)imgData
                    toDestFile:(NSString *)destFileName
                  withPassword:(NSString *)pw
{
    NSString *fileFullPath = destFileName;  //绝对路径
    const char *cfullpath = [fileFullPath UTF8String];
    //CFDataRef data = (__bridge CFDataRef)imgData;   //use arc
    CFDataRef data = (__bridge CFDataRef)imgData;
    UIImage *image = [UIImage imageWithData:imgData];
    CGRect pageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    //CFStringRef password = (__bridge CFStringRef)pw;    //use arc
    CFStringRef password = (__bridge CFStringRef)pw;
    
    zhuCreatePDFFile(data,pageRect, cfullpath, password);
}

-(Class)SDKHaveClassFromString:(NSString *)classStr
{
    //判断当前 SDK 是否支持 类
    return NSClassFromString(@"UIPrintInteractionController");
}
-(BOOL)SDKClassHaveMethod:(NSString*)classStr Method:(SEL)method
{
    return [NSClassFromString(classStr) instancesRespondToSelector:method];
}

-(NSString *)ToHex:(int)tmpid
{
    //十进制转十六进制
    NSString *endtmp=@"";
    NSString *nLetterValue;
    NSString *nStrat;
    int ttmpig=tmpid%16;
    int tmp=tmpid/16;
    switch (ttmpig)
    {
        case 10:
            nLetterValue =@"A";break;
        case 11:
            nLetterValue =@"B";break;
        case 12:
            nLetterValue =@"C";break;
        case 13:
            nLetterValue =@"D";break;
        case 14:
            nLetterValue =@"E";break;
        case 15:
            nLetterValue =@"F";break;
        default:
            nLetterValue=[[NSString alloc] initWithFormat:@"%i",ttmpig];
            
    }
    switch (tmp)
    {
        case 10:
            nStrat =@"A";break;
        case 11:
            nStrat =@"B";break;
        case 12:
            nStrat =@"C";break;
        case 13:
            nStrat =@"D";break;
        case 14:
            nStrat =@"E";break;
        case 15:
            nStrat =@"F";break;
        default:
            nStrat=[[NSString alloc] initWithFormat:@"%i",tmp];
            
    }
    endtmp=[[NSString alloc]initWithFormat:@"%@%@",nStrat,nLetterValue];
    return endtmp;
}

-(void)appendData:(NSObject *)data toFile:(NSString *)file
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0){
		NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
		if(![fileManager fileExistsAtPath:path]){
			NSMutableArray *fileData = [[NSMutableArray alloc] init];
            if([fileData writeToFile:path atomically:YES]){
                
            }
            
		}
        NSMutableArray *fileData = [[NSMutableArray alloc] initWithContentsOfFile:path];
        [fileData addObject:data];
        if([fileData writeToFile:path atomically:YES]){
            
        }
	}
}

-(void)prependData:(NSObject *)data toFile:(NSString *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0){
		NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
		if(![fileManager fileExistsAtPath:path]){
			NSMutableArray *fileData = [[NSMutableArray alloc] init];
            if([fileData writeToFile:path atomically:YES]){
                
            }
		}
        NSMutableArray *fileData = [[NSMutableArray alloc] initWithContentsOfFile:path];
        if(![fileData containsObject:data]){
            [fileData insertObject:data atIndex:0];
            if([fileData writeToFile:path atomically:YES]){
                
            }
        }
	}
}

-(NSMutableArray *)getDataFromFile:(NSString *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0){
		NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
		if(![fileManager fileExistsAtPath:path]){
			return nil;
		}
        
        NSMutableArray *fileData = [[NSMutableArray alloc] initWithContentsOfFile:path];
        return  fileData;
	}
    return nil;
}

-(void)deleteData:(NSObject *)data ofFile:(NSString *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0){
		NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
		if([fileManager fileExistsAtPath:path]){
			NSMutableArray *fileData = [[NSMutableArray alloc] initWithContentsOfFile:path];
            [fileData removeObject:data];
            if([fileData writeToFile:path atomically:YES]){}
		}
	}
}

-(void)empty:(NSString *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0){
		NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
		if([fileManager fileExistsAtPath:path]){
			NSMutableArray *fileData = [[NSMutableArray alloc] initWithContentsOfFile:path];
            [fileData removeAllObjects];
            if([fileData writeToFile:path atomically:YES]){}
		}
	}
}


-(long long)fileSizeAtPath:(NSString *)path
{
    //判断文件大小，也可当 pathFileExist用
    struct stat st;
    
    if (!stat([path cStringUsingEncoding:NSUTF8StringEncoding], &st)) {
        return st.st_size;
    }
    return 0;
}

//遍历文件夹获得文件夹大小，返回多少M
- (float) folderSizeAtPath:(NSString*) folderPath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil)
    {
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}
-(BOOL)createDirectory:(NSString*)strFolderPath
{
    //创建文件夹
    BOOL bDo1=YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:strFolderPath] == NO) {
        bDo1=[fileManager createDirectoryAtPath:strFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return bDo1;
}

-(BOOL)deleteFileAtPath:(NSString*)path
{
    BOOL bDo1=NO;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path])
    {
        bDo1=[fileManager removeItemAtPath:path error:nil];
    }
    
    return bDo1;
}
-(BOOL)moveFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath
{
    BOOL bDo1=NO;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:oldPath])
    {
        NSURL *old=[NSURL fileURLWithPath:oldPath];
        NSURL *new=[NSURL fileURLWithPath:newPath];
        bDo1=[fileManager moveItemAtURL:old toURL:new error:nil];
    }
    
    return bDo1;
}
-(BOOL)copyFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath
{
    BOOL bDo1=NO;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:oldPath])
    {
//        NSURL *old=[NSURL fileURLWithPath:oldPath];
//        NSURL *new=[NSURL fileURLWithPath:newPath];
        bDo1=[fileManager copyItemAtPath:oldPath toPath:newPath error:nil];
    }
    
    return bDo1;
}
-(BOOL)deleteDirectory:(NSString*)strFolderPath DelSelf:(BOOL)bDelSelf
{
    //删除文件夹（自身是否删除）
    BOOL bDo1=YES;
    
    NSFileManager *localFileManager=[NSFileManager defaultManager];
    if (bDelSelf)
    {
        //删除自身
        if (! [localFileManager removeItemAtPath:strFolderPath error:nil])
        {
#ifdef DEBUG
            NSLog(@"fail del=%@",strFolderPath);
#endif
            bDo1=NO;
        }
    }
    else
    {
        //不删除自身
        NSDirectoryEnumerator *dirEnum =[localFileManager enumeratorAtPath:strFolderPath];
        NSString *file;
        while (file = [dirEnum nextObject])
        {
            NSString *delPath=[strFolderPath stringByAppendingPathComponent:file];
            if (! [localFileManager removeItemAtPath:delPath error:nil])
            {
#ifdef DEBUG
                NSLog(@"fail del=%@",delPath);
#endif
                bDo1=NO;
            }
        }
    }

    return bDo1;
}
-(NSString*)fileParentFolder:(NSString*)fileFullPath
{
    //得到文件父文件夹
    int lastSlash = (int)[fileFullPath rangeOfString:@"/" options:NSBackwardsSearch].location;
    NSString *parentFolder = [fileFullPath substringToIndex:(lastSlash +1)];
    return parentFolder;
}


-(BOOL)deleteAllFileInTmpDirectory
{
    //删除系统 “／tmp” 内的所有文件
    NSString *tmpDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"tmp"];
    return [self deleteDirectory:tmpDir DelSelf:NO];
}
-(BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)path
{
    NSURL *urla = [NSURL fileURLWithPath:path];
    return [self addSkipBackupAttributeToItemAtURL:urla];
}
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL*)URL
{
    //5.0.1 方法  5.0.1以下的只能存放在 library/caches里面
    const char* filePath=[[URL path] fileSystemRepresentation];
    const char* attrName="com.apple.MobileBackup";
    u_int8_t attrValue=1;
    int iResult=setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return (iResult == 0) ;
    
    // ios5.1 or later  
    
    //文件取消iCloud 的backup属性，设为不备份
    NSError *error=nil;
    BOOL success=[URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
#ifdef DEBUG
    if (!success) {
        NSLog(@"error excluding %@ from backup %@",[URL lastPathComponent],error);
    }
#endif
    return success;
}

-(BOOL)isFileHaveBackupAttributeAtPath:(NSString *)path
{
    NSURL *urla = [NSURL fileURLWithPath:path];
    return [self isFileHaveBackupAttributeAtURL:urla];
}
-(BOOL)isFileHaveBackupAttributeAtURL:(NSURL *)URL
{
    if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]])
        return NO;
    NSError *error = nil;
    
    NSNumber *bHave=nil;
    [URL getResourceValue:&bHave forKey:NSURLIsExcludedFromBackupKey error:&error];
    
    BOOL bRet=[bHave boolValue];
    return bRet;
}
-(BOOL)isFileExist:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}
-(NSString*)fileContentMD5:(NSString*)path
{
    //
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if(handle == nil)
        return nil;
    CC_MD5_CTX md5_ctx;
    CC_MD5_Init(&md5_ctx);
    NSData* filedata;
    do {
        filedata = [handle readDataOfLength:1024];
        CC_MD5_Update(&md5_ctx, [filedata bytes], (CC_LONG)[filedata length]);
    }
    while([filedata length]);
	
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5_ctx);
    [handle closeFile];
    NSMutableString *hash = [NSMutableString string];
    for(int i=0;i<CC_MD5_DIGEST_LENGTH;i++){
        [hash appendFormat:@"%02x",result[i]];
    }
    return [hash lowercaseString];
    
    /*
     NSData *filedata = [NSData dataWithContentsOfFile:path];  //zhu
     
     //char buffer[512];
     char buffer[CC_MD5_DIGEST_LENGTH*2];
     unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH*2];
     
     NSRange range;
     range.length = CC_MD5_DIGEST_LENGTH;
     range.location = 0;
     [filedata getBytes:buffer range:range];
     range.location = [filedata length] - CC_MD5_DIGEST_LENGTH;
     [filedata getBytes:(buffer+CC_MD5_DIGEST_LENGTH) range:range];
     
     CC_MD5(buffer, (CC_LONG)(CC_MD5_DIGEST_LENGTH*2), outputBuffer);
     
     NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH*2] ;
     
     //for(NSInteger count = 0; count < 512; count++){
     for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
     [outputString appendFormat:@"%02x",outputBuffer[count]];
     }
     
     return [outputString autorelease];
     
     */
}

-(NSString*)getFileMD5WithPath:(NSString*)path
{
    //利用文件流，算大文件的MD5值(程序不会导致内存崩溃)
    return FileMD5HashCreateWithPath(path,FileHashDefaultChunkSizeForReadingData);
}

NSString* FileMD5HashCreateWithPath(NSString* filePath,
                                    size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    //CFStringRef result = NULL;
    NSMutableString *result=nil;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    
    CC_MD5_CTX hashObject;
    bool hasMoreData = true;
    bool didSucceed;
    
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1)break;
        if (readBytesCount == 0) {
            hasMoreData =false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    //    char hash[22 *sizeof(digest) + 1];
    //    for (size_t i =0; i < sizeof(digest); ++i) {
    //        snprintf(hash + (22 * i),3, "%02x", (int)(digest[i]));
    //    }
    //
    //    //这里 运行的result 返回不对
    //    result = CFStringCreateWithCString(kCFAllocatorDefault,
    //                                       (const char *)hash,
    //                                       kCFStringEncodingUTF8);
    
    result = [NSMutableString string];
    for(int i=0;i<CC_MD5_DIGEST_LENGTH;i++){
        [result appendFormat:@"%02x",digest[i]];
    }
    
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}


-(NSString*)fileCRC:(NSString*)path
{
    NSData *buf=[[NSData alloc] initWithContentsOfFile:path];
    
    uLong crc=crc32(0L,Z_NULL,0);
    crc=crc32(crc, [buf bytes] , (uInt)[buf length]);
    
    NSString *strResult=[NSString stringWithFormat:@"%lu",crc];
    
    return strResult;
}
-(NSString*)dataCRC:(NSData*)data1
{
    NSData *buf=[[NSData alloc] initWithData:data1];
    
    uLong crc=crc32(0L,Z_NULL,0);
    crc=crc32(crc, [buf bytes] , (uInt)[buf length]);
    
    NSString *strResult=[NSString stringWithFormat:@"%lu",crc];
    
    return strResult;
}

-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName
{
    //根据名称，返回绝对路径
    NSString *ret=nil;
    NSRange r1=[fileName rangeOfString:@"."];
    if (r1.location != NSNotFound )
    {
        NSString *name=[fileName substringToIndex:r1.location];
        NSString *fileExt=[fileName pathExtension];
        ret = [[NSBundle mainBundle] pathForResource:name ofType:fileExt];
    }
    
    return ret;
    
}
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName InDirectory:(NSString*)inDirectory
{
    //根据名称，返回绝对路径
    NSString *ret=nil;
    NSRange r1=[fileName rangeOfString:@"."];
    if (r1.location != NSNotFound )
    {
        NSString *name=[fileName substringToIndex:r1.location];
        NSString *fileExt=[fileName pathExtension];
        ret = [[NSBundle mainBundle] pathForResource:name ofType:fileExt inDirectory:inDirectory];
    }
    return ret;
    
}


-(NSURL*)fileToURL:(NSString*)fileName
{
    NSArray *fileComponent=[fileName componentsSeparatedByString:@"."];    
    NSString *filePath=[[NSBundle mainBundle] pathForResource:[fileComponent objectAtIndex:0] ofType:[fileComponent objectAtIndex:1]];
    return [NSURL fileURLWithPath:filePath];
}
-(NSInteger)fileEncoding:(NSString*)fileFullPath
{
    //测试ok
    //内容编码格式 { ansi=0 , unicode=1 , utf8=2}
    NSInteger iResult=0;
    
    FILE *file1=fopen([fileFullPath UTF8String], "r");
    char read1[10];
    memset(read1, 0, 10);
    
    if (file1)
    {
        while (fgets(read1, 10, file1))
        {
            break;         }
        
        //判断
        if (read1[0] == '\xef' && read1[1] == '\xbb' && read1[2] == '\xbf')
        {
            iResult=2;
        }
        else if(read1[0] == '\xff' && read1[1] == '\xfe')
        {
            iResult=1;
        }
        fclose(file1);
    }

    
    return iResult;
}
-(NSString*)fileContent:(NSString*)fileFullPath
{
    //得到内容
    NSString *strContent=nil;
    if ( ! [self isFileExist:fileFullPath] )
    {
        return strContent;
    }
    NSInteger fileEncoding=[self fileEncoding:fileFullPath];
    NSData *fileData=[[NSData alloc] initWithContentsOfFile:fileFullPath];
    if (fileEncoding == 2)
    {
        //utf8       “window 记事本另存 utf8”
        strContent=[[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    }
    else if (fileEncoding == 1)
    {
        //unicode    “window 记事本另存 unicode”
        strContent=[[NSString alloc] initWithData:fileData encoding:NSUTF16StringEncoding];
    }
    else
    {
        //ansi       “window 记事本另存 ansi”
        NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        strContent = [[NSString alloc] initWithData:fileData encoding:enc];
    }
    
    return strContent;
}
-(NSData*)fileContentData:(NSString*)fileFullPath
{
    //得到内容 nsdata
    if ( ! [self isFileExist:fileFullPath] )
    {
        return nil;
    }
    NSData *fileData=[[NSData alloc] initWithContentsOfFile:fileFullPath];
    
    return fileData;
}
-(int)fileAppendData:(NSData*)appendData FileFullPath:(NSString*)fileFullPath
{
    //文件内容追加
    int iResult=0;
    if ([appendData length] < 1 || [fileFullPath length] <2)
    {
        return iResult;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:fileFullPath]){
        [fileManager createFileAtPath:fileFullPath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle=[NSFileHandle fileHandleForWritingAtPath:fileFullPath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:appendData];
        
        iResult=1;
    }
    [fileHandle closeFile];
    
    
    return iResult;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

-(NSString*)getNowString
{
    NSDate *today = [NSDate date];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    
    //[dateFormatter setAMSymbol:@"AM"];
    //[dateFormatter setPMSymbol:@"PM"];
    //[dateFormatter setDateFormat:@"dd/MM/yyyy hh:mmaaa"];
    [dateFormatter setAMSymbol:@"上午"];
    [dateFormatter setPMSymbol:@"下午"];
    [dateFormatter setDateFormat:@"yyyy / MM / dd aah:mm:ss"];  //2013 / 01 / 04 上午 11:10:08
    
    NSString *strNow=[dateFormatter stringFromDate:today];
    
    return strNow;
}
-(NSString*)getTimeIntervalStringFromNow:(NSTimeInterval)interval
{
    //从当前时间 加减 秒数 , 返回毫秒数
    NSDate *now=[NSDate date];
    
    NSDate *date1=[NSDate dateWithTimeInterval:interval sinceDate:now];
    //NSDate *date1=[now initWithTimeIntervalSinceReferenceDate:interval];
    NSTimeInterval val=[date1 timeIntervalSince1970];
    NSString *ret=[NSString stringWithFormat:@"%.00f",val*1000.0f]; //时间戳签名。为从1970-1-1 0:0:0 GMT至今的毫秒数。目前和授权服务器允许有10分钟的误差
    return ret;
}
-(NSString*)getNowTimeIntervalString
{
    //返回当前时间 毫秒数
    NSDate *now=[NSDate date];
    NSTimeInterval val=[now timeIntervalSince1970];
    NSString *ret=[NSString stringWithFormat:@"%.00f",val*1000.0f]; //时间戳签名。为从1970-1-1 0:0:0 GMT至今的毫秒数。目前和授权服务器允许有10分钟的误差
    return ret;
    

}

-(NSString*)getDateStringFromTimeInterval:(NSString*)strTimeInterval
{
    //根据毫秒数  得到当前时间
    long long  d1=[strTimeInterval longLongValue];  //毫秒
    //NSTimeInterval ti=(d1/1000.0f); // 得到错误的结果
    NSTimeInterval ti=d1/1000; // 正确
    if (ti <= 0)
        return @"N/A";
    NSDate *date1= [NSDate dateWithTimeIntervalSince1970:ti];
    //NSLog(@"getDateStringFromTimeInterval = %@ from %f and %lld",date1,ti,d1);
    return [self NSDateToNSString:date1];
}
-(NSDate*)getDateFromTimeInterval:(NSString*)strTimeInterval
{
    long long  d1=[strTimeInterval longLongValue];  //毫秒
    //NSTimeInterval ti=(d1/1000.0f); // 得到错误的结果
    NSTimeInterval ti=d1/1000; // 正确
    if (ti <= 0)
        return nil;
    NSDate *date1= [NSDate dateWithTimeIntervalSince1970:ti];
    return date1;
}
- (NSDate *)getNowDateFromatAnDate:(NSDate *)anyDate
{
    //设置源日期时区
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];//或GMT

    //设置转换后的目标日期时区
    NSTimeZone* destinationTimeZone = [NSTimeZone localTimeZone];
    
    //得到源日期与世界标准时间的偏移量
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:anyDate];
    
    //目标日期与本地时区的偏移量
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:anyDate];
    
    //得到时间偏移量的差值
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    //转为现在时间
    NSDate* destinationDateNow = [[NSDate alloc] initWithTimeInterval:interval sinceDate:anyDate];
    
    return destinationDateNow;
}
-(NSDate *)localDateToGMTDate:(NSDate *)localDate
{
    //本地时区 转 GMT 时区
    
    //设置源日期时区
    NSTimeZone* sourceTimeZone = [NSTimeZone localTimeZone];
    
    //设置转换后的目标日期时区
    NSTimeZone* destinationTimeZone =[NSTimeZone timeZoneWithAbbreviation:@"GMT"];//或GMT;
    
    //得到源日期与世界标准时间的偏移量
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:localDate];
    
    //目标日期与本地时区的偏移量
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:localDate];
    
    //得到时间偏移量的差值
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    //转为现在时间
    NSDate* ret = [[NSDate alloc] initWithTimeInterval:interval sinceDate:localDate] ;
    
    return ret;
}

-(NSDate *)localDateToUTCDate:(NSDate *)localDate
{
    //本地时区 转 UTC 时区
    //设置源日期时区
    NSTimeZone* sourceTimeZone = [NSTimeZone localTimeZone];
    
    //设置转换后的目标日期时区
    NSTimeZone* destinationTimeZone =[NSTimeZone timeZoneWithAbbreviation:@"UTC"];//或GMT;
    
    //得到源日期与世界标准时间的偏移量
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:localDate];
    
    //目标日期与本地时区的偏移量
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:localDate];
    
    //得到时间偏移量的差值
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    //转为现在时间
    NSDate* ret = [[NSDate alloc] initWithTimeInterval:interval sinceDate:localDate] ;
    
    return ret;
}

- (NSDate *)stringToDate:(NSString *)strdate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *retdate = [dateFormatter dateFromString:strdate];
    
    
    return retdate;    
}

//NSDate 2 NSString
- (NSString *)dateToString:(NSDate *)date
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    return strDate;
    
}


-(NSString *)getUTCFormateLocalDate:(NSString *)localDate
{
    
    //将本地日期字符串转为UTC日期字符串
    //本地日期格式:2013-08-03 12:53:51
    //可自行指定输入输出格式
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //输入格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *dateFormatted = [dateFormatter dateFromString:localDate];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    //输出格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *dateString = [dateFormatter stringFromDate:dateFormatted];
    
    return dateString;
}

-(NSString *)getLocalDateFormateUTCDate:(NSString *)utcDate
{
    
    //将UTC日期字符串转为本地时间字符串
    //输入的UTC日期格式2013-08-03T04:53:51+0000
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //输入格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    [dateFormatter setTimeZone:localTimeZone];
    
    NSDate *dateFormatted = [dateFormatter dateFromString:utcDate];
    //输出格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:dateFormatted];
    
    return dateString;
}
-(NSString *)getUTCFormatDate:(NSDate *)localDate
{    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    [dateFormatter setTimeZone:timeZone];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSString *dateString = [dateFormatter stringFromDate:localDate];
    
    
    return dateString;
    
}

-(NSDate *)getLocalFromUTC:(NSString *)utc
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    
    [dateFormatter setTimeZone:timeZone];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    NSDate *ldate = [dateFormatter dateFromString:utc];
    
    
    return ldate;
    
}

-(NSDate*)NSStringToNSDate:(NSString*)strDate
{
    //字符串转日期
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setAMSymbol:@"AM"];
    //[dateFormatter setPMSymbol:@"PM"];
    //[dateFormatter setDateFormat:@"dd/MM/yyyy hh:mmaaa"];
    
    [dateFormatter setAMSymbol:@"上午"];
    [dateFormatter setPMSymbol:@"下午"];
    [dateFormatter setDateFormat:@"yyyy / MM / dd aah:mm:ss"];  //2013 / 01 / 04 上午11:10:08
    
    NSDate *Date1 = [dateFormatter dateFromString:strDate];
    
    return Date1;
}

-(NSString*)NSDateToNSString:(NSDate*)data1
{
    //日期转字符串
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    
    //zhu edit 20130104
    //[dateFormatter setAMSymbol:@"AM"];
    //[dateFormatter setPMSymbol:@"PM"];
    //[dateFormatter setDateFormat:@"dd/MM/yyyy hh:mmaaa"];
    [dateFormatter setAMSymbol:@"上午"];
    [dateFormatter setPMSymbol:@"下午"];
    [dateFormatter setDateFormat:@"yyyy / MM / dd aah:mm:ss"];  //2013 / 01 / 04 上午 11:10:08
    
    NSString *strDate=[dateFormatter stringFromDate:data1];
    
    return strDate;
}
-(NSDate*)NSDateFromNSString:(NSString*)strDate WithFormatString:(NSString*)formatString
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatString];    
    NSDate *Date1 = [dateFormatter dateFromString:strDate];
    
    return Date1;
}
-(NSString*)NSStringFromNSDate:(NSDate*)data1 WithFormatString:(NSString*)formatString
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatString];    
    NSString *strDate=[dateFormatter stringFromDate:data1];
    
    return strDate;
}

-(NSString*)longToHexSring:(long long)long1
{
    //  long  转  hex 字符串
    NSNumber *number;
    NSString *hexString;
    
    number = [NSNumber numberWithLongLong:long1];
    hexString = [NSString stringWithFormat:@"%qx", [number longLongValue]];
    
    return hexString;
    //NSLog(@"hexString = %@", hexString);
}
-(long long)hexStringToLong:(NSString*)hexStr1
{
    //NSString* pString = @"ffffb382ddfe";
    //NSScanner* pScanner = [NSScanner scannerWithString: pString];
    NSScanner* pScanner = [NSScanner scannerWithString: hexStr1];
    
    unsigned long long long1;
    [pScanner scanHexLongLong: &long1];
    
    return long1;
    //NSLog(@"iValue2 = %lld", long1);
}
-(NSData *)toJSONData:(id)theData
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData options:NSJSONWritingPrettyPrinted error:&error];
    
    if ([jsonData length] > 0 && error == nil){
        return jsonData;
    }else{
        return nil;
    }
}
-(NSString*)UIColorToNSString:(UIColor*)color
{
    // uicolor rgba 转 string 
    const CGFloat* components = CGColorGetComponents([color CGColor]);
    int r=components[0]*255;
    int g=components[1]*255;
    int b=components[2]*255;
    int a=components[3]*255;
    NSString *strColor=[NSString stringWithFormat:@"%02X%02X%02X%02X",a,r, g, b];

    return strColor;
}
-(UIColor*)NSStringToUIColor:(NSString*)strColor
{
    // string 转 uicolor rgba
    if ([strColor length] != 8)
    {
        return [UIColor clearColor];
    }
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //a
    NSString *aString = [strColor substringWithRange:range];
    if ([aString isEqualToString:@"00"]) {
        aString=@"ff";
    }
    //r
    range.location = 2;
    NSString *rString = [strColor substringWithRange:range];
    
    //g
    range.location = 4;
    NSString *gString = [strColor substringWithRange:range];
    
    //b
    range.location = 6;
    NSString *bString = [strColor substringWithRange:range];
    
    unsigned int r, g, b,a;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:aString] scanHexInt:&a];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:((float) a / 255.0f)];
}

-(UIColor*)UIColorFromRGBString:(NSString*)strRGB
{
    UIColor *ret=nil;
    
    NSString *rgb=[strRGB stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSString *rgba=nil;
    if ([rgb length] == 6) {
        rgba=[NSString stringWithFormat:@"ff%@",rgb];
    }
    else if ([rgb length] == 8)
    {
        rgba=rgb;
    }
    
    if (rgba) {
        ret=[self NSStringToUIColor:rgba];
    }
    
    return ret;
}

-(NSString *)md5:(NSString *)str
{
    //    NSString *string = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), (unsigned char*)result );
    NSMutableString *hash = [NSMutableString string];
    for(int i=0;i<CC_MD5_DIGEST_LENGTH;i++)
    {
        [hash appendFormat:@"%02X",result[i]];
    }
    return [hash lowercaseString];
}

-(NSString*)trimWhiteSpace:(NSString*)strContent
{
    //去除空格
    return [strContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
-(NSString*)trimWhiteSpaceAndNewLine:(NSString*)strContent
{
    //去除空格和换行
    return [strContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
-(NSString *)replaceUnicodeString:(NSString *)unicodeStr
{
    //网络编程。从服务器获得的数据一般是Unicode格式字符串，要正确显示需要转换成中文编码
    // NSString值为Unicode格式的字符串编码(如\u7E8C)转换成中文
    //unicode编码以\u开头
    
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListFromData:tempData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}
-(NSComparisonResult)compareCNStr:(NSString*)first1 Second:(NSString*)second2
{
    //比较带中文字符串   
    NSLocale *lc=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_hans"];
    long len=([first1 length]> [second2 length])?[first1 length]:[second2 length];
    NSComparisonResult result = [first1 compare:second2 options:NSCaseInsensitiveSearch range:NSMakeRange(0, len) locale:lc];
    
    return result;
}

- (NSString *)pinyinWithCNStr:(NSString *)chinese {
    //汉字-->拼音 多音字不支持
    NSMutableString *pinyin = [chinese mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    return [pinyin uppercaseString];
}

-(NSString*)stringCNKIEncryptWithGTMBase64:(NSString*)strSource
{
    //加密  ok  安全
    //密钥  ok
    NSString *encryptKey=@"jds)(#&dsa7SDNJ32hwbds%u32j33edjdu2@**@3w";
    char* szKey = (char*)[encryptKey UTF8String];
    int nKeyLength =(int)strlen(szKey);
    //明文密码
    char* szPassword = (char*)[strSource UTF8String];
    int nLength=(int)strlen(szPassword);
    
    //加密后的明文密码
    Byte *pEncryptPassword=(Byte*)malloc(nLength+1);
    memset(pEncryptPassword, 0, nLength+1);
    
    for (int i=0; i<nLength ; ++i)
    {
        int j = i;
        while(j >= nKeyLength)
			j -= nKeyLength;
        pEncryptPassword[i] = szPassword[i] ^ szKey[j];
    }
    
    NSData *data=[NSData dataWithBytes:pEncryptPassword length:nLength];
    
    data = [CNKI_Z_GTMBase64 encodeData:data];
    NSString *strResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    free(pEncryptPassword);
    
    return strResult ;
}
-(NSString*)stringCNKIDecryptWithGTMBase64:(NSString*)strEncryptSource
{
    //解密   ok  安全
    
    //密钥
    NSString *encryptKey=@"jds)(#&dsa7SDNJ32hwbds%u32j33edjdu2@**@3w";
    char* szKey = (char*)[encryptKey UTF8String];
    int nKeyLength = (int)strlen(szKey);
    
    //base还原
    NSData *data = [strEncryptSource dataUsingEncoding:NSUTF8StringEncoding];
    data = [CNKI_Z_GTMBase64 decodeData:data];

    
    //加密后的明文密码
    char *szEncrptPassword=(char*)[data bytes];
    //int nLength = strlen(szEncrptPassword); //不能用strlen， 因为字符中间可能有 '\0'
    int nLength =(int)[data length];
    //明文密码
    char *szPassword =malloc(nLength+1);
    memset(szPassword,0,nLength+1);
    
    for (int i=0; i<nLength; ++i)
    {
        int j=i;
        while(j >= nKeyLength)
			j -= nKeyLength;
		szPassword[i] = szEncrptPassword[i] ^ szKey[j];
    }
    
    NSString *strResult=[[NSString alloc] initWithUTF8String:szPassword];
    
    //释放
    free(szPassword);    

    
    return strResult;
}
-(NSString*)stringCNKIEncrypt:(NSString*)strSource
{
    //加密  ok  注意 －－ 不安全
    //注意
    //这个方法存在隐患， 如"test" 加密后 的四个字符， 其中第三个是 '\0' ,导致返回的结果不正确，解密后只得到 "te"
    
    //    ---- 字符串  和  秘钥字符串  进行亦或
  
    //密钥
    NSString *encryptKey=@"jds)(#&dsa7SDNJ32hwbds%u32j33edjdu2@**@3w";
    char* szKey = (char*)[encryptKey UTF8String];
    int nKeyLength = (int)strlen(szKey);
    //明文密码
    char* szPassword = (char*)[strSource UTF8String];
    int nLength=(int)strlen(szPassword);
    
    //加密后的明文密码
    char *pEncryptPassword=malloc(nLength+1);
    memset(pEncryptPassword, 0, nLength+1);
    
    for (int i=0; i<nLength ; ++i)
    {
        int j = i;
        while(j >= nKeyLength)
			j -= nKeyLength;
        pEncryptPassword[i] = szPassword[i] ^ szKey[j];
    }

    NSString *strResult=[[NSString alloc] initWithUTF8String:pEncryptPassword]; 
    free(pEncryptPassword);
    
    return strResult;

}
-(NSString*)stringCNKIDecrypt:(NSString*)strEncryptSource
{
    //解密 ok  注意 －－ 不安全
    //密钥
    NSString *encryptKey=@"jds)(#&dsa7SDNJ32hwbds%u32j33edjdu2@**@3w";
    char* szKey = (char*)[encryptKey UTF8String];
    int nKeyLength = (int)strlen(szKey);
    
    //加密后的明文密码
    char *szEncrptPassword=(char*)[strEncryptSource UTF8String];
    int nLength = (int)strlen(szEncrptPassword);
    
    //明文密码
    char *szPassword =malloc(nLength+1);
    memset(szPassword,0,nLength+1);
    
    for (int i=0; i<nLength; ++i)
    {
        int j=i;
        while(j >= nKeyLength)
			j -= nKeyLength;
		szPassword[i] = szEncrptPassword[i] ^ szKey[j];
    }

    NSString *strResult=[[NSString alloc] initWithUTF8String:szPassword]; 
    free(szPassword);
    
    return strResult;
}
-(NSString*)stringGTMBase64encode:(NSString*)strSource
{
    //加密   ok
    //NSData *data = [strSource dataUsingEncoding:NSUnicodeStringEncoding];
    //NSData *data = [strSource dataUsingEncoding:NSASCIIStringEncoding]; //返回nil
    NSData *data = [strSource dataUsingEncoding:NSUTF8StringEncoding];
    
    data = [CNKI_Z_GTMBase64 encodeData:data];
    
    NSString *strResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSString *strResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];  //ok   NSUTF8StringEncoding
    return strResult;
}
-(NSString*)stringGTMBase64decode:(NSString*)strSourceEncode
{
    //解密  ok
    NSData *data =[CNKI_Z_GTMBase64 decodeString:strSourceEncode];
    
//    NSData *data = [strSourceEncode dataUsingEncoding:NSUnicodeStringEncoding];
//    data = [GTMBase64 decodeData:data];
    NSString *strResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return strResult;
}

/******************************************************************************
 函数名称 : + (NSData *)dataWithBase64EncodedString:(NSString *)string
 函数描述 : base64格式字符串转换为文本数据
 输入参数 : (NSString *)string
 输出参数 : N/A
 返回参数 : (NSData *)
 备注信息 :
 ******************************************************************************/
-(NSData *)dataWithBase64EncodedString:(NSString *)string WithEncodeList:(NSString*)encodeList
{
    const char *encodingTable=NULL;
    NSString *encodeListDefault=@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    if ([encodeList length]>1)
    {
        encodingTable= [encodeList UTF8String];
    }
    else
    {
        encodingTable= [encodeListDefault UTF8String];
    }
    //char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    
    if (string == nil)
        [NSException raise:NSInvalidArgumentException format:nil];
    if ([string length] == 0)
        return [NSData data];
    
    static char *decodingTable = NULL;
    if (decodingTable == NULL)
    {
        decodingTable = malloc(256);
        if (decodingTable == NULL)
            return nil;
        memset(decodingTable, CHAR_MAX, 256);
        NSUInteger i;
        for (i = 0; i < 64; i++)
            decodingTable[(short)encodingTable[i]] = i;
    }
    
    const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL)     //  Not an ASCII string!
        return nil;
    char *bytes = malloc((([string length] + 3) / 4) * 3);
    if (bytes == NULL)
        return nil;
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (YES)
    {
        char buffer[4];
        short bufferLength;
        for (bufferLength = 0; bufferLength < 4; i++)
        {
            if (characters[i] == '\0')
                break;
            if (isspace(characters[i]) || characters[i] == '=')
                continue;
            buffer[bufferLength] = decodingTable[(short)characters[i]];
            if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
            {
                free(bytes);
                return nil;
            }
        }
        
        if (bufferLength == 0)
            break;
        if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
        {
            free(bytes);
            return nil;
        }
        
        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2)
            bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
        if (bufferLength > 3)
            bytes[length++] = (buffer[2] << 6) | buffer[3];
    }
    
    bytes = realloc(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length];
}
/******************************************************************************
 函数名称 : + (NSString *)base64EncodedStringFrom:(NSData *)data
 函数描述 : 文本数据转换为base64格式字符串
 输入参数 : (NSData *)data
 输出参数 : N/A
 返回参数 : (NSString *)
 备注信息 :
 ******************************************************************************/
-(NSString *)base64EncodedStringFrom:(NSData *)data WithEncodeList:(NSString*)encodeList
{
    const char *encodingTable=NULL;
    NSString *encodeListDefault=@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    if ([encodeList length]>1)
    {
        encodingTable= [encodeList UTF8String];
    }
    else
    {
        encodingTable= [encodeListDefault UTF8String];
    }
    //char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    if ([data length] == 0)
        return @"";
    
    char *characters = malloc((([data length] + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (i < [data length])
    {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        while (bufferLength < 3 && i < [data length])
            buffer[bufferLength++] = ((char *)[data bytes])[i++];
        
        //  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
        characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
        characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        if (bufferLength > 1)
            characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        else characters[length++] = '=';
        if (bufferLength > 2)
            characters[length++] = encodingTable[buffer[2] & 0x3F];
        else characters[length++] = '=';
    }
    
    return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}
-(NSString *)base64StringFromString:(NSString *)text WithEncodeList:(NSString*)encodeList
{
    if (text && ![text isEqualToString:@""]) {
        //取项目的bundleIdentifier作为KEY  改动了此处
        //NSString *key = [[NSBundle mainBundle] bundleIdentifier];
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        //IOS 自带DES加密 Begin  改动了此处
        //data = [self DESEncrypt:data WithKey:key];
        //IOS 自带DES加密 End
        return [self base64EncodedStringFrom:data WithEncodeList:encodeList];
    }
    else
    {
        return @"";
    }
}

-(NSString *)stringFromBase64String:(NSString *)base64 WithEncodeList:(NSString*)encodeList
{
    if (base64 && ![base64 isEqualToString:@""]) {
        //取项目的bundleIdentifier作为KEY   改动了此处
        //NSString *key = [[NSBundle mainBundle] bundleIdentifier];
        NSData *data = [self dataWithBase64EncodedString:base64 WithEncodeList:encodeList];
        //IOS 自带DES解密 Begin    改动了此处
        //data = [self DESDecrypt:data WithKey:key];
        //IOS 自带DES加密 End
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    else
    {
        return @"";
    }
}

/******************************************************************************
 函数名称 : + (NSData *)DESEncrypt:(NSData *)data WithKey:(NSString *)key
 函数描述 : 文本数据进行DES加密
 输入参数 : (NSData *)data
 (NSString *)key
 输出参数 : N/A
 返回参数 : (NSData *)
 备注信息 : 此函数不可用于过长文本
 ******************************************************************************/
-(NSData *)DESEncrypt:(NSData *)data WithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeDES,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

/******************************************************************************
 函数名称 : + (NSData *)DESEncrypt:(NSData *)data WithKey:(NSString *)key
 函数描述 : 文本数据进行DES解密
 输入参数 : (NSData *)data
 (NSString *)key
 输出参数 : N/A
 返回参数 : (NSData *)
 备注信息 : 此函数不可用于过长文本
 ******************************************************************************/
-(NSData *)DESDecrypt:(NSData *)data WithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeDES,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return nil;
}
-(NSString *)AES128Encrypt:(NSString *)plainText withKey:(NSString*)gkey withgIv:(NSString*)gIv
{
    char keyPtr[kCCKeySizeAES128+1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [gkey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    
    [gIv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSData* data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    
    int diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    int newSize = 0;
    
    if(diff > 0)
    {
        newSize = (int)dataLength + diff;
    }
    
    char dataPtr[newSize];
    memcpy(dataPtr, [data bytes], [data length]);
    for(int i = 0; i < diff; i++)
    {
        dataPtr[i + dataLength] = 0x00;
    }
    
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    memset(buffer, 0, bufferSize);
    
    size_t numBytesCrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,               //No padding
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          dataPtr,
                                          sizeof(dataPtr),
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        
        return [CNKI_Z_GTMBase64 stringByEncodingData:resultData];
    }
    free(buffer);
    return nil;
}

-(NSString *)AES128Decrypt:(NSString *)encryptText withKey:(NSString*)gkey withgIv:(NSString*)gIv
{
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [gkey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    memset(ivPtr, 0, sizeof(ivPtr));

    [gIv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSData *data = [CNKI_Z_GTMBase64 decodeData:[encryptText dataUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return nil;
}
-(NSString*)getWebViewInnerHtml: (UIWebView *) webView
{
    //返回webView实际加载的网址
    if( ! webView ){
        return nil;
    }
    return [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
}

-(BOOL)mySystemVersionCreaterThanOrEqualTo:(NSString*)compareVersion
{
    BOOL bRet=[[[UIDevice currentDevice] systemVersion] compare:compareVersion options:NSNumericSearch] != NSOrderedAscending ;
    return bRet;
}

-(void)setWindowToucheEnable:(BOOL)bEnable
{
    //是否接受输入
    UIApplication *app=[UIApplication sharedApplication];
    if (bEnable)
    {
        //恢复接受输入      
        if ([app isIgnoringInteractionEvents])
        {
            [app endIgnoringInteractionEvents];
        }
    }
    else
    {
        //不接受输入
        if (! [app isIgnoringInteractionEvents] )
        {
            [app beginIgnoringInteractionEvents];
        }        
    }
}

-(NSMutableDictionary*)ParseURLParams:(NSString*)url
{
    //分析url
    NSURL *urla = [NSURL URLWithString:url];
    NSString *paramstring = [urla query];
    NSArray *params = [paramstring componentsSeparatedByString:@"&"];
    __block NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [params enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeOfString:@"="];
        if (range.length > 0)
        {
            [dict setObject:[obj substringFromIndex:range.location+1] forKey:[obj substringToIndex:range.location]];
        }
    }];
    return dict;
}

-(NSDictionary*)getWeatherFromURLString:(NSString*)strUrl
{
    //使用IOS5自带解析类NSJSONSerialization方法解析：（无需导入包，IOS5支持，低版本IOS不支持）
    // url返回 用的是同步，需要放入子线程中运行
    /*国家气象局提供的天气预报接口
    
    接口地址有三个：    
     http://www.weather.com.cn/data/sk/101010100.html  //ok  
     http://www.weather.com.cn/data/cityinfo/101010100.html   // ok
     http://m.weather.com.cn/data/101010100.html  //ok
    
     101010100  指北京
     通过
     http://blog.csdn.net/duxinfeng2010/article/details/7830136
     查询其他城市代码
     */
    
    //根据url 得到天气    
    
    //加载一个NSURL对象
    NSURLRequest *request=nil;
    if ([strUrl length]<4) {
        request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.weather.com.cn/data/101010100.html"]];
    }
    else
    {
        request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    }
    
    //将请求的url数据放到NSData对象中
    NSError *error;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
    NSDictionary *weatherDic = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
    
    NSDictionary *weatherInfo=nil;
    if (weatherDic) {
        weatherInfo = [weatherDic objectForKey:@"weatherinfo"];
    }
    
//    if (weatherInfo) {
//        strResult = [NSString stringWithFormat:@"今天是 %@  %@  %@  的天气状况是：%@  %@ ",[weatherInfo objectForKey:@"date_y"],[weatherInfo objectForKey:@"week"],[weatherInfo objectForKey:@"city"], [weatherInfo objectForKey:@"weather1"], [weatherInfo objectForKey:@"temp1"]];
//    }    
    
    return weatherInfo;
}
-(NSString*)getURLContent:(NSString*)strURL
{
    //线程
    //得到简单网址返回的 字串
    NSString *ret=nil;
    ret=[NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
    
    return ret;
}
-(NSData*)getDataWithURL:(NSString*)strURL
{
    //线程
    //得到简单网址返回的 流  ，可以下载文件的流， 到时候自己再保存data
    NSData *ret=nil;
    ret=[NSData dataWithContentsOfURL:[NSURL URLWithString:strURL]];
    return  ret;
}
-(NSURL *)appStoreURLforApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"http://itunes.apple.com/cn/app/id%@?mt=8", identifier];
	
	return [NSURL URLWithString:link];
}

-(NSURL *)appStoreReviewURLForApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", identifier];
	return [NSURL URLWithString:link];
}
-(NSDictionary*)getAppVersionWithAppid:(NSString*)identifier
{
    //根据AppID，得到appStore的版本
    NSString *kAppdateUrl = @"http://itunes.apple.com/lookup";
    NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"%@?id=%@", kAppdateUrl, identifier]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    

    //这个会阻碍 主线程, 即使在子线程运行，也阻碍主线程
    //[NSOperationQueue mainQueue] ok
    //[NSOperationQueue currentQueue] fail  很奇怪，可能和线程结束有关
    
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//        sleep(10);
//        NSDictionary *dictAppVersion = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//        NSLog(@"dictAppVersion=%@",dictAppVersion);
//    }];
    
    NSDictionary *dictAppVersion=nil;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
    if (data)
    {
        dictAppVersion = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    }    
    
    return dictAppVersion;
}

-(long long)deviceFreeSpace
{
    //得到设备空闲空间大小
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/", &buf) >= 0){
        freespace = (long long)buf.f_bsize * buf.f_bfree;
    }
    
    return freespace;
}
-(CGFloat)deviceTotalDiskSpace
{
    //得到设备空间大小
    //InBytes
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    struct statfs tStats;
    statfs([[paths lastObject] cString], &tStats);
    float totalSpace = (float)(tStats.f_blocks * tStats.f_bsize);
    
    return totalSpace;
}
-(int)openURLWithString:(NSString*)strURL
{
    //
    int iResult=0;
    
    UIApplication *app= [UIApplication sharedApplication];
    
    NSString *str1=[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    if ([app canOpenURL:url])
    {
        [app openURL:url];
        iResult=1;
    }    
    
    return iResult;
}
-(id)doHttpSQLRequestWithGet:(NSString*)httpURL AddRequestHeaders:(NSMutableDictionary*)requestHeaders WithGZIP:(NSInteger)iGzip WithReturnType:(NSInteger)iReturnType
{
    //Get 方式请求
    //iReturnType ---  0 NSData , 1 NSString
    //注意， 返回的结果， 要小心开头和结尾会多出个引号
    id ret=nil;
    NSString *str1=[httpURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    {
        NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
        if (iGzip)
        {
            [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        }
        
        if (requestHeaders)
        {
            for (NSString *key in [requestHeaders allKeys])
            {
                NSString *val=[requestHeaders objectForKey:key];
                if ([key isEqualToString:@"bearer"])
                {
                    NSString* strVal=[NSString stringWithFormat:@"Bearer %@",val];
                    [request setValue:strVal forHTTPHeaderField:@"Authorization"];
                }
                else
                {
                    [request setValue:val forHTTPHeaderField:key];
                }
                
            }
        }

        //[request setHTTPMethod:@"POST"];
        //[request setHTTPBody:data1];
        
        NSHTTPURLResponse* urlResponse = nil;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];

        if (!error && responseData)
        {
            if (iReturnType == 1)
            {
                
                ret= [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
            }
            else
            {
                ret=responseData;
            }
        }
        else
        {
#ifdef DEBUG
            NSLog(@"doHttpSQLRequestWithGet 失败\n请求httpURL=%@\n错误error=%@\n",httpURL,error);
#endif
        }
        
    }
    
    return ret;

}
-(id)doHttpRequest:(NSString*)strHttpSQL ReturnType:(NSInteger)type
{
    id ret=nil;
    NSString *str1=[strHttpSQL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    {
        NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        //[request setHTTPMethod:@"POST"];
        //[request setHTTPBody:data1];
        
        NSHTTPURLResponse* urlResponse = nil;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        if (!error && responseData)
        {
            if (type == 1)
            {
                
                ret= [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
            }
            else
            {
                ret=responseData;
            }
        }
        
    }
    
    return ret;
}
-(id)doHttpSQLRequest:(NSString*)strHttpSQL
{
    id ret=nil;
    NSString *str1=[strHttpSQL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    {
        NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        //[request setHTTPMethod:@"POST"];
        //[request setHTTPBody:data1];
        
        NSHTTPURLResponse* urlResponse = nil;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        if (!error && responseData)
        {
            NSError *errorJSON=nil;
            ret = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&errorJSON];
            if (errorJSON)
            {
                
            }
        }
    }
    
    return ret;
}
-(id)doRequestWithPostData:(NSMutableDictionary *)para
{
    //放在线程里
    // post 流， 并返回请求数据   自定义 post 方式
    id ret=nil;
    
    NSString *strURL=[para objectForKey:@"url"];
    NSData *data1=[para objectForKey:@"data"];

    NSString *str1=[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str1];
    
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data1];
    
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    
    if (!error && responseData)
    {
        ret=responseData;
        
        //            NSString *aaa=[[NSString alloc] initWithFormat:@"%S",(const unsigned short*)[data bytes]];
        //            NSLog(@"%@",aaa);   //  返回值 ok
        //
        //            NSString *tmp1=[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF16StringEncoding];   // 返回值 ok
        //
        //            NSString *tmp2=[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF16BigEndianStringEncoding];  //  返回值 fail
        //
        //            NSString *tmp3=[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF16LittleEndianStringEncoding];   //  返回值 ok
        //
        //            ret = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
        
    }
    else
    {
#ifdef DEBUG
        NSLog(@"doRequestWithPostData 失败 , error=%@",error);
#endif
    }

    return ret;
}
-(CGFloat)ExDegreesToRadians:(CGFloat)degrees
{
    return degrees * M_PI / 180;
}

-(CGFloat)ExRadiansToDegrees:(CGFloat)radians
{
    return radians * 180/M_PI;
}

-(NSString *)getMacAddress
{
    //得到mac地址
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        if (msgBuffer)
        {
            free(msgBuffer);
            msgBuffer=NULL;
        }
        
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}
-(id)getUserDefaults:(NSString *) name
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:name];
}

-(void) setUserDefaults:(NSObject *) defaults forKey:(NSString *) key
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:defaults forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(id)Weather
{
    //最好线程
    //得到天气  一周的
    id ret=nil;
//    NSString *cityNumber=nil;
//    //解析网址通过ip 获取城市天气代码
//    NSURL *url = [NSURL URLWithString:@"http://61.4.185.48:81/g/"];
    
    
    return ret;
}
-(void)buttonAddCorner:(UIButton*)btn CornerRadius:(CGFloat)cornerRadius BorderWidth:(CGFloat)borderWidth BorderColor:(UIColor*)borderColor;
{
    //button 圆角
    CALayer *layer=btn.layer;
    layer.cornerRadius=cornerRadius;
    layer.borderWidth=borderWidth;
    layer.masksToBounds=YES;
    if (borderColor) {
        layer.borderColor=borderColor.CGColor;
    }    
}
-(void)viewAddShadow:(UIView*)theView
{
    //有效果，view里面有阴影
    CALayer *layer=theView.layer;
    layer.cornerRadius=8.0f;
    layer.borderWidth=6.0f;
    layer.masksToBounds=YES;
    layer.borderColor=[UIColor colorWithWhite:0.4f alpha:0.2].CGColor;
    
    //
    CAGradientLayer *shineLayer=[CAGradientLayer layer];
    
    shineLayer.colors=@[(id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor
                        ,(id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor
                        ,(id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor
                        ,(id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor
                        ,(id)[UIColor colorWithWhite:1.0 alpha:0.4f].CGColor];
    
    shineLayer.locations=@[[NSNumber numberWithFloat:0.0]
                           ,[NSNumber numberWithFloat:0.5f]
                           ,[NSNumber numberWithFloat:0.5f]
                           ,[NSNumber numberWithFloat:0.8f]
                           ,[NSNumber numberWithFloat:1.0f]
                           ];
    
    [theView.layer addSublayer:shineLayer];
    
}
-(void)viewAddSimpleReflection:(UIView*)theView
{
    const CGFloat kReflectPercent = -0.25f;
    const CGFloat kReflectOpacity = 0.3f;
    const CGFloat kReflectDistance = 10.0f;
    
    CALayer *reflectionLayer = [CALayer layer];
    reflectionLayer.contents = [theView layer].contents;
    reflectionLayer.opacity = kReflectOpacity;
    reflectionLayer.frame = CGRectMake(0.0f,0.0f,theView.frame.size.width,theView.frame.size.height*kReflectPercent);  //倒影层框架设置，其中高度是原视图的百分比
    CATransform3D stransform = CATransform3DMakeScale(1.0f,-1.0f,1.0f);
    CATransform3D transform = CATransform3DTranslate(stransform,0.0f,-(kReflectDistance + theView.frame.size.height),0.0f);
    reflectionLayer.transform = transform;
    reflectionLayer.sublayerTransform = reflectionLayer.transform;
    [[theView layer] addSublayer:reflectionLayer];
    
}

-(NSString*)getCountryCode
{
    //US,CN
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

-(NSString*)getLanguageCode
{
    //en,zh
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
}

-(void)checkDylibs
{
    //列出自己所链接的动态库
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0 ; i < count; ++i)
    {
        NSString *name = [[NSString alloc]initWithUTF8String:_dyld_get_image_name(i)];
        NSLog(@"--%@", name);
    }
    //越狱机的输出结果会包含字符串： Library/MobileSubstrate/MobileSubstrate.dylib
}
int code_convert(char *from_charset, char *to_charset, char *inbuf, size_t inlen, char *outbuf, size_t outlen) {
    iconv_t cd = NULL;
    
    cd = iconv_open(to_charset, from_charset);
    if(!cd)
        return -1;
    
    memset(outbuf, 0, outlen);
    if(iconv(cd, &inbuf, &inlen, &outbuf, &outlen) == -1)
        return -1;
    
    iconv_close(cd);
    return 0;
}
int u2g(char *inbuf, size_t inlen, char *outbuf, size_t outlen)
{
    return code_convert("utf-8", "gb2312", inbuf, inlen, outbuf, outlen);
}

int g2u(char *inbuf, size_t inlen, char *outbuf,size_t outlen)
{
    return code_convert("gb2312", "utf-8", inbuf, inlen, outbuf, outlen);
}
- (NSString*)getANSIString:(NSData*)ansiData
{
    NSString *string = nil;
    char *ansiString = (char*)[ansiData bytes];
    int ansiLen = (int)[ansiData length];
    int utf8Len = ansiLen*2;
    char *utf8String = (char*)malloc(utf8Len);
    memset(utf8String, 0, utf8Len);
    int result = code_convert("gb2312", "utf8", ansiString, ansiLen, utf8String, utf8Len);
    if (result == -1) {
    }
    else {
        string = [[NSString alloc] initWithUTF8String:utf8String];
    }
    free(utf8String);
    return string;
}
-(NSString*)getStringFromANSIByte:(NSData*)data1
{
    //ansi 文件读取
    NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSString *strResult = [[NSString alloc] initWithData:data1 encoding:enc];
    
    return strResult;
    
//    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
//    char*c_test = "先先先";
//    int nLen = strlen(c_test);
//    NSString* str = [[NSString alloc]initWithBytes:c_test length:nLen encoding:enc ];
//    return [str autorelease];
}

-(void)openApp
{
    // - (void)applicationDidEnterBackground:(UIApplication *)application 运行
    //后台打开程序  
    //system([[NSString stringWithFormat:@"uiopen \"%@\"", @"myapp://com.test"] UTF8String]);
}

-(NSString*)scanDecodeFromEncryption:(NSString*)strEncryption
{
    //王云飞，二维码
    //初步测试ok
    int key2=59;
    int key11=109;
    
    NSMutableString *strDecode=[[NSMutableString alloc] init];
    
    char *cSrc=(char*)[strEncryption UTF8String];
    NSInteger length=[strEncryption lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    for (int i=0;i<length; ++i)
    {
        int iPos=cSrc[i];
        iPos=key11*(iPos-key2);
        iPos=iPos%128;
        while (iPos<0) {
            iPos+=128;
        }
        [strDecode appendFormat:@"%c",iPos];
    }
    
    return strDecode;
}

-(NSMutableDictionary*)getDictionaryFromString:(NSString*)str1 WithSeparatedString:(NSString*)sep
{
    //转换
    NSMutableDictionary *dictRet=nil;
    NSArray *params=[str1 componentsSeparatedByString:sep];
    if ([params count]>0)
    {
        dictRet=[[NSMutableDictionary alloc] initWithCapacity:[params count]];
        for (NSString *one in params)
        {
            NSRange range = [one rangeOfString:@"="];
            
            if (range.location !=NSNotFound && range.length > 0)
            {
                NSString *key1=[one substringToIndex:range.location];
                NSString *value1=[one substringFromIndex:range.location+1];
                
                [dictRet setObject:[self trimWhiteSpace:value1] forKey:[self trimWhiteSpace:key1]];
            }
        }
    }
    
    return dictRet;
}
-(NSString*)getStringFromDictionary:(NSDictionary*)dict1 WithSeparatedString:(NSString*)sep
{
    //转换
    NSString *strResult=nil;
    NSMutableArray *params=[[NSMutableArray alloc] init];
    for (NSString *key1 in [dict1 allKeys])
    {
        NSString *value1=[dict1 objectForKey:key1];
        NSString *one=[[NSString alloc] initWithFormat:@"%@=%@",key1,value1];
        [params addObject:one];
    }
    
    if ([params count]>0)
    {
        strResult=[params componentsJoinedByString:sep];
    }

    return strResult;
}

-(id)sendPostRequestTo:(NSString *) targetURL withData:(NSDictionary *) postData
{
    
//    NSMutableString *sb = [[NSMutableString alloc] init];
//    for(NSString *k in [postData allKeys] ) {
//        ([sb length] != 0) ? [sb appendString:@"&"] : nil;
//        
//        [sb appendString:k];
//        [sb appendString:@"="];
//        if ([[postData objectForKey:k] isKindOfClass:[NSDictionary class]]||
//            [[postData objectForKey:k] isKindOfClass:[NSArray class] ] ) {
//            
//            SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
//            NSString *jsonString = [jsonWriter stringWithObject:[postData objectForKey:k] ];
//            if(jsonString != nil)
//                [sb appendString:[Utils urlEscapedString:jsonString] ];
//        } else {
//            [sb appendString:[Utils urlEscapedString:[postData objectForKey:k]]];
//        }
//    }
//    
//    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:targetURL]
//                                                       cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
//                                                   timeoutInterval:30];
//    [req setHTTPMethod:@"POST"];
//    [req setHTTPBody:[sb dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    NSURLResponse *resp;
//    NSError *err;
//    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
//    
//    if ((data != nil) && ([data length] != 0) ) {
//        NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
//        id dataResponse = [jsonParser objectWithString:status];
//        return dataResponse;
//    } else {
//        NSLog(@"Request failed...");
//        NSLog(@"Error : %@", [err userInfo]);
//        return nil;
//    }
    return nil;
}

- (CGFloat)heightForLabel:(NSString *)labelContent Width:(float)width Font:(UIFont *)font1
{
    // UILabel 计算高度
    CGSize sizeToFit=[labelContent sizeWithFont:font1 constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];//此处的换行类型（lineBreakMode）可根据自己的实际情况进行设置
    return sizeToFit.height;
}

- (CGFloat)heightForTextView:(NSString *)txtContent Width:(float)width Font:(UIFont *)font1
{
    //其实UITextView在上下左右分别有一个8px的padding,当使用[NSString sizeWithFont:constrainedToSize:lineBreakMode:]时，需要将UITextView.contentSize.width减去16像素（左右的padding 2 x 8px）。同时返回的高度中再加上16像素（上下的padding），这样得到的才是UITextView真正适应内容的高度。
    
    // UITextView 计算高度
    
    float fPadding=16.0f; // 8.0px x 2
    
    CGSize constraint = CGSizeMake(width - fPadding, CGFLOAT_MAX);
    
    //CGSize constraint = CGSizeMake(textView.contentSize.width - fPadding, CGFLOAT_MAX);
    
    CGSize size = [txtContent sizeWithFont:font1 constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat fHeight = size.height + fPadding;
    return fHeight;
}

#pragma mark - UIImage
- (UIImage *)imgURL:(NSString *)str {
    //获取URL图片
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]]];
}

- (UIImage *)imgColor:(UIColor *)color {
    //根据颜色生成图片
    CGFloat img_w = 3.0f;
    CGFloat img_h = 3.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(img_w, img_h), NO, 0.0f);
    [color set];
    UIRectFill(CGRectMake(0, 0, img_w, img_h));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory {
    //获取本地图片
    directory = [directory containsString:@"."]?directory:[NSString stringWithFormat:@"%@.bundle", directory];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];//NSBundle.mainBundle
    NSString *path = [[bundle pathForResource:directory ofType:nil] stringByAppendingPathComponent:name];
    return path?[UIImage imageNamed:path]:nil;
}

- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory alpha:(CGFloat)alpha {
    //获取本地图片 透明度
    return [self imgChangeAlpha:[self imgName:name directory:directory] alpha:alpha];
}

- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory color:(UIColor *)color {
    //获取本地图片 颜色
    return [self imgChangeColor:[self imgName:name directory:directory] color:color];
}

- (UIImage *)imgBarCode:(NSString *)str size:(CGSize)size {
    //生成条形码
    //注意生成条形码的编码方式
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    //设置生成的条形码的上，下，左，右的margins的值
    [filter setValue:[NSNumber numberWithInteger:0] forKey:@"inputQuietSpace"];
    CIImage *image = filter.outputImage;
    //位图
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scaleWidth = size.width/CGRectGetWidth(extent);
    CGFloat scaleHeight = size.height/CGRectGetHeight(extent);
    size_t width = CGRectGetWidth(extent) * scaleWidth;
    size_t height = CGRectGetHeight(extent) * scaleHeight;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    CGContextRef contentRef = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(contentRef, kCGInterpolationNone);
    CGContextScaleCTM(contentRef, scaleWidth, scaleHeight);
    CGContextDrawImage(contentRef, extent, imageRef);
    //保存bitmap到图片
    CGImageRef imageRefResized = CGBitmapContextCreateImage(contentRef);
    CGContextRelease(contentRef);
    CGImageRelease(imageRef);
    return [UIImage imageWithCGImage:imageRefResized];
}

- (UIImage *)imgQRCode:(NSString *)str size:(CGFloat)size {
    //生成二维码
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //内容
    [filter setValue:[str dataUsingEncoding:NSUTF8StringEncoding] forKey:@"inputMessage"];
    //纠错级别
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *image = filter.outputImage;
    //位图
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    //保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

- (UIImage *)imgChangeColor:(UIImage *)img color:(UIColor *)color {
    //改变图片颜色
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextClipToMask(context, rect, img.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imgChangeAlpha:(UIImage *)img alpha:(CGFloat)alpha {
    //改变图片透明度
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextSetAlpha(context, alpha);
    CGContextDrawImage(context, rect, img.CGImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imgAddIcon:(UIImage *)img icon:(UIImage *)icon size:(CGSize)size {
    //添加中心图标
    UIGraphicsBeginImageContext(img.size);
    [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
    [icon drawInRect:CGRectMake((img.size.width-size.width)*0.5f, (img.size.height-size.height)*0.5f, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imgAppend:(NSArray *)arr horizontal:(NSInteger)horizontal {
    //拼接图片
    CGSize size = CGSizeZero;
    for (UIImage *img in arr) {
        if (horizontal) {
            //横向
            size.width += img.size.width;
            size.height = MAX(size.height, img.size.height);
        } else {
            //纵向
            size.height += img.size.height;
            size.width = MAX(size.width, img.size.width);
        }
    }
    //
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGFloat offset = 0.0f;
    for (UIImage *img in arr) {
        if (horizontal) {
            //横向
            [img drawAtPoint:CGPointMake(offset, 0)];
            offset += img.size.width;
        } else {
            //纵向
            [img drawAtPoint:CGPointMake(0, offset)];
            offset += img.size.height;
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (BOOL)imgSave:(UIImage *)img path:(NSString *)path {
    //保存图片
    if (img && path && [path.pathExtension.lowercaseString compare:@"png"]==NSOrderedSame) {
        //save png
        NSData *data = UIImagePNGRepresentation(img);
        return [data writeToFile:path atomically:YES];
    } else {
        //save jpg
        NSData *data = UIImageJPEGRepresentation(img, 0);
        return [data writeToFile:path atomically:YES];
    }
}

#pragma mark - CGRect
- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font {
    //rect计算
    NSDictionary *dict = @{NSFontAttributeName:font};
    return [str boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dict context:nil];
}

- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing {
    //rect计算 + 行间距
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    NSDictionary *dict = @{NSFontAttributeName:font,
                           NSParagraphStyleAttributeName:paragraphStyle};
    return [str boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dict context:nil];
}

- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing {
    //rect计算 + 行间距 + 段间距
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    paragraphStyle.paragraphSpacing = paragraphSpacing;
    NSDictionary *dict = @{NSFontAttributeName:font,
                           NSParagraphStyleAttributeName:paragraphStyle};
    return [str boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dict context:nil];
}

- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing kern:(CGFloat)kern {
    //rect计算 + 行间距 + 字间距
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    NSDictionary *dict = @{NSKernAttributeName:@(kern),
                           NSFontAttributeName:font,
                           NSParagraphStyleAttributeName:paragraphStyle};
    return [str boundingRectWithSize:CGSizeMake(width, 0) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dict context:nil];
}

#pragma mark - NSString
- (NSString *)stringTrimNewline:(NSString *)str {
    //去除换行
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)stringTrimWhitespace:(NSString *)str {
    //去除空格
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)stringTrimWhitespaceAndNewline:(NSString *)str {
    //去除空格和换行
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringUnicode:(NSString *)str {
    //unicode编码
    NSString *temp1 = [str stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *temp2 = [temp1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *temp3 = [[@"\""stringByAppendingString:temp2] stringByAppendingString:@"\""];
    NSString *temp4 = [NSPropertyListSerialization propertyListWithData:[temp3 dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListImmutable format:NULL error:NULL];
    return [temp4 stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

- (NSString *)stringPinyin:(NSString *)str {
    //拼音
    NSMutableString *pinyin = [str mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    return pinyin.uppercaseString;
}

#pragma mark - Time
- (NSString *)time1970 {
    //毫秒数 目前和授权服务器允许有10分钟的误差
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%0.0f", time*1000.0f];
}

- (NSString *)time1970:(NSString *)str {
    //毫秒数 根据时间字符串
    return [self time1970:str dateFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)time1970:(NSString *)str dateFormat:(NSString *)dateFormat {
    //毫秒数 根据时间字符串
    NSDateFormatter *dateFormatter = [NSDateFormatter alloc].init;
    dateFormatter.dateFormat = dateFormat;
    NSTimeInterval time = [[dateFormatter dateFromString:str] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%0.0f", time*1000.0f];
}

- (NSDate *)timeDate:(NSString *)str {
    //NSDate 根据毫秒数
    return [[NSDate alloc] initWithTimeIntervalSince1970:str.doubleValue/1000.0f];
}

- (NSString *)timeString {
    //时间字符串
    return [self timeString:[self time1970]];
}

- (NSString *)timeString:(NSString *)str {
    //时间字符串 根据毫秒数
    return [self timeString:str dateFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)timeString:(NSString *)str dateFormat:(NSString *)dateFormat {
    //时间字符串 根据毫秒数
    NSDateFormatter *dateFormatter = [NSDateFormatter alloc].init;
    dateFormatter.dateFormat = dateFormat;
    NSTimeInterval time = str.doubleValue/1000.0f;
    return time>0?[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]]:@"N/A";
}

- (NSString *)timeSeconds:(NSString *)str {
    //计算时差 秒
    return [self timeSeconds:[self time1970] time:str];
}

- (NSString *)timeSeconds:(NSString *)str1 time:(NSString *)str2 {
    //计算时差 秒
    return [NSString stringWithFormat:@"%0.0f", (str2.doubleValue-str1.doubleValue)/1000.0f];
}

- (NSString *)timeDays:(NSString *)str {
    //计算时差 天
    return [self timeDays:[self time1970] time:str];
}

- (NSString *)timeDays:(NSString *)str1 time:(NSString *)str2 {
    //计算时差 天
    NSDate *date1;
    NSDate *date2;
    NSCalendar *time = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [time rangeOfUnit:NSCalendarUnitDay startDate:&date1 interval:NULL forDate:[self timeDate:str1]];
    [time rangeOfUnit:NSCalendarUnitDay startDate:&date2 interval:NULL forDate:[self timeDate:str2]];
    NSInteger day = [time components:NSCalendarUnitDay fromDate:date1 toDate:date2 options:0].day;
    return [NSString stringWithFormat:@"%ld", day];
}

- (NSString *)timeDay:(NSInteger)day {
    //毫秒数 day天后的日期
    NSDate *date = [NSDate dateWithTimeInterval:day*24*60*60 sinceDate:[NSDate date]];
    NSTimeInterval time = [date timeIntervalSince1970];
    return [NSString stringWithFormat:@"%0.0f", time*1000.0f];
}

#pragma mark - NSMutableArray
- (void)sortUsingComparator:(NSMutableArray *)arr key:(NSString *)key ascend:(BOOL)ascend {
    //数组排序
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *str1 = nil;
        NSString *str2 = nil;
        if (key.length) {
            NSMutableDictionary *dict1 = obj1;
            NSMutableDictionary *dict2 = obj2;
            NSString *key1 = [NSString stringWithFormat:@"%@", dict1[key]];
            NSString *key2 = [NSString stringWithFormat:@"%@", dict2[key]];
            str1 = key1.length?key1:@"";
            str2 = key2.length?key2:@"";
        } else {
            str1 = [NSString stringWithFormat:@"%@", obj1];
            str2 = [NSString stringWithFormat:@"%@", obj2];
        }
        str1 = [self stringPinyin:str1];
        str2 = [self stringPinyin:str2];
        NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch |
        NSWidthInsensitiveSearch | NSForcedOrderingSearch;
        NSComparisonResult result = [str1 compare:str2 options:comparisonOptions];
        if (result == NSOrderedAscending) {
            return ascend?NSOrderedAscending:NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            return ascend?NSOrderedDescending:NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
}

- (void)sortUsingDescriptors:(NSMutableArray *)arr key:(NSString *)key ascend:(BOOL)ascend {
    //数组排序 针对数组中存放对象
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
    [arr sortUsingDescriptors:sortDescriptors];
}

#pragma mark - Keychain
- (void)keychainSave:(NSString *)keychain key:(NSString *)key value:(NSString *)value {
    //保存 Keychain 信息
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    para[key] = value;
    //Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:keychain];
    //Delete old item before add new item
    SecItemDelete((CFDictionaryRef)keychainQuery);
    //Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:para] forKey:(id)kSecValueData];
    //Add item to keychain with the search dictionary
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

- (void)keychainSave:(NSString *)keychain info:(NSMutableDictionary *)info {
    //保存 Keychain 信息
    //Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:keychain];
    //Delete old item before add new item
    SecItemDelete((CFDictionaryRef)keychainQuery);
    //Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:info] forKey:(id)kSecValueData];
    //Add item to keychain with the search dictionary
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

- (NSString *)keychainLoad:(NSString *)keychain key:(NSString *)key {
    //读取 Keychain 信息
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:keychain];
    //Configure the search setting
    //Since in our simple case we are expecting only a single attribute to be returned (the password) we can set the attribute kSecReturnData to kCFBooleanTrue
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            para = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", keychain, e);
        } @finally {
            
        }
    }
    if (keyData) {
        CFRelease(keyData);
    }
    return para[key];
}

- (NSMutableDictionary *)keychainLoad:(NSString *)keychain {
    //读取 Keychain 信息
    NSMutableDictionary *dictRet = [NSMutableDictionary dictionary];
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:keychain];
    //Configure the search setting
    //Since in our simple case we are expecting only a single attribute to be returned (the password) we can set the attribute kSecReturnData to kCFBooleanTrue
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            dictRet = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", keychain, e);
        } @finally {
            
        }
    }
    if (keyData) {
        CFRelease(keyData);
    }
    return dictRet;
}

- (void)keychainDelete:(NSString *)keychain {
    //删除 Keychain 信息
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:keychain];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}

- (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    //Get search dictionary
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassGenericPassword, (id)kSecClass,
            service, (id)kSecAttrService,
            service, (id)kSecAttrAccount,
            (id)kSecAttrAccessibleAfterFirstUnlock, (id)kSecAttrAccessible,
            nil];
}

#pragma mark - BOOL
- (BOOL)isJailBreak {
    //是否越狱
    return [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"cydia://"]]?YES:NO;
}

- (BOOL)isJailBroken {
    //是否越狱
    const char *jailbreak_tool_pathes[] = {
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt"
    };
    for (int i=0; i<sizeof(jailbreak_tool_pathes)/sizeof(jailbreak_tool_pathes[0]); i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_tool_pathes[i]]]) {
            return YES;
        }
    }
    return NO;
    
    /**
     可以尝试使用NSFileManager判断设备是否安装了如下越狱常用工具：
     /Applications/Cydia.app
     /Library/MobileSubstrate/MobileSubstrate.dylib
     /bin/bash
     /usr/sbin/sshd
     /etc/apt
     */
    //return [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]?YES:NO;
}

- (BOOL)isNetIPV6 {
    //判断网络 是否为 ipv6 环境
    struct hostent *host = gethostbyname2("www.cnki.net", AF_INET6);
    return host?YES:NO;
}

- (BOOL)isName:(NSString *)str {
    //名字判断
    BOOL isValid = NO;
    if (str.length) {
        for (int i = 0; i<str.length; i++) {
            unichar chr = [str characterAtIndex:i];
            //NSLog(@"%x", chr);
            if (chr < 0x80) {
                //字符
                if (chr >= 'a' && chr <= 'z') {
                    isValid = YES;
                } else if (chr >= 'A' && chr <= 'Z') {
                    isValid = YES;
                } else if (chr >= '0' && chr <= '9') {
                    isValid = NO;
                } else if (chr == '-' || chr == '_') {
                    isValid = YES;
                } else {
                    isValid = NO;
                }
            } else if (chr >= 0x4e00 && chr < 0x9fa5) {
                //中文
                isValid = YES;
            } else if (chr == 0xb7) {
                //·
                isValid = YES;
            } else {
                //无效字符
                isValid = NO;
            }
            //
            if (!isValid) {
                break;
            }
        }
    }
    return isValid;
}

- (BOOL)isMobileNumber:(NSString *)str {
    //手机号判断
    /**
     * 手机号码:
     * 13[0-9], 14[5,7], 15[0, 1, 2, 3, 5, 6, 7, 8, 9], 17[0, 1, 6, 7, 8], 18[0-9]
     * 移动号段: 134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
     * 联通号段: 130,131,132,145,155,156,170,171,175,176,185,186
     * 电信号段: 133,149,153,170,173,177,180,181,189
     */
    NSString *MOBILE = @"^1(3[0-9]|4[57]|5[0-35-9]|7[0135678]|8[0-9])\\d{8}$";
    /**
     * 中国移动：China Mobile
     * 134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
     */
    NSString *CM = @"^1(3[4-9]|4[7]|5[0-27-9]|7[08]|8[2-478])\\d{8}$";
    /**
     * 中国联通：China Unicom
     * 130,131,132,145,155,156,170,171,175,176,185,186
     */
    NSString *CU = @"^1(3[0-2]|4[5]|5[56]|7[0156]|8[56])\\d{8}$";
    /**
     * 中国电信：China Telecom
     * 133,149,153,170,173,177,180,181,189
     */
    NSString *CT = @"^1(3[3]|4[9]|53|7[037]|8[019])\\d{8}$";
    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *pred4 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    return [pred1 evaluateWithObject:str] || [pred2 evaluateWithObject:str] || [pred3 evaluateWithObject:str] || [pred4 evaluateWithObject:str];
}

- (BOOL)isPhoneNumber:(NSString *)str {
    //手机号判断
    NSString *regex = @"^1([3-9])\\d{9}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isEmail:(NSString *)str {
    //邮箱判断
    NSString *regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isIDNumber:(NSString *)str {
    //身份证号判断
    NSString *regex = @"^(\\d{14}|\\d{17})(\\d|[xX])$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isIdNumber:(NSString *)str {
    //身份证号判断
    NSString *carid = str;
    long lSumQT = 0;
    //加权因子
    int R[] = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2 };
    //校验码
    unsigned char sChecker[11] = {'1','0','X', '9', '8', '7', '6', '5', '4', '3', '2'};
    //将15位身份证号转换成18位
    NSMutableString *mString = [NSMutableString stringWithString:str];
    if (str.length == 15) {
        [mString insertString:@"19" atIndex:6];
        long p = 0;
        const char *pid = [mString UTF8String];
        for (int i=0; i<=16; i++) {
            p += (pid[i]-48)*R[i];
        }
        int o = p%11;
        NSString *string_content = [NSString stringWithFormat:@"%c", sChecker[o]];
        [mString insertString:string_content atIndex:[mString length]];
        carid = mString;
    }
    //判断地区码
    NSString *sProvince = [carid substringToIndex:2];
    if (![self areaCode:sProvince]) {
        return NO;
    }
    //判断年月日是否有效
    int year = [[carid substringWithRange:NSMakeRange(6,4)] intValue];
    int month = [[carid substringWithRange:NSMakeRange(10,2)] intValue];
    int day = [[carid substringWithRange:NSMakeRange(12,2)] intValue];
    //
    NSDateFormatter *dateFormatter = [NSDateFormatter alloc].init;
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%d-%d-%d 12:01:01", year, month, day]];
    if (date == nil) {
        return NO;
    }
    const char *PaperId = [carid UTF8String];
    //检验长度
    if(18 != strlen(PaperId)) return -1;
    //校验数字
    for (int i = 0; i < 18; i++) {
        if (!isdigit(PaperId[i]) && !(('X' == PaperId[i] || 'x' == PaperId[i]) && 17 == i)) {
            return NO;
        }
    }
    //验证最末的校验码
    for (int i = 0; i <= 16; i++) {
        lSumQT += (PaperId[i]-48)*R[i];
    }
    if (sChecker[lSumQT%11] != PaperId[17]) {
        return NO;
    }
    return YES;
}

- (BOOL)areaCode:(NSString *)code {
    //功能:判断是否在地区码内
    //参数:地区码
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    para[@"11"] = @"北京";
    para[@"12"] = @"天津";
    para[@"12"] = @"河北";
    para[@"14"] = @"山西";
    para[@"15"] = @"内蒙古";
    para[@"21"] = @"辽宁";
    para[@"22"] = @"吉林";
    para[@"23"] = @"黑龙江";
    para[@"31"] = @"上海";
    para[@"32"] = @"江苏";
    para[@"33"] = @"浙江";
    para[@"34"] = @"安徽";
    para[@"35"] = @"福建";
    para[@"36"] = @"江西";
    para[@"37"] = @"山东";
    para[@"41"] = @"河南";
    para[@"42"] = @"湖北";
    para[@"43"] = @"湖南";
    para[@"44"] = @"广东";
    para[@"45"] = @"广西";
    para[@"46"] = @"海南";
    para[@"50"] = @"重庆";
    para[@"51"] = @"四川";
    para[@"52"] = @"贵州";
    para[@"53"] = @"云南";
    para[@"54"] = @"西藏";
    para[@"61"] = @"陕西";
    para[@"62"] = @"甘肃";
    para[@"63"] = @"青海";
    para[@"64"] = @"宁夏";
    para[@"65"] = @"新疆";
    para[@"71"] = @"台湾";
    para[@"81"] = @"香港";
    para[@"82"] = @"澳门";
    para[@"91"] = @"国外";
    return para[code]?YES:NO;
}

- (BOOL)isAppInstalled:(NSString *)str {
   //是否安装某app 根据scheme
    return [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:str]];
}

- (BOOL)isHaveChinese:(NSString *)str {
    //判断字符串是否有中文
    for(int i=0; i<str.length; i++) {
        int a = [str characterAtIndex:i];
        if(a>0x4e00 && a<0x9fff) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isHaveOnlyChinese:(NSString *)str {
    //判断字符串是否只含中文
    NSString *regex = @"[\u4e00-\u9fa5]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isHaveOnlyLetters:(NSString *)str {
    //判断字符串是否只含字母
    NSString *regex = @"[a-zA-Z]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isHaveOnlyNumbers:(NSString *)str {
    //判断字符串是否只含数字
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isHaveOnlyLettersOrNumbers:(NSString *)str {
    //判断字符串是否只含字母或数字
    NSString *regex = @"[a-zA-Z0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isHaveOnlyLettersAndNumbers:(NSString *)str {
    //判断字符串是否只含字母和数字
    NSString *regex = @"^(?![0-9]+$)(?![a-zA-Z]+$)[a-zA-Z0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isHaveOnlyChineseOrLettersOrNumbers:(NSString *)str {
    //判断字符串是否只含中文、字母或数字
    NSString *regex = @"[a-zA-Z0-9\u4e00-\u9fa5]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (BOOL)isURL:(NSString *)str {
    //判断字符串是否是网址
    NSString *regex = @"[a-zA-z]+://.*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:str];
}

- (void)clearAllUserDefaultsData2
{
    //清除所有的存储本地的数据
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)clearAllUserDefaultsData
{
    //清除所有的存储本地的数据
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *dic = [userDefaults dictionaryRepresentation];
    for (id  key in dic) {
        [userDefaults removeObjectForKey:key];
    }
    [userDefaults synchronize];
}

@end
