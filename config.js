var Confidence = require('confidence');


var criteria = {
    env: process.env.NODE_ENV
};


var config = {
    $meta: 'This file configures the plot device.',
    projectName: 'joyyserver',
    port: {
        api: {
            $filter: 'env',
            test: 9000,
            $default: 8000
        }
    },
    db: {
        connectionString: 'postgres://postgres:password@localhost/joyy',
        native: true
    },
    redis: {
        host: '127.0.0.1',
        password: 'TheSimplePasswordForTestOnly',
        port: 6379
    },
    authAttempts: {
        forIp: 50,
        forIpAndUser: 7
    },
    nodemailer: {
        host: 'smtp.gmail.com',
        port: 465,
        secure: true,
        auth: {
            user: 'joyybiz@gmail.com',
            pass: 'weserveeachother!'
        }
    },
    system: {
        fromAddress: {
            name: 'joyyserver',
            address: 'joyybiz@gmail.com'
        },
        toAddress: {
            name: 'joyyserver',
            address: 'joyybiz@gmail.com'
        }
    }
};


var store = new Confidence.Store(config);


exports.get = function (key) {

    return store.get(key, criteria);
};


exports.meta = function (key) {

    return store.meta(key, criteria);
};
