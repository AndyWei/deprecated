\ir  setup.sql


INSERT INTO person
    (    name,                                                       password,                 email,      org,     cell,  verified,            ct,            ut, coords) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'jack@gmail.com', 'goooog',  '94555',      true, 1437524632001, 1437524632001, ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com', 'goooog',  '94555',      true, 1437524632002, 1437524632002, ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',      'appple',  '94555',      true, 1437524632003, 1437524632003, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com', 'joyyyy',  '94102',      true, 1437524632004, 1437524632004, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO post
    (owner,            filename,  uv,  caption,            ct,    cell, coords) VALUES
    (    1, 'j5802_458440716099',  0, '750_.7', 1437524632000, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j0128_458441665579',  0, '375_.7', 1437524632001, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j6301_458441807960',  0, '375_.7', 1437524632002, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j5222_458441928465',  0, '375_.9', 1437524632003, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j2552_458446437154',  0, '375_.7', 1437524632004, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j9187_458447815669',  0, '375_.7', 1437524632005, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j2715_458447869224',  0, '375_.7', 1437524632006, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326));


INSERT INTO comment
    ( post, owner,            ct, content) VALUES
    (    1,     2, 1437524632001, 'How many sqft?'),
    (    1,     3, 1437524632002, 'Include kitchen as well?'),
    (    1,     4, 1437524632003, 'I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (    1,     1, 1437524632004, '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!'),
    (    2,     2, 1437524632005, 'This is andy!'),
    (    2,     3, 1437524632006, 'Ping'),
    (    2,     4, 1437524632007, 'Mike always talk a lot: I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (    2,     1, 1437524632008, '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!');


INSERT INTO heart
    (sender, receiver, status,            ct,            ut) VALUES
    (     4,        1,     20, 1437524632001, 1437524632001),
    (     3,        1,     20, 1437524632002, 1437524632002),
    (     2,        1,     20, 1437524632003, 1437524632003),
    (     2,        1,     20, 1437524632004, 1437524632004),
    (     4,        2,      0, 1437524632005, 1437524632005),
    (     3,        2,      0, 1437524632006, 1437524632006),
    (     1,        2,      0, 1437524632007, 1437524632007),
    (     1,        2,      0, 1437524632008, 1437524632008),
    (     4,        1,      0, 1437524632009, 1437524632009),
    (     3,        1,      0, 1437524632010, 1437524632010),
    (     2,        1,      0, 1437524632020, 1437524632020),
    (     2,        1,      0, 1437524632030, 1437524632030);
