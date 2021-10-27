use DESTATIS;

-- Initialisieren der Tabelle mit den Sterbefällen pro Woche

drop table if exists SterbefaelleWoche ;
drop table if exists SWoche ;

create temporary table SWoche (
      Geschlecht INT DEFAULT 1 
    , Jahr INT DEFAULT 2021
    , Kw INT DEFAULT 1
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (Geschlecht, Jahr, Kw, AlterVon, AlterBis)
    ) ;

LOAD DATA LOCAL 
INFILE '/tmp/SterbefaelleW.csv'      
INTO TABLE SWoche
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;


create table SterbefaelleWoche (
    Jahr INT DEFAULT 2021
    , Kw INT DEFAULT 1
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Male BIGINT DEFAULT 0
    , Female BIGINT DEFAULT 0
    , PRIMARY KEY (Jahr, Kw, AlterVon, AlterBis)
    )
    
select 
    Jahr
    , Kw
    , AlterVon
    , AlterBis
    , sum(Male) as Male
    , sum(Female) as Female
from ( 
    select 
        Jahr
        , Kw
        , AlterVon
        , AlterBis
        , case when Geschlecht = 1 then Anzahl else 0 end as Male
        , case when Geschlecht = 2 then Anzahl else 0 end as Female
    from SWoche 
    ) as A 
group by 
    Jahr
    , Kw
    , AlterVon
    , AlterBis
;

-- Initialisieren der Tabelle mit den Sterbefällen pro Monat

drop table if exists SterbefaelleMonat ;

create temporary table SMonat (
      Geschlecht INT DEFAULT 1 
    , Jahr INT DEFAULT 2021
    , Monat INT DEFAULT 1
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (Geschlecht, Jahr, Monat, AlterVon, AlterBis)
    ) ;
    
LOAD DATA LOCAL 
INFILE '/tmp/SterbefaelleM.csv'      
INTO TABLE SMonat
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

create table SterbefaelleMonat (
    Jahr INT DEFAULT 2021
    , Monat INT DEFAULT 1
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Male BIGINT DEFAULT 0
    , Female BIGINT DEFAULT 0
    , PRIMARY KEY (Jahr, Monat, AlterVon, AlterBis)
    )
    
select 
    Jahr
    , Monat
    , AlterVon
    , AlterBis
    , sum(Male) as Male
    , sum(Female) as Female
from ( 
    select 
        Jahr
        , Monat
        , AlterVon
        , AlterBis
        , case when Geschlecht = 1 then Anzahl else 0 end as Male
        , case when Geschlecht = 2 then Anzahl else 0 end as Female
    from SMonat 
    where Monat < 13
    ) as A 
group by 
    Jahr
    , Monat
    , AlterVon
    , AlterBis
;
