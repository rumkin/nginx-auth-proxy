'use strict';

const fetch = require('node-fetch');

fetch('http://nginx-auth-proxy', {
    method: 'POST',
    headers: {
        'x-authenticate': 'web-rsa',
        'x-auth-user': 'user',
        'x-auth-sign': 'signature',
    }
})
.then(res => res.text())
.then(text => console.log(text))
.catch(err => {
    console.error(err.stack || err.message);
    process.exit(1);
});
