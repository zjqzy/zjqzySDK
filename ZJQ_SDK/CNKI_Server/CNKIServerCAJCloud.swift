//
//  CNKIServerCAJCloud.swift
//
/*
 
 CAJ云阅读 后台
 
 */


import Foundation
import CommonCrypto


public let k_notification_cajcloud_error: String = "k_notification_cajcloud_request_error"  // 通知


open class CNKIServerCAJCloud: NSObject,URLSessionDelegate {
    
    /// 服务地址
    open var cnki_cajcloud_Server:String = "";
    open func z_Server(_ url : String?) -> CNKIServerCAJCloud?{
        
        if url != nil {
            self.cnki_cajcloud_Server=url!;
            return self;
        }
        return nil;
    }
    
    /// 产品标识  （开发者）
    open var appKey:String = "";
    open func z_appKey(_ key:String?) -> CNKIServerCAJCloud? {
        if key != nil {
            self.appKey=key!;
            return self;
        }
        return nil;
    }
    
    /// 产品标识  （开发者）
    open var appSecretKey:String = "";
    open func z_appSecretKey(_ secretKey:String?) -> CNKIServerCAJCloud? {
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
    /// 对请求是否为自己人的再次判断
    open var cloudAuth:String = "";
    
    
    /// 语言环境 Language environment ， 当请求出现错误时，影响返回的message
    /// 无论什么环境，都会返回英文错误描述， 追加 其他语言的描述，如message（默认message,英文），message_cn,message_jp等
    /// 如果为空，则只返回英文描述，message，没有message_cn,message_jp等
    open var app_language_environment:String = "cn"
    
    
    /// 当请求出错时，尝试次数
    open var repeatRequestWhenError:Int=0;
    
    /// 额外传递的文件头信息
    open var dictHeaderExtra:Dictionary<String,String>?
    
    /// 属性block
    //public typealias blocktype1 = (_ paramOne : String? ) -> () //ok
    //public var block1:blocktype1?;  //ok
    open var block_custom:((_ para1:Dictionary<String,Any>? )->Any)?
    
    /// 与服务器时间差,单位秒
    var timeDifference:Double = 0;
    
    /// 请求时间戳
    var cajcloudTimeStamp:String = "0"
    
    /// json
    var dictAllInfo:Dictionary<String,Any>?
    var dictCAJCloud:Dictionary<String,Any>?
    
    
    // MARK: - 计算属性 -
    public var nowServerTimeStamp : String {
        
        // 返回 秒
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let timeStamp = Int(timeInterval-timeDifference)
        return "\(timeStamp)"
        
    }
    
    public var nowServerTimeStamp_Millisecond : String {
        // 返回 毫秒
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let millisecond = CLongLong(round((timeInterval-timeDifference)*1000))
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
            
            var item:Dictionary<String,Any>=dictionaryFromArray(fields: cells as! Array<Dictionary<String, Any>>);
            
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
                // 这里数据修正，越早越好
                
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
    public func URLPerform(httpURL:String,sign:String,timestamp:String,body:Data?,otherInfo:Dictionary<String,Any>?=nil) -> Dictionary<String,Any> {
        
        precondition(httpURL.count > 0, "【\(#function)】 httpURL Must have value.")
        precondition(sign.count > 0, "【\(#function)】 sign Must have value.")
        precondition(timestamp.count > 0, "【\(#function)】 timestamp Must have value.")
        
        var dictRet:Dictionary<String,Any> = [:]
        
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
        request.setValue(self.app_language_environment, forHTTPHeaderField:"app_language_environment")
        
        if self.dictHeaderExtra != nil {
            for (key,value) in self.dictHeaderExtra!{
                request.setValue(value, forHTTPHeaderField:key)
            }
        }
        
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
            
            if timeout > 1 {
                config.timeoutIntervalForRequest = timeout   //默认60
            }
        }
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        // 设置信号开始
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask=session.dataTask(with: request) { (data, response, error) in
            
            if error != nil{
                
                dictRet["CAJErrorCode"]="-180001"
                dictRet["CAJErrorMsg"]="\(error!)"
                
                ZJQLogger.zPrint("\(error!)");
                
            } else {
                
                let dictJson = self.dictFromResponseData(data:data!, msg:httpURL)
                if dictJson == nil {
                    
                    let str = String(data: data!, encoding: String.Encoding.utf8)
                    
                    dictRet["CAJErrorCode"]="-180002"
                    dictRet["CAJErrorMsg"]="请求成功，转换json失败：\(str!)"
                    
                    ZJQLogger.zPrint("请求成功，转换json失败:\(str!)");
                    
                }
                else
                {
                    
                    // 错误号
                    dictRet=dictJson!;
                    
                    let cajErrorCode = dictRet["errorcode"] ?? dictRet["errcode"]
                    if cajErrorCode != nil {
                        
                        //dictRet["CAJErrorCode"]="\(String(describing: cajErrorCode))"
                        dictRet["CAJErrorCode"]="\(cajErrorCode!)"
                        
                        let cajErrorMsg = dictRet["message+\(self.app_language_environment)"] ?? dictRet["message"] ?? "unknown error"
                        
                        dictRet["CAJErrorMsg"]=cajErrorMsg
                        
                    }
                }
            }
            
            _ = semaphore.signal()
            
            } as URLSessionTask;
        
        //使用resume方法启动任务
        dataTask.resume()
        //等待完成..
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return dictRet;
    }
    
    
    /// 请求
    ///
    /// - Parameters:
    ///   - key: 请求key
    ///   - postdata: 参数
    /// - Returns: 返回结果或nil
    public func invoke(key:String,postdata:Dictionary<String,Any>?)->Dictionary<String,Any>? {
        
        precondition(key.count > 0, "【\(#function)】 key Must have value.")
        
        var dictRet:Dictionary<String, Any>?=nil
        
        let dictInfo:Dictionary<String,Any>?=dictCAJCloud?[key] as? Dictionary<String, Any>;
        
        guard dictInfo != nil else {
            return dictRet;
        }
        
        let path:String=(dictInfo?["path"] as? String) ?? ""
        
        cajcloudTimeStamp=nowServerTimeStamp;
        
        let sign1 = "\(cajcloudTimeStamp)\(appKey)"
        let sign = sha1(src:sign1)
        
        let httpURL="\(cnki_cajcloud_Server)\(path)"
        
        var body:Data?=nil;
        if postdata != nil {
            body=try? JSONSerialization.data(withJSONObject: postdata!, options: .prettyPrinted)
        }
        
        // 执行
        dictRet=URLPerform(httpURL: httpURL, sign: sign, timestamp: cajcloudTimeStamp, body: body, otherInfo: dictInfo)
        
        var error1:String? = dictRet?["CAJErrorCode"] as? String
        
        // 尝试请求次数
        repeatRequestWhenError=1;
        let maxRepeatRequestWhenError:Int = Int("\(dictInfo?["maxRepeatRequestWhenError"] ?? 0)") ?? 0
        let whichErrorCanRepeat:String = (dictInfo?["whichErrorCanRepeat"] as? String) ?? ""
        
        while error1 != nil
            &&  maxRepeatRequestWhenError>repeatRequestWhenError
        {
            
            if whichErrorCanRepeat.count>0 && error1 != nil {
                let range1 = whichErrorCanRepeat.range(of: error1!)
                if range1 == nil {
                    break;
                }
            }
            
            repeatRequestWhenError += 1;
            dictRet=URLPerform(httpURL: httpURL, sign: sign, timestamp: cajcloudTimeStamp, body: body, otherInfo: dictInfo)
            
            error1 = dictRet?["CAJErrorCode"] as? String
        }
        
        // 通知
        let canNotification:Int = Int("\(dictInfo?["notificationWhenError"] ?? 0)") ?? 0
        if error1 != nil
            && canNotification > 0
        {
            var notifyPara:Dictionary<String,Any>=[:]
            notifyPara["key"]=key
            notifyPara["postdata"]=postdata
            notifyPara["httpURL"]=httpURL
            notifyPara["sign"]=sign
            notifyPara["timestamp"]=cajcloudTimeStamp
            notifyPara["error"]=error1;
            
            NotificationCenter.default.post(name: Notification.Name.init(k_notification_cajcloud_error), object: nil, userInfo: notifyPara)
        }
        
        return dictRet;
        
    }
    
    
    /// 错误请求重发机制
    ///
    /// - Parameter itemPara: 特定参数
    /// - Returns: 返回结果或nil
    public func invoke_error_redo(itemPara:Dictionary<String,Any>)->Dictionary<String,Any>? {
        
        let key:String=(itemPara["key"] as? String) ?? ""
        let postdata:Dictionary<String, Any>=itemPara["postdata"] as! Dictionary<String, Any>
        //let httpURL:String=itemPara["httpURL"] as! String
        //let sign:String=itemPara["sign"] as! String
        //let timestamp:String=itemPara["timestamp"] as! String
        //let error=itemPara["error"]
        
        if key.count > 0 {
            return invoke(key: key, postdata: postdata)
        }
        return nil;
        
    }
}

