//
//  CNKIServerOData.swift
//
/*

 CNKI OData查询服务
 
 */

import UIKit;
import CommonCrypto;

open class CNKIServerOData: NSObject {
    
    // MARK: - 存储属性 -
    /// 配置
    private var cnki_odata_Server:String = "";
    
    /// 产品标识  （开发者）
    var appKey:String = "";
    var appSecretKey:String = "";
    
    /// 请求附加信息，可直接默认值
    var deviceIP:String = "127.8.8.8";
    var deviceID:String = "{123456}";
    var phoneNumber:String = "";
    var deviceLocation:String = "0,0";
    
    /// 云后台，授权得到
    var cloudAuth:String = "";
    
    /// 与服务器时间差,单位秒
    private var timeDifference:Double = 0;
    
    /// 请求时间戳
    private var odataTimeStamp:String = "0"
    
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
    static private let _sharedInstance = CNKIServerOData()
    public class var sharedInstance : CNKIServerOData {
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
    public func URLPerform(httpURL:String,sign:String,body:String = "") -> Dictionary<String,Any>? {
        
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
        request.setValue(self.odataTimeStamp,forHTTPHeaderField:"timestamp")
        request.setValue(sign, forHTTPHeaderField:"sign")
        request.setValue(self.deviceIP, forHTTPHeaderField:"ip")
        request.setValue(self.deviceLocation, forHTTPHeaderField:"location")
        request.setValue(self.deviceID, forHTTPHeaderField:"did")
        request.setValue(self.phoneNumber, forHTTPHeaderField:"mobile")
        
        request.setValue(self.cloudAuth, forHTTPHeaderField:"CloudAuth")
        let cookie1="cloud_session=\(self.cloudAuth)"
        request.setValue(cookie1, forHTTPHeaderField:"Cookie")
        
        // post
        if body.count>0 {
            
            request.httpMethod = "POST"
            
//            // 设置要post的内容，字典格式
//            let postData = ["name":"1","password":"2"]
//            let postString = postData.compactMap({ (key, value) -> String in
//                return "\(key)=\(value)"
//            }).joined(separator: "&")
//            request.httpBody = postString.data(using: .utf8)
            request.httpBody=body.data(using: .utf8);
        }

        
        // 开始请求
//        let config = URLSessionConfiguration.default
//        let session = URLSession(configuration: config)
        let session = URLSession.shared
        
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
            
//            DispatchQueue.main.async{
//
//            }

            
            } as URLSessionTask;
        
        //使用resume方法启动任务
        dataTask.resume()
        //等待完成..
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        
        return dictRet;
    }
    
    // MARK: - 扩展 -
    public func search(type:String,fields:String,query:String = "",group:String = "",order:String = "",start:String = "0" ,length:String = "20")->Dictionary<String, Any>?{
        
        var dictRet:Dictionary<String, Any>?
        
        
        self.odataTimeStamp=self.nowServerTimeStamp;
        
        let sign1="timestamp=\(self.odataTimeStamp)&appid=\(self.appKey)&appkey=\(self.appSecretKey)&ip=\(self.deviceIP)&location=\(self.deviceLocation)&mobile=\(self.phoneNumber)&did=\(self.deviceID)&op=data_gets&type=\(type)&fields=\(fields)&query=\(query)&group=\(group)&order=\(order)"
        
        let sign = self.sha1(src:sign1)

        let httpURL = "\(self.cnki_odata_Server)/api/db/\(type)?fields=\(fields)&query=\(query)&group=\(group)&order=\(order)&start=\(start)&length=\(length)"
        
        dictRet=self.URLPerform(httpURL: httpURL , sign: sign)
        
        return dictRet;
    }
}
