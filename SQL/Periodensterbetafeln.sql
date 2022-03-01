use DESTATIS;

--
-- Importieren der Tabelle mit der Sterbewahrscheinlichkeiten
-- 

drop table if exists Periodensterbetafeln ;

create table Periodensterbetafeln (
      Jahr INT DEFAULT 2018
    ,  `Geschlecht` CHAR(1) DEFAULT 'M'
    , `Alter` INT DEFAULT 1
    , p double DEFAULT 0
    , PRIMARY KEY (`Jahr`, `Geschlecht`, `Alter`)
    ) ;

LOAD DATA LOCAL 
INFILE '/tmp/Periodensterbetafeln.csv'      
INTO TABLE Periodensterbetafeln
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

