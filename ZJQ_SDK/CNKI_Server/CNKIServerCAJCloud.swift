//
//  CNKIServerCAJCloud.swift
//
/*
 
 CAJ云阅读 后台
 
 */

import UIKit
import CommonCrypto;


/// 通知
public let k_notification_cajcloud_error: String = "k_notification_cajcloud_request_error"


///
open class CNKIServerCAJCloud: NSObject,URLSessionDelegate {

    
    /// 服务地址
    public var cnki_cajcloud_Server:String = "";
    public func z_Server(_ url : String?) -> CNKIServerCAJCloud?{
        
        if url != nil {
           self.cnki_cajcloud_Server=url!;
            return self;
        }
        return nil;
    }
    
    /// 产品标识  （开发者）
    public var appKey:String = "";
    public func z_appKey(_ key:String?) -> CNKIServerCAJCloud? {
        if key != nil {
            self.appKey=key!;
            return self;
        }
        return nil;
    }
    
    public var appSecretKey:String = "";
    public func z_appSecretKey(_ secretKey:String?) -> CNKIServerCAJCloud? {
        if secretKey != nil {
            self.appSecretKey=secretKey!;
            
//            if self.block_custom != nil {
//                var para1:Dictionary<String,Any>=[:]
//                para1["a"]="靠"
//                _=self.block_custom?(para1);
//            } //测试ok
            
            return self;
        }
        return nil;
    }
    
    /// 云后台，授权得到
    public var cloudAuth:String = "";
    
    
    /// 属性block
    //public typealias blocktype1 = (_ paramOne : String? ) -> () //ok
    //public var block1:blocktype1?;  //ok
    public var block_custom:((_ para1:Dictionary<String,Any>? )->Any)?
    
    /// 与服务器时间差,单位秒
    private var timeDifference:Double = 0;
    
    /// 请求时间戳
    private var cajcloudTimeStamp:String = "0"
    
    /// json
    private var dictAllInfo:Dictionary<String,Any>?
    private var dictCAJCloud:Dictionary<String,Any>?
    
    
    // MARK: - 计算属性 -
    public var nowServerTimeStamp : String {
        
        // 返回 秒
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let timeStamp = Int(timeInterval-self.timeDifference)
        return "\(timeStamp)"
        
    }
    
    public var nowServerTimeStamp_Millisecond : String {
        // 返回 毫秒
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let millisecond = CLongLong(round((timeInterval-self.timeDifference)*1000))
        return "\(millisecond)"
    }
    
    // MARK: - 单例 -
    //单例 Sington
    static private let _sharedInstance = CNKIServerCAJCloud()
    
    public class var sharedInstance : CNKIServerCAJCloud {
        
        return _sharedInstance
    }
    
    //私有化init方法
    //避免外部对象通过访问init方法创建单例类的其他实例
    private
    override init() {
        //print("init \(#function)");
        super.init();
        
        // json
        let bundle:Bundle=Bundle(for: type(of: self));
        let jsonFile:String?=bundle.path(forResource: "cnki_server", ofType: "json", inDirectory: "cnki_server.bundle");

        if jsonFile != nil {
            _=self.load(jsonFilePath: jsonFile!)
        }
    }
    
    //析构 销毁对象
    deinit {
        
        ZJQLogger.zPrint("析构: \(type(of: self))")
        
        //        print("deinit: \(type(of: self))")
        //        print("deinit: \(NSStringFromClass(type(of: self)).components(separatedBy: ".").last!)")
        //        NSLog("%@", self); //fail 写self 报错
        //        NSLog("%@", self.description); //ok
        
    }
    public func load(jsonFilePath:String)->Dictionary<String,Any>?{
        // 读取json
        var dictRet:Dictionary<String,Any>?
        
        let fileManager = FileManager.default

        //let jsonFilePath = Bundle.main.path(forResource: fileNameStr, ofType: type);
        if !fileManager.fileExists(atPath: jsonFilePath) {
            return dictRet
        }
        
        //let url = URL.init(string: jsonFilePath)
        let url = URL.init(fileURLWithPath: jsonFilePath)
        //let txtData = fileManager.contents(atPath: url!.path)
        
        do {
            /*
             * try 和 try! 的区别
             * try 发生异常会跳到catch代码中
             * try! 发生异常程序会直接crash
             */
            
            let data = try Data(contentsOf: url)
            //let dataString = String(data: data, encoding: String.Encoding.utf8)
            dictRet = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, Any>
            
        } catch let error as Error? {
            ZJQLogger.zPrint(error?.localizedDescription ?? "读取json失败")
            dictRet = nil;
        }
        
        if dictRet != nil {
            self.dictAllInfo=dictRet;
            self.dictCAJCloud=self.dictAllInfo?["cajcloud"] as? Dictionary<String, Any>;
        }
        
        return dictRet;
        
    }
    
    // MARK: - 基础方法 -
    public func sha1(src:String) -> String{
        
        // sha1s
        
        let data1:Data! = src.data(using: String.Encoding.utf8, allowLossyConversion: true);
        
        
        var digest=[UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        let bytes = [UInt8](data1)
        let len = data1.count;
        
        CC_SHA1(bytes, CC_LONG(len), &digest)
        
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest{
            output.appendFormat("%02x", byte)
        }
        return output as String
    }
    public func dictionaryFromArray(fields:Array<Dictionary<String, Any>>)->Dictionary<String,Any>{
        
        var rowInfo:Dictionary<String,Any>=[:]
        for field in fields {
            
            let name:String = field["Name"] as! String;
            let value = field["Value"]
            
            if name.count > 0 && value != nil {
                rowInfo[name]=value
            }
            
        }
        
        return rowInfo;
    }
    public func rowsEditFromRows(rows:Array<Dictionary<String, Any>>) -> Array<Any> {
        
        var arrRet:Array<Any>=Array<Any>()
        
        for row in rows {
            let cells=row["Cells"]
            
            var item:Dictionary<String,Any>=self.dictionaryFromArray(fields: cells as! Array<Dictionary<String, Any>>);
            
            if  item.keys.count>0 {
                item["Id"]=row["Id"]
                item["Type"]=row["Type"]
                
                arrRet.append(item)
            }
        }
        
        return arrRet;
    }
    public func dictFromResponseData( data:Data,msg:String)->Dictionary<String, Any>?{
        
        var dictRet:Dictionary<String, Any>?
        
        do {
            try dictRet=JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any>
            
            //let aa = (( dictRet?["result"] as? Int ) ?? 0 )
            if (( dictRet?["result"] as? Int ) ?? 0 ) > 0{
                // 前期数据纠正
                
            }
            
        } catch  {
            
            let strError = "dictFromResponseData错误json转换\n信息：\(msg)\n错误：\(error)"
            ZJQLogger.zPrint(strError);
        }
        
        return dictRet;
    }
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // 单向认证
        if challenge.protectionSpace.authenticationMethod
            == (NSURLAuthenticationMethodServerTrust) {
            //print("服务端证书认证！")
            
            let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
            //let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
            let credential = URLCredential(trust: serverTrust)
            
            challenge.sender!.continueWithoutCredential(for: challenge)
            challenge.sender?.use(credential, for: challenge)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential,URLCredential(trust: challenge.protectionSpace.serverTrust!))
            
        }
    }
    
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
//
//        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
//
//        var credential:URLCredential? = nil
//        /*disposition：如何处理证书
//         performDefaultHandling:默认方式处理
//         useCredential：使用指定的证书
//         cancelAuthenticationChallenge：取消请求
//         */
//
//        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//            credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
//
//            if credential != nil {
//                disposition = URLSession.AuthChallengeDisposition.useCredential
//            }
//        }else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
//            //单向验证，客户端不需要服务端验证，此处与默认处理一致即可
//            disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
//        }
//        else {
//            disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
//        }
//
//        completionHandler(disposition, credential)
//
//    }
    public func URLPerform(httpURL:String,sign:String,timestamp:String,body:Data?,otherInfo:Dictionary<String,Any>?=nil) -> Dictionary<String,Any>? {
        
        var dictRet:Dictionary<String,Any>?
        
        var notifyPara:Dictionary<String,Any>=[:]
        notifyPara["httpURL"]=httpURL
        notifyPara["timestamp"]=timestamp
        if body != nil {
            notifyPara["body"]=body!
        }
        
        //        let charSet = NSMutableCharacterSet()
        //        charSet.formUnion(with: CharacterSet.urlQueryAllowed)
        //        charSet.addCharacters(in: "#")  // 不转的符号
        //        let str1 = httpURL.addingPercentEncoding(withAllowedCharacters: charSet as CharacterSet)
        
        var str1 = httpURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        //var cs=NSCharacterSet(charactersIn:"`#%^{}\"[]|\\<>//").inverted
        let cs=NSCharacterSet(charactersIn:"+").inverted
        str1=str1?.addingPercentEncoding(withAllowedCharacters: cs);
        
        var request = URLRequest(url: URL(string: str1!)!)
        
        // 请求头
        //request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(self.appKey, forHTTPHeaderField:"app_id")
        request.setValue(timestamp,forHTTPHeaderField:"timestamp")
        request.setValue(sign, forHTTPHeaderField:"sign")
        request.setValue(self.cloudAuth, forHTTPHeaderField:"CloudAuth")
        
        // post
        
        if body != nil {
            
            request.httpMethod = "POST"
            request.httpBody=body
        }
        
        // 开始请求
//        let session = URLSession.shared
        let config = URLSessionConfiguration.default
        if otherInfo != nil {

            let timeout:TimeInterval = TimeInterval(otherInfo?["timeout"] as! String) ?? 0
            config.timeoutIntervalForRequest = max(timeout, 30.0)   //默认60
        }
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        // 设置信号开始
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask=session.dataTask(with: request) { (data, response, error) in
            
            if error != nil{
                
                notifyPara["error"]="\(error!)"
                NotificationCenter.default.post(name: Notification.Name.init(k_notification_cajcloud_error), object: nil, userInfo: notifyPara)
                
                ZJQLogger.zPrint("\(error!)");
                
            } else {
                
                dictRet = self.dictFromResponseData(data:data!, msg:httpURL)
                if dictRet == nil {
                    
                    let str = String(data: data!, encoding: String.Encoding.utf8)
                    ZJQLogger.zPrint("请求成功，数据json失败:\(str!)");
                    
                    notifyPara["error"]="请求成功，数据json失败:\(str!)"
                    
                }
            }
            
            _ = semaphore.signal()

            } as URLSessionTask;
        
        //使用resume方法启动任务
        dataTask.resume()
        //等待完成..
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        // 通知
        let canNotification:Int = (otherInfo?["notificationWhenError"] as? Int) ?? 0
        let error1:String? = notifyPara["error"] as? String
        if error1 != nil
            && canNotification > 0
        {
            NotificationCenter.default.post(name: Notification.Name.init(k_notification_cajcloud_error), object: nil, userInfo: notifyPara)
        }
        
        
        return dictRet;
    }
    
    // MARK: - 扩展 -
    public func request_cajcloud(key:String,postdata:Dictionary<String,Any>?)->Dictionary<String,Any>? {
        
        var dictRet:Dictionary<String, Any>?=nil
        
        let dictInfo:Dictionary<String,Any>?=self.dictCAJCloud?[key] as? Dictionary<String, Any>;
        
        guard dictInfo != nil else {
            return dictRet;
        }
        
        let path:String=(dictInfo?["path"] as? String) ?? ""
        
        self.cajcloudTimeStamp=self.nowServerTimeStamp;
        
        let sign1 = "\(self.cajcloudTimeStamp)\(self.appKey)"
        let sign = self.sha1(src:sign1)
        
        let httpURL="\(self.cnki_cajcloud_Server)\(path)"
        
        // post数据
        var body:Data?=nil;
        if postdata != nil {
            body=try? JSONSerialization.data(withJSONObject: postdata!, options: .prettyPrinted)
        }
        
        // 执行
        dictRet=self.URLPerform(httpURL: httpURL, sign: sign, timestamp: self.cajcloudTimeStamp, body: body, otherInfo: dictInfo)
        
        return dictRet;
        
    }
    
    
    public func Login(username:String,password:String,platform:String,clientid:String,version:String) -> Dictionary<String,Any>? {
        
        var dictRet:Dictionary<String, Any>?
        
        guard username.count>0 else {
            return dictRet;
        }
        
        self.cajcloudTimeStamp=self.nowServerTimeStamp;
        
        let sign1 = "\(self.cajcloudTimeStamp)\(self.appKey)"
        let sign = self.sha1(src:sign1)
        
        let httpURL="\(self.cnki_cajcloud_Server)/users/login"
        
        // post数据
        var para1:Dictionary<String,String>=Dictionary<String,String>()
        para1["username"]=username;
        para1["password"]=password;
        para1["platform"]=platform;
        para1["clientid"]=clientid;
        para1["version"]=version;
        let body=try! JSONSerialization.data(withJSONObject: para1, options: .prettyPrinted)
        
        // 执行
        dictRet=self.URLPerform(httpURL: httpURL, sign: sign, timestamp: self.cajcloudTimeStamp, body: body)
        
        return dictRet;
        
    }
}
