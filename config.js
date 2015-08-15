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
    db: {
        connectionString: 'postgres://postgres:password@localhost/joyy',
        native: true
    },
    jwt: {
        key: 'Lh;U2.JD5VW8*LoCJT1xR,Q9On=khDcy',
        expiresInMinutes: 31
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
    s3: {
        bucketName: 'joyydev',
        accessControlLevel: 'public-read',
        region: 'us-east-1'
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
