function __add_host {
    sudo bash -c 'echo "127.0.0.1 nginx-auth-proxy" >> /etc/hosts'
}

function __remove_host {
    sudo bash -c 'sed -i "/nginx-auth-proxy/d" /etc/hosts'
}

function __add_nginx_config {
    sudo ln -s $PWD/nginx-auth-proxy.nginx /etc/nginx/sites-enabled/nginx-auth-proxy
}

function __rm_nginx_config {
    sudo rm -f /etc/nginx/sites-enabled/nginx-auth-proxy
}

function __install_deps {
    cd lua
    git clone https://github.com/cloudflare/lua-resty-cookie.git
    git clone https://github.com/openresty/lua-resty-redis.git
    git clone https://github.com/openresty/lua-cjson.git
    git clone https://github.com/Tieske/uuid.git
    git clone https://github.com/pintsized/lua-resty-http.git

    # If there is problems with building lua-cjson
    # git clone https://github.com/harningt/luajson.git
}

function __build {
    if [ -z "$DIR" ]
    then
        DIR=$PWD
    fi

    # Socket could be empty but should be set manually
    SOCKET=$1
    if [ -z "$SOCKET" ]
    then
        echo "Socket path isn't set. You should specify it manually" >&2
    fi

    CFG=$(cat ./src/nginx-auth-proxy.nginx | sed "s#\${DIR}#$DIR#g" | sed "s#\${SOCKET}#$SOCKET#g" )

    echo "$CFG" > nginx-auth-proxy.nginx
}

function __apply {
    sudo service nginx restart
}

function __log {
    sudo tail -n 40 /var/log/nginx/error.log
}

function __run {
    node test/auth-server.js 1999 &
    AUTH_SRV_PID=$!

    SOCKET=/tmp/nginx/echo.sock
    ls $(dirname $SOCKET) | grep $(basename $SOCKET) && rm $SOCKET
    node test/echo.js $SOCKET &

    ECHO_SRV_PID=$!

    sleep 1

    FORCE_COLOR=1 node test/request.js

    kill -s 9 $ECHO_SRV_PID
    kill -s 9 $AUTH_SRV_PID
}

function __test {
    result=$(__run)
    if [ $? -ne 0 ]
    then
        exit 1
    fi

    filter=$(echo $result | egrep '[0-9]+')

    if [ "$result" != "$filter" ]; then
        echo $result >&2
        exit 1
    else
        echo $result
    fi
}
