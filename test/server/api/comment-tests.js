//  Copyright (c) 2015 Joyy, Inc. All rights reserved.


var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var CommentPlugin = require('../../../server/api/comment');


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
    id: 1,
    username: 'jack'
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, CommentPlugin];
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

lab.experiment('Comment POST: ', function () {

    lab.test('/comment: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/comment',
            payload: {
                post: '1',
                content: 'yes'
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            return done();
        });
    });
});


lab.experiment('Comment GET: ', function () {

    lab.test('/comment: GET successfully', function (done) {

        request = {
            method: 'GET',
            url: '/comment?post=1&after=1437524632001&before=1437524632004'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            return done();
        });
    });


    lab.test('/comment: GET recent successfully', function (done) {

        request = {
            method: 'GET',
            url: '/comment/recent?post=1&post=2&post=3'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            return done();
        });
    });
});

