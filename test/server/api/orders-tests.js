var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var OrdersPlugin = require('../../../server/api/orders');
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


var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, OrdersPlugin];
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


lab.experiment('Orders GET: ', function () {

    lab.test('/orders/100: RECORD_NOT_FOUND when id not exist', function (done) {

        request = {
            method: 'GET',
            url: '/order/100'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            done();
        });
    });


    lab.test('/orders/98765432109876543210: query error when id is invalid for Joi', function (done) {

        request = {
            method: 'GET',
            url: '/orders/98765432109876543210',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            done();
        });
    });

    lab.test('/orders/9876543210987654321: query error when id is invalid for DB', function (done) {

        request = {
            method: 'GET',
            url: '/orders/9876543210987654321',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(500);

            done();
        });
    });


    lab.test('/orders/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/orders/1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders/from_me: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/from_me',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(4);

            done();
        });
    });

    lab.test('/orders/from_me: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/from_me',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/orders/won_by_me: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/won_by_me',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });

    lab.test('/orders/won_by_me: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/won_by_me',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/orders/nearby: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=-122.4376&lat=37.7577'  // San Francisco, CA
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(3);

            done();
        });
    });

    lab.test('/orders/nearby: before and after', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=-122.4376&lat=37.7577&before=3&after=1' // San Francisco, CA
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });

    lab.test('/orders/nearby: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=-121.3018775&lat=37.9730234' // Stockton, CA
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/orders/nearby: found 2 in categories 1 and 2', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=-122.4176&lat=37.7577&categories=1&categories=2'  // San Francisco, CA
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });

    lab.test('/orders/nearby: found 1 in category 1', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=-122.4176&lat=37.7577&categories=1'  // San Francisco, CA
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });
});


lab.experiment('Orders POST: ', function () {

    lab.test('/orders: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/orders',
            payload: {
                price: 1.13,
                currency: 'usd',
                country: 'us',
                category: 6,
                description: 'jump start',
                address: '37010 Dusterberry Way Fremont, CA 94536',
                lon: -122.0135916,
                lat: 37.555883
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: create failed due to bad lon', function (done) {

        request = {
            method: 'POST',
            url: '/orders',
            payload: {
                price: 1,
                currency: 'usd',
                country: 'us',
                description: 'jump start',
                address: '2290 good ave, Fremont, CA 94555',
                lon: 180.3,
                lat: 75.84
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: update all fields successfully', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            payload: {
                address: '37010 Dusterberry Way Fremont, CA 94536',
                category: 6,
                description: 'what ever:)',
                lat: 37.555883,
                lon: -122.0135916,
                price: 1.13
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: update one field successfully', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            payload: {
                price: 8
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: update two fields successfully', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            payload: {
                address: '1 Joyy Way, San Francisco, CA 94101',
                price: 88.88
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: update failed due to wrong user_id', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            payload: {
                address: '37010 Dusterberry Way Fremont, CA 94536',
                category: 6,
                description: 'what ever:)',
                lat: 37.555883,
                lon: -122.0135916,
                price: 1.13
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.ORDER_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/orders: update failed due to wrong status', function (done) {

        request = {
            method: 'POST',
            url: '/orders/4',
            payload: {
                address: '37010 Dusterberry Way Fremont, CA 94536',
                category: 6,
                description: 'what ever:)',
                lat: 37.555883,
                lon: -122.0135916,
                price: 1.13
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.ORDER_UPDATE_FAILED);

            done();
        });
    });

    lab.test('/orders: update failed due to no payload', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.QUERY_INVALID);

            done();
        });
    });

    lab.test('/orders: update failed due to incomplete coordinate', function (done) {

        request = {
            method: 'POST',
            url: '/orders/3',
            payload: {
                address: '37010 Dusterberry Way Fremont, CA 94536',
                category: 6,
                description: 'what ever:)',
                lat: 37.555883,
                price: 1.13
            },
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(422);
            Code.expect(response.result.message).to.equal(c.COORDINATE_INVALID);

            done();
        });
    });

    lab.test('/orders: revoke successfully', function (done) {

        request = {
            method: 'POST',
            url: '/orders/revoke/1',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders: revoke failed due to wrong user_id', function (done) {

        request = {
            method: 'POST',
            url: '/orders/revoke/2',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.ORDER_REVOKE_FAILED);
            done();
        });
    });

    lab.test('/orders: revoke failed due to wrong status', function (done) {

        request = {
            method: 'POST',
            url: '/orders/revoke/4',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result.message).to.equal(c.ORDER_REVOKE_FAILED);
            done();
        });
    });
});
