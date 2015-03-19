var Token = require('./server/token');
var composer = require('./index');


composer(function (err, server) {

    if (err) {
        throw err;
    }

    Token.attach(server);

    server.start(function () {
        console.info('Started joyy server');
    });
});
