--Tools
local _AnaUtil = {}

local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")
--local zlib = require('ffi-zlib')
local cjson = require("cjson")
local baseStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function _AnaUtil.post(url,eventArrayJson,encode)
    if eventArrayJson == nil or tableIsEmpty(eventArrayJson) then
        return "",400,""
    end
    local request_body = toJson(eventArrayJson)
    if(encode) then
        --request_body = encodeBase64(encodeGzip(request_body))
    end
    local response_body = {}
    local res, code = http.request{
        url = url,
        create = function()
            local req_sock = socket.tcp()
            req_sock:settimeout(30, 't')
            return req_sock
        end,
        method = "POST",
        headers =
        {
            ["Content-Type"] = "application/x-www-form-urlencoded";
            ["Content-Length"] = #request_body;
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
    }
    res = table.concat(response_body)
    if(code ~= nil and type(code) == "number" and (tonumber(code) < 200 or tonumber(code) >= 300)) then
        print("Warn: Up Unsuccess, data: "..request_body)
    end
    if("{\"code\":200}" ~= res and "H4sIAAAAAAAAAKtWSs5PSVWyMjIwqAUAVAOW6gwAAAA=" ~= res) then
        print("Warn: Up Unsuccess, data: "..request_body)
    end
    return res,code,request_body
end

function isWindows()
    local separator = package.config:sub(1,1)
    local osName = os.getenv("OS")
    local isWindows = (separator == '\\' or (osName ~= nil and startWith(string.lower(osName),"windows")))
    return isWindows
end

function toJson(eventArrayJson)
    return cjson.encode(eventArrayJson)
end

-- base64
function encodeBase64(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return baseStr:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- gzip
function encodeGzip(data)
    local count = 0
    local chunk = 16384
    local input = function(bufsize)
        local start = count > 0 and bufsize*count or 1
        local data = data:sub(start, (bufsize*(count+1)-1))
        if data == "" then
            data = nil
        end
        count = count + 1
        return data
    end
    local output_table = {}
    local output = function(data)
        table.insert(output_table, data)
    end
    local ok, err = zlib.deflateGzip(input, output, chunk)
    if not ok then
        log("Error: ", "Gzip Error: ", err)
    end
    local compressed = table.concat(output_table,'')
    return compressed
end

function _AnaUtil.regEx(str,len)
    return string.match(str,"^(xwhat)$") ~= str and
            string.match(str,"^(xwhen)$") ~= str and
            string.match(str,"^(xwho)$") ~= str and
            string.match(str,"^(appid)$") ~= str and
            string.match(str,"^(xcontext)$") ~= str and
            string.match(str,"^(%$lib)$") ~= str and
            string.match(str,"^(%$lib_version)$") ~= str and
            string.match(str,"^[$a-zA-Z][$a-zA-Z0-9_]+$") == str and
            string.len(str) <= tonumber(len)
end

function tableIsEmpty(t)
    return _G.next( t ) == nil
end

function _AnaUtil.mergeTables(...)
    local tabs = {...}
    if not tabs then
        return {}
    end
    local origin = tabs[1]
    for i = 2,#tabs do
        if origin then
            if tabs[i] then
                for k,v in pairs(tabs[i]) do
                    origin[k] = v
                end
            end
        else
            origin = tabs[i]
        end
    end
    return origin
end

function fileExists(path)
    local retTable = {os.execute("cd "..path) }
    local code = retTable[3] or retTable[1]
    return code == 0
end

function _AnaUtil.mkdirFolder(path)
    if(fileExists(path)) then
        return path
    end
    local isWindows = isWindows()
    local cmd = "mkdir -p "..path
    if (isWindows) then
        cmd = "mkdir "..path
    end
    local retTable = {os.execute(cmd)}
    local code = retTable[3] or retTable[1]
    if (code ~= 0) then
        if (isWindows) then
            return os.getenv("TEMP")
        else
            return "/tmp"
        end
    end
    return path
end

function _AnaUtil.writeFile(filePath,rule,eventArrayJson,encode)
    local isWindows = isWindows()
    local separator = "/"
    if (isWindows) then
        separator = "\\"
    end
    local fileFullName = filePath..separator.."datas_"..os.date(rule)..".log"
    local file = assert(io.open(fileFullName, 'a'))
    local data = ""
    for i=1, #eventArrayJson do
        local json = toJson(eventArrayJson[i])
        --if(encode) then
        --    json = encodeBase64(encodeGzip(json))
        --end
        data = data..json.."\n"
    end
    file:write(data)
    file:close()
    file = nil
    return data
end

function _AnaUtil.trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function _AnaUtil.startWith(str,substr)
    if str == nil or substr == nil then
        return false
    end
    if string.find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

function isTimeStamp(t)
    local rt = string.gsub(t,'%.','')
    if rt == nil or string.len(rt) < 13 or tonumber(rt) == nil then return false end
    local status = pcall(function(tim)
        local number,decimal = math.modf(tonumber(tim)/1000)
        os.date("%Y%m%d%H%M%S", number)
    end, rt)
    return status
end

function _AnaUtil.now(t)
    if t == nil or string.len(t) == 0 then
        local number,decimal = math.modf(socket.gettime() * 1000)
        return number
    end
    if(isTimeStamp(t)) then
        return t
    end
    return nil
end

function _AnaUtil.clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function _AnaUtil.printTable(t)
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
end

--日志打印
function _AnaUtil.log(level,key,msg)
    print(level..(key or "")..(msg or ""))
end

--异常处理
function _AnaUtil.errorhandler(errmsg)
   print("ERROR===:",tostring(errmsg), debug.traceback())
end

return _AnaUtil