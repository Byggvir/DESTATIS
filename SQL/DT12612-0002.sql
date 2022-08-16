use DESTATIS;

drop table if exists DT126120002;

create table `DT126120002` (
  `Jahr` int(11),
  `Monat` int(11) NOT NULL DEFAULT 1,
  `Geschlecht` char(1) NOT NULL DEFAULT 'M',
  `Anzahl`  bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`Jahr`,`Monat`,`Geschlecht`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA LOCAL 
INFILE '/tmp/12612-0002.csv'      
INTO TABLE DT126120002
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;
