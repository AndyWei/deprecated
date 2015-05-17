var _ = require('underscore');


var exports = module.exports = {};

/*
 *  left pad zero: (199, 7) -> '0000199'
 */
exports.padZero = function (num, len, pad) {

    var prefix = '';
    var str = num.toString();

    pad = pad || '0';
    len = (len || 2) - str.length;

    while(prefix.length < len) {
        prefix += pad;
    }

    return prefix + str;
};

/*
 * Generate node-postgres variable length parameters string
 * E.g., input:  begin = 2, length = 3
 *       output: '($2, $3, $4)'
 */
exports.parametersString = function (begin, length) {

    var numbers = _.range(begin, begin + length);
    var parameters = _.map(numbers, function (num) { return '$' + num; });
    var result = '(' + parameters.join(', ') + ') ';
    return result;
};

