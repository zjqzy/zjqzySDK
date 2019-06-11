//
//  CNKI_Z_File.m
//

#import <sys/stat.h>                    //大小
#import <sys/xattr.h>                   //文件属性
#import <CommonCrypto/CommonDigest.h>   //算法 md5
#import <CommonCrypto/CommonCryptor.h>  // DES加密
#import <zlib.h>                        // crc

#import "CNKI_Z_File.h"

@implementation CNKI_Z_File
static CNKI_Z_File *s_file = nil;
+(CNKI_Z_File*)sharedInstance
{
    //单例
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_file = [[super allocWithZone:nil] init];
    });
    return s_file;
}
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_File sharedInstance] ;
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_File sharedInstance] ;
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [CNKI_Z_File sharedInstance];
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

/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////

-(NSString*)contentTypeForImageData:(NSData*)data
{
    //通过图片Data数据第一个字节 来获取图片扩展名
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c)
    {
        case 0xFF:
            return @"jpeg";
            
        case 0x89:
            return @"png";
            
        case 0x47:
            return @"gif";
            
        case 0x49:
        case 0x4D:
            return @"tiff";
            
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"]
                && [testString hasSuffix:@"WEBP"])
            {
                return @"webp";
            }
            
            return nil;
    }
    
    return nil;
}
-(BOOL)fileIsPDF:(NSString *)filePath
{
    //是否为PDF文件
    BOOL state = NO;
    
    if (filePath != nil) // Must have a file path
    {
        const char *path = [filePath fileSystemRepresentation];
        
        int fd = open(path, O_RDONLY); // Open the file
        
        if (fd > 0) // We have a valid file descriptor
        {
            const unsigned char sig[4]; // File signature
            
            ssize_t len = read(fd, (void *)&sig, sizeof(sig));
            
            if (len == 4)
                if (sig[0] == '%')
                    if (sig[1] == 'P')
                        if (sig[2] == 'D')
                            if (sig[3] == 'F')
                                state = YES;
            
            close(fd); // Close the file
        }
    }
    
    return state;
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
            break;
        }
        
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
-(long long)fileSizeAtPath:(NSString *)path
{
    //判断文件大小，也可当 pathFileExist用
    struct stat st;
    
    if (!stat([path cStringUsingEncoding:NSUTF8StringEncoding], &st)) {
        return st.st_size;
    }
    return 0;
}

- (float)folderSizeAtPath:(NSString*) folderPath
{
    //遍历文件夹获得文件夹大小，返回多少M
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
-(void)makeDirs:(NSString*)strFolderPath
{
    //创建文件夹,自动多级创建  初步测试ok
    if ([strFolderPath length]<1)
    {
        return;
    }
    
    NSString *folderParent=[self fileParentFolder:strFolderPath];
    if ( ![self fileIsExist:folderParent] )
    {
        [self makeDirs:folderParent];
    }

    [self createDirectory:strFolderPath];


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
        NSError *error = nil;
        NSURL *old=[NSURL fileURLWithPath:oldPath];
        NSURL *new=[NSURL fileURLWithPath:newPath];
        bDo1=[fileManager moveItemAtURL:old toURL:new error:&error];
        if (error) {
#ifdef DEBUG
            NSLog(@"%@",error);
#endif
        }
    }
    
    return bDo1;
}
-(BOOL)copyFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath
{
    BOOL bDo1=NO;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:oldPath])
    {
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
-(NSMutableArray*)getFolderFiles:(NSString*)fileFullPath
{
    //得到文件 下 子文件列表
    if ( ![self fileIsExist:fileFullPath] )
    {
        return nil;
    }
    NSString *strFolderPath=[NSString stringWithFormat:@"%@",fileFullPath];
    NSFileManager *localFileManager=[NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum =[localFileManager enumeratorAtPath:strFolderPath];
    NSString *file;
    NSMutableArray *arrRet=[NSMutableArray array];
    while (file = [dirEnum nextObject])
    {
        NSString *findFileFullPath=[strFolderPath stringByAppendingPathComponent:file];
        [arrRet addObject:findFileFullPath];
    }
    
    return arrRet;
}
-(NSMutableArray*)getFolderFileListWithFolderPath:(NSString *)folderFullPath HaveSuffix:(NSArray*)arrSuffix
{
    //得到文件夹下 子文件列表 ， 文件后缀 过滤

    NSMutableArray *allFiles=[NSMutableArray arrayWithCapacity:100];
    NSFileManager *localFileManager=[NSFileManager defaultManager];
    NSString *file=nil;
    NSString *searchDir=folderFullPath;
    NSDirectoryEnumerator *dirEnum =[localFileManager enumeratorAtPath:searchDir];
    
    //arrSuffix
    //NSArray *extArray=@[@"umd",@"chm",@"txt",@"epub",@"pdf",@"caj",@"kdh",@"nh",@"teb",@"doc",@"docx",@"ppt",@"pptx",@"xls",@"xlsx",@"html",@"xml",@"rtf"];
    
    if (dirEnum)
    {
        while (file=[dirEnum nextObject])
        {
            if ([arrSuffix count]>0)
            {
                NSString *ext = [[file pathExtension] lowercaseString];
                
                if ([arrSuffix containsObject:ext])
                {
                    [allFiles addObject:file];  //相对路径就行了
                }
            }
            else
            {
                [allFiles addObject:file];  //相对路径就行了
            }
        }
    }

    return allFiles;
}
-(NSString*)fileParentFolder:(NSString*)fileFullPath
{
    //得到文件父文件夹
    NSUInteger lastSlash = [fileFullPath rangeOfString:@"/" options:NSBackwardsSearch].location;
    NSString *parentFolder = [fileFullPath substringToIndex:lastSlash];
    return parentFolder;
}

-(BOOL)fileIsExist:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}
-(BOOL)isFileExist:(NSString *)path
{
    return [self fileIsExist:path];
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
-(NSString *)fileMd5:(NSString *) path
{
    //测试ok  根据整个文件计算 ,  处理大文件 ， 容易崩溃
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
}
-(NSString*)fileCRC:(NSString*)path
{
    //NSData *buf=[[NSData alloc] initWithContentsOfFile:path];
    NSData *buf=[NSData dataWithContentsOfFile:path];
    uLong crc=crc32(0L,Z_NULL,0);
    crc=crc32(crc, [buf bytes] , (uInt)[buf length]);
    
    NSString *strResult=[NSString stringWithFormat:@"%lu",crc];

    
    return strResult;
}
-(NSString*)dataCRC:(NSData*)data1
{
    uLong crc=crc32(0L,Z_NULL,0);
    crc=crc32(crc, [data1 bytes] , (uInt)[data1 length]);
    
    NSString *strResult=[NSString stringWithFormat:@"%lu",crc];

    return strResult;
}
-(NSString*)fileContent:(NSString*)fileFullPath
{
    //得到内容
    NSString *strContent=nil;
    if ( ! [self fileIsExist:fileFullPath] )
    {
        return strContent;
    }
    NSInteger fileEncoding=[self fileEncoding:fileFullPath];
    //NSData *fileData=[[NSData alloc] initWithContentsOfFile:fileFullPath];
    NSData *fileData=[NSData dataWithContentsOfFile:fileFullPath];
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
    
#if !__has_feature(objc_arc)
    [strContent autorelease];
#endif
    return strContent;
}
-(NSData*)fileContentData:(NSString*)fileFullPath
{
    //得到内容 nsdata
    NSData *fileData=nil;
    if ( ! [self fileIsExist:fileFullPath] )
    {
        return fileData;
    }
    //fileData=[[NSData alloc] initWithContentsOfFile:fileFullPath];
    fileData =[NSData dataWithContentsOfFile:fileFullPath];
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
-(NSMutableDictionary*)fileInfoWithPath:(NSString*)fileFullPath
{
    NSMutableDictionary *dictInfo=nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fileFullPath error:&error];
    
    if (fileAttributes != nil) {
        
        dictInfo=[NSMutableDictionary new];
        
        NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
        dictInfo[@"fileSize"]=fileSize;
        
        NSString *fileOwner = [fileAttributes objectForKey:NSFileOwnerAccountName];
        dictInfo[@"OwnerAccountName"]=fileOwner;
        
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        dictInfo[@"ModificationDate"]=fileModDate;
        
        NSDate *fileCreateDate = [fileAttributes objectForKey:NSFileCreationDate];
        dictInfo[@"CreationDate"]=fileCreateDate;
        
    }
    
    return dictInfo;
}
@end
