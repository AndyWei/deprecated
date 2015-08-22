//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Lab = require('lab');
var Code = require('code');
var Config = require('../config');


var lab = exports.lab = Lab.script();


lab.experiment('Config', function () {

    lab.test('it gets config data', function (done) {

        Code.expect(Config.get('/')).to.be.an.object();

        done();
    });


    lab.test('it gets config meta data', function (done) {

        Code.expect(Config.meta('/')).to.match(/This file configures the joyyserver./i);

        done();
    });
});
