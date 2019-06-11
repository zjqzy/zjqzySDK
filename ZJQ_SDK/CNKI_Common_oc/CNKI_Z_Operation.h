//
//  CNKI_Z_Operation.h
//
/*
 
 线程执行对象
 
 */


#import <Foundation/Foundation.h>

@interface CNKI_Z_Operation : NSOperation

/**
 参数
 @see 传递进来的参数，在 action 属性中 用到
 */
@property (strong) NSMutableDictionary *dictPara;


/**
 运行对象
 */
@property (weak) id target;


/**
 线程执行函数
 */
@property SEL action;

@end
