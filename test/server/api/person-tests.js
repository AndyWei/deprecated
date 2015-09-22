//  Copyright (c) 2015 Joyy Inc. All rights reserved.


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


var andy = {
    id: 1
};

var ping = {
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
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array();

            done();
        });
    });


    lab.test('/person/nearby: found in San Francisco', function (done) {

        request = {
            method: 'GET',
            url: '/person/nearby?zip=US94102&max=5000',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(11);

            done();
        });
    });

    lab.test('/person/nearby: not found in Japan', function (done) {

        request = {
            method: 'GET',
            url: '/person/nearby?zip=JP94102&max=5000',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/person/me: found a profile', function (done) {

        request = {
            method: 'GET',
            url: '/person/me',
            credentials: andy
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

    lab.test('/person/me: update successfully', function (done) {

        request = {
            method: 'POST',
            url: '/person/me',
            payload: {
                avatar: 'avatar.joyyapp.com/andy.jpg',
                yob: 1995,
                gender: 'M',
                lang: 'en_US'
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
                zip: 'US94102',
                cell: 'US'
            },
            credentials: ping
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});
