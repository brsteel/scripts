const express = require('express');
const multer  = require('multer');
const { BlockBlobClient } = require('@azure/storage-blob');
const inMemoryStorage = multer.memoryStorage();
const upload = multer({ storage: inMemoryStorage });

const app = express();

app.get('/', function (req, res) {
    var ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    res.send('Your IP address is ' + ip);
});

app.post('/upload', upload.single('networktest'), async function (req, res, next) {
    const sasUrl = req.query.sasUrl; // Get the SAS URL from the query parameters
    const blobClient = new BlockBlobClient(sasUrl);
    const blobName = Date.now() + req.file.originalname;
    
    // Upload the file to Azure Blob Storage
    const uploadBlobResponse = await blobClient.upload(req.file.buffer, req.file.size);
    console.log(`Upload block blob ${blobName} successfully`, uploadBlobResponse.requestId);
    
    res.send(`File uploaded to Azure Blob storage as blob: ${blobName}`);
});

app.listen(8080, function () {
    console.log('App listening on port 3000!');
});

app.use(function (err, req, res, next) {
    console.error(err.stack);
    res.status(500).send('Server error');
});