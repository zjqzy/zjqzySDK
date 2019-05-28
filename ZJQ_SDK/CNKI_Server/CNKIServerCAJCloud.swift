//
//  CNKIServerCAJCloud.swift
//
/*
 
 CAJ云阅读 后台
 
 */

import UIKit
import CommonCrypto;

public class CNKIServerCAJCloud: NSObject,URLSessionDelegate {

    
    /// 服务地址
    public var cnki_cajcloud_Server:String = "";
    
    /// 产品标识  （开发者）
    public var appKey:String = "";
    public var appSecretKey:String = "";
    
    /// 云后台，授权得到
    public var cloudAuth:String = "";
    
    /// 与服务器时间差,单位秒
    private var timeDifference:Double = 0;
    
    /// 请求时间戳
    private var cajcloudTimeStamp:String = "0"
    
    // MARK: - 计算属性 -
    var nowServerTimeStamp : String {
        
        // 返回 秒
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let timeStamp = Int(timeInterval-self.timeDifference)
        return "\(timeStamp)"
        
    }
    
    var nowServerTimeStamp_Millisecond : String {
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
    }
    
    //析构 销毁对象
    deinit {
        
        ZJQLogger.zPrint("析构: \(type(of: self))")
        
        //        print("deinit: \(type(of: self))")
        //        print("deinit: \(NSStringFromClass(type(of: self)).components(separatedBy: ".").last!)")
        //        NSLog("%@", self); //fail 写self 报错
        //        NSLog("%@", self.description); //ok
        
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
    public func URLPerform(httpURL:String,sign:String,timestamp:String,body:Data?) -> Dictionary<String,Any>? {
        
        var dictRet:Dictionary<String,Any>?
        
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
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        // 设置信号开始
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask=session.dataTask(with: request) { (data, response, error) in
            
            if error != nil{
                ZJQLogger.zPrint("\(error!)");
            } else {
                
                dictRet = self.dictFromResponseData(data:data!, msg:httpURL)
                if dictRet == nil {
                    let str = String(data: data!, encoding: String.Encoding.utf8)
                    ZJQLogger.zPrint("请求成功，数据json失败:\(str!)");
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
