var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var CommentsPlugin = require('../../../server/api/comments');


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

var request, server;


lab.beforeEach(function (done) {

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, CommentsPlugin];
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


lab.experiment('Comments GET: ', function () {

    lab.test('/comments/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/comments/1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/comments/of/orders: found', function (done) {

        request = {
            method: 'GET',
            url: '/comments/of/orders?&order_id=1&order_id=2&after=0'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(8);

            done();
        });
    });

    lab.test('/comments/of/orders: not found', function (done) {

        request = {
            method: 'GET',
            url: '/comments/of/orders?&order_id=3&order_id=4&after=0'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/comments/count/of/orders: found', function (done) {

        request = {
            method: 'GET',
            url: '/comments/count/of/orders?&order_id=1&order_id=2'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });
});


lab.experiment('Comments POST: ', function () {

    lab.test('/comments: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/comments',
            payload: {
                order_id: '1',
                peer_id: '3',
                is_from_joyyor: 0,
                is_to_joyyor: 1,
                to_username: 'andy',
                contents: 'yes'
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
