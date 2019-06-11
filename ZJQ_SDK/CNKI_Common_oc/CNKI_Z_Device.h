//
//  DeviceObject.h
//
//  Created by zhu jianqi on 2018/9/20.
//  Copyright © 2018年 zhu jianqi. All rights reserved.
//  Email : zhu.jian.qi@163.com

/*
 
 设备&应用 信息
 
 */
#import <Foundation/Foundation.h>


@interface CNKI_Z_Device : NSObject

//////////////////////////////////////////////
//////////////////////////////////////////////

/**
单例

@return 返回 self
*/
+(CNKI_Z_Device*)sharedInstance;

// 单例限制
// 告诉外面，alloc，new，copy，mutableCopy方法不可以直接调用。
// 否则编译不过

+(instancetype) alloc __attribute__((unavailable("call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) copy __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) mutableCopy __attribute__((unavailable("call sharedInstance instead")));

//////////////////////////////////////////////
//////////////////////////////////////////////

@property (strong, nonatomic) NSString *uniqueDeviceId; //设备标识符号唯一 OpenUDID,SecureUDID
@property (strong, nonatomic) NSString *uniqueDeviceName;//设备名称
@property (strong, nonatomic) NSString *systemname;      //系统版本
@property ( nonatomic) float systemversion;     //系统版本
@property (nonatomic) double deviceTotalMemory; //设备内存总大小 MB
@property (nonatomic) double deviceDpi;         //计算设备的DPI值
@property (nonatomic) float appBrightness;            //屏幕亮度
@property (strong, nonatomic) NSString *DeviceModel;  //设备类型
@property (strong, nonatomic) NSString *DeviceVersion;//设备版本
@property (strong, nonatomic) NSString *DeviceType;   //什么设备 根据尺寸 iphone4s,iphone5,ipad mini,ipad4,ipad5
@property (strong, nonatomic) NSString *appOnLine;     //是否在线
@property (nonatomic) NSInteger appLoginStatus;        //登录状态 0 未登录，1 登录ok , 2 异常 , 3 选中自动登录，但是登录不成功
@property (nonatomic) NSInteger isPhone;      //是不是 phone
@property (nonatomic) float screenScale;      //像素系数
@property (strong, nonatomic) NSArray *preferredLanguages; //当前语言环境列表 (英，中，日)

@property (strong, nonatomic) NSString *appLanguage;//APP当前语言环境, 一般返回小写 “en” 或 ”zh“

@property (atomic, strong ) NSMutableDictionary *appTokenRequestheaders;

@property (strong, nonatomic) NSString *pushToken;  //远程推送token
/////////////////////////////////////////////////////////
@property (strong, nonatomic) NSString *bundleID;   //bundle ID
@property (strong, nonatomic) NSString *appVersion;     //版本
@property (strong, nonatomic) NSString *appBuild;     //版本
@property (strong, nonatomic) NSString *appVersionInAppStore;  //appStore的版本
@property (strong, nonatomic) NSString *appName;        //
@property (strong, nonatomic) NSString *appTrackViewUrl;    //app store 下载地址

@property (strong, nonatomic) NSString *devicePlatform; //系统平台综合信息
@property (strong, nonatomic) NSString *appInfo;        //应用综合信息
@property (strong, nonatomic) NSString *osVersion;     //系统版本

@property (nonatomic) double accelerationX;  //重力感应 加速
@property (nonatomic) double accelerationY;  //重力感应
@property (nonatomic) double accelerationZ;  //重力感应

@property (nonatomic,strong) NSString *ipAddressLan;    //内网ip
@property (nonatomic,strong) NSString *ipAddressWan;    //外网ip

/////////////////////////////////////////////////////////////////////

@property (strong, nonatomic) NSString *bundlePath;   //路径
@property (strong, nonatomic) NSString *documentPath; //路径
@property (strong, nonatomic) NSString *LibraryPath;  //路径
@property (strong, nonatomic) NSString *tmpPath;      //路径
@property (strong, nonatomic) NSString *cachesPath;   //路径
@property (strong, nonatomic) NSString *ttknPath;        //程序公共路径  根
@property (strong, nonatomic) NSString *ttknThumbPath;   //程序公共路径  缩略图
@property (strong, nonatomic) NSString *ttknImageCache;  //程序公共路径  图片缓存
@property (strong, nonatomic) NSString *ttknAdPath;      //程序公共路径  广告缓存
@property (strong, nonatomic) NSString *ttknUserPath;    //用户文件夹  各个用户自己的信息 登录后刷新
@property (strong, nonatomic) NSString *epubCachePath;   //epub临时缓冲路径
@property (strong, nonatomic) NSString *epubSavePath;    //epub保存路径
@property (strong, nonatomic) NSString *fontsPath;    //下载字体保存路径
@property (strong, nonatomic) NSString *epubFontsPath;    //下载epub8种字体保存路径


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


-(double)batteryElectricity;    //电池电量
-(NSString*)getBatteryState;    //电池状态
-(double)getDeviceDpi;          //设备DPI 
-(double)deviceAvailableMemory; //设备可用内存
-(double)deviceTotalMemory;     //设备全部内存
-(long long)deviceFreeSpace;    //得到设备空闲空间大小
-(double)deviceTotalDiskSpace;  //得到设备空间大小
-(double)appUsedMemory;         //获取当前任务所占用的内存（单位：MB）
-(NSString*)deviceVersion;      //设备版本
-(BOOL)is64Bit;                 //设备是否支持64位
-(NSString*)devicePreferredLocalizations;   //APP当前使用的是什么语言
-(NSString*)getCountryCode;     //国家环境
-(NSString*)getLanguageCode;    //设备语言



-(NSString*)getWifiIPAddress;              //得到wifi网ip
-(void)getLANIPAddressWithCompletion:(void(^)(NSString *IPAddress))completion;//ip_intranet
-(void)getWANIPAddressWithCompletion:(void(^)(NSString *IPAddress))completion;//ip_internet

-(NSDictionary*)infoFromAppStoreWithAppid:(NSString*)identifier;

-(BOOL)isPhoneX;

@end



