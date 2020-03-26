参考

https://blog.csdn.net/potato512/article/details/51108813
https://blog.csdn.net/potato512/article/details/51108813?locationNum=4&fps=1
https://blog.csdn.net/zhaoyya/article/details/72842017

https://www.jianshu.com/p/82d3f83241f3  ， +1
https://www.jianshu.com/p/db158239f3a4

/////////////////////////

Cocoapods: pod search无法搜索到类库的解决办法
https://www.jianshu.com/p/b5e5cd053464

/////////////////////////

编辑好后最好先验证 .podspec 是否有有效
$ pod spec lint


如果是因为语法错误，验证失败后会给出错误的准确定位，
标记“^”的地方即为有语法错误的地方。

依赖错误
但是，有些非语法错误是不会给出错误原因的。这个时候可以使用“--verbose”来查看详细的验证过程来帮助定位错误。

这种情况下使用 --use-libraries 虽然不会出现错误（error），但是有时候会带来一些警告（waring），警告同样是无法通过验证的。这时可以用 --allow-warnings 来允许警告。

允许警告， 允许库
pod spec lint zjqzySDK.podspec --verbose --use-libraries --allow-warnings


/////////////////////////

可以查看你已经注册的信息，其中包含你的name、email、since、Pods、sessions，其中Pods为你往CocoaPods提交的所有的Pod！

pod trunk me

添加其他维护者（如果你的pod是由多人维护的，你也可以添加其他维护者）
pod trunk add-owner zjqzySDK wangxx@cocoapods.org

//////////////////////////

如果你在手动验证 Pod 时使用了 --use-libraries 或 --allow-warnings 等修饰符，那么发布的时候也应该使用相同的字段修饰，否则出现相同的报错。
pod trunk push zjqzySDK.podspec --use-libraries --allow-warnings

//////////////////////

清理本地spec文件缓存

//查看所有spec文件的缓存，可以直接到路径下删除文件
pod cache list
//删除指定库的缓存文件
pod cache clean AFNetworking
//运行podfile文件但不更新本地spec文件
pod install --no-repo-update


//////////////////////

gem环境安装

# 查看RubyGems软件的版本
gem -v
# 更新升级RubyGems软件自身
gem update --system
# 更新所有已安装的gem包
$ gem update
# 安装指定gem包，程序先从本机查找gem包并安装，如果本地没有，则从远程gem安装。
gem install [gemname]
# 查看本机已安装的所有gem包
gem list

pod ‘AFNetworking’ //不显式指定依赖库版本，表示每次都获取最新版本
pod ‘AFNetworking’, ‘2.0’ //只使用2.0版本
pod ‘AFNetworking’, ‘>2.0′ //使用高于2.0的版本
pod ‘AFNetworking’, ‘>=2.0′ //使用大于或等于2.0的版本
pod ‘AFNetworking’, ‘<2.0′ //使用小于2.0的版本
pod ‘AFNetworking’, ‘<=2.0′ //使用小于或等于2.0的版本
pod ‘AFNetworking’, ‘~>0.1.2′ //使用大于等于0.1.2但小于0.2的版本，相当于>=0.1.2并且<0.2.0
pod ‘AFNetworking’, ‘~>0.1′ //使用大于等于0.1但小于1.0的版本
pod ‘AFNetworking’, ‘~>0′ //高于0的版本，写这个限制和什么都不写是一个效果，都表示使用最新版本
pod ‘AFNetworking’, :head //一样代表使用最新版本（这个我测试用不起来）

//验证podspec文件是否可正常使用
命令行：pod lib lint
//上传podspec到trunk服务器中
命令行：pod trunk push HycProject.podspec
//上传需要一定时间，成功后更新本地pod依赖库
命令行：pod setup
//查看代码有没有通过审核版本是否更新
命令行：pod search HycProject
//下载线上git仓库（Podfile文件不在此讨论）
命令行：pod install

/////////////////////////////
/////////////////////////////

必要属性
//
Pod::Spec.new do|s|
//项目名
s.name ='HycProject'
//版本号
s.version ='1.0.1'
//listen文件的类型
s.license = 'MIT'
//简单描述
s.summary = 'ATest in iOS.'
//项目的getub地址，只支持HTTP和HTTPS地址，不支持ssh的地址
s.homepage ='https://github.com/hyc603671932/HycProject'
//作者和邮箱
s.authors = {'HouKavin' => '603671932@qq.com' }
//git仓库的https地址
s.source = { :git=> 'https://github.com/hyc603671932/HycProject.git', :tag =>s.version}
//是否要求arc（有部分非arc文件情况未考证）
s.requires_arc = true
//在这个属性中声明过的.h文件能够使用<>方法联想调用（这个是可选属性）
s.public_header_files = 'UIKit/*.h'
//表示源文件的路径，这个路径是相对podspec文件而言的。（这属性下面单独讨论）
s.source_files ='AppInfo/*.*'
//需要用到的frameworks，不需要加.frameworks后缀。（这个没有用到也可以不填）
s.frameworks ='Foundation', 'CoreGraphics', 'UIKit'
end
//可选属性

Pod::Spec.new do|s|
...
...
...
//详细介绍
s.description = "详细介绍"
//支持的平台及版本
s.platform     = :ios, '7.0'
//最低要求的系统版本
s.ios.deployment_target= '7.0'
//主页，需填写可访问地址
s.homepage = "https://coding.net/u/wtlucky/p/podTestLibrary"
//截图
s.screenshots     = "www.example.com/screenshots_1"
//多媒体介绍地址
s.social_media_url = 'https://twitter.com/<twitter_username>'
//效果和s.public_header_files的相同，只需要配置一种
s.ios.public_header_files = 'URS/URSAuth.h'
//不常用，所有文件默认即为private只能用import"XXX"调用
s.ios.private_header_files
#依赖关系，该项目所依赖的其他库
s.dependency 'AFNetworking', '~> 2.3'
//可拥有多个dependency依赖属性
s.dependency 'JSONKit', '~> 1.4'

//动态库所使用的资源文件存放位置，放在Resources文件夹中
s.resource_bundles = {
    'Test5' => ['Test5/Assets/*.png']
}
//资源文件（具体使用带考证）
s.resources = 'src/SinaWeibo/SinaWeibo.bundle/**/*.png'
//建立名称为Info的子文件夹（虚拟路径）
s.subspec 'Info' do |ss|
//应该和s.subspec作用相同（未考证）
s.default_subspec
end
s.source_files

//下载AppInfo文件夹下的所有文件，子文件夹不识别
s.source_files ='AppInfo'
//下载AppInfo目录下所有格式文件
s.source_files ='AppInfo/*.*'
**/*表示Classes目录及其子目录下所有文件
   s.source_files = 'AppInfo/**/*'


//下载HycProject文件夹下名称为AppManInfo和AppWomanInfo的共4项文件
s.source_files ='HycProject/App{Man,Woman}Info.{h,m}'
//目标路径下的文件不进行下载
s.ios.exclude_files = 'AppInfo/Info/json'
文件层次

Pod::Spec.new do|s|
//第一层文件夹名称HycProject
s.name ='HycProject'
...
...
...
//第二层文件夹名称AppInfo（虚拟路径）
s.subspec 'AppInfo' do |ss|
//下载HycProject文件夹下AppInfo的.h和.m文件
ss.source_files = 'HycProject/AppInfo.{h,m}'
//允许使用import<AppInfo.h>
ss.public_header_files = 'HycProject/AppInfo.h'
//依赖的frameworks
ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'

//第三层文件夹名称Info（虚拟路径）
ss.subspec 'Info' do |sss|
//最低要求的系统版本7.0
sss.ios.deployment_target = '7.0'
//只允许使用import"AppInfo.h"访问
sss.ios.private_header_files = 'AppInfo/Info/**/*.h'
// 下载路径下的.h/.m/.c文件
sss.ios.source_files = 'AppInfo/Info/**/*.{h,m,c}'
//引用xml2库,但系统会找不到这个库的头文件，需与下方sss.xcconfig配合使用(这里省略lib)
sss.libraries = "xml2"
//在pod target项的Header Search Path中配置:${SDK_DIR}/usr/include/libxml2
sss.xcconfig = { 'HEADER_SEARCH_PATHS' => '${SDK_DIR}/usr/include/libxml2' }
//json目录下的文件不做下载
sss.ios.exclude_files = 'AppInfo/Info/json'
end
end


end




