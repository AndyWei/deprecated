var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Error = require('../../../server/error');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var Lab = require('lab');
var Manifest = require('../../../manifest');
var OrdersPlugin = require('../../../server/api/orders');
var Path = require('path');
var PgPlugin = require('hapi-node-postgres');
var Proxyquire = require('proxyquire');


var lab = exports.lab = Lab.script();
var PgPlugin, request, server, stub;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, AuthPlugin, PgPlugin, OrdersPlugin];
    server = new Hapi.Server();
    server.connection({ port: Config.get('/port/web') });
    server.register(plugins, function (err) {

        if (err) {
            return done(err);
        }

        done();
    });
});


lab.afterEach(function (done) {

    // server.plugins['hapi-mongo-models'].BaseModel.disconnect();

    done();
});


lab.experiment('Orders GET: ', function () {

    lab.test('return an 404 error on incorrect path', function (done) {

        request = {
            method: 'GET',
            url: '/order/100/100',
            // credentials: AuthenticatedUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);

            done();
        });
    });


    lab.test('return a not found when find by id misses', function (done) {

        request = {
            method: 'GET',
            url: '/order/100',
            // credentials: AuthenticatedUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(404);
            Code.expect(response.result.message).to.match(Error.RecordNotFound);

            done();
        });
    });


    lab.test('return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/order/1',
            // credentials: AuthenticatedUser
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });
});


