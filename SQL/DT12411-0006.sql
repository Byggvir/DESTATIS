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

create table DT124110006X ( 
  Stichtag date
  , Geschlecht char(1)
  , `Alter` int(11)
  , Einwohner bigint(20)
  , primary key (Stichtag,Geschlecht, `Alter`)) 
  select 
    * 
  from DT124110006 
  where `Alter` <85

  union 

  select 
    C.Stichtag
    , A.Geschlecht
    , B.`Alter`
    , round(B.Einwohner/A.Einwohner * C.Einwohner) as Einwohner
  from WPP85 as A 
  join WPP as B 
  on 
    A.Jahr = year(B.Stichtag)
    and A.geschlecht = B.Geschlecht
  join DT124110006 as C
  on 
    A.Jahr = year(C.Stichtag)
    and A.geschlecht = C.Geschlecht
    and C.`Alter` = 85
  where 
    B.`Alter` > 84 
  ;
