//
//  CNKIServerECP.swift
//
/*
 
 CNKI 电商服务
 
 */

import UIKit

open class CNKIServerECP: NSObject {
    
    // MARK: - 存储属性 -
    /// 电商服务地址
    open var cnki_ecp_Server:String = "";
    
    /// token服务地址
    open var cnki_token_Server:String = "";
    
    /// 令牌（产品标识）
    private var cnki_ecp_token:String = "";
    
    /// 产品标识  （开发者）
    open var appKey:String = "";
    open var appSecretKey:String = "";
    
    open func z_initPare(_ server:String) -> (_ tokenServer:String) -> (_ appkey:String) -> ( _ secretKey:String) ->Void {
        
        return {(_ tokenServer:String) -> (_ appkey:String) -> ( _ secretKey:String) ->Void in
            return { (_ appkey:String) -> (_ secretKey:String) ->Void in
                return {  (_ secretKey:String) ->Void in
                    self.cnki_ecp_Server=server;
                    self.cnki_token_Server=tokenServer;
                    self.appKey=appkey
                    self.appSecretKey=secretKey;
                }
            }
        }
    }
    
    // MARK: - 单例 -
    //单例 Sington
    static private let _sharedInstance = CNKIServerECP()
    public class var sharedInstance : CNKIServerECP {
        return _sharedInstance
    }
    
    
    //构造 私有化init方法
    //避免外部对象通过访问init方法创建单例类的其他实例
    private
    override init() {
        super.init()
    }
    
    //析构 销毁对象
    deinit {
        ZJQLogger.zPrint("析构: \(type(of: self))")
    }
    
    // MARK: - 基础方法 -
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
    public func tokenRefresh()->Dictionary<String,Any>?{
        
        //var dictRet:Dictionary<String,Any>=Dictionary<String,Any>();
        var dictRet:Dictionary<String,Any>?
        
        let httpURL = cnki_token_Server.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        var request = URLRequest(url: URL(string: httpURL!)!)
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        
        // post
        request.httpMethod = "POST"
        let body1:String="client_id=\(appKey)&client_secret=\(appSecretKey)&grant_type=client_credentials"
        request.httpBody = body1.data(using: .utf8);
        
        // 开始请求
        let session = URLSession.shared
        
        // 设置信号开始
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask=session.dataTask(with: request) { (data, response, error) in
            
            if error != nil{
                ZJQLogger.zPrint("\(error!)");
            } else {
                
                dictRet = self.dictFromResponseData(data:data!, msg:httpURL!)!
                if dictRet == nil {
                    let str = String(data: data!, encoding: String.Encoding.utf8)
                    ZJQLogger.zPrint("请求成功，数据json失败:\(str!)");
                } else {
                    //成功
                    let access_token1:String?=dictRet?["access_token"] as? String;
                    if access_token1 != nil {
                        self.cnki_ecp_token=access_token1!
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
    public func URLPerform(httpURL:String,body:String = "") -> Dictionary<String,Any>? {
        
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
        if self.cnki_ecp_token.count < 2 {
            _ = self.tokenRefresh();
        }
        
        let sign = "Bearer \(self.cnki_ecp_token)"
        request.setValue(sign, forHTTPHeaderField:"Authorization")
        
        
        // post
        if body.count>0 {
            request.httpMethod = "POST"
            request.httpBody=body.data(using: .utf8);
        }
        
        // 开始请求
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
            
            } as URLSessionTask;
        
        //使用resume方法启动任务
        dataTask.resume()
        //等待完成..
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        
        return dictRet;
    }
    
    // MARK: - 扩展 -
    
    
    /// 基础调用
    ///
    /// - Parameters:
    ///   - path: 类型，例如 “/Resourceserver/resource/search”
    ///   - query: 条件，参考API说明
    /// - Returns: 结果或nil
    public func invoke(path:String,query:String = "")->Dictionary<String,Any>?{
        
        guard path.count > 0 else {
            return nil;
        }
        
        let httpURL="\(cnki_ecp_Server)\(path)\(query)"
        
        let dictRet = URLPerform(httpURL: httpURL)
        
        return dictRet
    }
    
    /// 获取充值历史交易记录
    ///
    /// - Parameters:
    ///   - userName: 用户名
    ///   - paySources: 产品, 例如 【 13 = 快报，云阅读】
    ///   - startDate: 参数，可忽略
    ///   - endDate: 参数，可忽略
    ///   - spIds: 参数，可忽略
    ///   - status: 参数，可忽略
    /// - Returns: 服务器结果，可选类型
    public func log_get_recharge_history(userName:String,paySources:String,startDate:String = "",endDate:String = "",spIds:String = "",status:String = "")->Dictionary<String,Any>? {
        ///
        let httpURL="\(cnki_ecp_Server)/Log/get_recharge_history?userName=\(userName)&paySources=\(paySources)"
        
        let dictRet = URLPerform(httpURL: httpURL)
        
        return dictRet
        
    }
    
}

