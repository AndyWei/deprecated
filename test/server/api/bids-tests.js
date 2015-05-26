var AuthPlugin = require('../../../server/authenticate');
var BidsPlugin = require('../../../server/api/bids');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
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

var jack = {
    id: 1,
    username: 'jack'
};

var andy = {
    id: 2,
    username: 'andy'
};

var mike = {
    id: 4,
    username: 'mike'
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


lab.experiment('Bids: ', function () {

    lab.test('/bids/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/bids/1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids/from_me: found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/from_me',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });

    lab.test('/bids/from_me: not found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/from_me',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/bids/orders: found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/of/orders?&order_id=1&order_id=3&after=0',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(6);

            done();
        });
    });

    lab.test('/bids/orders: not found', function (done) {

        request = {
            method: 'GET',
            url: '/bids/of/orders?&order_id=2&order_id=4&after=0',
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

    lab.test('/bids: create a bid successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids',
            payload: {
                order_id: '3',
                price: 9.55,
                note: 'I love this job!',
                expire_at: 100000000
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids: accept a bid fail due to wrong user_id', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept',
            payload: {
                id: '4'
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.ORDER_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/bids: accept the bid failed because bid status is not active', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept',
            payload: {
                id: '2'
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.BID_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/bids: accept a bid successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept',
            payload: {
                id: '4'
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids: revoke fail due to wrong user_id', function (done) {

        request = {
            method: 'POST',
            url: '/bids/revoke',
            payload: {
                id: '6'
            },
            credentials: mike
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.BID_REVOKE_FAILED);
            done();
        });
    });

    lab.test('/bids: revoke fail due to wrong status', function (done) {

        request = {
            method: 'POST',
            url: '/bids/revoke',
            payload: {
                id: '7'
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.BID_REVOKE_FAILED);
            done();
        });
    });

    lab.test('/bids: revoke successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids/revoke',
            payload: {
                id: '5'
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});
