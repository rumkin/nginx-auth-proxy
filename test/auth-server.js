'use strict';

const http = require('http');
const port = process.argv[2] || 8080;
const ed = require('ed25519-supercop');
const crypto = require('crypto');

var sign = ed.createKeyPair(crypto.createHash('sha256').update('12345678').digest());

http.createServer((req, res) => {
    // Read body
    if (req.method === 'GET') {
        res.end('{}');
        return;
    }

    let chunks = [];
    let json = function(data) {
        var out = JSON.stringify(data);
        res.setHeader('content-type', 'application/json');
        res.setHeader('content-length', out.length);
        res.end(out);
    }

    if (! req.headers['content-length']) {
        res.statusCode = 400;
        json({error: 'empty_body'});
        return;
    }

    req.on('data', chunk => {
        chunks.push(chunk);
    });

    req.on('end', () => {
        var data = Buffer.concat(chunks).toString();

        try {
            data = JSON.parse(data);
        } catch (err) {
            res.statusCode = 400;
            json({error: 'not_a_json'});
            return;
        }

        if (typeof data !== 'object') {
            res.statusCode = 400;
            json({error: 'json_body'});
            return;
        }

        if (data.user !== 'user' || ! ed.verify(data.signature, 'nginx-auth-proxy', sign.publicKey)) {
            res.statusCode = 403;
            json({result: false});
            return;
        }

        json({result: true});
    });
})
.listen(port, () => {
    console.log('Server is started at port %s', port);
});
