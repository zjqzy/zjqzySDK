//
//  CNKI_Z_Lib.h
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/*
 
 常用，便捷的函数类
 
 */
@interface CNKI_Z_Lib : NSObject

//////////////////////////////////////////////
//////////////////////////////////////////////

/**
 单例
 
 @return 返回 self
 */
+(CNKI_Z_Lib*)sharedInstance;

// 单例限制
// 告诉外面，alloc，new，copy，mutableCopy方法不可以直接调用。
// 否则编译不过

+(instancetype) alloc __attribute__((unavailable("call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) copy __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) mutableCopy __attribute__((unavailable("call sharedInstance instead")));

//////////////////////////////////////////////
//////////////////////////////////////////////

/**
 *  @brief  创建PDF文件   图片生成PDF
 *
 *  @param  imgData         NSData型   照片数据
 *  @param  destFileName    NSString型 生成的PDF文件名 -- 绝对路径
 *  @param  pw              NSString型 要设定的密码
 
 *  调用方法
 NSData *data = [NSData dataWithContentsOfFile:your_image_path];
 NSString *pdfname = @".../photoToPDF.pdf"; //绝对路径
[zhuIOSLib zhuImageToPDFFileWithSrc:imgData toDestFile:pdfname withPassword:nil];
 
 */
-(void)zhuImageToPDFFileWithSrc:(NSData *)imgData
                    toDestFile:(NSString *)destFileName
                  withPassword:(NSString *)pw;

/**
 
 判断当前 SDK 是否支持 类
 */
-(Class)SDKHaveClassFromString:(NSString *)classStr;
-(BOOL)SDKClassHaveMethod:(NSString*)classStr Method:(SEL)method;
/**
 //十进制转十六进制
 *调用方法
 const CGFloat *cs=CGColorGetComponents(color1.CGColor);
 NSString *r = [NSString stringWithFormat:@"%@",[self  ToHex:cs[0]*255]];
 NSString *g = [NSString stringWithFormat:@"%@",[self  ToHex:cs[1]*255]];
 NSString *b = [NSString stringWithFormat:@"%@",[self  ToHex:cs[2]*255]];
 strCol= [NSString stringWithFormat:@"#%@%@%@",r,g,b]; 
 */
-(NSString *)ToHex:(int)tmpid;

/**
 文件
    判断文件大小
    创建文件夹
    修改文件备份属性
 */

-(void)appendData:(NSObject *)data toFile:(NSString *)file;
-(void)prependData:(NSObject *)data toFile:(NSString *)file;
-(NSMutableArray *)getDataFromFile:(NSString *)file;
-(void)deleteData:(NSObject *)data ofFile:(NSString *)file;
-(void)empty:(NSString *)file;

-(long long)fileSizeAtPath:(NSString *)path;
-(float)folderSizeAtPath:(NSString*)folderPath;
-(BOOL)createDirectory:(NSString*)strFolderPath;    //创建文件夹,自动多级创建
-(BOOL)deleteFileAtPath:(NSString*)path;
-(BOOL)moveFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath;
-(BOOL)copyFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath;
-(BOOL)deleteDirectory:(NSString*)strFolderPath DelSelf:(BOOL)bDelSelf; //删除文件夹（自身是否删除）
-(NSString*)fileParentFolder:(NSString*)fileFullPath;//得到文件父文件夹
-(BOOL)deleteAllFileInTmpDirectory; //删除系统 “／tmp” 内的所有文件
-(BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)path;
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL*)URL;//文件取消iCloud 的backup属性，设为不备份
-(BOOL)isFileHaveBackupAttributeAtPath:(NSString *)path;
-(BOOL)isFileHaveBackupAttributeAtURL:(NSURL *)URL;
-(BOOL)isFileExist:(NSString *)path;
-(NSString*)fileContentMD5:(NSString*)path;
-(NSString*)getFileMD5WithPath:(NSString*)path;

-(NSString*)fileCRC:(NSString*)path;
-(NSString*)dataCRC:(NSData*)data1;
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName;   //根据名称，返回绝对路径
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName InDirectory:(NSString*)inDirectory;
-(NSURL*)fileToURL:(NSString*)fileName;
-(NSInteger)fileEncoding:(NSString*)fileFullPath; //内容编码格式 {0 ansi,1 unicode,2 utf8}
-(NSString*)fileContent:(NSString*)fileFullPath;   //得到内容
-(NSData*)fileContentData:(NSString*)fileFullPath;   //得到内容
-(int)fileAppendData:(NSData*)appendData FileFullPath:(NSString*)fileFullPath; //文件内容追加
/*
 转换
 */
/**
 日期
    得到现在的时间
    NSString 与 NSDate 的转换
 */
-(NSString*)getNowTimeIntervalString;
-(NSString*)getDateStringFromTimeInterval:(NSString*)strTimeInterval;
-(NSDate*)getDateFromTimeInterval:(NSString*)strTimeInterval;
-(NSString*)getNowString;
-(NSString*)getTimeIntervalStringFromNow:(NSTimeInterval)interval;   //从当前时间 加减 秒数
-(NSDate *)getNowDateFromatAnDate:(NSDate *)anyDate;
-(NSDate *)localDateToGMTDate:(NSDate *)localDate;  //本地时区 转 GMT 时区
-(NSDate *)localDateToUTCDate:(NSDate *)localDate;  //本地时区 转 UTC 时区
-(NSDate *)stringToDate:(NSString *)strdate;
-(NSString *)dateToString:(NSDate *)date;
-(NSString *)getUTCFormateLocalDate:(NSString *)localDate;
-(NSString *)getLocalDateFormateUTCDate:(NSString *)utcDate;
-(NSString *)getUTCFormatDate:(NSDate *)localDate;
-(NSDate *)getLocalFromUTC:(NSString *)utc;

-(NSDate*)NSStringToNSDate:(NSString*)strDate;
-(NSString*)NSDateToNSString:(NSDate*)data1;
-(NSDate*)NSDateFromNSString:(NSString*)strDate WithFormatString:(NSString*)formatString;
-(NSString*)NSStringFromNSDate:(NSDate*)data1 WithFormatString:(NSString*)formatString;

-(NSString*)longToHexSring:(long long)long1; //  long  转  hex 字符串
-(long long)hexStringToLong:(NSString*)hexStr1;
-(NSData *)toJSONData:(id)theData;  // 
/**
 颜色转换
 */
-(NSString*)UIColorToNSString:(UIColor*)color;
-(UIColor*)NSStringToUIColor:(NSString*)strColor;
-(UIColor*)UIColorFromRGBString:(NSString*)strRGB;

/**
 字符串
    trim，比较（支持中文比较,默认是英文）
    
    compare 比较规则options
    NSLiteralSearch 区分大小写(完全比较)
    NSCaseInsensitiveSearch 不区分大小写  默认
    NSNumericSearch 只比较字符串的个数，而不比较字符串的字面值 
 */
-(NSString *)md5:(NSString *)str;
-(NSString*)trimWhiteSpace:(NSString*)strContent;           //去除空格
-(NSString*)trimWhiteSpaceAndNewLine:(NSString*)strContent; //去除空格和换行
-(NSString*)replaceUnicodeString:(NSString *)unicodeStr;   //把unicode格式，转成中文
-(NSComparisonResult)compareCNStr:(NSString*)first1 Second:(NSString*)second2; //比较带中文字符串
- (NSString *)pinyinWithCNStr:(NSString *)chinese;//汉字-->拼音

/*
 字符串 加密解密
 */
-(NSString*)stringCNKIEncryptWithGTMBase64:(NSString*)strSource;    //ok
-(NSString*)stringCNKIDecryptWithGTMBase64:(NSString*)strEncryptSource;
-(NSString*)stringCNKIEncrypt:(NSString*)strSource; //和秘钥的字符串亦或
-(NSString*)stringCNKIDecrypt:(NSString*)strEncryptSource;
-(NSString*)stringGTMBase64encode:(NSString*)strSource; //base64    ok
-(NSString*)stringGTMBase64decode:(NSString*)strSourceEncode;

-(NSData *)dataWithBase64EncodedString:(NSString *)string WithEncodeList:(NSString*)encodeList;
-(NSString *)base64EncodedStringFrom:(NSData *)data WithEncodeList:(NSString*)encodeList;
-(NSString *)base64StringFromString:(NSString *)text WithEncodeList:(NSString*)encodeList;
-(NSString *)stringFromBase64String:(NSString *)base64 WithEncodeList:(NSString*)encodeList;

-(NSData *)DESEncrypt:(NSData *)data WithKey:(NSString *)key;
-(NSData *)DESDecrypt:(NSData *)data WithKey:(NSString *)key;

-(NSString *)AES128Encrypt:(NSString *)plainText withKey:(NSString*)gkey withgIv:(NSString*)gIv;
-(NSString *)AES128Decrypt:(NSString *)encryptText withKey:(NSString*)gkey withgIv:(NSString*)gIv;

/*
 web
 当前webView加载的实际网址
 */
-(NSString*)getWebViewInnerHtml:(UIWebView *) webView;

/**
 设备
 */
-(BOOL)mySystemVersionCreaterThanOrEqualTo:(NSString*)compareVersion;

/*
 是否接收 event
 */
-(void)setWindowToucheEnable:(BOOL)bEnable;

/*
 分析url
 */
-(NSMutableDictionary*)ParseURLParams:(NSString*)url;

/*
 根据url 得到天气
 */
-(NSDictionary*)getWeatherFromURLString:(NSString*)strUrl;
/*
得到下载的url内容  string，data
 */
-(NSString*)getURLContent:(NSString*)strURL;
-(NSData*)getDataWithURL:(NSString*)strURL;
/*
 根据AppID，得到  商店地址，评论地址 , appStore的版本,
 */
-(NSURL *)appStoreURLforApplicationIdentifier:(NSString *)identifier;
-(NSURL *)appStoreReviewURLForApplicationIdentifier:(NSString *)identifier;
-(NSDictionary*)getAppVersionWithAppid:(NSString*)identifier;

/*
 得到设备空闲空间大小
 得到设备空间大小
 */
-(long long)deviceFreeSpace;
-(CGFloat)deviceTotalDiskSpace;

/*
 网络请求
 */
-(int)openURLWithString:(NSString*)strURL;
-(id)doHttpRequest:(NSString*)strHttpSQL ReturnType:(NSInteger)type;
-(id)doHttpSQLRequest:(NSString*)strHttpSQL;
-(id)doHttpSQLRequestWithGet:(NSString*)httpURL AddRequestHeaders:(NSMutableDictionary*)requestHeaders WithGZIP:(NSInteger)iGzip WithReturnType:(NSInteger)iReturnType;
-(id)doRequestWithPostData:(NSMutableDictionary *)para;

/*
 计算
 弧度，角度
 */
-(CGFloat)ExDegreesToRadians:(CGFloat)degrees;
-(CGFloat)ExRadiansToDegrees:(CGFloat)radians;

/*
 系统相关
 得到mac地址
 默认设置
 */
-(NSString *)getMacAddress;
-(id)getUserDefaults:(NSString *) name;
-(void)setUserDefaults:(NSObject *) defaults forKey:(NSString *) key;

/*
 天气
 */
-(NSDictionary*)Weather;

/*
 给 View 添加圆角,阴影
 */
-(void)buttonAddCorner:(UIButton*)btn CornerRadius:(CGFloat)cornerRadius BorderWidth:(CGFloat)borderWidth BorderColor:(UIColor*)borderColor;
-(void)viewAddShadow:(UIView*)theView;
-(void)viewAddSimpleReflection:(UIView*)theView;

-(NSString*)getCountryCode;     //国家环境 
-(NSString*)getLanguageCode;    //设备语言
-(void)checkDylibs;     //app 链接的动态库

-(NSString*)getANSIString:(NSData*)ansiData;
-(NSString*)getStringFromANSIByte:(NSData*)data1;

-(void)openApp; //打开程序

-(NSString*)scanDecodeFromEncryption:(NSString*)strEncryption;  //王云飞，二维码

-(NSMutableDictionary*)getDictionaryFromString:(NSString*)str1 WithSeparatedString:(NSString*)sep;
-(NSString*)getStringFromDictionary:(NSDictionary*)dict1 WithSeparatedString:(NSString*)sep;

/*
 UILabel、UITextView自适应得到高度 计算
 */
- (CGFloat)heightForLabel:(NSString *)labelContent Width:(float)width Font:(UIFont *)font1;
- (CGFloat)heightForTextView:(NSString *)txtContent Width:(float)width Font:(UIFont *)font1;

#pragma mark - UIImage
/**获取URL图片*/
- (UIImage *)imgURL:(NSString *)str;
/**根据颜色生成图片*/
- (UIImage *)imgColor:(UIColor *)color;
/**获取本地图片*/
- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory;
/**获取本地图片*/
- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory alpha:(CGFloat)alpha;
/**获取本地图片*/
- (UIImage *)imgName:(NSString *)name directory:(NSString *)directory color:(UIColor *)color;
/**生成条形码*/
- (UIImage *)imgBarCode:(NSString *)str size:(CGSize)size;
/**生成二维码*/
- (UIImage *)imgQRCode:(NSString *)str size:(CGFloat)size;
/**改变图片颜色*/
- (UIImage *)imgChangeColor:(UIImage *)img color:(UIColor *)color;
/**改变图片透明度*/
- (UIImage *)imgChangeAlpha:(UIImage *)img alpha:(CGFloat)alpha;
/**添加中心图标*/
- (UIImage *)imgAddIcon:(UIImage *)img icon:(UIImage *)icon size:(CGSize)size;
/**图片拼接*/
- (UIImage *)imgAppend:(NSArray *)arr horizontal:(NSInteger)horizontal;
/**保存图片*/
- (BOOL)imgSave:(UIImage *)img path:(NSString *)path;

#pragma mark - CGRect
/**rect计算*/
- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font;
/**rect计算 + 行间距*/
- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing;
/**rect计算 + 行间距 + 段间距*/
- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing;
/**rect计算 + 行间距 + 字间距*/
- (CGRect)rectString:(NSString *)str maxWidth:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing kern:(CGFloat)kern;

#pragma mark - NSString
/**去除换行*/
- (NSString *)stringTrimNewline:(NSString *)str;
/**去除空格*/
- (NSString *)stringTrimWhitespace:(NSString *)str;
/**去除空格和换行*/
- (NSString *)stringTrimWhitespaceAndNewline:(NSString *)str;
/**unicode编码*/
- (NSString *)stringUnicode:(NSString *)str;
/**拼音*/
- (NSString *)stringPinyin:(NSString *)str;

#pragma mark - Time
/**毫秒数*/
- (NSString *)time1970;
/**毫秒数 根据时间字符串*/
- (NSString *)time1970:(NSString *)str;
/**毫秒数 根据时间字符串*/
- (NSString *)time1970:(NSString *)str dateFormat:(NSString *)dateFormat;
/**NSDate 根据毫秒数*/
- (NSDate *)timeDate:(NSString *)str;
/**时间字符串*/
- (NSString *)timeString;
/**时间字符串 根据毫秒数*/
- (NSString *)timeString:(NSString *)str;
/**时间字符串 根据毫秒数*/
- (NSString *)timeString:(NSString *)str dateFormat:(NSString *)dateFormat;
/**计算时差 秒*/
- (NSString *)timeSeconds:(NSString *)str;
/**计算时差 秒*/
- (NSString *)timeSeconds:(NSString *)str1 time:(NSString *)str2;
/**计算时差 天*/
- (NSString *)timeDays:(NSString *)str;
/**计算时差 天*/
- (NSString *)timeDays:(NSString *)str1 time:(NSString *)str2;
/**毫秒数 day天后的日期*/
- (NSString *)timeDay:(NSInteger)day;

#pragma mark - NSMutableArray
/**数组排序*/
- (void)sortUsingComparator:(NSMutableArray *)arr key:(NSString *)key ascend:(BOOL)ascend;
/**数组排序 针对数组中存放对象 key不能是nil*/
- (void)sortUsingDescriptors:(NSMutableArray *)arr key:(NSString *)key ascend:(BOOL)ascend;

#pragma mark - Keychain
//#import <Security/Security.h>
/**保存 Keychain 信息*/
- (void)keychainSave:(NSString *)keychain key:(NSString *)key value:(NSString *)value;
/**保存 Keychain 信息*/
- (void)keychainSave:(NSString *)keychain info:(NSMutableDictionary *)info;
/**读取 Keychain 信息*/
- (NSString *)keychainLoad:(NSString *)keychain key:(NSString *)key;
/**读取 Keychain 信息*/
- (NSMutableDictionary *)keychainLoad:(NSString *)keychain;
/**删除 Keychain 信息*/
- (void)keychainDelete:(NSString *)keychain;

#pragma mark - BOOL
/**是否越狱*/
- (BOOL)isJailBreak;
/**是否越狱*/
- (BOOL)isJailBroken;
/**判断网络 是否为 ipv6 环境*/
- (BOOL)isNetIPV6;
/**名字判断*/
- (BOOL)isName:(NSString *)str;
/**手机号判断*/
- (BOOL)isMobileNumber:(NSString *)str;
/**手机号判断*/
- (BOOL)isPhoneNumber:(NSString *)str;
/**邮箱判断*/
- (BOOL)isEmail:(NSString *)str;
/**身份证号判断*/
- (BOOL)isIDNumber:(NSString *)str;
/**身份证号判断*/
- (BOOL)isIdNumber:(NSString *)str;
/**是否安装某app 根据scheme, 可行*/
- (BOOL)isAppInstalled:(NSString *)str;
/**判断字符串是否有中文*/
- (BOOL)isHaveChinese:(NSString *)str;
/**判断字符串是否只含中文*/
- (BOOL)isHaveOnlyChinese:(NSString *)str;
/**判断字符串是否只含字母*/
- (BOOL)isHaveOnlyLetters:(NSString *)str;
/**判断字符串是否只含数字*/
- (BOOL)isHaveOnlyNumbers:(NSString *)str;
/**判断字符串是否只含字母或数字*/
- (BOOL)isHaveOnlyLettersOrNumbers:(NSString *)str;
/**判断字符串是否只含字母和数字*/
- (BOOL)isHaveOnlyLettersAndNumbers:(NSString *)str;
/**判断字符串是否只含中文、字母或数字*/
- (BOOL)isHaveOnlyChineseOrLettersOrNumbers:(NSString *)str;
/**判断字符串是否是网址*/
- (BOOL)isURL:(NSString *)str;

- (void)clearAllUserDefaultsData2;//清除所有的存储本地的数据
- (void)clearAllUserDefaultsData;//清除所有的存储本地的数据

@end
