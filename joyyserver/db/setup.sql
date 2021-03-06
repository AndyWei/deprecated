/* Delete all the tables and data contained, then we'll make 'joyy' a virgin DB */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public IS 'standard public schema';

/* Enable PostGIS*/
CREATE EXTENSION postgis;

BEGIN;
\ir  tables/person.sql
\ir  tables/post.sql
\ir  tables/comment.sql
\ir  tables/wink.sql
COMMIT;
