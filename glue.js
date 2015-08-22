//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Async = require('async');
var Hapi = require('hapi');
var Hoek = require('hoek');
var Joi = require('joi');
var Path = require('path');


var exports = module.exports = {};
var internals = {};


internals.schema = {
    options: Joi.object({
        relativeTo: Joi.string()
    }),
    manifest: Joi.object({
        server: Joi.object(),
        connections: Joi.array().min(1),
        plugins: Joi.object()
    })
};


exports.compose = function (manifest /*, [options], callback */) {

    var options = arguments.length === 2 ? {} : arguments[1];
    var callback = arguments.length === 2 ? arguments[1] : arguments[2];

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Joi.assert(options, internals.schema.options, 'Invalid options');
    Joi.assert(manifest, internals.schema.manifest, 'Invalid manifest');

    // Create server

    var serverOpts = internals.parseServer(manifest.server || {}, options.relativeTo);
    var server = new Hapi.Server(serverOpts);

    Async.waterfall([
        function (next) {

            if (manifest.connections) {
                manifest.connections.forEach(function (connect) {

                    server.connection(connect);
                });
            }
            else {
                server.connection();
            }

            next();
        },
        function (next) {

            var plugins = [];

            Object.keys(manifest.plugins || {}).forEach(function (name) {

                var plugin = internals.parsePlugin(name, manifest.plugins[name], options.relativeTo);
                plugins = plugins.concat(plugin);
            });

            next(null, plugins);
        },
        function (plugins, next) {
            internals.registerPlugins(server, plugins, function (err) {
                next(err);
            });
        }
    ], function (err) {

        if (err) {
            console.log(err);
            return callback(err);
        }

        callback(null, server);
    });
};

internals.registerPlugins = function (server, plugins, callback) {

    Async.eachSeries(plugins, function(plugin, next) {

        server.register(plugin.module, plugin.apply, function (err) {
            if (err) {
                next(err);
            }
            else {
                next(null);
            }
        });
    }, function(err) {
        
        if ( err ) {
            return callback(err);
        }

        callback(null);
    });
};


internals.parseServer = function (server, relativeTo) {

    if (server.cache) {
        server = Hoek.clone(server);

        var caches = [];
        var config = [].concat(server.cache);

        for (var i = 0, il = config.length; i < il; ++i) {
            var item = config[i];
            if (typeof item === 'string') {
                item = { engine: item };
            }
            if (typeof item.engine === 'string') {
                var strategy = item.engine;
                if (relativeTo && strategy[0] === '.') {
                    strategy = Path.join(relativeTo, strategy);
                }

                item.engine = require(strategy);
            }

            caches.push(item);
        }

        server.cache = caches;
    }

    return server;
};


internals.parsePlugin = function (name, plugin, relativeTo) {

    var path = name;
    if (relativeTo && path[0] === '.') {
        path = Path.join(relativeTo, path);
    }

    if (Array.isArray(plugin)) {
        var plugins = [];

        Hoek.assert(plugin.length > 0, 'Invalid plugin configuration');

        plugin.forEach(function (instance) {

            Hoek.assert(typeof instance === 'object', 'Invalid plugin configuration');

            var registerOptions = Hoek.cloneWithShallow(instance, 'options');
            delete registerOptions.options;

            plugins.push({
                module: {
                    register: require(path),
                    options: instance.options
                },
                apply: registerOptions
            });
        });

        return plugins;
    }

    return {
        module: {
            register: require(path),
            options: plugin
        },
        apply: {}
    };
};
