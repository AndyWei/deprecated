CREATE TABLE person
(
    -- Account fields updated in POST signup
    id                     BIGSERIAL  PRIMARY KEY,
    username               TEXT          NOT NULL, -- unique display name
    password               TEXT          NOT NULL, -- bcrypt hashed password, it always 60 bytes, however TEXT makes it flexible
    phone                  BIGINT        NOT NULL, -- phone number

    -- Profile fields updated in POST profile
    lang                   TEXT                  , -- the language of the person's phone locale
    reg                    CHAR(2)               , -- the photo bucket region of the avatar photo, which will be used by client to compose the subdomain of the avatar photo URL. E.g., 'na', 'eu', 'as'
    fn                     TEXT                  , -- the filename of avatar photo, which will be used to compose the avatar photo URL
    sex                    CHAR(1)               , -- 'M' - male, 'F' - female, 'X' - other
    yob                    NUMERIC(4)            , -- year of birth
    bio                    TEXT                  , -- user provided bio

    -- Social fields
    wcnt                   BIGINT                , -- the number of winks this person received
    fcnt                   INTEGER               , -- the number of friends of this person
    score                  BIGINT                , -- score will be used to sort person in a cell. score = 5 * winks + 10 * friends. In the future, more factors will contribute to score 

    -- Geo fields
    zip                    TEXT                  , -- the combined zipcode where the person last stayed. The format is Gender + CountryCode + OriginalZipcode. E.g. "MUS94555"

    -- Device fields
    service                SMALLINT              , -- the push service of the user equipment. 1 - APN, 2 - GCM, 3 - MPN,  
    device                 TEXT                  , -- the device token that identify an user equipment

    -- Management fields
    ct                     BIGINT        NOT NULL, -- created_at timestamp
    ut                     BIGINT        NOT NULL, -- updated_at timestamp
    deleted                BOOLEAN       NOT NULL DEFAULT false,

    UNIQUE (username)
);


CREATE INDEX person_username_index  ON person (username);
CREATE INDEX person_phone_index     ON person (phone);
CREATE INDEX person_score_index     ON person (score);
CREATE INDEX person_zip_index       ON person (zip);

