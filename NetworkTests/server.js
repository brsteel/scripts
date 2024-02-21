const express = require('express');
const multer  = require('multer');
const inMemoryStorage = multer.memoryStorage();
const upload = multer({ storage: inMemoryStorage });
const { BlockBlobClient } = require('@azure/storage-blob');

const app = express();

function getAddresses(req) {
    let forwarded = req.headers['x-forwarded-for'];
    let remoteAddress = req.socket.remoteAddress;
    let response = '';
  
    if (forwarded) {
      response += 'Forwarded Address: ' + forwarded;
    }
  
    if (remoteAddress) {
      if (response.length > 0) {
        response += '<br>';
      }
      response += 'Remote Address: ' + remoteAddress;
    }
  
    return response;
  }
  
  app.get('/', function (req, res) {
    var response = getAddresses(req);
    res.send(response);
  });

  
  app.put('/upload', upload.single('networktest'), async function (req, res) {
    const sasUrl = req.query.sasUrl; // Get the SAS URL from the query parameters
    console.log('sasUrl: ' + sasUrl);
    console.log('req.file: ' + req.file);
    if (!sasUrl) {
        res.status(400).send({
            message: 'SAS URL is required',
            sasUrl: sasUrl
        });
        return;
    }
    const blobName = Date.now() + req.file.originalname;

    // Create a BlockBlobClient directly with the SAS URL and blob name
    const blockBlobClient = new BlockBlobClient(sasUrl, blobName);

    // Upload the file to Azure Blob Storage
    const uploadBlobResponse = await blockBlobClient.upload(req.file.buffer, req.file.size);
    console.log(`Upload block blob ${blobName} successfully`, uploadBlobResponse.requestId);

    // Include sasUrl in the response
    res.send({
        message: `File uploaded to Azure Blob storage as blob: ${blobName}`,
        sasUrl: sasUrl
    });
});



const port = process.env.PORT || 3000;
app.listen(port, function () {
    console.log('App listening on port ' + port + '!');
});

app.use(function (err, req, res, next) {
    console.error(err.stack);
    res.status(500).send('Server error');
});