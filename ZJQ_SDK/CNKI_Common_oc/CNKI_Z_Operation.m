//
//  CNKI_Z_Operation.m
//

#import "CNKI_Z_Operation.h"

@interface CNKI_Z_Operation ()

@end

@implementation CNKI_Z_Operation

-(void)dealloc
{
//#ifdef DEBUG
//    NSLog(@"析构 Operation = %@",self.name);
//#endif
    
    self.target=nil;
    self.action=nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif

}
-(NSString*)description
{
    //描述
    NSString *strDesc=[NSString stringWithFormat:@"class=%@\nName=%@\nParam=%@",[NSString stringWithUTF8String:object_getClassName(self)],self.name,_dictPara];
    
    return strDesc;
}

- (id)init
{
	if ((self = [super init])) // Initialize
	{
        _target=nil;
        _action=nil;
        
	}
	return self;
}

-(void)main
{
    //启动运行
    if (self.target && self.action) {
        //arc 环境下 会有警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:_dictPara];
#pragma clang diagnostic pop
    }
}

@end
