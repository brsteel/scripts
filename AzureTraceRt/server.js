const express = require('express');
const { exec } = require('child_process');
const app = express();
app.get('/traceroute', (req, res) => {
    exec(`traceroute ${req.query.url}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        res.send(stdout);
    });
});
const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server running on port ${port}`));
