\ir  setup.sql


INSERT INTO person
    (    name,                                                       password,                 email, org_name, validated, created_at, updated_at, coordinate) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'jack@gmail.com', 'goooog',      true,      now(),      now(),   ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com', 'goooog',      true,      now(),      now(),   ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',      'appple',      true,      now(),      now(),   ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com', 'joyyyy',      true,      now(),      now(),   ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO media
    (owner_id,            filename,  path_version,  caption, created_at, coordinate) VALUES
    (      1, 'j5802_458440716099',             0, '750_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j0128_458441665579',             0, '375_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j6301_458441807960',             0, '375_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j5222_458441928465',             0, '375_.9',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j2552_458446437154',             0, '375_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j9187_458447815669',             0, '375_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (      1, 'j2715_458447869224',             0, '375_.7',      now(), ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326));


INSERT INTO comment
    (media_id, owner_id, created_at, content) VALUES
    (       1,        2,      now(), 'How many sqft?'),
    (       1,        3,      now(), 'Include kitchen as well?'),
    (       1,        4,      now(), 'I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (       1,        1,      now(), '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!'),
    (       2,        2,      now(), 'This is andy!'),
    (       2,        3,      now(), 'Ping'),
    (       2,        4,      now(), 'Mike always talk a lot: I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (       2,        1,      now(), '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!');


INSERT INTO love
    (sender_id, receiver_id, status, created_at, updated_at) VALUES
    (        4,           1,     20,      now(),      now()),
    (        3,           1,     20,      now(),      now()),
    (        2,           1,     20,      now(),      now()),
    (        2,           1,     20,      now(),      now()),
    (        4,           2,      0,      now(),      now()),
    (        3,           2,      0,      now(),      now()),
    (        1,           2,      0,      now(),      now()),
    (        1,           2,      0,      now(),      now()),
    (        4,           1,      0,      now(),      now()),
    (        3,           1,      0,      now(),      now()),
    (        2,           1,      0,      now(),      now()),
    (        2,           1,      0,      now(),      now());
