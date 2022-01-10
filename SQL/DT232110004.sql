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

-- 
--  drop table if exists DT232110004;
-- 

create table if not exists `DT232110004` (
  `Jahr` int(11)
  , `AlterVon` int(11)
  , `AlterBis` int(11)
  , `Male` bigint(20) NOT NULL DEFAULt 0
  , `Female` bigint(20) NOT NULL DEFAULT 0
  , PRIMARY KEY (`Jahr`, `AlterBis`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--LOAD DATA LOCAL 
--INFILE '/tmp/23211-0004.csv'      
--INTO TABLE DT232110004
--FIELDS TERMINATED BY ','
--IGNORE 0 ROWS;

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


create table if not exists SuizideAG 
    ( AlterVon INT(11) NOT NULL PRIMARY KEY
    , AlterBis INT(11) NOT NULL 
    , Altersgruppe CHAR (8)
    , INDEX(AlterBis)
    , INDEX(Altersgruppe))
select distinct
  AlterVon,
  AlterBis,
  concat('A',AlterVon,'-A', AlterBis) as Altergruppe
from DT232110004
;

--
--  Create table StdBev18
--  

drop table if exists StdBev18;

create table StdBev18 (
      Stichtag date NOT NULL
    , Geschlecht CHAR (1) DEFAULT 'M'
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 120
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY ( 
        Stichtag
        , Geschlecht
        , AlterVon
        )
    )
    
select 
    S.Stichtag as Stichtag
    , 'M' as Geschlecht
    , A.AlterVon as AlterVon
    , A.AlterBis as AlterBis
    , sum(S.Male) as Anzahl
from SuizideAG as A
join DT124110006 as S
on 
    S.`Alter`<= A.AlterBis
    and S.`Alter` >= A.AlterVon
group by
    S.Stichtag
    , A.AlterVon
    , A.AlterBis

union

select 
    S.Stichtag as Stichtag
    , 'F' as Geschlecht
    , A.AlterVon as AlterVon
    , A.AlterBis as AlterBis
    , sum(S.Female) as Anzahl
from SuizideAG as A
join DT124110006 as S
on 
    S.`Alter`<= A.AlterBis
    and S.`Alter` >= A.AlterVon
group by
    S.Stichtag
    , A.AlterVon
    , A.AlterBis
    ;
    
--
--  Views
--

create or replace view Selbstmorde as 
select 
    Jahr
    , case when S.Geschlecht = 'M' then 'Männer' else 'Frauen' end as Geschlecht
    , concat( 'A',S.AlterVon, '-A', S.AlterBis ) as Altersgruppe
    , S.AlterVon as AlterVon
    , S.AlterBis as AlterBis
    , S.Anzahl as Anzahl
    , B.Anzahl as PersonenZahl
    , S.Anzahl / B.Anzahl * 100000 as SuizidRate
from DT232110004mod as S 
join StdBev18 as B 
on 
    year(adddate(Stichtag,1)) = Jahr 
    and S.Geschlecht=B.Geschlecht 
    and S.AlterVon = B.AlterVon
;

create or replace view StdSelbstmorde as 
select 
    Jahr
    , case when S.Geschlecht = 'M' then 'Männer' else 'Frauen' end as Geschlecht
    , concat( 'A',S.AlterVon, '-A', S.AlterBis ) as Altersgruppe
    , S.AlterVon as AlterVon
    , S.AlterBis as AlterBis
    , S.Anzahl as Anzahl
    , S.Anzahl / B1.Anzahl * B2.Anzahl as StdAnzahl  
    , B1.Anzahl as PersonenZahl
    , B2.Anzahl as StdPersonenZahl
    , S.Anzahl / B1.Anzahl * 100000 as SuizidRate
from DT232110004mod as S 
join StdBev18 as B1 
on 
    year(adddate(B1.Stichtag,1)) = Jahr 
    and S.Geschlecht = B1.Geschlecht 
    and S.AlterVon   = B1.AlterVon
join StdBev18 as B2
on 
    S.Geschlecht = B2.Geschlecht 
    and S.AlterVon = B2.AlterVon
where
    year(adddate(B2.Stichtag,1)) = 2011
    and S.AlterVon > -1
;


create or replace view StdSelbstmordeJahr as 

select
    Jahr
    , Geschlecht
    , sum(Anzahl) as Anzahl
    , round(sum(StdAnzahl)) as StdAnzahl
from StdSelbstmorde
group by
    Jahr
    , Geschlecht;
