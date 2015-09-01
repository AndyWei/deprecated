//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Confidence = require('confidence');


var criteria = {
    env: process.env.NODE_ENV
};


var config = {
    $meta: 'This file configures the joyyserver.',
    projectName: 'joyyserver',
    authAttempts: {
        forIp: 50,
        forIpAndUser: 7
    },
    aws: {
        accessKeyId: 'AKIAICT6VFHHEMOS62AQ',
        secretAccessKey: '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',
        region: 'us-east-1',
        identifyPoolId: 'us-east-1:a9366287-4298-443f-aa0b-d4d6ee43fa67',
        identifyExpiresInSeconds: 3600
    },
    db: {
        connectionString: 'postgres://postgres:password@localhost/joyy',
        native: true
    },
    jwt: {
        key: 'Lh;U2.JD5VW8*LoCJT1xR,Q9On=khDcy',
        expiresInMinutes: 65
    },
    port: {
        api: {
            $filter: 'env',
            test: 9000,
            $default: 8000
        }
    },
    redis: {
        host: '127.0.0.1',
        password: 'TheSimplePasswordForTestOnly',
        port: 6379
    },
    stripe: {
        platformSecretKey: 'sk_test_LhUJDVWLoCJT1xRQ9OnkhDcy'
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
