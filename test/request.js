'use strict';

const fetch = require('node-fetch');
const ed = require('ed25519-supercop');
const crypto = require('crypto');

var sign = ed.createKeyPair(crypto.createHash('sha256').update('12345678').digest());

fetch('http://nginx-auth-proxy', {
    method: 'POST',
    headers: {
        'x-authenticate': 'web-rsa',
        'x-auth-user': 'user@127.0.0.1',
        'x-auth-sign': ed.sign('nginx-auth-proxy', sign.publicKey, sign.secretKey).toString('hex'),
    }
})
.then(res => res.text())
.then(text => console.log(text))
.catch(err => {
    console.error(err.stack || err.message);
    process.exit(1);
});
