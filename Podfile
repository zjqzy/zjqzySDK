
# 一旦你指定了其他source 就必须也把官方的指定上
# 官方specs的位置，
source 'https://github.com/CocoaPods/Specs.git'

# 私有specs的位置
#source 'https://gitee.com/carvings/ZJQSpecs.git'



platform :ios, '9.0'
use_modular_headers!
# use_frameworks!



target 'zjqzySDKDemo' do

    # 明确指定继承于父层的所有pod，默认就是继承的
    inherit! :search_paths


    # ------- 开源库 --------
 
    # 数据库SQLite
    pod 'FMDB'


    # ------- 私有库 --------

    # 通用类
    pod 'CNKI_Z_BaseSDK', :git => 'https://github.com/zjqzy/CNKIZBaseUtil.git'

    pod 'zjqzySDK', :git => 'https://github.com/zjqzy/zjqzySDK.git'


end


# ----------------------------------------------- #
# --------------  常用命令  和配置无关   ------------ #
# ----------------------------------------------- #

# pod setup
# 将所有第三方的Podspec索引文件更新到本地的~/.cocoapods/repos目录下,更新本地仓库。


# pod repo update
# 执行 pod repo update更新本地仓库，本地仓库完成后，即可搜索到指定的第三方库，作用类似pod setup。不过这个命令经常不单独调用。比如执行pod setup、pod # search、pod install、pod update会默认执行pod repo update


# pod search xxx
# 查找某一个开源库。查找开源库之前，默认会执行pod repo update指令


# pod list
# 列出所有可用的第三方库


# pod install
# 会根据Podfile.lock文件中列举的版本号来安装第三方框架
# 如果一开始Podfile.lock文件不存在, 就会按照Podfile文件列举的版本号来安装第三方框架
# 安装开源库之前, 默认会执行pod repo update指令
# pod install 命令执行成功后，会看到项目根目录下多出xxx.xcworkspace、Podfile.lock文件和Pods目录


# pod update 
# 将所有第三方框架更新到最新版本, 并且创建一个新的Podfile.lock文件
# 安装开源库之前, 默认会执行pod repo update指令


# 安装开源库之前, 不会执行pod repo update指令
# pod install --no-repo-update
# pod update --no-repo-update

