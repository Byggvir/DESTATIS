use DESTATIS;

drop table if exists DT124110006;

create temporary table if not exists `DT124110006tmp` (
  `Stichtag` DATE,
  `Alter` int(11) NOT NULL DEFAULT 0,
  `Male` bigint(20) NOT NULL DEFAULT 0,
  `Female` bigint(20) NOT NULL DEFAULT 0,
  `Both` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`Stichtag`,`Alter`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL 
INFILE '/tmp/12411-0006.csv'      
INTO TABLE DT124110006tmp
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

create table if not exists `DT124110006` (
  `Stichtag` DATE
  , `Geschlecht` CHAR(1) DEFAULT 'M'
  , `Alter` int(11) NOT NULL DEFAULT 0
  , `Einwohner` bigint(20) NOT NULL DEFAULt 0
  , PRIMARY KEY (`Stichtag`,`Geschlecht`,`Alter`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

select
    `Stichtag` as `Stichtag`
    , 'M' as `Geschlecht`
    , `Alter` as `Alter`
    , `Male` as `Einwohner`
from DT124110006tmp
union
select
    `Stichtag` as `Stichtag`
    , 'F' as `Geschlecht`
    , `Alter` as `Alter`
    , `Female` as `Einwohner`
from DT124110006tmp
;
