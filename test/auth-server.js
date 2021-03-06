'use strict';

const http = require('http');
const port = process.argv[2] || 8080;
const cryptoStamp = require('crypto-stamp');

var key = cryptoStamp.createKey('user', '12345678');

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

        if (data.signer !== 'user@127.0.0.1' || ! cryptoStamp.verify(data, key.publicKey)) {
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
