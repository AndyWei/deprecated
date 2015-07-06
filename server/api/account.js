var Async = require('async');
var Boom = require('boom');
var Config = require('../../config');
var Stripe = require('stripe')(Config.get('/stripe/platformSecretKey'));
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');
var _ = require('underscore');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // Create an individial account. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/account/individual',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    email: Joi.string().email().lowercase().min(3).max(30).required(),
                    first_name: Joi.string().max(50).required(),
                    last_name: Joi.string().max(50).required(),
                    year: Joi.number().min(1915).max(2015).required(),
                    month: Joi.number().min(1).max(12).required(),
                    day: Joi.number().min(1).max(31).required(),
                    ssn_last_4: Joi.string().regex(/^[0-9]+$/).length(4).required(),
                    line1: Joi.string().max(100).required(),
                    line2: Joi.string().optional(),
                    city: Joi.string().max(30).required(),
                    state: Joi.string().max(50).required(),
                    zipcode: Joi.string().max(10).required(),
                    routing_number: Joi.string().regex(/^[0-9]+$/).length(9).required(),
                    account_number: Joi.string().max(30).required()
                }
            }
        },
        handler: function (request, reply) {
            internals.createAccountHandler(0, request, reply);
        }
    });


    // Create a company account. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/account/company',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    biz_name: Joi.string().max(100).required(),
                    biz_tax_id: Joi.string().length(9).required(),
                    biz_line1: Joi.string().max(100).required(),
                    biz_line2: Joi.string().optional(),
                    biz_city: Joi.string().max(30).required(),
                    biz_state: Joi.string().max(50).required(),
                    biz_zipcode: Joi.string().max(10).required(),
                    email: Joi.string().email().lowercase().min(3).max(30).required(),
                    first_name: Joi.string().max(50).required(),
                    last_name: Joi.string().max(50).required(),
                    year: Joi.number().min(1915).max(2015).required(),
                    month: Joi.number().min(1).max(12).required(),
                    day: Joi.number().min(1).max(31).required(),
                    ssn_last_4: Joi.string().regex(/^[0-9]+$/).length(4).required(),
                    line1: Joi.string().max(100).required(),
                    line2: Joi.string().optional(),
                    city: Joi.string().max(30).required(),
                    state: Joi.string().max(50).required(),
                    zipcode: Joi.string().max(10).required(),
                    routing_number: Joi.string().regex(/^[0-9]+$/).length(9).required(),
                    account_number: Joi.string().max(30).required()
                }
            }
        },
        handler: function (request, reply) {
            internals.createAccountHandler(1, request, reply);
        }
    });

    next();
};


exports.register.attributes = {
    name: 'account'
};

internals.getIndividualAccountParameters = function (request) {

    var p = request.payload;
    var bankAccount = {
        country: 'US',
        currency: 'usd',
        routing_number: p.routing_number,
        account_number: p.account_number
    };

    var personalAddress = {
        line1: p.line1,
        city: p.city,
        state: p.state,
        postal_code: p.zipcode,
        country: 'US'
    };

    if (p.line2) {
        personalAddress.line2 = p.line2;
    }

    var legalEntity = {
        type: 'individual',
        first_name: p.first_name,
        last_name: p.last_name,
        dob: {
            year: p.year,
            month: p.month,
            day: p.day
        },
        personal_address: personalAddress,
        ssn_last_4: p.ssn_last_4
    };

    var tosAcceptance = {
        date: _.now(),
        ip: request.info.remoteAddress
    };

    var parameters = {
        country: 'US',
        managed: true,
        email: p.email,
        bank_account: bankAccount,
        default_currency: 'usd',
        legal_entity: legalEntity,
        tos_acceptance: tosAcceptance
    };

    return parameters;
};


internals.getCompanyAccountParameters = function (request) {

    var p = request.payload;
    var parameters = internals.getIndividualAccountParameters(request);

    parameters.business_name = p.biz_name;

    var address = {
        line1: p.biz_line1,
        city: p.biz_city,
        state: p.biz_state,
        postal_code: p.biz_zipcode,
        country: 'US'
    };

    if (p.biz_line2) {
        address.line2 = p.biz_line2;
    }

    parameters.legal_entity.address = address;
    parameters.legal_entity.business_name = p.biz_name;
    parameters.legal_entity.business_tax_id = p.biz_tax_id;
    parameters.legal_entity.type = 'company';

    return parameters;
};


internals.createAccountHandler = function (accountType, request, reply) {

    var userId = request.auth.credentials.id;
    var parameters = (accountType === 0) ? internals.getIndividualAccountParameters(request) : internals.getCompanyAccountParameters(request);

    Async.auto({
        stripe: function (next) {

            Stripe.accounts.create(parameters, function (err, result) {

                if (err) {
                    return next(err);
                }

                console.info(result);

                next(null, result);
            });
        },
        begin: ['stripe', function (next) {

            request.pg.client.query('BEGIN', function(err) {
                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                next(null);
            });
        }],
        accountId: ['begin', function (next, results) {

            var s = results.stripe;
            var queryConfig = {
                name: 'account_create',
                text: 'INSERT INTO account \
                           (account_type, user_id, email, stripe_account_id, secret, publishable, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, now(), now()) \
                           RETURNING id',
                values: [accountType, userId, parameters.email, s.id, s.keys.secret, s.keys.publishable]
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
        }],
        joyyorStatus: ['accountId', function (next) {

            var queryConfig = {
                name: 'jyuser_update_joyyor_status_unverified',
                text: 'UPDATE jyuser ' +
                      'SET joyyor_status = 1, updated_at = now() ' +
                      'WHERE id = $1 AND joyyor_status = 0 ' +
                      'RETURNING id',
                values: [userId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badData(c.QUERY_FAILED));
                }

                next(null);
            });
        }],
        commit: ['joyyorStatus', function (next) {

            request.pg.client.query('COMMIT', function(err) {
                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                next(null);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, results.accountId);
    });
};
