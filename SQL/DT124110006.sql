use DESTATIS;

drop table if exists DT124110006;

create table `DT124110006` (
  `Stichtag` DATE,
  `Alter` int(11) NOT NULL DEFAULT 0,
  `Male` bigint(20) NOT NULL DEFAULt 0,
  `Female` bigint(20) NOT NULL DEFAULT 0,
  `Both`  bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`Stichtag`,`Alter`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL 
INFILE '/tmp/12411-0006.csv'      
INTO TABLE DT124110006
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;
