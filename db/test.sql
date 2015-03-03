/* Delete all the tables and data contained, then we'll make 'joyy' a virgin DB */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public IS 'standard public schema';


/* Create orders table and insert test data */
CREATE TABLE orders (
   id            BIGSERIAL  PRIMARY KEY,
   description   VARCHAR(1000) NOT NULL,
   price         NUMERIC(12,2) NOT NULL,
   currency      CHAR(3)       NOT NULL,  --ISO 4217 Currency Codes
   status        SMALLINT      NOT NULL,
   created_by    BIGINT        NOT NULL,
   created_at    TIMESTAMP     NOT NULL,
   updated_at    TIMESTAMP     NOT NULL,
   deleted       BOOLEAN       NOT NULL,
   meeted_by     BIGINT                
);

INSERT INTO orders 
    (description,         price, currency, status, created_by, created_at, updated_at, deleted) VALUES
    ('jumpstart',          9.99,    'USD',      1,         1,       now(),      now(),   FALSE),
    ('house clean',       89.99,    'USD',      2,         1,       now(),      now(),    TRUE),
    ('fuzz buzz', 1234567890.99,    'RMB',      3,         1,       now(),      now(),   FALSE);
