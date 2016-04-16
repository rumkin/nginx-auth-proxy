# Nginx Auth Proxy

Nginx Auth Proxy is set of lua scripts to realize web-rsa authentication
exchange algorithm. It can be used with any kind of web services. It best fit
for microservices and web api.

# Authentication

Auth proxy at first needs `Authorize` header to be set as `web-rsa`. Than it
read authentication headers started with `x-auth-`:

```
Authenticate: web-rsa
X-Auth-Type: authenticate
X-Auth-User: username
X-Auth-Sign: ...signature...
```

If username has `@` character than authentication request should be sent on
remote host. Example:
```
admin // host = 127.0.0.1
admin@neonbrush.com // host = neonbrush.com
```

When headers values validated request will be converted into `web-rsa` json
and passed to authentication server. Which should return authentication status.

If status is `{result: true}` than there will be created a key into redis
to store authentication session data. After that all requests passed throw
auth proxy will have auth status header: `X-Auth-Verified: 1` otherwise it will
be `0`.

# Installation

Os dependencies are nginx, lua 5.1 and lua-lpeg library. They can be installed from os
package manager on most of linux distributions. Example for Ubuntu:

```
sudo apt-get install nginx lua5.1 lua-lpeg
```

Than call `bake` to build nginx configuration:
```
bake install-deps
bake build # Optional parameter is unix socket or port for proxying
```

Or if you have no bake just use `bin/bake`

Manual installation of dependencies:
```
mkdir lua
cd lua
git clone https://github.com/cloudflare/lua-resty-cookie.git
git clone https://github.com/openresty/lua-resty-redis.git
git clone https://github.com/pintsized/lua-resty-http.git
git clone https://github.com/harningt/luajson.git
git clone https://github.com/Tieske/uuid.git
```

Now you can configure `nginx-auth-proxy.nginx` to setup listening and redirection
hosts. Than put this file into nginx configuretion directory.
