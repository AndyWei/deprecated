//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var HeartPlugin = require('../../../server/api/wink');


var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreAuth'
    }
};

var jack = {
    id: 1
};

var mike = {
    id: 4
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, HeartPlugin];
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
            done();
        });
    });
});


lab.afterEach(function (done) {

    Cache.stop();
    done();
});


lab.experiment('wink GET: ', function () {

    lab.test('/wink/me: found for jack', function (done) {

        request = {
            method: 'GET',
            url: '/wink/me?status=0&before=100',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(4);

            done();
        });
    });

    lab.test('/wink/me: not found for mike', function (done) {

        request = {
            method: 'GET',
            url: '/wink/me?status=0&before=100',
            credentials: mike
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/wink/my: found for jack', function (done) {

        request = {
            method: 'GET',
            url: '/wink/my?status=0&before=100',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });
});


lab.experiment('wink POST: ', function () {

    lab.test('/wink: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/wink',
            payload: {
                receiver: '2'
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});
