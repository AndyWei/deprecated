var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var PersonPlugin = require('../../../server/api/person');


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

var andy = {
    id: 2
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, PersonPlugin];
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


lab.experiment('person GET: ', function () {

    lab.test('/person: return multi records successfully', function (done) {

        request = {
            method: 'GET',
            url: '/person?id=1&id=2&id=3',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(3);

            done();
        });
    });


    lab.test('/person/nearby: found in San Francisco', function (done) {

        request = {
            method: 'GET',
            url: '/person/nearby?lon=-122.416462&lat=37.776609&before=5000',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });

    lab.test('/person/nearby: not found in Stockton', function (done) {

        request = {
            method: 'GET',
            url: '/person/nearby?lon=-122.4376&lat=37.7577&before=5000',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/person/profile: found a profile', function (done) {

        request = {
            method: 'GET',
            url: '/person/profile',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });
});


lab.experiment('person POST: ', function () {

    lab.test('/person/device: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/person/device',
            payload: {
                service: 1,
                device: 'FAKE_DEVICE_TOKEN',
                badge: 1
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/person/profile: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/person/profile',
            payload: {
                yob: 1995,
                bio: 'I love this game',
                name: 'andy',
                gender: 1
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/person/location: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/person/location',
            payload: {
                lat: 37.555883,
                lon: -122.0135916,
                cell: '94102'
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
