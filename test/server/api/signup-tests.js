var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var Lab = require('lab');
var SignupPlugin = require('../../../server/api/signup');
var c = require('../../../server/constants');


var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreHandler'
    }
};

var request, server;


lab.experiment('Signup: ', function () {

    lab.before(function (done) {

        var plugins = [PgPlugin, SignupPlugin];
        server = new Hapi.Server();
        server.connection({ port: Config.get('/port/api') });
        server.register(plugins, function (err) {

            if (err) {
                return done(err);
            }
        });

        server.start(function () {

            Cache.start(function (error) {
                if (error) {
                    return done(error);
                }
                done();
            });
        });
    });


    lab.after(function (done) {

        server.stop(function () {

            Cache.stop();
            done();
        });
    });


    lab.test('return an 400 error on password missing', function (done) {

        request = {
            method: 'POST',
            url: '/signup',
            payload: {
                email: 'mrmud@mudmail.mud',
                password: ''
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            done();
        });
    });


    lab.test('return when email exist', function (done) {

        request = {
            method: 'POST',
            url: '/signup',
            payload: {
                email: 'andy94555@gmail.com',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(409);
            Code.expect(response.result.message).to.equal(c.EMAIL_IN_USE);

            done();
        });
    });


    lab.test('return query error when email missing', function (done) {

        request = {
            method: 'POST',
            url: '/signup',
            payload: {
                email: '',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            done();
        });
    });


    lab.test('signup successfully', function (done) {

        request = {
            method: 'POST',
            url: '/signup',
            payload: {
                email: 'good789@gmail.com',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(201);

            done();
        });
    });

    lab.test('signup successfully with duplicate first name', function (done) {

        request = {
            method: 'POST',
            url: '/signup',
            payload: {
                email: 'andy@gmail.com',
                password: 'password'
            }
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(201);

            done();
        });
    });
});
