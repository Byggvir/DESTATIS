use DESTATIS;

drop table if exists DT124110013;

create table `DT124110013` (
  `Stichtag` DATE,
  `IdBundesland` int(11) NOT NULL DEFAULT 0,
  `Geschlecht` char(1) NOT NULL DEFAULT 'M',
  `Altersgruppe` int(11) NOT NULL DEFAULT 0,
  `Anzahl`  bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`Stichtag`,`IdBundesland`,`Geschlecht`,`Altersgruppe`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL 
INFILE '/tmp/12411-0013.csv'      
INTO TABLE DT124110013
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;
