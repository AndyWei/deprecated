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
        'hapi-mongo-models': {
            mongodb: Config.get('/hapiMongoModels/mongodb'),
            models: {
                Account: './server/models/account',
                AdminGroup: './server/models/admin-group',
                Admin: './server/models/admin',
                AuthAttempt: './server/models/auth-attempt',
                Session: './server/models/session',
                Status: './server/models/status',
                User: './server/models/user'
            },
            autoIndex: Config.get('/hapiMongoModels/autoIndex')
        },
        'hapi-node-postgres': {
            connectionString: Config.get('/db/connectionString'),
            native: Config.get('/db/natvie')
        },
        'lout': {},
        'visionary': {
            engines: { jade: 'jade' },
            path: './server/web'
        },
        './server/auth': {},
        './server/mailer': {},
        './server/api/accounts': { basePath: '/v1' },
        './server/api/admin-groups': { basePath: '/v1' },
        './server/api/admins': { basePath: '/v1' },
        './server/api/auth-attempts': { basePath: '/v1' },
        './server/api/contact': { basePath: '/v1' },
        './server/api/index': { basePath: '/v1' },
        './server/api/login': { basePath: '/v1' },
        './server/api/logout': { basePath: '/v1' },
        './server/api/orders': { basePath: '/v1' },
        './server/api/sessions': { basePath: '/v1' },
        './server/api/signup': { basePath: '/v1' },
        './server/api/statuses': { basePath: '/v1' },
        './server/api/users': { basePath: '/v1' },
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
