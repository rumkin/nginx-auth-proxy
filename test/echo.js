'use strict';

const http = require('http');
const port = process.argv[2] || 8080;

http.createServer((req, res) => {
    res.connection.on('finish', () => {
        console.log(req.headers);
    });

    // Read body
    if (req.method === 'GET') {
        res.end('echo');
        return;
    }

    var chunks = [];

    req.on('data', chunk => {
        chunks.push(chunk);
    });

    req.on('end', () => {
        res.end(Buffer.concat(chunks));
    });
})
.listen(port, () => {
    console.log('Server is started at port %s', port);
});
