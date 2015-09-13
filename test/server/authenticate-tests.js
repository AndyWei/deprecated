//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var AuthPlugin = require('../../server/authenticate');
var Code = require('code');
var Config = require('../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');

var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreHandler'
    }
};

var server;

lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/api') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        done();
    });
});


lab.afterEach(function (done) {
    done();
});


lab.experiment('Auth Basic: ', function () {

    lab.test('return authentication credentials for valid phone:password', function (done) {

        server.route({
            method: 'GET',
            path: '/',
            handler: function (request, reply) {

                server.auth.test('simple', request, function (err, credentials) {

                    Code.expect(err).to.not.exist();
                    Code.expect(credentials).to.be.an.object();
                    reply('ok');
                });
            }
        });

        var getRequest = {
            method: 'GET',
            url: '/',
            headers: {
                authorization: 'Basic ' + (new Buffer('14257850318:password')).toString('base64')
            }
        };

        server.inject(getRequest, function () {
            done();
        });
    });


    lab.test('detect wrong password', function (done) {

        server.route({
            method: 'GET',
            path: '/',
            handler: function (request, reply) {

                server.auth.test('simple', request, function (err, credentials) {

                    Code.expect(err).to.exist();
                    Code.expect(err.output.statusCode).to.equal(401);
                    Code.expect(credentials).to.be.null();
                    reply('reject');
                });
            }
        });

        var getRequest = {
            method: 'GET',
            url: '/',
            headers: {
                authorization: 'Basic ' + (new Buffer('14257850318:wrongpassword')).toString('base64')
            }
        };

        server.inject(getRequest, function () {
            done();
        });
    });


    lab.test('detect non-exist phone', function (done) {

        server.route({
            method: 'GET',
            path: '/',
            handler: function (request, reply) {

                server.auth.test('simple', request, function (err, credentials) {

                    Code.expect(err).to.exist();
                    Code.expect(err.output.statusCode).to.equal(401);
                    Code.expect(credentials).to.be.null();
                    reply('reject');
                });
            }
        });

        var getRequest = {
            method: 'GET',
            url: '/',
            headers: {
                authorization: 'Basic ' + (new Buffer('11234567890:password')).toString('base64')
            }
        };

        server.inject(getRequest, function () {
            done();
        });
    });


    lab.test('detect absent username', function (done) {

        server.route({
            method: 'GET',
            path: '/',
            handler: function (request, reply) {

                server.auth.test('simple', request, function (err, credentials) {

                    Code.expect(err).to.exist();
                    Code.expect(credentials).to.be.undefined();
                    reply('reject');
                });
            }
        });

        var getRequest = {
            method: 'GET',
            url: '/',
            headers: {
                authorization: 'Basic ' + (new Buffer(':password')).toString('base64')
            }
        };

        server.inject(getRequest, function () {
            done();
        });
    });
});
