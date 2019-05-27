//
//  ZJQLogger.swift
//
/*
 
 日志
 控制台
 
 */

import UIKit


public class ZJQLogger {
    
    
    // log是否输出时间
    static var showLogTime:Int=1;
    
    // 日期格式
    static private var zjqDateFormatter = DateFormatter()
    static var defaultDateFormatter: DateFormatter {
        get {
            zjqDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return zjqDateFormatter
        }
    }
    
    
    /// print
    ///
    /// - Parameter item: 闭包
    final class func zPrint(_ item:@autoclosure() -> Any) {
        
        #if DEBUG
        
        if showLogTime > 0 {
            print("\(defaultDateFormatter.string(from: Date()))  \(item())")
        }
        else
        {
            print(item())
        }
        
        #endif
    }
    
    
    /// 断言
    ///
    /// - Parameters:
    ///   - predicate: bool 表达式
    ///   - message: 为false，显示内容
    ///   - file: 所在文件名
    ///   - function: 所在函数
    ///   - line: 所在行数
    static func assert(_ predicate: @autoclosure () -> Bool ,_ message: @autoclosure () -> String = String(), file: String = #file,function:String = #function, line: UInt = #line){
        #if !NDEBUG
        if !predicate() {
            
            let fileName = (file as NSString).lastPathComponent
            
            zPrint("[Assert] \(fileName):\(line) \(function) | \(message())")
            
            abort()
        }
        #endif
    }
    
    
    /// 日志
    ///
    /// - Parameters:
    ///   - message: 内容
    ///   - file: 所在文件名
    ///   - function: 所在函数
    ///   - line: 所在行数
    static func log<T>(_ message:T , file: String = #file,function:String = #function, line: UInt = #line){
        
        #if DEBUG
        
        let fileName = (file as NSString).lastPathComponent
        
        let consoleStr = "\(fileName):\(line) \(function) | \(message)"
        
        zPrint(consoleStr)
        
        #endif
    }
    
    
    /// 日志写入文件
    ///
    /// - Parameters:
    ///   - message: 内容
    ///   - file: 所在文件名
    ///   - function: 所在函数
    ///   - line: 所在行数
    static func logF<T>(_ message:T, file:String = #file, function:String = #function, line:Int = #line) {
        
        
        let fileName = (file as NSString).lastPathComponent
        let consoleStr = "\(fileName):\(line) \(function) \(message)"
        let datestr=defaultDateFormatter.string(from: Date())
 
        // 写入文件（ Caches文件夹下 zjqlog.txt ）
        let cachePath = FileManager.default.urls(for: .cachesDirectory,
                                                 in: .userDomainMask)[0]
        let logURL = cachePath.appendingPathComponent("zjqlog.txt")
        appendText(fileURL: logURL, string: "\(datestr) \(consoleStr)")
        
        #if DEBUG
        zPrint(consoleStr)
        #endif
    }
    static private func appendText(fileURL: URL, string: String) {
        do {
            //如果文件不存在则新建一个
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            let stringToWrite = "\n" + string
            
            //找到末尾位置并添加
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
            
        } catch let error as NSError {
            print("failed to append: \(error)")
        }
    }
    
    
    /// 构造
    init() {
        
    }
    deinit {
        
    }
}
