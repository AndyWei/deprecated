var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var LoginPlugin = require('../../../server/api/login');
var Token = require('../../../server/token');


var lab = exports.lab = Lab.script();

var request, server;

var jack = {
    id: 1
};


lab.experiment('Login: ', function () {

    lab.before(function (done) {

        var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, LoginPlugin];
        server = new Hapi.Server();
        server.connection({ port: Config.get('/port/api') });
        server.register(plugins, function (err) {

            if (err) {
                return done(err);
            }

            server.start(function () {

                Token.attach(server);
                done();
            });
        });
    });


    lab.after(function (done) {

        server.stop(function () {

            Token.detach();
            done();
        });
    });


    lab.test('assign token successfully', function (done) {

        request = {
            method: 'GET',
            url: '/login',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result.token).to.exist();
            done();
        });
    });
});
