//
//  CNKI_Z_Device.m

//

#import <UIKit/UIKit.h>

#import <sys/sysctl.h>
#import <mach/mach.h>
#import <sys/mount.h>

#include <ifaddrs.h>    //ip
#include <arpa/inet.h>  //ip

#import "CNKI_Z_UICKeyChainStore.h"
#import "CNKI_Z_Device.h"

@implementation CNKI_Z_Device
static CNKI_Z_Device *s_device = nil;
+(CNKI_Z_Device*)sharedInstance
{
    //单例
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_device = [[super allocWithZone:nil] init];
    });
    return s_device;
}
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Device sharedInstance] ;
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [CNKI_Z_Device sharedInstance] ;
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [CNKI_Z_Device sharedInstance];
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
    
    NSString *strDesc=[NSString stringWithFormat:@"class=%@\ndevicename=%@\nsystemname=%@\nsystemversion=%0.2f\nDeviceModel=%@\nscreenScale=%0.2f\ndeviceDPI=%0.2f\ndeviceTotalMemory=%0.2fMB\nDeviceVersion=%@\n%@设备  uniqueDeviceId=%@\n国家=%@",[NSString stringWithUTF8String:object_getClassName(self)],self.uniqueDeviceName,self.systemname,_systemversion ,self.DeviceModel,_screenScale,_deviceDpi,_deviceTotalMemory,_DeviceVersion,[self is64Bit]?@"64位":@"32位",self.uniqueDeviceId,[self getCountryCode]];

    return strDesc;
}

- (id)init
{
	if ((self = [super init])) // Initialize
	{
        [self initParam];
	}
    
	return self;
}

-(void)initParam
{

    //self.uniqueDeviceId = [[UIDevice currentDevice] uniqueDeviceIdentifier];

    {
        //BA02A2FB-E934-442D-93F5-14B489653F2E
        NSString *deviceId = [CNKI_Z_UICKeyChainStore stringForKey:@"deviceId" service:@"TTKN"];
        if ([deviceId length]<2) {
            deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            [CNKI_Z_UICKeyChainStore setString:deviceId forKey:@"deviceId" service:@"TTKN"];
        }
        self.uniqueDeviceId=deviceId;
    }
    self.uniqueDeviceName = [[UIDevice currentDevice] name];
    self.systemname = [[UIDevice currentDevice] systemName];
    self.systemversion = [[[UIDevice currentDevice] systemVersion] floatValue];
    self.DeviceModel=[[UIDevice currentDevice] model];
    self.deviceTotalMemory= [self deviceTotalMemory];
    self.deviceDpi=[self getDeviceDpi];
    self.DeviceVersion = [self deviceVersion];
    self.osVersion = [[UIDevice currentDevice] systemVersion];
    
    self.devicePlatform=[NSString stringWithFormat:@"iOS-%@-%@", self.DeviceVersion, self.osVersion];
    
    self.appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!self.appName) {        
        self.appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    
    self.appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    self.appBuild =[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    self.bundleID =[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];

    self.appInfo=[NSString stringWithFormat:@"%@(%@)",self.appName,self.appVersion];
    self.appOnLine = @"1";
    self.appBrightness= [UIScreen mainScreen].brightness;
    self.DeviceType=[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"iphone" : @"ipad" ;
    if ([self.DeviceType isEqualToString:@"iphone"])
    {
        self.isPhone=1;
        self.screenScale=[UIScreen mainScreen].scale;
    }
    else
    {
        self.isPhone=0;
        self.screenScale=2;
    }
    
   // self.screenScale=[UIScreen mainScreen].scale;
    self.preferredLanguages=[NSLocale preferredLanguages];
    self.appLanguage=[[self getLanguageCode] lowercaseString];
    
    //公共路径
    self.bundlePath = [[NSBundle mainBundle] bundlePath];
    self.documentPath = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    self.LibraryPath = [NSHomeDirectory() stringByAppendingPathComponent:  @"Library"];
    self.tmpPath = [NSHomeDirectory() stringByAppendingPathComponent:  @"tmp"];
    self.cachesPath=[self.LibraryPath stringByAppendingPathComponent:  @"Caches"];

    //程序公共路径  根
    self.ttknPath= [self.LibraryPath stringByAppendingPathComponent:  @"TTKN"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.ttknPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.ttknPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    //程序公共路径  缩略图
    self.ttknThumbPath= [self.ttknPath stringByAppendingPathComponent:  @"Thumb"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.ttknThumbPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.ttknThumbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //程序公共路径  图片缓存
    self.ttknImageCache= [self.cachesPath stringByAppendingPathComponent:  @"readImageCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.ttknImageCache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.ttknImageCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //程序公共路径  广告
    self.ttknAdPath= [self.ttknPath stringByAppendingPathComponent:  @"AdInfo"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.ttknAdPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.ttknAdPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    //epub临时路径
    self.epubCachePath=[self.ttknPath stringByAppendingPathComponent:@"epubcache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.epubCachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.epubCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //epub保存路径
    self.epubSavePath=[self.ttknPath stringByAppendingPathComponent:@"epubsave"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.epubSavePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.epubSavePath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    //下载字体保存路径
    self.fontsPath=[self.LibraryPath stringByAppendingPathComponent:  @"Fonts"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.fontsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.fontsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //下载epub8种字体保存路径
    self.epubFontsPath=[self.fontsPath stringByAppendingPathComponent:  @"epub8"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.epubFontsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.epubFontsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

//////////////////////////////////////////
#pragma mark - 方法
-(double)batteryElectricity
{
    //电池电量  模拟器为 －1， 真机为［0，1］
    UIDevice *device = [UIDevice currentDevice];
    
    [device setBatteryMonitoringEnabled:YES];
    
    return device.batteryLevel;
    
//    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
//    {
//         // Level has changed
//         NSLog(@"Battery Level Change %.2f",device.batteryLevel);
//     }];
}
-(NSString*)getBatteryState {
    UIDevice *device = [UIDevice currentDevice];
    if (device.batteryState == UIDeviceBatteryStateUnknown) {
        return @"UnKnow";
    } else if (device.batteryState == UIDeviceBatteryStateUnplugged){
        return @"Unplugged";
    } else if (device.batteryState == UIDeviceBatteryStateCharging){
        return @"Charging";
    } else if (device.batteryState == UIDeviceBatteryStateFull){
        return @"Full";
    }
    return nil;
}
-(double)getDeviceDpi
{
    //设备DPI
    double dpi=160.0f;
    double scale=1.0f;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        scale=[[UIScreen mainScreen] scale];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        dpi=132*scale;
    }
    else if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        dpi=163*scale;
    }
    else
    {
        dpi=160*scale;
    }
    return dpi;
}

-(double)deviceAvailableMemory
{
    //设备可用内存
    
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
#ifdef DEBUG
//    NSLog(@"free: %lu\nactive: %lu\ninactive: %lu\nwire: %lu\nzero fill: %lu\nreactivations: %lu\npageins: %lu\npageouts: %lu\nfaults: %lu\ncow_faults: %lu\nlookups: %lu\nhits: %lu",
//          vmStats.free_count * vm_page_size,
//          vmStats.active_count * vm_page_size,
//          vmStats.inactive_count * vm_page_size,
//          vmStats.wire_count * vm_page_size,
//          vmStats.zero_fill_count * vm_page_size,
//          vmStats.reactivations * vm_page_size,
//          vmStats.pageins * vm_page_size,
//          vmStats.pageouts * vm_page_size,
//          vmStats.faults,
//          vmStats.cow_faults,
//          vmStats.lookups,
//          vmStats.hits
//          );
#endif
    
//    注意这些字段大都是页面数，要乘以vm_page_size才能拿到字节数。
//    顺便再简要介绍下：free是空闲内存；active是已使用，但可被分页的（在iOS中，只有在磁盘上静态存在的才能被分页，例如文件的内存映射，而动态分配的内存是不能被分页的）；inactive是不活跃的，也就是程序退出后却没释放的内存，以便加快再次启动，而当内存不足时，就会被回收，因此也可看作空闲内存；wire就是已使用，且不可被分页的。此外，这篇文档也有作介绍。
//    
//    最后你会发现，即使把这些全加起来，也比设备内存少很多，那么剩下的只好当成已被占用的神秘内存了。不过在模拟器上，这4个加起来基本上就是Mac的物理内存量了，相差不到2MB。
//    而总物理内存可以用NSRealMemoryAvailable()来获取，这个函数不需要提供参数，文档里也有记载，我就不写演示代码了

    
    return ((vm_page_size *vmStats.free_count) / 1024.0) / 1024.0;
    
}
-(double)deviceTotalMemory
{
    //设备全部内存（单位：MB）
    unsigned long long totalMemory=0;
//    if (_systemversion<6.0)
//    {
//        totalMemory=NSRealMemoryAvailable();
//    }
//    else
//    {
//        NSProcessInfo *processInfo=[NSProcessInfo processInfo];
//        totalMemory=processInfo.physicalMemory;
//    }
    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    totalMemory=processInfo.physicalMemory;
    
    double dResult=totalMemory/1024.0f/1024.0f;
    
    return dResult;
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
-(double)deviceTotalDiskSpace
{
    //得到设备空间大小
    //InBytes
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    struct statfs tStats;
    statfs([[paths lastObject] cString], &tStats);
    float totalSpace = (float)(tStats.f_blocks * tStats.f_bsize);
    
    return totalSpace;
}
-(double)appUsedMemory
{
    //获取当前任务所占用的内存（单位：MB）
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO,
                                         (task_info_t)&taskInfo,
                                         &infoCount);
    
    if (kernReturn != KERN_SUCCESS
        ) {
        return NSNotFound;
    }
    
    return taskInfo.resident_size / 1024.0 / 1024.0;
}

-(NSString*)deviceVersion
{
    //设备版本
    //可通过苹果review
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    //NSString *platform = [NSStringstringWithUTF8String:machine];二者等效
    free(machine);
    return platform;
}
-(BOOL)is64Bit
{
    
#if defined(__LP64__) && __LP64__
    
    return YES;
    
#else
    
    return NO;
    
#endif
    
}
-(NSString*)devicePreferredLocalizations
{
    //APP当前使用的是什么语言
    return [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    /*
     NSLocal+preferredLanguages. 可惜的是这个方法不会告诉你APP实际呈现的文字语种。你仅仅会得到iOS系统里“Settings->General->Language&Region->Preferred Language”列表中的选项
     
     NSLocal+canonicalLanguageIdentifierFromString:
     来确保你使用的文字语种是规范的语种。
     
     */
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
-(NSString *)getWifiIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}
-(void)getLANIPAddressWithCompletion:(void(^)(NSString *IPAddress))completion
{
    //ip_intranet 内网
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *IP = [self getWifiIPAddress];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(IP);
            }
        });
    });
}
-(void)getWANIPAddressWithCompletion:(void(^)(NSString *IPAddress))completion
{
    //ip_internet 外网
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *IP = @"0.0.0.0";
        NSURL *url = [NSURL URLWithString:@"http://ifconfig.me/ip"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:8.0];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error)
        {
            NSLog(@"Failed to get WAN IP Address!\n%@", error);
            //[[[UIAlertView alloc] initWithTitle:@"获取外网 IP 地址失败" message:[error localizedFailureReason] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else
        {
            NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            IP = responseStr;
            
#if !__has_feature(objc_arc)
            [responseStr autorelease];
#endif
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(IP);
        });
    });
}
-(NSDictionary*)infoFromAppStoreWithAppid:(NSString*)identifier
{
    //根据AppID，去appStore获取APP信息
    NSDictionary *dictAppVersion=nil;
    
    NSString *kAppdateUrl = @"http://itunes.apple.com/lookup";
    NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"%@?id=%@", kAppdateUrl, identifier]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
    __block NSURLResponse* urlResponse = nil;
    __block NSError *error1 = nil;
    __block NSData *responseData=nil;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        error1=error;
        urlResponse=response;
        responseData=data;
        
        dispatch_semaphore_signal(semaphore);   //发送信号
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);  //等待
    
    if (!error1 && responseData)
    {
        //请求成功
        NSError *errorJSON=nil;
        dictAppVersion = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&errorJSON];
        if (errorJSON)
        {
#ifdef DEBUG
            NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse*)urlResponse;
            NSLog(@"responseData生成json对象失败 %@\nhttpURL=%@,statusCode=%@",errorJSON,url,@(httpResponse.statusCode));
            if (responseData) {
                NSString *str1=[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"responseData=%@",str1);
            }
            
#endif
        }
    }
    else
    {
        //请求失败
#ifdef DEBUG
        NSLog(@"%@请求失败\nError=%@",url,error1);
#endif
        dictAppVersion=nil;
    }
    
    if (dictAppVersion)
    {
        int resultCount=[[dictAppVersion objectForKey:@"resultCount"] intValue];
        if (resultCount > 0)
        {
            NSArray *results=dictAppVersion[@"results"];
            if (results.count>0) {
                NSDictionary *result0=results[0];

                self.appVersionInAppStore=result0[@"version"];
                self.appTrackViewUrl=result0[@"trackViewUrl"];;
            }
        }
    }
    
    return dictAppVersion;
}
-(BOOL)isPhoneX
{
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO);
}
@end
