# joyyserver

The Node.js server for joyy.

## Technology

__Primary goal:__ Build a clean and scalable RESTful API for joyy.

Joyyserver is is built with the [hapi.js framework](https://github.com/hapijs/hapi) and
[toolset](https://github.com/hapijs). We're using
[PostgreSQL](https://www.postgresql.org/) as a data store. We
also use [Nodemailer](https://github.com/andris9/Nodemailer) for email
transport.

## Requirements

You need [Node.js](http://nodejs.org/download/) and
[PostgreSQL](https://www.postgresql.org/) installed and running.

We use [`bcrypt`](https://github.com/ncb000gt/node.bcrypt.js) for hashing
secrets. If you have issues during installation related to `bcrypt` then [refer
to this wiki
page](https://github.com/jedireza/frame/wiki/bcrypt-Installation-Trouble).


## Installation

```bash
$ git clone git@github.com:AndyWei/joyyserver.git && cd ./joyyserver
$ npm install
```


## Setup

__WARNING:__ This will clear all data in existing `users`, `admins` and
`adminGroups` MongoDB collections. It will also overwrite `/config.js` if one
exists.

```bash
$ npm run setup

# > joyyserver@0.0.0 setup /Users/ping/joyy/joyyserver
# > ./setup.js

# Project name: (joyyserver)
# Postgres URL: (postgres://postgres:password@localhost:5432/joyy)
# Root user email: joyybiz@gmail.com
# Root user password:
# System email: (joyybiz@gmail.com)
# SMTP host: (smtp.gmail.com)
# SMTP port: (465)
# SMTP username: (joyybiz@gmail.com)
# SMTP password:
# Setup complete.
```


## Running the app

```bash
$ npm start

# > joyyserver@0.0.0 start /Users/ping/joyy/joyyserver
# > ./node_modules/nodemon/bin/nodemon.js -e js,md server

# 20 Sep 03:47:15 - [nodemon] v1.2.1
# 20 Sep 03:47:15 - [nodemon] to restart at any time, enter `rs`
# 20 Sep 03:47:15 - [nodemon] watching: *.*
# 20 Sep 03:47:15 - [nodemon] starting `node server index.js`
# Started the plot device.
```

This will start the app using [`nodemon`](https://github.com/remy/nodemon).
`nodemon` will watch for changes and restart the app as needed.


## Philosophy

 - Create a RESTful API
 - Don't include a front-end
 - Write code in a simple and consistent way
 - It's just JavaScript
 - 100% test coverage


## Features

 - Login system with forgot password and reset password
 - Abusive login attempt detection
 - Facilities for notes and status updates

## Questions and contributing

Any issues or questions (no matter how basic), open an issue. Please take the
initiative to include basic debugging information like operating system
and relevant version details such as:

```bash
$ npm version

# { http_parser: '2.3',
#   node: '0.12.0',
#   v8: '3.28.73',
#   ares: '1.9.0-DEV',
#   uv: '0.10.27',
#   zlib: '1.2.8',
#   modules: '14',
#   openssl: '1.0.1h',
#   npm: '2.5.1'}
```


## Follow the [hapi.js coding conventions](http://hapijs.com/styleguide)



## Running tests

[Lab](https://github.com/hapijs/lab) is part of the hapi.js toolset and what we
use to write all of our tests.

For command line output:

```bash
$ npm test

# > joyyserver@0.0.1 test /Users/ping/joyy/joyyserver
# > ./node_modules/lab/bin/lab -c

# ..................................................
# ..................................................
# ..................................................
# ..................................................
# ..................................................
# .............................

# 249 tests complete
# Test duration: 4628 ms
# No global variable leaks detected
# Coverage: 100.00%
```

With html code coverage report:

```bash
$ npm run test-cover

# > joyyserver@0.0.1 test-cover /Users/ping/joyy/joyyserver
# > ./node_modules/lab/bin/lab -c -r html -o ./test/artifacts/coverage.html && open ./test/artifacts/coverage.html
```

This will run the tests and open a web browser to the visual code coverage
artifacts. The generated source can be found in `/tests/artifacts/coverage.html`.


## Copyright

© 2015 Ping Yang. All rights reserved.
