function __add_host {
    sudo bash -c 'echo "127.0.0.1 nginx-auth-proxy" >> /etc/hosts'
}

function __remove_host {
    sudo bash -c 'sed -i "/nginx-auth-proxy/d" /etc/hosts'
}

function __add_nginx_config {
    sudo ln -s $HOME/nging-auth-proxy /etc/nginx/sites-enabled
}

function __remove_nginx_config {
    sudo rm -f /etc/nginx/sites-enabled
}

function __install_deps {
    cd lua
    git clone https://github.com/cloudflare/lua-resty-cookie.git
    git clone https://github.com/openresty/lua-resty-redis.git
    git clone https://github.com/openresty/lua-cjson.git
    git clone https://github.com/Tieske/uuid.git
    # If there is problems with building lua-cjson
    # git clone https://github.com/harningt/luajson.git
}

function __apply {
    sudo service nginx restart
}

function __log {
    sudo tail -n 40 /var/log/nginx/error.log
}

function __run {
    node test/auth-server.js 1999 &

    SERVER_PID=$!
    sleep 1

    curl -sS \
        -H 'x-authenticate: signature' \
        -H 'x-auth-user: user' \
        -H 'x-auth-sign: signature' \
        -b tmp/cookie -c tmp/cookie \
        http://nginx-auth-proxy/

    kill -s 9 $SERVER_PID
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
