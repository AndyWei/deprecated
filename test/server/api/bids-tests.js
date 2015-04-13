var AuthPlugin = require('../../../server/authenticate');
var BidsPlugin = require('../../../server/api/bids');
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
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

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
});


lab.experiment('Bids POST: ', function () {

    lab.test('/bids: create a bid successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids',
            payload: {
                order_id: '3',
                price: 9.55,
                note: 'I love this job!'
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids: accept a bid successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept/4',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/bids: accept a bid fail due to wrong user_id ', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept/1',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.ORDER_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/bids: accept a bid fail due to wrong status ', function (done) {

        request = {
            method: 'POST',
            url: '/bids/accept/1',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.ORDER_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/bids: revoke successfully', function (done) {

        request = {
            method: 'POST',
            url: '/bids/revoke/1',
            credentials: andy
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
            url: '/bids/revoke/2',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.BID_REVOKE_FAILED);
            done();
        });
    });

    lab.test('/bids: revoke fail due to wrong status', function (done) {

        request = {
            method: 'POST',
            url: '/bids/revoke/2',
            credentials: mike
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.BID_REVOKE_FAILED);
            done();
        });
    });
});
