/*
 * area.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */


/*
 * DSE In-Memory table for sczip -> areaid mapping of user areas
 * For memory management and table backing up, refer to http://docs.datastax.com/en/datastax_enterprise/4.8/datastax_enterprise/inmem/inmemTOC.html 
 *
 * @Discussion: this table is for the dynamic area use case. When the product got to GA, there will be only two areas for each country,
 *              and the api server will dynamically spict the area into small ones to make sure not too much users are in the same area
 */
CREATE TABLE IF NOT EXISTS wink.area (
    sczip     text, -- the users' sex-country-zip code where the user last stayed. The format is Sex + CountryCode + OriginalZipcode. E.g., "MUS94555"
    areaid    text, -- the current area id of the sczip. The areaid  should be a prefix of sczip. E.g., "MUS945". Note areaid could be the same as sczip

    PRIMARY KEY (sczip) 
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

