var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var BidsPlugin = require('../../../server/api/bids');


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

var mike = {
    id: 4
};

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, BidsPlugin];
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


lab.experiment('Bids GET: ', function () {

    lab.test('/bid/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/bid/1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids/my: found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/my',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });

    lab.test('/bids/my: not found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/my',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/bids/won: found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/won',
            credentials: mike
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });

    lab.test('/bids/won: not found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/won',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });
});


lab.experiment('Bids POST: ', function () {

    lab.test('/bid: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bid',
            payload: {
                orderid: 3,
                price: 9.1,
                description: 'ssssss'
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
