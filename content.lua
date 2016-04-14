-- local res = ngx.location.capture("http://localhost")

-- default status variables
local ok, err

local redis = require "resty.redis"
local ck = require "resty.cookie"
local json = require "cjson"
local http = require "resty.http"

-- -- create redis connection
-- local red = redis:new()
--
--
-- ok, err = red:connect("127.0.0.1", 6379)
-- if not ok then
--     ngx.say("failed to connect: ", err)
--     return
-- end
--
-- -- cookie parser
-- local cookie, err = ck:new()
-- if not cookie then
--     ngx.log(ngx.ERR, err)
--     return
-- end
--
-- local uuid = require "uuid"
--
-- -- Get session id from cookie. If cookie not found start new session
-- local field, err = cookie:get("sid")
-- if not field then
--     field = uuid()
--     ok, err = cookie:set({
--         key = "sid", value = field, path = "/",
--         -- secure = true,
--         httponly = true,
--         -- max_age = 50,
--         -- extension = "a4334aebaec"
--     })
--
--     if not ok then
--         ngx.log(ngx.ERR, err)
--     end
-- end
--
-- local params, err = red:get(field)
-- if not params then
--     ngx.say("failed to get params: ", err)
--     return
-- end
--
-- if params == ngx.null then
--     params = {
--         counter = 10
--     }
-- else
--     params = json.decode(params)
-- end
--
-- data = {counter = params.counter}
--
-- if data.counter < 1 then
--     data.counter = 10
-- else
--     data.counter = data.counter - 1
-- end
--
-- ok, err = red:set(field, json.encode(data))
-- if not ok then
--     ngx.say("failed to set params: ", err)
--     return
-- end

-- ngx.say(params.counter)

local headers = ngx.req.get_headers()

if headers["x-authenticate"] == "signature" then
    local user = headers["x-auth-user"]
    local sign = headers["x-auth-sign"]
    local data = json.encode({user=user, signature=sign})
    local res, err = http.new():request_uri(
        "http://127.0.0.1:1999",
        {
            method="POST",
            headers={
                ["Content-Type"] = "application/json",
                -- ["Content-Length"] = #data,
            },
            body= data
        }
    )

    if err ~= nil then
        ngx.log(ngx.ERR, "Request failed: ", err)
        ngx.say("not authenticated")
    else
        local auth = json.decode(res.body)

        if auth.result == true then
            ngx.say("authenticated")
        else
            ngx.say("not authenticated")
        end
    end
else
    ngx.say("not authenticated")
end
