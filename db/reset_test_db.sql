\ir  setup.sql


INSERT INTO person
    (    name,                                                       password,                 email,      org,     cell,  verified, gender,  yob,                  ppf, hearts,   score,            ct,            ut, coords) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'jack@gmail.com', 'goooog',  '94555',      true,      1, 1980, 'j5802_458440716099',      1,       5, 1437524632001, 1437524632001, ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com', 'goooog',  '94555',      true,      1, 1977, 'j0128_458441665579',      1,       5, 1437524632002, 1437524632002, ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'ping@gmail.com', 'appple',  '94555',      true,      2, null, 'j6301_458441807960',    235,    1155, 1437524632003, 1437524632003, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com', 'joyyyy',  '94102',      true,      1, null, 'j5222_458441928465',      1,       5, 1437524632004, 1437524632004, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'moon', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'moon@gmail.com', 'goooog',  '94555',      true,      0, null, 'j2552_458446437154',      0,       0, 1437524632001, 1437524632001, ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'sky1', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'sky1@gmail.com', 'goooog',  '94555',      true,      0, null, 'j9187_458447815669',      0,       0, 1437524632002, 1437524632002, ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  'sun2', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'sun2@gmail.com', 'appple',  '94555',      true,      0, null, 'j2715_458447869224',      0,       0, 1437524632003, 1437524632003, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'mini', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'mini@gmail.com', 'joyyyy',  '94102',      true,      3, null, 'j2725_460785678403', 342718, 1500000, 1437524632004, 1437524632004, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO post
    (owner,            filename,  uv,  caption,                              ct,    cell, coords) VALUES
    (    1, 'j5802_458440716099',  0, 'Whats up',                 1437524632000, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j0128_458441665579',  0, 'DREAM',                    1437524632001, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j6301_458441807960',  0, 'HOPE',                     1437524632002, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j5222_458441928465',  0, 'Like it',                  1437524632003, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j2552_458446437154',  0, 'maybe the best of things', 1437524632004, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j9187_458447815669',  0, 'Leonardo da Vinci',        1437524632005, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j3844_461624043152',  0, 'Take off',                 1437524632006, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326));


INSERT INTO comment
    ( post, owner,            ct, content) VALUES
    (    1,     2, 1437524632001, 'How many girlfriends?'),
    (    1,     3, 1437524632002, 'Whats up?'),
    (    1,     4, 1437524632003, 'The quick brown fox jumps over the lazy dog. '),
    (    1,     1, 1437524632004, 'Leonardo di ser Piero da Vinci, more commonly Leonardo da Vinci, (15 April 1452 – 2 May 1519) was an Italian polymath. His areas of strength included painting, sculpting, architecture, science, music, mathematics, engineering, invention, anatomy, geology, astronomy, botany, writing, history, and cartography.'),
    (    2,     2, 1437524632005, 'So we beat on, boats against the current, borne back ceaselessly into the past.'),
    (    2,     3, 1437524632006, 'The knife came down, missing him by inches, and he took off.'),
    (    2,     4, 1437524632007, 'What are u talking about?'),
    (    2,     1, 1437524632008, 'Remember Red, hope is a good thing, maybe the best of things, and no good thing ever dies.');


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
