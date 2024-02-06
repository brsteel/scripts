const express = require('express');
const multer  = require('multer');
const { BlobServiceClient } = require('@azure/storage-blob');
const inMemoryStorage = multer.memoryStorage();
const upload = multer({ storage: inMemoryStorage });

const app = express();

app.get('/', function (req, res) {
    res.send('Your IP address is ' + req.ip);
});

app.post('/upload', upload.single('networktest'), async function (req, res, next) {
    const blobServiceClient = BlobServiceClient.fromConnectionString('your-azure-storage-connection-string');
    const containerClient = blobServiceClient.getContainerClient('your-container-name');

    const blobName = Date.now() + req.file.originalname;
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);

    // Insert client IP address into the file before uploading
    const fileContent = `Client IP: ${req.ip}\n\n${req.file.buffer.toString()}`;
    const uploadBlobResponse = await blockBlobClient.upload(fileContent, fileContent.length);

    res.send(`File uploaded to Azure Blob storage as blob: ${blobName}`);
});

app.listen(3000, function () {
    console.log('App listening on port 3000!');
});