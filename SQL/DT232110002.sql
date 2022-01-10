use DESTATIS;

# drop table if exists DT232110002;

create table if not exists `DT232110002` (
  `Jahr` int(11)
  , `Male` bigint(20) NOT NULL DEFAULt 0
  , `Female` bigint(20) NOT NULL DEFAULT 0
  , PRIMARY KEY (`Jahr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL 
INFILE '/tmp/23211-0002.csv'      
INTO TABLE DT232110002
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

create or replace view Selbstmorde as

select
    `Jahr` as Jahr
    , 'Männer' as Geschlecht
    , Male as Anzahl
from DT232110002
union
select
    `Jahr` as Jahr
    , 'Frauen' as Geschlecht
    , Female as Anzahl
from DT232110002
;
