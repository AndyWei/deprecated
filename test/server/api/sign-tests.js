//  Copyright (c) 2015 Joyy, Inc. All rights reserved.


var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var SignPlugin = require('../../../server/api/sign');
var c = require('../../../server/constants');


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

    var plugins = [PgPlugin, HapiAuthBasic, HapiAuthToken, AuthPlugin, SignPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/api') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        server.start(function () {

            Cache.start(function (error) {
                if (error) {
                    return done(error);
                }
                return done();
            });
        });
    });
});


lab.after(function (done) {

    server.stop(function () {

        Cache.stop();
        return done();
    });
});


// lab.experiment('SignIn: ', function () {


//     lab.test('Sign in successfully', function (done) {

//         request = {
//             method: 'GET',
//             url: encodeURI('/signin?email=jack@gmail.com&password=password')
//         };

//         server.inject(request, function (response) {

//             Code.expect(response.statusCode).to.equal(200);
//             Code.expect(response.result.token).to.exist();
//             return done();
//         });
//     });
// });


lab.experiment('Signup: ', function () {

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

            return done();
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

            return done();
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

            return done();
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

            return done();
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

            return done();
        });
    });
});
