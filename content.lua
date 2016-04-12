-- local res = ngx.location.capture("http://localhost")

-- default status variables
local ok, err

local redis = require "resty.redis"
local ck = require "resty.cookie"
local json = require "json"

-- create redis connection
local red = redis:new()


ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    ngx.say("failed to connect: ", err)
    return
end

-- cookie parser
local cookie, err = ck:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    return
end

local uuid = require "uuid"

-- Get session id from cookie. If cookie not found start new session
local field, err = cookie:get("sid")
if not field then
    field = uuid()
    ok, err = cookie:set({
        key = "sid", value = field, path = "/",
        -- secure = true,
        httponly = true,
        -- max_age = 50,
        -- extension = "a4334aebaec"
    })

    if not ok then
        ngx.log(ngx.ERR, err)
    end
end

local params, err = red:get(field)
if not params then
    ngx.say("failed to get params: ", err)
    return
end

if params == ngx.null then
    params = {
        counter = 10
    }
else
    params = json.decode(params)
end

data = {counter = params.counter}

if data.counter < 1 then
    data.counter = 10
else
    data.counter = data.counter - 1
end

ok, err = red:set(field, json.encode(data))
if not ok then
    ngx.say("failed to set params: ", err)
    return
end

-- local headers = ngx.req.get_headers()
-- if headers["x-authenticate"] ~= nil then
--     ngx.say("auth header: " .. headers["x-authenticate"])
-- else
--     ngx.say("-")
-- end

ngx.say(params.counter)
