// Copyright (c) 2015 Joyy Inc. All rights reserved.

var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var Jwt  = require('jsonwebtoken');
var Lab = require('lab');
var XmppPlugin = require('../../../server/api/xmpp');

var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreAuth'
    }
};

var request, server, jwtToken;


function createJwtToken (personId, username) {

    var obj = { id: personId, username: username };
    var key = Config.get('/jwt/key');
    var options = { expiresInMinutes: Config.get('/jwt/expiresInMinutes')};
    var token = Jwt.sign(obj, key, options);

    return token;
}

lab.before(function (done) {

    var plugins = [PgPlugin, XmppPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/api') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        server.start(function () {

            jwtToken = createJwtToken('1', 'andy');
            console.log('jwtToken = %s', jwtToken);
            return done();
        });
    });
});


lab.after(function (done) {

    server.stop(function () {

        return done();
    });
});


lab.experiment('XMPP check_password for MongooseIM: ', function () {

    lab.test('auth success', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/check_password?user=andy&server=joyy.im&pass=' + jwtToken
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.boolean().and.to.equal(true);

            return done();
        });
    });

    lab.test('auth fail due to wrong password', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/check_password?user=andy&server=joyy.im&pass=' + 'invalid_token'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.boolean().and.to.equal(false);

            return done();
        });
    });

    lab.test('auth fail due to invalid domain name', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/check_password?user=andy&server=google.com&pass=' + jwtToken
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            return done();
        });
    });
});


lab.experiment('XMPP user_exists for MongooseIM: ', function () {

    lab.test('user exists', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/user_exists?user=andy&server=joyy.im'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.boolean().and.to.equal(true);

            return done();
        });
    });

    lab.test('username is valid but does not exists', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/user_exists?user=somebody&server=joyy.im'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.boolean().and.to.equal(false);

            return done();
        });
    });

    lab.test('username is invalid', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/user_exists?user=#&server=joyy.im'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            return done();
        });
    });

    lab.test('username auth fail due to invalid JID domain', function (done) {

        request = {
            method: 'GET',
            url: '/xmpp/user_exists?user=1&server=google.com'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            return done();
        });
    });
});
