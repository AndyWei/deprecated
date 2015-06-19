var Async = require('async');
var Boom = require('boom');
var Config = require('../../config');
var Stripe = require('stripe')(Config.get('/stripe/platformSecretKey'));
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get all credit cards of the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/creditcards/my',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'creditcards_my',
                text: 'SELECT * FROM creditcards \
                       WHERE user_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [userId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // create a creditcard. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/creditcards',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    email: Joi.string().email().lowercase().min(3).max(30).required(),
                    number_last_4: Joi.string().regex(/^[0-9]+$/).length(4).required(),
                    stripe_token: Joi.string().max(50).required(),
                    expire_month: Joi.number().min(1).max(12).required(),
                    expire_year: Joi.number().min(2014).required()
                }
            }
        },
        handler: internals.createCardHandler
    });

    next();
};


exports.register.attributes = {
    name: 'creditcards'
};


internals.createCardHandler = function (request, reply) {

    var userId = request.auth.credentials.id;
    var p = request.payload;

    Async.auto({
        stripe: function (next) {

            var parameters = {
                source: p.stripe_token,
                description: p.email
            };

            Stripe.customers.create(parameters, function (err, customer) {

                if (err) {
                    return next(err);
                }

                console.info(customer);

                next(null, customer);
            });
        },
        creditCard: ['stripe', function (next, results) {

            var queryConfig = {
                name: 'creditcards_create',
                text: 'INSERT INTO creditcards \
                           (user_id, number_last_4, stripe_customer_id, expire_month, expire_year, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, now(), now()) \
                           RETURNING id',
                values: [userId, p.number_last_4, results.stripe.id, p.expire_month, p.expire_year]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badData(c.QUERY_FAILED));
                }

                next(null, result.rows[0]);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, {customer_id: results.stripe.id});
    });
};
