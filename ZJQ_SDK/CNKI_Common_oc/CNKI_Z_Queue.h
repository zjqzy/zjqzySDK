//
//  CNKI_Z_Queue.h
//
//  Created by zhu jianqi on 2018/9/20.
//  Copyright © 2018年 zhu jianqi. All rights reserved.
//  Email : zhu.jian.qi@163.com

/*
 
 线程池对象
 
 */

#import <Foundation/Foundation.h>

@interface CNKI_Z_Queue : NSOperationQueue


/**
 根据线程名称，找到该线程
 
 @param findName 要查找的线程名称
 @return 返回线程对象
 */
-(NSOperation*)findOperationsWithName:(NSString*)findName;


/**
 根据线程名称，找到该线程 并从线程池中 移除该线程
 
 @param findName 要查找的线程名称
 */
- (void)cancelOperationsWithName:(NSString *)findName;


/**
 根据线程名称，找到该线程 并等待线程结束
 
 @param findName 要查找的线程名称
 */
-(void)waitOperationFinishedWithName:(NSString*)findName;


/**
 挂起所有线程, 等待所有线程挂起，同步等待正在运行的线程
 */
-(void)SuspendAllThread;


/**
 得到线程池中所有线程的名称
 
 @return 数组<NSString*>，元素为线程名称
 */
-(NSArray*)getAllOperationsName;


/**
 得到当前正在运行的线程
 
 @return 返回线程名称
 */
-(NSString*)getRunningOperationName;

@end
