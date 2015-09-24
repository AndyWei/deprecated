//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var PostPlugin = require('../../../server/api/post');


var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreAuth'
    }
};

var andy = {
    id: 1
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, PostPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/api') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        Cache.start(function (error) {
            if (error) {
                return done(error);
            }
            return done();
        });
    });
});


lab.afterEach(function (done) {

    Cache.stop();
    return done();
});


lab.experiment('post GET: ', function () {

    lab.test('/post/nearby: found in Fremont', function (done) {

        request = {
            method: 'GET',
            url: '/post/nearby?zip=US94555&after=1437524632000&before=1437524632006'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(5);

            return done();
        });
    });

    lab.test('/post/nearby: not found in Japan', function (done) {

        request = {
            method: 'GET',
            url: '/post/nearby?zip=JP94103'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            return done();
        });
    });

    lab.test('/post: create new post', function (done) {

        request = {
            method: 'POST',
            url: '/post',
            payload: {
                reg: 'as',
                fn: 'some',
                caption: 'some caption',
                zip: 'CN610028'
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            return done();
        });
    });
});
