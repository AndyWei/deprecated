//  Copyright (c) 2015 Joyy, Inc. All rights reserved.


var Cache = require('./server/cache');
var Push = require('./server/push');
var composer = require('./index');


composer(function (err, server) {

    if (err) {
        console.error(err);
        throw err;
    }

    Cache.start(function (error) {

        if (error) {
            console.error(error);
            throw error;
        }
    });

    Push.connect();

    server.start(function () {
        console.info('Started joyy server');
    });
});
