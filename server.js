var Cache = require('./server/cache');
var Push = require('./server/push');
var composer = require('./index');


composer(function (err, server) {

    if (err) {
        throw err;
    }

    Cache.attach(server);
    Push.connect();

    server.start(function () {
        console.info('Started joyy server');
    });
});
