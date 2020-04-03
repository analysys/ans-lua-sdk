# [易观方舟](https://www.analysys.cn/) ans-lua-sdk 


## Lua SDK 基础说明
+ 快速集成

      local AnaSDK = require "AnalysysLuaSdk"
      local APP_ID = "APPKEY"
      local ANALYSYS_SERVICE_URL = "http://host:port"
      local collector = AnaSDK.SyncCollecter(ANALYSYS_SERVICE_URL)
      local analysys = AnaSDK(APP_ID, collector)   --初始化sdk;
      analysys:setDebugMode(analysys.DEBUG.CLOSE)  --设置debug模式

    
+ APP_ID: 网站获取的 Key。
+ ANALYSYS_SERVICE_URL: 数据接收地址。
+ debug模式，有 DEBUG.CLOSE、DEBUG.OPENNOSAVE、DEBUG.OPENANDSAVE 三种值。
    + DEBUG.CLOSE 表示关闭 Debug 模式 （默认状态）
    + DEBUG.OPENNOSAVE 表示打开 Debug 模式，但该模式下发送的数据仅用于调试，不计入平台数据统计
    + DEBUG.OPENANDSAVE 表示打开 Debug 模式，该模式下发送的数据可计入平台数据统计
注意：发布版本时debug模式设置为`DEBUG.CLOSE`。


事件收集器提供实时收集器、批量收集器和落地文件收集器三种：   

+ SyncCollecter：实时收集器,该收集器则立即上传数据至接收服务器
+ BatchCollecter：批量收集器,该收集器将先缓存数据，直到数量达到用户设置的阈值，才会触发真正的上传
+ LogCollecter：落地文件收集器,可以把用户触发的事件经过封装处理成标准的JSON写入本地文件中


> 通过以上步骤您即可验证SDK是否已经集成成功，更多Api使用方法参考：[易观方舟 Lua SDK 文档](https://docs.analysys.cn/ark/integration/sdk/lua-sdk)

> 注意 SDK 可能不完全向前兼容，请查看版本更新说明 [Release及版本升级记录](https://github.com/analysys/ans-lua-sdk/releases)。如果有说明不兼容的话，需要升级易观方舟对应的版本。 请根据需要前往 [Release](https://github.com/analysys/ans-lua-sdk/releases) 里下载对应的文件

## 版本升级记录
请参见 [Release及版本升级记录](https://github.com/analysys/ans-lua-sdk/releases)

         

## 讨论
+ 微信号：nlfxwz
+ 钉钉群：30099866
+ 邮箱：nielifeng@analysys.com.cn


**禁止一切基于易观方舟 Node 开源 SDK 的所有商业活动！**

---


