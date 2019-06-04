

import UIKit

extension CNKIServerCAJCloud{
    
    public func test(){
        
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
    
    public func Login2(username:String,password:String,platform:String,clientid:String,version:String) -> Dictionary<String,Any>? {
        
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
