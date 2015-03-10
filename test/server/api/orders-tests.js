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

var testUser = {
    email: 'andy94555@gmail.com',
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

    lab.test('return an 404 error on incorrect path', function (done) {

        request = {
            method: 'GET',
            url: '/order/100/100',
            credentials: testUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);

            done();
        });
    });


    lab.test('return RecordNotFound when id not exist', function (done) {

        request = {
            method: 'GET',
            url: '/order/100',
            credentials: testUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result.message).to.equal(c.RecordNotFound);

            done();
        });
    });


    lab.test('return query error when id is invalid for Joi', function (done) {

        request = {
            method: 'GET',
            url: '/order/98765432109876543210',
            credentials: testUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(400);

            done();
        });
    });

    lab.test('return query error when id is invalid for DB', function (done) {

        request = {
            method: 'GET',
            url: '/order/9876543210987654321',
            credentials: testUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(500);

            done();
        });
    });


    lab.test('return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/order/1',
            credentials: testUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.a.string();

            done();
        });
    });
});
