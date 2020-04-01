--LuaSDK
local AnaUtil = require "AnalysysUtil"

function class(base, _ctor)
    local c = {}
    if not _ctor and type(base) == 'function' then
        _ctor = base
        base = nil
    elseif type(base) == 'table' then
        for i,v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    c.__index = c
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj,c)
        if _ctor then
            _ctor(obj,...)
        end
        return obj
    end
    c._ctor = _ctor
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

--SDK
_AnaSDK = class(function(self,appid,collecter)
    if appid == nil or type(appid) ~= "string" or string.len(appid) == 0 then
        error("appid不能为空.")
    end
    if collecter == nil or type(collecter) ~= "table" then
        error("collecter参数不正确.")
    end
    self.collecter = collecter
    self.appid = appid
    self.debug = self.DEBUG.CLOSE
    self.egBaseProperties = {}
    self.egBaseProperties["$lib"] = self.platForm
    self.egBaseProperties["$lib_version"] = self.version
    self.xcontextSuperProperties = {}
end)

--Collecter
_AnaSDK.SyncCollecter = class(function(self,url,encode)
    if url == nil or type(url) ~= "string" or string.len(url) == 0 then
        error("上报地址不能为空.")
    end
    self.url = url.."/up"
    self.encoder = false
    if encode ~= nil and type(encode) == "boolean" then
        self.encoder = encode
    end
    self.debug = _AnaSDK.DEBUG.CLOSE
    self.logMode = false
    self.logPath = _AnaSDK.logModePath
    self.rule = _AnaSDK.LOGRULE.HOUR
end)
function _AnaSDK.SyncCollecter:setDebugMode(d)
    self.debug = d
end
function _AnaSDK.SyncCollecter:setLogMode(islog)
    self.logMode = islog
end
function _AnaSDK.SyncCollecter:setLogPath(logPath,rule)
    if(logPath ~= nil and type(logPath) == "string") then
        self.logPath = AnaUtil.mkdirFolder(logPath)
    end
    if(rule ~= nil and type(rule) == "string") then
        self.rule = rule
    end
    if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
        AnaUtil.log("Info: ","LogCollector生效, 日志目录为: "..self.logPath.." 文件格式: "..self.rule)
    end
end
function _AnaSDK.SyncCollecter:send(msg)
    local eventArrayJson = {}
    eventArrayJson[1] = msg
    if(self.logMode) then
        local body = AnaUtil.writeFile(self.logPath,self.rule,eventArrayJson,self.encoder)
        return body
    else
        local resp, code, body = AnaUtil.post(self.url,eventArrayJson,self.encoder)
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","同步发送到: "..self.url.." 返回Code:["..code.."]\nBody: "..body.."\n返回: "..resp)
        end
        return body
    end
end
function _AnaSDK.SyncCollecter:flush() end
function _AnaSDK.SyncCollecter:toString()
    if(self.logMode) then
        return "\n--Collector: LogCollecter"..
                "\n----Collector.LogRule: "..self.rule..
                "\n----Collector.LogPath: "..self.logPath
    end
    return "\n--Collector: SyncCollecter"..
            "\n--Collector.Url: "..self.url
end

_AnaSDK.BatchCollecter = class(function(self,url,batchNum,encode)
    if url == nil or type(url) ~= "string" or string.len(url) == 0 then
        error("上报地址不能为空.")
    end
    if batchNum ~= nil and type(batchNum) ~= "number" then
        error("批量条数应该为Number类型.")
    end
    self.url = url.."/up"
    self.batchNum = batchNum or _AnaSDK.batchNumber
    self.encoder = false
    if encode ~= nil and type(encode) == "boolean" then
        self.encoder = encode
    end
    self.debug = _AnaSDK.DEBUG.CLOSE
    self.eventArrayJson = {}
    self.logMode = false
    self.logPath = _AnaSDK.logModePath
    self.rule = _AnaSDK.LOGRULE.HOUR
end)
function _AnaSDK.BatchCollecter:setDebugMode(d)
    self.debug = d
end
function _AnaSDK.BatchCollecter:setLogMode(islog)
    self.logMode = islog
end
function _AnaSDK.BatchCollecter:setLogPath(logPath,rule)
    if(logPath ~= nil and type(logPath) == "string") then
        self.logPath = AnaUtil.mkdirFolder(logPath)
    end
    if(rule ~= nil and type(rule) == "string") then
        self.rule = rule
    end
    if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
        AnaUtil.log("Info: ","LogCollector生效, 日志目录为: "..self.logPath.." 文件格式: "..self.rule)
    end
end
function _AnaSDK.BatchCollecter:send(msg)
    self.eventArrayJson[#self.eventArrayJson + 1] = msg
    local num = #self.eventArrayJson
    if(num >= self.batchNum or "$alias" == msg["xwhat"]) then
        self:flush()
    end
    return num
end
function _AnaSDK.BatchCollecter:flush()
    if(self.logMode) then
        local body = AnaUtil.writeFile(self.logPath,self.rule,self.eventArrayJson,self.encoder)
        self.eventArrayJson = {}
        return body
    else
        local resp, code, body = AnaUtil.post(self.url,self.eventArrayJson,self.encoder)
        self.eventArrayJson = {}
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","批量发送到: "..self.url.." 返回Code:["..code.."]\nBody: "..body.."\n返回: "..resp)
        end
        return body
    end
end
function _AnaSDK.BatchCollecter:toString()
    if(self.logMode) then
        return "\n--Collector: LogCollecter"..
                "\n----Collector.LogRule: "..self.rule..
                "\n----Collector.LogPath: "..self.logPath
    end
    return "\n--Collector: BatchCollecter"..
            "\n--Collector.Url: "..self.url
end

_AnaSDK.LogCollecter = function(logFolder,async,batchNum,rule,encode)
    if logFolder == nil or type(logFolder) ~= "string" or string.len(logFolder) == 0 then
        error("日志目录不能为空.")
    end
    if rule ~= nil and type(rule) ~= "string" then
        error("文件名规则参数错误.")
    end
    local collecter = {}
    local batchSend = _AnaSDK.batchModel
    if async ~= nil and type(async) == "boolean" then
        batchSend = async
    end
    if(batchSend) then
        if batchNum ~= nil and type(batchNum) ~= "number" then
            error("批量条数应该为Number类型.")
        end
        collecter = _AnaSDK.BatchCollecter("null",batchNum,encode)
    else
        collecter = _AnaSDK.SyncCollecter("null",encode)
    end
    collecter:setLogPath(logFolder,rule)
    collecter:setLogMode(true)
    return collecter
end

--设置Debug模式
function _AnaSDK:setDebugMode(d)
    self.debug = d
    self.collecter:setDebugMode(d)
end

--[[
	 * 注册超级属性,注册后每次发送的消息体中都包含该属性值
	 * @param params 属性
--]]
function _AnaSDK:registerSuperProperties(params)
    local ok,ret = pcall(checkKV,params)
    if not ok then
        AnaUtil.log("Error: ","注册超级属性错误: ",ret)
    else
        if(type(params) == "table") then
            self.xcontextSuperProperties = AnaUtil.mergeTables(self.xcontextSuperProperties,params)
        end
    end
end
function _AnaSDK:registerSuperPropertie(key,value)
    if(key ~= nil) then
        local params = {}
        params[key] = value
        self:registerSuperProperties(params)
    end
end
--[[
	 * 移除超级属性
	 * @param key 属性Key
--]]
function _AnaSDK:unRegisterSuperProperty(key)
    self.xcontextSuperProperties[key] = nil
end
--[[
	 * 获取超级属性
	 * @param key 属性Key
	 * @return 该KEY的超级属性值
--]]
function _AnaSDK:getSuperPropertie(key)
    AnaUtil.log("","获取超级属性"..key.."值为: "..self.xcontextSuperProperties[key])
    return self.xcontextSuperProperties[key]
end
--[[
	 * 获取超级属性
	 * @return 所有超级属性
--]]
function _AnaSDK:getSuperProperties()
    local prop = self.xcontextSuperProperties
    AnaUtil.printTable(prop)
    return prop
end
--清除超级属性
function _AnaSDK:clearSuperProperties()
    self.xcontextSuperProperties = {}
end

--[[
     * 设置用户的属性
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param properties 用户属性
	 * @param platform 平台类型
--]]
function _AnaSDK:profileSet(distinctId,isLogin,properties,platform,xwhen)
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_set",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileSet方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileSet方法错误: ",ret)
    end
end
--[[
	 * 首次设置用户的属性,该属性只在首次设置时有效
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param properties 用户属性
	 * @param platform 平台类型
--]]
function _AnaSDK:profileSetOnce(distinctId,isLogin,properties,platform,xwhen)
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_set_once",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileSetOnce方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileSetOnce方法错误: ",ret)
    end
end
--[[
	 * 为用户的一个或多个数值类型的属性累加一个数值
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param properties 用户属性
	 * @param platform 平台类型
--]]
function _AnaSDK:profileIncrement(distinctId,isLogin,properties,platform,xwhen)
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_increment",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileIncrement方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileIncrement方法错误: ",ret)
    end
end
--[[
	 * 追加用户列表类型的属性
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param properties 用户属性
	 * @param platform 平台类型
--]]
function _AnaSDK:profileAppend(distinctId,isLogin,properties,platform,xwhen)
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_append",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileAppend方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileAppend方法错误: ",ret)
    end
end
--[[
	 * 删除用户某一个属性
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param property 用户属性名称
	 * @param platform 平台类型
--]]
function _AnaSDK:profileUnSet(distinctId,isLogin,propertie,platform,xwhen)
    local properties = {}
    properties[propertie] = ""
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_unset",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileUnSet方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileUnSet方法错误: ",ret)
    end
end
--[[
	 * 删除用户所有属性
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param platform 平台类型
--]]
function _AnaSDK:profileDelete(distinctId,isLogin,platform,xwhen)
    local properties = {}
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,"$profile_delete",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用profileDelete方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用profileDelete方法错误: ",ret)
    end
end
--[[
	 * 关联用户匿名ID和登录ID
	 * @param aliasId 用户登录ID
	 * @param distinctId 用户匿名ID
	 * @param platform 平台类型
--]]
function _AnaSDK:alias(aliasId,distinctId,platform,xwhen)
    local properties = {}
    properties["$original_id"] = distinctId
    local isLogin = true
    local ok,ret = pcall(upload,self.collecter,self.appid,aliasId,isLogin,"$alias",properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用alias方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用alias方法错误: ",ret)
    end
end
--[[
	 * 追踪用户多个属性的事件
	 * @param distinctId 用户ID
	 * @param isLogin 用户ID是否是登录 ID
	 * @param eventName 事件名称
	 * @param properties 事件属性
	 * @param platform 平台类型
--]]
function _AnaSDK:track(distinctId,isLogin,eventName,properties,platform,xwhen)
    local ok,ret = pcall(upload,self.collecter,self.appid,distinctId,isLogin,eventName,properties,platform,xwhen,self.egBaseProperties,self.xcontextSuperProperties,self.debug)
    if ok then
        if (self.debug ~= _AnaSDK.DEBUG.CLOSE) then
            AnaUtil.log("Info: ","调用track方法: 成功")
        end
        return ret
    else
        AnaUtil.log("Error: ","调用track方法错误: ",ret)
    end
end
--[[
	 * 上传数据,首先校验相关KEY和VALUE,符合规则才可以上传
	 * @param collecter 收集器
	 * @param distinctId 用户标识
	 * @param isLogin 是否登陆
	 * @param eventName 事件名称
	 * @param properties 属性
	 * @param platform 平台类型
	 * @param xwhen 时间戳
	 * @param base 基础属性
	 * @param super 超级属性
	 * @param debugMode debug值
--]]
function upload(collecter,appid,distinctId,isLogin,eventName,properties,platform,xwhen,base,super,debugMode)
    local cloneProperties = AnaUtil.clone(properties or {})
    local targetProperties = check(distinctId,isLogin,eventName,cloneProperties,platform,xwhen)
    local xContextProperties = {}
    if(not (AnaUtil.startWith(eventName,"$profile") or "$alias" == eventName)) then
        xContextProperties = AnaUtil.mergeTables(xContextProperties,super)
    end
    xContextProperties = AnaUtil.mergeTables(xContextProperties,targetProperties,base)
    xContextProperties["$debug"] = debugMode
    xContextProperties["$is_login"] = isLogin
    local newPlatForm = getPlatForm(platform)
    if(newPlatForm ~= nil and string.len(newPlatForm) > 0) then
        xContextProperties["$platform"] = newPlatForm
    end
    --Send
    local eventJson = {}
    eventJson["xwho"] = tostring(distinctId)
    local mXwhen = AnaUtil.now(xwhen or "")
    if(mXwhen == nil) then
        error("The param xwhen "..xwhen.." not a millisecond timestamp.")
    end
    eventJson["xwhen"] = tonumber(mXwhen)
    eventJson["xwhat"] = tostring(eventName)
    eventJson["appid"] = tostring(appid)
    eventJson["xcontext"] = xContextProperties
    local ret = collecter:send(eventJson)
    cloneProperties = nil
    targetProperties = nil
    xContextProperties = nil
    eventJson = nil
    return ret
end

function check(distinctId,isLogin,eventName,properties,platform,xwhen)
    assert(type(distinctId) == "string" or type(distinctId) == "number", "distinctId参数应该为数字或字符串")
    assert(type(isLogin) == "boolean", "isLogin参数 不是一个布尔值")
    assert(type(eventName) == "string", "eventName参数 不是一个字符串")
    assert(type(properties) == "table", "properties 不是一个Table")
    assert(type(platform) == "string", "platform参数 不是一个字符串")
    if(xwhen ~= nil) then
        assert(type(xwhen) == "string", "xwhen参数 不是一个字符串")
    end
    --校验字段
    local eventNameLen = 99
    local idLength = 255
    local xContextPatams = {}
    local aliasEventName = "$alias"
    local originalId = "$original_id"
    if(properties ~= nil) then
        xContextPatams = properties
    end
    if(distinctId == nil or string.len(distinctId) == 0) then
        error("aliasId is null or empty.")
    end
    if(string.len(distinctId) > idLength) then
        error("aliasId %s is too long, max length is "..idLength)
    end
    if(eventName == nil or string.len(eventName) == 0) then
        AnaUtil.log("Warn: ","EventName is null or empty.")
    end
    if(string.len(eventName) > eventNameLen) then
        AnaUtil.log("Warn: ","EventName %s is too long, max length is "..eventNameLen)
    end
    if(not AnaUtil.regEx(eventName,eventNameLen)) then
        AnaUtil.log("Warn: ","EventName: "..eventName.." is invalid.")
    end
    if(aliasEventName == eventName) then
        if(xContextPatams[originalId] == nil or string.len(xContextPatams[originalId]) == 0) then
            error("original_id is empty.")
        end
        if(string.len(xContextPatams[originalId]) > idLength) then
            error("original_id is too long, max length is "..idLength)
        end
    end
    checkKV(xContextPatams, eventName)
    return xContextPatams
end

function checkKV(xContextPatams, eventName)
    --校验K/V
    local valueLength = 8192
    local valueWarnLength = 255
    local keyLength = 99
    local valueListLen = 100
    local piEventName = "$profile_increment"
    local paEventName = "$profile_append"
    local puEventName = "$profile_unset"
    for key, value in pairs(xContextPatams) do
        if(string.len(key) > keyLength) then
            AnaUtil.log("Warn: ","The property key "..key.." is too long, max length is "..keyLength)
        end
        if(string.len(key) == 0) then
            AnaUtil.log("Warn: ","The property key is empty")
        else
            if(not AnaUtil.regEx(key,keyLength)) then
                AnaUtil.log("Warn: ","The property key "..key.." is invalid.")
            end
        end
        if(type(value) ~= "string" and
                type(value) ~= "number" and
                type(value) ~= "boolean" and
                type(value) ~= "table") then
            AnaUtil.log("Warn: ","The property "..key.." is not number, string, boolean, table.")
        end
        if(type(value) == "table") then
            for k, v in pairs(value) do
                if(type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean") then
                    AnaUtil.log("Warn: ","The table property "..k.." is not number, string, boolean.")
                end
            end
        end
        if(type(value) == "string" and string.len(value) == 0 and not (puEventName == eventName)) then
            AnaUtil.log("Warn: ","The property "..key.." string value is null or empty")
        end
        if(type(value) == "string" and string.len(value) > valueWarnLength) then
            AnaUtil.log("Warn: ","The property "..key.." string value is too long, max length is "..valueWarnLength)
        end
        if(type(value) == "string" and string.len(value) > valueLength) then
            xContextPatams[key] = string.sub(value,1,valueLength).."$"
        end
        if(type(value) == "table") then
            if(#value > valueListLen) then
                AnaUtil.log("Warn: ","The property "..key.." max number should be "..valueListLen)
                --for i = #value, 1, -1 do
                --    if #value > valueListLen then
                --        table.remove(value, i)
                --    end
                --end
            end
            for k, v in pairs(value) do
                if(type(v) ~= "string") then
                    AnaUtil.log("Warn: ","The property "..key.." should be a table of string.")
                end
                if(string.len(v) == 0) then
                    AnaUtil.log("Warn: ","The property "..key.." string value is empty")
                end
                if(string.len(v) > valueWarnLength) then
                    AnaUtil.log("Warn: ","The property "..key.." some value is too long, max length is "..valueWarnLength)
                end
                if(string.len(v) > valueLength) then
                    value[k] = string.sub(v,1,valueLength).."$"
                end
            end
        end
        if(piEventName == eventName and type(value) ~= "number") then
            AnaUtil.log("Warn: ","The property value of "..key.." should be a number ")
        end
        if(paEventName == eventName and type(value) ~= "table") then
            AnaUtil.log("Warn: ","The property value of "..key.." should be a table ")
        end
    end
end

function getPlatForm(platform)
    if platform == nil or string.len(platform) == 0 or string.lower(platform) == "lua" then return "Lua" end
    if string.lower(platform) == "js" then return "Js" end
    if string.lower(platform) == "java" then return "Java" end
    if string.lower(platform) == "python" then return "python" end
    if string.lower(platform) == "node" then return "Node" end
    if string.lower(platform) == "php" then return "PHP" end
    if string.lower(platform) == "wechat" then return "WeChat" end
    if string.lower(platform) == "android" then return "Android" end
    if string.lower(platform) == "ios" then return "iOS" end
    return platform
end

function _AnaSDK:flush()
    self.collecter:flush()
end

function _AnaSDK:toString()
    return "--AppID: "..self.appid..
            "\n--Debug: "..self.debug..
            "\n--Lib: "..self.egBaseProperties["$lib"]..
            "\n--LibVersion: "..self.egBaseProperties["$lib_version"]..
            self.collecter:toString()
end

_AnaSDK.platForm = "Lua"
_AnaSDK.version = "4.3.0"
_AnaSDK.batchNumber = 10
_AnaSDK.batchModel = false
_AnaSDK.encodeJson = false
_AnaSDK.logModePath = "."

_AnaSDK.DEBUG = {}
_AnaSDK.DEBUG.CLOSE = 0
_AnaSDK.DEBUG.OPENNOSAVE = 1
_AnaSDK.DEBUG.OPENANDSAVE = 2

_AnaSDK.LOGRULE = {}
_AnaSDK.LOGRULE.HOUR = "%Y%m%d%H"
_AnaSDK.LOGRULE.DAY = "%Y%m%d"
return _AnaSDK
