var Push = require('./server/push');
var Token = require('./server/token');
var composer = require('./index');


composer(function (err, server) {

    if (err) {
        throw err;
    }

    Token.attach(server);
    Push.connect();

    server.start(function () {
        console.info('Started joyy server');
    });
});
