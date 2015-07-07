var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var UserPlugin = require('../../../server/api/user');


var lab = exports.lab = Lab.script();

var PgPlugin = {
    register: require('hapi-node-postgres'),
    options: {
        connectionString: Config.get('/db/connectionString'),
        native: Config.get('/db/native'),
        attach: 'onPreHandler'
    }
};

var jack = {
    id: 1
};

var andy = {
    id: 2
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, UserPlugin];
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


lab.experiment('user GET: ', function () {

    lab.test('/user: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/user?id=1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/user/me: found record for jack', function (done) {

        request = {
            method: 'GET',
            url: '/user/me',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });


    lab.test('/user/nearby: found in San Francisco', function (done) {

        request = {
            method: 'GET',
            url: '/user/nearby?lon=-122.4376&lat=37.7577&category=1&rating_below=5000'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });

    lab.test('/user/nearby: not found in Stockton', function (done) {

        request = {
            method: 'GET',
            url: '/user/nearby?lon=-121.3018775&lat=37.9730234&category=1&rating_below=5000'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });
});


lab.experiment('user POST: ', function () {

    lab.test('/user/profile: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/user/profile',
            payload: {
                age: 18,
                bio: 'I love this game',
                category: 1,
                display_name: 'andy',
                gender: 'm',
                hourly_rate: 100
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/user/coordinate: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/user/coordinate',
            payload: {
                lat: 37.555883,
                lon: -122.0135916
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
