var Composer = require('./index');

Composer(function (err, server) {

    if (err) {
        throw err;
    }

    server.start(function () {
        console.info('Started joyy server');
    });
});
