--Demo
local AnaSDK = require "AnalysysLuaSdk"
local APP_ID = "1234"
local ANALYSYS_SERVICE_URL = "http://127.0.0.1:8089"

--初始化
local collector = AnaSDK.SyncCollecter(ANALYSYS_SERVICE_URL)  --同步收集器
--collector = AnaSDK.BatchCollecter(ANALYSYS_SERVICE_URL)    --批量收集器
--collector = AnaSDK.LogCollecter("/tmp/data") --落地文件收集器
local analysys = AnaSDK(APP_ID, collector)

local distinctId = "1234567890987654321"
local platForm = "Lua"
analysys:setDebugMode(analysys.DEBUG.CLOSE) --设置debug模式

--浏览商品
local trackPropertie = {}
trackPropertie["productNames"] = {"Lua入门","Lua从精通到放弃"}
trackPropertie["productType"] = "Lua书籍"
trackPropertie["producePrice"] = 80
trackPropertie["shop"] = "xx网上书城"
analysys:track(distinctId, false, "ViewProduct", trackPropertie, platForm)

--用户注册登录
local registerId = "ABCDEF123456789"
analysys:alias(registerId, distinctId, platForm)

--设置公共属性
local superPropertie = {}
superPropertie["sex"] = "male" --性别
superPropertie["age"] = 23 --年龄
analysys:registerSuperProperties(superPropertie)
--用户信息设置
local profiles = {}
profiles["$city"] = "北京"		--城市
profiles["$province"] = "北京"  --省份
profiles["nickName"] = "昵称123"--昵称
profiles["userLevel"] = 0		--用户级别
profiles["userPoint"] = 0		--用户积分
local interestList = {"户外活动","足球赛事","游戏"}
profiles["interest"] = interestList --用户兴趣爱好
analysys:profileSet(registerId, true, profiles, platForm)

--用户注册时间
local profile_age = {}
profile_age["registerTime"] = "20180101101010"
analysys:profileSetOnce(registerId, true, profile_age, platForm)

--重新设置公共属性
analysys:clearSuperProperties()
superPropertie = {}
superPropertie["userLevel"] = 0 --用户级别
superPropertie["userPoint"] = 0 --用户积分
analysys:registerSuperProperties(superPropertie)

--再次浏览商品
trackPropertie = {}
trackPropertie["productName"] = {"Thinking in Lua"}   --商品列表
trackPropertie["productType"] = "Lua书籍" --商品类别
trackPropertie["producePrice"] = 80		    --商品价格
trackPropertie["shop"] = "xx网上书城"      --店铺名称
analysys:track(registerId, true, "ViewProduct", trackPropertie, platForm)

--订单信息
trackPropertie = {}
trackPropertie["orderId"] = "ORDER_12345"
trackPropertie["price"] = 80
analysys:track(registerId, true, "Order", trackPropertie, platForm)

--支付信息
trackPropertie = {}
trackPropertie["orderId"] = "ORDER_12345"
trackPropertie["productName"] = "Thinking in Lua"
trackPropertie["productType"] = "Lua书籍"
trackPropertie["producePrice"] = 80
trackPropertie["shop"] = "xx网上书城"
trackPropertie["productNumber"] = 1
trackPropertie["price"] = 80
trackPropertie["paymentMethod"] = "AliPay"
analysys:track(registerId, true, "Payment", trackPropertie, platForm)

analysys:flush()
