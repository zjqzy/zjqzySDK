//
//  NSUncaughtExceptionUtil.h
//
//  Created by zhu jianqi on 2018/9/20.
//  Copyright © 2018年 zhu jianqi. All rights reserved.
//  Email : zhu.jian.qi@163.com

/*
 
 捕捉程序异常， 并生成crash日志
 
 
 在启动函数 application:didFinishLaunchingWithOptions: 里 加入
 [[CNKI_Z_Exception sharedInstance] triggerWithHandler:nil];

 
 crash文件路径
 ”NSHomeDirectory()/Library/app_CrashLog.txt"
 
 
 */
#import <Foundation/Foundation.h>

@interface CNKI_Z_Exception : NSObject

/**
 单例

 @return 返回 self
 */
+(CNKI_Z_Exception*)sharedInstance;


/**
 Returns the top-level error handler.

 @return A pointer to the top-level error-handling function where you can perform last-minute logging before the program terminates.
 */
-(NSUncaughtExceptionHandler*)getHandler;


/**
 异常 trigger
 
 @param handler1 函数指针
 
 @see 绑定异常触发后的函数
 */
-(void)triggerWithHandler:(NSUncaughtExceptionHandler)handler1;


//////////////////////////////////////////////
//////////////////////////////////////////////
// 单例限制
// 告诉外面，alloc，new，copy，mutableCopy方法不可以直接调用。
// 否则编译不过

+(instancetype) alloc __attribute__((unavailable("call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) copy __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) mutableCopy __attribute__((unavailable("call sharedInstance instead")));

@end
