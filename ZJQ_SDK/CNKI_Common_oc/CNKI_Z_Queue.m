//
//  CNKI_Z_Queue.m
//


#import "CNKI_Z_Queue.h"

@implementation CNKI_Z_Queue
-(void)dealloc
{

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
}


-(NSString*)description
{
    //描述
    NSString *strDesc=[NSString stringWithFormat:@"class=%@\nname=%@\nthreadcount=%@",[NSString stringWithUTF8String:object_getClassName(self)],self.name,@(self.operations.count)];
    
    return strDesc;
}

- (id)init
{
    
    if ((self = [super init])) // Initialize
    {
        
    }
    return self;
}

-(NSOperation*)findOperationsWithName:(NSString*)findName
{
    //根据线程名称，找到该线程
    NSOperation *findOperation=nil;
    
    for (NSOperation *operation1 in self.operations)
    {
        if ([operation1.name isEqualToString:findName]) {
            findOperation=operation1;
            break;
        }
    }
    
    return findOperation;
    
}
- (void)cancelOperationsWithName:(NSString *)findName
{
    //根据线程名称，找到该线程 并从线程池中 移除该线程
    [self setSuspended:YES];
    
    NSOperation *findOp=[self findOperationsWithName:findName];
    
    if (findOp) {
        [findOp cancel];
    }
    
    [self setSuspended:NO];
}
-(void)waitOperationFinishedWithName:(NSString*)findName
{
    //根据线程名称，找到该线程 并等待线程结束
    
    NSOperation *findOp=[self findOperationsWithName:findName];
    
    if (findOp) {
        [findOp waitUntilFinished];
    }
}

-(void)SuspendAllThread
{
    //挂起所有线程, 等待所有线程挂起，同步等待正在运行的线程
    [self setSuspended:YES];
    for (NSOperation *operation1 in self.operations)
    {
        BOOL bRunning=[operation1 isExecuting];
        if (bRunning)
        {
            [operation1 waitUntilFinished];
        }
    }
    
}

-(NSArray*)getAllOperationsName
{
    //得到包含线程的关键字
    NSMutableArray *retArray=[[NSMutableArray alloc] initWithCapacity:self.operationCount];
    
    [self setSuspended:YES];
    
    for (NSOperation *operation1 in self.operations)
    {
        [retArray addObject:[NSString stringWithFormat:@"%@",operation1.name]];
    }
    
    [self setSuspended:NO];
    
    return retArray;
}

-(NSString*)getRunningOperationName
{
    //得到当前正在运行的线程
    NSString *strResult=nil;
    for (NSOperation *operation1 in self.operations)
    {
        if ([operation1 isExecuting])
        {
            strResult=[NSString stringWithFormat:@"%@",operation1.name];
            break;
        }
    }
    return strResult;
}
@end
