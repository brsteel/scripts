const https = require('https');
const express = require('express');
const path = require('path');
const app = express();

function getAddresses(req) {
    let forwarded = req.headers['x-forwarded-for'];
    let remoteAddress = req.socket.remoteAddress;
    let response = '<h1>Your IP Addresses</h1>';
  
    if (forwarded) {
      response += '<p>Forwarded Address: ' + forwarded + '</p>';
    }
  
    if (remoteAddress) {
      response += '<p>Remote Address: ' + remoteAddress + '</p>';
    }

    response += '<a href="/testconnectivity.ps1.txt">Download testconnectivity.ps1 as text file</a><br>';
    response += '<a href="/params.json.txt">Download params.json as text file</a>';
  
    return response;
}

app.get('/', function (req, res) {
    var response = getAddresses(req);
    res.send(response);
});

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

const port = process.env.PORT || 3000;
app.listen(port, function () {
    console.log('App listening on port ' + port + '!');
});

app.use(function (err, req, res, next) {
    console.error(err.stack);
    res.status(500).send('Server error');
});