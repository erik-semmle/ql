const http = require('http');

const server = http.createServer((req, res) => {
    res.setHeader("Set-Cookie", `authKey=${makeAuthkey()}; SameSite=None`);
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h2>Hello world</h2>');
});