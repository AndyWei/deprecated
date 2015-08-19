var AuthPlugin = require('../../../server/api/auth');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var Lab = require('lab');

var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreAuth'
    }
};

var request, server;

lab.before(function (done) {

    var plugins = [PgPlugin, AuthPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/api') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        server.start(function () {
            return done();
        });
    });
});


lab.after(function (done) {

    server.stop(function () {

        return done();
    });
});


lab.experiment('Auth credential for external service: ', function () {

    lab.test('credential auth success', function (done) {

        request = {
            method: 'POST',
            url: '/auth/credential',
            payload: {
                jid: '1@joyy.im',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(true);

            return done();
        });
    });

    lab.test('credential auth fail due to wrong password', function (done) {

        request = {
            method: 'POST',
            url: '/auth/credential',
            payload: {
                jid: '1@joyy.im',
                password: 'invalidpassword'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(false);

            return done();
        });
    });

    lab.test('credential auth fail due to invalid domain name', function (done) {

        request = {
            method: 'POST',
            url: '/auth/credential',
            payload: {
                jid: '1@joyy.com',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(false);

            return done();
        });
    });
});


lab.experiment('Auth username for external service: ', function () {

    lab.test('username exists', function (done) {

        request = {
            method: 'POST',
            url: '/auth/username',
            payload: {
                jid: '1@joyy.im'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(true);

            return done();
        });
    });

    lab.test('username auth fail due to invalid JID name', function (done) {

        request = {
            method: 'POST',
            url: '/auth/username',
            payload: {
                jid: 'what@joyy.im'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(false);

            return done();
        });
    });

    lab.test('username auth fail due to invalid JID domain', function (done) {

        request = {
            method: 'POST',
            url: '/auth/username',
            payload: {
                jid: '1@joyy.in'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();
            Code.expect(response.result.success).to.equal(false);

            return done();
        });
    });
});
