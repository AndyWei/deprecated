var TokenManager = require('./server/tokenmanager');
var composer = require('./index');


composer(function (err, server) {

    if (err) {
        throw err;
    }

    TokenManager.setCache(server);

    server.start(function () {
        console.info('Started joyy server');
    });
});
