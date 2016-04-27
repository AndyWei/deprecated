#!/bin/bash
# The script to copy config files from joyyim repo to MongooseIM 

cp -f ~/joyyim/conf/ejabberd.cfg ~/MongooseIM/rel/mongooseim/etc/ejabberd.cfg
cp -f ~/joyyim/conf/app.config ~/MongooseIM/rel/mongooseim/etc/app.config
cp -f ~/joyyim/conf/vm.args ~/MongooseIM/rel/mongooseim/etc/vm.args 
cp -f ~/joyyim/conf/vars.config ~/MongooseIM/rel/vars.config
