var AuthPlugin = require('../../../server/authenticate');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var ReviewsPlugin = require('../../../server/api/reviews');


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

    var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, PgPlugin, ReviewsPlugin];
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


lab.experiment('Reviews GET: ', function () {

    lab.test('/reviews/1: return a record successfully', function (done) {

        request = {
            method: 'GET',
            url: '/reviews/1'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.object();

            done();
        });
    });

    lab.test('/reviews/from_me: found', function (done) {

        request = {
            method: 'GET',
            url: '/reviews/from_me',
            credentials: andy
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(1);

            done();
        });
    });

    lab.test('/reviews/from_me: not found', function (done) {

        request = {
            method: 'GET',
            url: '/reviews/from_me',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });

    lab.test('/reviews/of: found', function (done) {

        request = {
            method: 'GET',
            url: '/reviews/of/2'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.have.length(2);

            done();
        });
    });

    lab.test('/reviews/of: not found', function (done) {

        request = {
            method: 'GET',
            url: '/reviews/of/3'
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result).to.be.an.array().and.to.be.empty();

            done();
        });
    });
});


lab.experiment('Reviews POST: ', function () {

    lab.test('/reviews: create successfully', function (done) {

        request = {
            method: 'POST',
            url: '/reviews',
            payload: {
                revieweeid: '4',
                rating: 4.5,
                comment: 'I like his attitude@!!'
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
