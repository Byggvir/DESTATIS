use DESTATIS;

--  Requirements
-- 
--  This SLQ Job requires table DT124110006 from file 12411-0006.csv 
--  which can be imported from DESTATIS via ../bin/DT124110006  
--  
--  1. Download file 23211-0004.csv from DESTATIS
--  2. Prepare input with DT232110004 in ../bin 
--  3. Output must be in /tmp/23211-0004.csv
--  4. Execute this file with mysql < DT232110004.sql

--  After execution there will be three tables and on Views
--  * DT232110004
--  * DT232110004mod
--  * StdBev18
--  * SuizidRate

LOAD DATA LOCAL 
INFILE '/tmp/23211-0004-2020.csv'      
INTO TABLE DT232110004
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

drop table if exists DT232110004mod; 
create table if not exists `DT232110004mod` (
  `Jahr` int(11)
  , `Geschlecht` CHAR(1)
  , `AlterVon` int(11)
  , `AlterBis` int(11)
  , `Anzahl` bigint(20) NOT NULL DEFAULt 0
  , PRIMARY KEY (
        `Jahr`
        , `Geschlecht`
        , `AlterVon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

select 
    S.`Jahr` as Jahr
    , 'M' as Geschlecht
    , S.AlterVon
    , S.AlterBis
    , S.Male as Anzahl
from DT232110004 as S
union
select 
    S.`Jahr` as Jahr
    , 'F' as Geschlecht
    , S.AlterVon
    , S.AlterBis
    , S.Female as Anzahl
from DT232110004 as S
;
