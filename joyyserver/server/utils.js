//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var _ = require('lodash');

var exports = module.exports = {};

/*
 * Generate node-postgres variable length parameters string
 * E.g., input:  begin = 2, length = 3
 *       output: '($2, $3, $4) '
 */
exports.parametersString = function (begin, length) {

    var numbers = _.range(begin, begin + length);
    var parameters = _.map(numbers, function (num) { return '$' + num; });
    var result = '(' + parameters.join(', ') + ') ';
    return result;
};


/*
 * Generate money string from a number
 * E.g., formatMoney(12345678) -> "123,456.78"
 */
exports.formatMoney = function(cents, decimals, decimal_sep, thousands_sep) {

   var dollars = cents / 100;
   var decimalLength = isNaN(decimals) ? 2 : Math.abs(decimals), //if decimal is zero we must take it, it means user does not want to show any decimal
   d = decimal_sep || '.', //if no decimal separator is passed we use the dot as default decimal separator (we MUST use a decimal separator)

   t = (typeof thousands_sep === 'undefined') ? ',' : thousands_sep, //if you don't want to use a thousands separator you can pass empty string as thousands_sep value

   sign = (dollars < 0) ? '-' : '',

   //extracting the absolute value of the integer part of the number and converting to string
   i = parseInt(dollars = Math.abs(dollars).toFixed(decimalLength)) + '',

   j = ((j = i.length) > 3) ? j % 3 : 0;
   return sign + (j ? i.substr(0, j) + t : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, '$1' + t) + (decimalLength ? d + Math.abs(dollars - i).toFixed(decimalLength).slice(2) : '');
};
