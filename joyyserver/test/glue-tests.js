//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Code = require('code');
var Glue = require('../glue');
var Lab = require('lab');

// Test shortcuts
var lab = exports.lab = Lab.script();
var describe = lab.describe;
var it = lab.it;
var expect = Code.expect;


describe('compose()', function () {

    it('composes server with an empty manifest', function (done) {

        var manifest = {};

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            expect(server.connections).length(1);
            done();
        });
    });

    it('composes server with connections array having multiple entries', function (done) {

        var manifest = {
            connections: [
                {labels: 'a'},
                {labels: 'b'}
            ]
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            expect(server.connections).length(2);
            done();
        });
    });

    it('composes server with plugins having a plugin with null options', function (done) {

        var manifest = {
            plugins: {
                './test/plugins/helloworld.js': null
            }
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            expect(server.plugins.helloworld).to.exist();
            expect(server.plugins.helloworld.hello).to.equal('world');
            done();
        });
    });

    it('composes server with plugins having a plugin registered with options', function (done) {

        var manifest = {
            plugins: {
                './test/plugins/helloworld.js': {who: 'earth'}
            }
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            expect(server.plugins.helloworld).to.exist();
            expect(server.plugins.helloworld.hello).to.equal('earth');
            done();
        });
    });

    it('composes server with plugins having a plugin with null options and null register options', function (done) {

        var manifest = {
            plugins: {
                './test/plugins/helloworld.js': [{}]
            }
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            expect(server.plugins.helloworld).to.exist();
            expect(server.plugins.helloworld.hello).to.equal('world');
            done();
        });
    });

    it('composes server with plugins having a plugin registered with register options', function (done) {

        var manifest = {
            plugins: {
                './test/plugins/route.js': [{
                    routes: { prefix: '/test/' }
                }]
            }
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            server.inject('/test/plugin', function (response) {

                expect(response.statusCode).to.equal(200);
                done();
            });
        });
    });

    it('composes server with plugins having a plugin loaded multiple times', function (done) {

        var manifest = {
            connections: [
                {labels: 'a'},
                {labels: 'b'}
            ],
            plugins: {
                './test/plugins/route.js': [
                    {
                        select: 'a',
                        routes: { prefix: '/a/' }
                    },
                    {
                        select: 'b',
                        routes: { prefix: '/b/' }
                    }
                ]
            }
        };

        Glue.compose(manifest, function (err, server) {

            expect(err).to.not.exist();
            server.select('a').inject('/a/plugin', function (response) {

                expect(response.statusCode).to.equal(200);
                server.select('b').inject('/b/plugin', function (res) {

                    expect(res.statusCode).to.equal(200);
                    done();
                });
            });
        });
    });

    it('composes server with plugins resolved using options.relativeTo', function (done) {

        var manifest = {
            plugins: {
                './helloworld.js': null
            }
        };

        Glue.compose(manifest, { relativeTo: __dirname + '/plugins' }, function (err, server) {

            expect(err).to.not.exist();
            expect(server.plugins.helloworld.hello).to.equal('world');
            done();
        });
    });

    it('throws on bogus options.realativeTo path (server.cache)', function (done) {

        var manifest = {
            server: {
                cache: './catbox-memory'
            }
        };

        expect(function () {

            Glue.compose(manifest, { relativeTo: __dirname + '/badpath' }, function () { });
        }).to.throw(/Cannot find module/);
        done();
    });

    it('throws on options not an object', function (done) {

        var manifest = {};

        expect(function () {

            Glue.compose(manifest, 'hello', function () { });
        }).to.throw(/Invalid options/);
        done();
    });

    it('throws on callback not a function', function (done) {

        var manifest = {};

        expect(function () {

            Glue.compose(manifest, 'hello');
        }).to.throw(/Invalid callback/);
        done();
    });

    it('throws on invalid manifest (not an object)', function (done) {

        var manifest = 'hello';

        expect(function () {

            Glue.compose(manifest, function () { });
        }).to.throw(/Invalid manifest/);
        done();
    });

    it('throws on invalid manifest (server not an object)', function (done) {

        var manifest = {
            server: 'hello'
        };

        expect(function () {

            Glue.compose(manifest, function () { });
        }).to.throw(/Invalid manifest/);
        done();
    });

    it('throws on invalid manifest (connections not an array)', function (done) {

        var manifest = {
            connections: 'hello'
        };

        expect(function () {

            Glue.compose(manifest, function () { });
        }).to.throw(/Invalid manifest/);
        done();
    });

    it('throws on invalid manifest (connections must have at least one entry)', function (done) {

        var manifest = {
            connections: []
        };

        expect(function () {

            Glue.compose(manifest, function () { });
        }).to.throw(/Invalid manifest/);
        done();
    });

    it('throws on invalid manifest (plugins not an object)', function (done) {

        var manifest = {
            plugins: 'hello'
        };

        expect(function () {

            Glue.compose(manifest, function () { });
        }).to.throw(/Invalid manifest/);
        done();
    });
});
