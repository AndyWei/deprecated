// define is a function that binds "constants" to an object (commonly exports)
var define = require("node-constants")(exports);


// Error strings
define('RecordNotFound', 'Query excuted but no record found');