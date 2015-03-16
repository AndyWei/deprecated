var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
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
    id: 1,
    username: 'jack',
    password: 'password'
};

var andy = {
    id: 2,
    username: 'andy',
    password: 'password'
};


var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, AuthPlugin, PgPlugin, OrdersPlugin];
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

    lab.test('/order/100: RecordNotFound when id not exist', function (done) {

        request = {
            method: 'GET',
            url: '/order/100',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result.message).to.equal(c.RecordNotFound);

            done();
        });
    });


    lab.test('/order/98765432109876543210: query error when id is invalid for Joi', function (done) {

        request = {
            method: 'GET',
            url: '/order/98765432109876543210',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            done();
        });
    });

    lab.test('/order/9876543210987654321: query error when id is invalid for DB', function (done) {

        request = {
            method: 'GET',
            url: '/order/9876543210987654321',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(500);

            done();
        });
    });


    lab.test('/order/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/order/1',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });

    lab.test('/orders/my: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/my',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });

    lab.test('/orders/my: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/my',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders/won: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/won',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });

    lab.test('/orders/won: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/won',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/orders/nearby: found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=0&lat=0'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });

    lab.test('/orders/nearby: not found', function (done) {

        request = {
            method: 'GET',
            url: '/orders/nearby?lon=10000.0&lat=-345.32'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});


lab.experiment('Orders POST: ', function () {

    lab.test('/order: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/order',
            payload: {
                price: 1.1,
                currency: 'usd',
                country: 'us',
                description: 'jump start',
                address: '2290 good ave, Fremont, CA 94555',
                lon: -3.456,
                lat: 75.84
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });

    lab.test('/order: create failed due to bad lon', function (done) {

        request = {
            method: 'POST',
            url: '/order',
            payload: {
                price: 1.1,
                currency: 'usd',
                country: 'us',
                description: 'jump start',
                address: '2290 good ave, Fremont, CA 94555',
                lon: 180.3,
                lat: 75.84
            },
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});
