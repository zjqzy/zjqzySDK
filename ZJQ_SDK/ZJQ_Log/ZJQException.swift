//
//  ZJQException.swift
//
/*
 
 异常
 
 */


import Foundation


func UncaughtExceptionHandler(exception:NSException)->Void {
    
    let arrStack = exception.callStackSymbols
    let reason = exception.reason
    let name = exception.name
    
    let zjqDateFormatter = DateFormatter()
    zjqDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now1 = zjqDateFormatter.string(from: Date())
    
    let exceptionContent="\n\(now1)\n=== 异常崩溃报告 === ===\n\nname:\(name)\nreason:\(String(describing: reason))\ncallStackSymbols:\n\(arrStack.joined(separator: "\n"))\n\n\n\n"
    
    //追加写入文档
    let fileFolder = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    let fileURL = fileFolder.appendingPathComponent("app_CrashLog.txt")
    
    
    do {
        //如果文件不存在则新建一个
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        let stringToWrite = "\n" + exceptionContent
        
        //找到末尾位置并添加
        fileHandle.seekToEndOfFile()
        fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
        fileHandle.closeFile();
        
        
    } catch let error as NSError {
        print("failed to append: \(error)")
    }
    
    //后续工作
    //除了可以选择写到应用下的某个文件，通过后续处理将信息发送到服务器等
    //还可以选择调用发送邮件的的程序，发送信息到指定的邮件地址
    //或者调用某个处理程序来处理这个信息
    
}

class ZJQException: NSObject {
    
    public static func getHandler() -> NSUncaughtExceptionHandler {
        return NSGetUncaughtExceptionHandler()!;
    }
    
    
    public static func triggerWithHandler(_ handler1 : (@convention(c) (NSException) -> Void)?) {
        
        // 妈的，不起作用
        
        if handler1 != nil {
            NSSetUncaughtExceptionHandler(handler1)
        } else {
            NSSetUncaughtExceptionHandler(UncaughtExceptionHandler)
        }
        
        //
//        NSSetUncaughtExceptionHandler { (exception) in
//
//            var message:String = ""
//            message.append("错误理由：\(exception.reason!)")
//            message.append("错误详细信息：\(exception.callStackSymbols)")
//
//            print("系统bug日志记录－－－－－－－－－－－－－－－－－－－－－\n\(message)")
//        }
    }
    
}
