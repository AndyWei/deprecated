/*
 * dev.cql
 * 
 * The setup file for local dev only
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */
 

/*
 * keyspace
 * refer to http://docs.datastax.com/en/cql/3.3/cql/cql_using/useExampleCreatingKeyspace.html
 * @Discussion: only need run it once
*/
CREATE KEYSPACE IF NOT EXISTS winkrock WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': '1'
 };

/*
 * DB users and premissions
 */
CREATE USER IF NOT EXISTS dev WITH PASSWORD 'password' NOSUPERUSER;

GRANT SELECT ON KEYSPACE winkrock TO dev;
GRANT MODIFY ON KEYSPACE winkrock TO dev;

