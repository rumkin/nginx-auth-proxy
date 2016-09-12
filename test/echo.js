'use strict';

const fs = require('fs');
const grp = require('grp');
const http = require('http');
const port = process.argv[2] || process.env.PORT || 8080;
const group = process.argv[3] || process.env.GROUP || 'www-data';

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
    fs.chownSync(port, process.getuid(), grp.getgrnam(group).gr_gid);
    console.log('Server is started at port %s', port);
});
