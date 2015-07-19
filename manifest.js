var Confidence = require('confidence');
var Config = require('./config');

var criteria = {
    env: process.env.NODE_ENV
};


var manifest = {
    $meta: 'This file defines the joyy server.',
    server: {
        debug: {
            request: ['error']
        }
    },
    connections: [{
        port: Config.get('/port/api'),
        labels: ['api']
    }],
    plugins: {
        'good': {
            opsInterval: 1000,
            reporters: [{
                reporter: require('good-console'),
                events: { log: '*', response: '*' }
            }, {
                reporter: require('good-file'),
                events: { error: '*' },
                config: './log/good.log'
            }]
        },
        'hapi-node-postgres': {
            connectionString: Config.get('/db/connectionString'),
            native: Config.get('/db/native'),
            attach: 'onPreAuth'
        },
        'hapi-auth-basic': {},
        'hapi-auth-bearer-token': {},
        './server/authenticate': {},
        './server/api/comment': { basePath: '/v1' },
        './server/api/love': { basePath: '/v1' },
        './server/api/media': { basePath: '/v1' },
        './server/api/notification': { basePath: '/v1' },
        './server/api/person': { basePath: '/v1' },
        './server/api/sign': { basePath: '/v1' }
    }
};


var store = new Confidence.Store(manifest);


exports.get = function (key) {

    return store.get(key, criteria);
};


exports.meta = function (key) {

    return store.meta(key, criteria);
};
