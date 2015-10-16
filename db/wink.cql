/*
 * wink.cql
 * 
* The setup file for production
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */
 

/*
 * keyspace
 * refer to http://docs.datastax.com/en/cql/3.3/cql/cql_using/useExampleCreatingKeyspace.html
 * @Discussion: only need run it once
*/
CREATE KEYSPACE IF NOT EXISTS wink WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3
 };

/*
 * DB users and premissions
 */
CREATE USER IF NOT EXISTS api_server WITH PASSWORD 'password' NOSUPERUSER;

GRANT MODIFY ON KEYSPACE wink TO api_server;
