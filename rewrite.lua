-- local res = ngx.location.capture("http://localhost")

-- default status variables
local ok, err

local redis = require "resty.redis"
local ck = require "resty.cookie"
local json = require "json"
local http = require "resty.http"
local uuid = require "uuid"

Auth = {}

-- Add value into redis store
function Auth.set_redis(id, data)
    local ok, err
    local red = redis:new()

    ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        return false, err
    end

    ok, err = red:set(id, json.encode(data))
    if not ok then
        return false, err
    end

    red:close()
    return true, nil
end

-- Get value from redis store
function Auth.get_redis(id)
    local ok, err, value
    local red = redis:new()

    ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        return nil, err
    end

    value, err = red:get(id)
    if not ok then
        return nil, err
    end

    if value ~= ngx.null then
        value = json.decode(value)
    end

    red:close()

    return value, nil
end

-- Set cookie value
function Auth.set_cookie(key, value)
    local ok, err
    local cookie, err = ck:new()

    if not cookie then
        return false, err
    end

    ok, err = cookie:set({
        key = key, value = value, path = "/",
        httponly = true,
    })

    if not ok then
        return ok, err
    end

    return true, nil
end

-- Set cookie value
function Auth.get_cookie(key)
    local cookie, err = ck:new()
    if not cookie then
        return false, err
    end

    return cookie:get(key)
end

local headers = ngx.req.get_headers()

if headers["authorization"] == "web-rsa" and headers["x-auth-type"] == "authenticate" then
    local user = headers["x-auth-user"]
    local signature = headers["x-auth-sign"]
    local host

    local i = user:find("@")

    if i == nil then
        host = "127.0.0.1"
    else
        host = user:sub(i + 1)
        user = user:sub(1, i - 1)
    end

    local data = json.encode({user=user, signature=signature})

    local res, err = http.new():request_uri(
        "http://" .. host .. ":1999",
        {
            method="POST",
            headers={
                ["Content-Type"] = "application/json",
                -- ["Content-Length"] = #data,
            },
            body= data
        }
    )

    local success = true
    if err ~= nil then
        ngx.log(ngx.ERR, "Request failed: ", err)
    else
        local body = json.decode(res.body)

        if res.status ~= 200 then
            if body.error then
                ngx.log(ngx.WARN, "WebRSA request failed: ", body.error)
            else
                ngx.log(ngx.WARN, "WebRSA request failed: ", res.body)
            end
        end

        if body.result == true then
            local sid = uuid()

            ok, err = Auth.set_redis(sid, {user = user, signature = signature})
            if not ok then
                ngx.log(ngx.ERR, "Redis error: ", err)
            else
                ok, err = Auth.set_cookie("sid", sid)
                if not ok then
                    ngx.log(ngx.Err, "Cookie error: ", err)
                else
                    success = true
                end
            end
        end
    end

    if success then
        ngx.req.set_header("x-auth-verified", 1)
    else
        ngx.req.set_header("x-auth-verified", nil)
    end
else
    local data
    local sid, err = Auth.get_cookie("sid")

    ngx.log(ngx.ERR, "SID '", sid, "'")
    if sid ~= nil then
        data, err = Auth.get_redis(sid)

        if data == ngx.null then
            data = nil
        end
    end

    if data ~= nil then
        ngx.req.set_header("authorization", 'web-rsa')
        ngx.req.set_header("x-auth-user", data.user)
        ngx.req.set_header("x-auth-sign", data.signature)
        ngx.req.set_header("x-auth-verified", 1)
    else
        ngx.req.set_header("x-auth-verified", 0)
    end
end
