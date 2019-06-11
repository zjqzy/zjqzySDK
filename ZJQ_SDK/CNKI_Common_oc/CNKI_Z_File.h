//
//  CNKI_Z_File.h
//
//  Created by zhu jianqi on 2018/9/20.
//  Copyright © 2018年 zhu jianqi. All rights reserved.
//  Email : zhu.jian.qi@163.com

/*
 
 IO 库

 文件 文件夹等相关方法
 
 */

#import <Foundation/Foundation.h>

@interface CNKI_Z_File : NSObject

//////////////////////////////////////////////
//////////////////////////////////////////////

/**
 单例
 
 @return 返回 self
 */
+(CNKI_Z_File*)sharedInstance;

// 单例限制
// 告诉外面，alloc，new，copy，mutableCopy方法不可以直接调用。
// 否则编译不过

+(instancetype) alloc __attribute__((unavailable("call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) copy __attribute__((unavailable("call sharedInstance instead")));
-(instancetype) mutableCopy __attribute__((unavailable("call sharedInstance instead")));

//////////////////////////////////////////////
//////////////////////////////////////////////

-(NSString*)contentTypeForImageData:(NSData *)data;//通过图片Data数据第一个字节 来获取图片扩展名
-(BOOL)fileIsPDF:(NSString *)filePath;  //是否为PDF文件
-(NSInteger)fileEncoding:(NSString*)fileFullPath; //内容编码格式 {0 ansi,1 unicode,2 utf8}
-(long long)fileSizeAtPath:(NSString *)path;        //文件大小
- (float)folderSizeAtPath:(NSString*) folderPath;   //文件夹大小

-(BOOL)createDirectory:(NSString*)strFolderPath;    //创建文件夹
-(void)makeDirs:(NSString*)strFolderPath;            //创建文件夹,自动多级创建
-(BOOL)deleteFileAtPath:(NSString*)path;                                    //删除
-(BOOL)moveFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath;    //移动
-(BOOL)copyFileFromPath:(NSString*)oldPath ToNewPath:(NSString*)newPath;    //拷贝
-(BOOL)deleteDirectory:(NSString*)strFolderPath DelSelf:(BOOL)bDelSelf; //删除文件夹（自身是否删除）

-(NSMutableArray*)getFolderFiles:(NSString*)fileFullPath;//得到文件 下 子文件列表
-(NSMutableArray*)getFolderFileListWithFolderPath:(NSString *)folderFullPath HaveSuffix:(NSArray*)arrSuffix;
-(NSString*)fileParentFolder:(NSString*)fileFullPath;//得到文件父文件夹
-(BOOL)fileIsExist:(NSString *)path;        //文件是否存在
-(BOOL)isFileExist:(NSString *)path;
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName; //查找文件 根据名称，返回绝对路径
-(NSString*)fileFindFullPathWithFileName:(NSString*)fileName InDirectory:(NSString*)inDirectory;    //查找文件

-(BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)path; //文件属性
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL*)URL;//文件取消iCloud 的backup属性，设为不备份
-(BOOL)isFileHaveBackupAttributeAtPath:(NSString *)path;    //文件属性
-(BOOL)isFileHaveBackupAttributeAtURL:(NSURL *)URL;         //文件属性

-(NSString*)fileMd5:(NSString *)path;       //md5 , 根据整个文件内容计算
-(NSString*)fileCRC:(NSString*)path;        //crc 压缩
-(NSString*)dataCRC:(NSData*)data1;         //crc

-(NSString*)fileContent:(NSString*)fileFullPath;        //得到内容
-(NSData*)fileContentData:(NSString*)fileFullPath;      //得到内容
-(int)fileAppendData:(NSData*)appendData FileFullPath:(NSString*)fileFullPath; //文件内容追加
-(NSMutableDictionary*)fileInfoWithPath:(NSString*)fileFullPath;

@end
