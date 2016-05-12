'use strict';

const fetch = require('node-fetch');
const crypto = require('crypto');
const chalk = require('chalk');
const cryptoStamp = require('crypto-stamp');

var cookies;
var holder = 'http://localhost';
var key = cryptoStamp.createKey('user', '12345678');
var stamp = cryptoStamp.generate({
    action: 'auth',
    signer: 'user@127.0.0.1',
    holders: ['localhost']
}, key.publicKey, key.secretKey);

fetch('http://nginx-auth-proxy', {
    method: 'POST',
    headers: {
        'authorization': 'web-rsa',
        'x-auth-user': stamp.signer,
        'x-auth-hash': stamp.hash,
        'x-auth-signature': stamp.signature,
        'origin': holder,
    }
})
.then(res => {
    cookies = res.headers.get('set-cookie');
    if (cookies) {
        if (! Array.isArray(cookies)) {
            cookies = [cookies];
        }
    }
    else {
        cookies = [];
    }

    cookies = cookies.map(cookie => (cookie||'').split(' ').shift().slice(0, -1));
    return res.text();
})
.then(text => console.log(chalk.yellow(text)))
.then(() => fetch('http://nginx-auth-proxy',
    {headers: {cookie: cookies}}
))
.then(res => res.text())
.then(text => console.log(chalk.yellow(text)))
.catch(err => {
    console.error(err.stack || err.message);
    process.exit(1);
});
