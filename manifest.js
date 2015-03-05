var Confidence = require('confidence');
var Config = require('./config');


var criteria = {
    env: process.env.NODE_ENV
};


var manifest = {
    $meta: 'This file defines the plot device.',
    server: {
        debug: {
            request: ['error']
        },
        connections: {
            routes: {
                security: true
            }
        }
    },
    connections: [{
        port: Config.get('/port/web'),
        labels: ['web']
    }],
    plugins: {
        'hapi-auth-basic': {},
        'hapi-node-postgres': {
            connectionString: Config.get('/db/connectionString'),
            native: Config.get('/db/natvie')
        },
        'lout': {},
        'visionary': {
            engines: { jade: 'jade' },
            path: './server/web'
        },
        './server/authenticate': {},
        './server/api/orders': { basePath: '/v1' },
        './server/web/index': {}
    }
};


var store = new Confidence.Store(manifest);


exports.get = function (key) {

    return store.get(key, criteria);
};


exports.meta = function (key) {

    return store.meta(key, criteria);
};
