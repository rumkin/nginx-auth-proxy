'use strict';

const fetch = require('node-fetch');
const ed = require('ed25519-supercop');
const crypto = require('crypto');
const chalk = require('chalk');

var sign = ed.createKeyPair(crypto.createHash('sha256').update('12345678').digest());

var cookies;

fetch('http://nginx-auth-proxy', {
    method: 'POST',
    headers: {
        'authorization': 'web-rsa',
        'x-auth-type': 'authenticate',
        'x-auth-user': 'user@127.0.0.1',
        'x-auth-sign': ed.sign('nginx-auth-proxy', sign.publicKey, sign.secretKey).toString('hex'),
    }
})
.then(res => {
    cookies = res.headers.get('set-cookies').map(cookie => cookie.split(' ').shift());
    return res.text();
})
.then(text => console.log(chalk.yellow(text)))
.then(() => fetch('http://nginx-auth-proxy',
    {headers: {cookies}}
))
.then(res => res.text())
.then(text => console.log(chalk.yellow(text)))
.catch(err => {
    console.error(err.stack || err.message);
    process.exit(1);
});
