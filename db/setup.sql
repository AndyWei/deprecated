/* Delete all the tables and data contained, then we'll make 'joyy' a virgin DB */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public IS 'standard public schema';

/* Enable PostGIS*/
CREATE EXTENSION postgis;

BEGIN;
\ir  tables/users.sql
\ir  tables/accounts.sql
\ir  tables/invite.sql
\ir  tables/orders.sql
\ir  tables/bids.sql
\ir  tables/comments.sql
\ir  tables/reviews.sql
\ir  tables/creditcards.sql
COMMIT;
