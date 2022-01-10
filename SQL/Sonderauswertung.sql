use DESTATIS;

-- Initialisieren der Tabelle mit den Sterbefällen pro Woche

drop table if exists SterbefaelleTag ;
drop table if exists STag ;

create temporary table STag (
      Jahr INT DEFAULT 2021
    , Tag INT DEFAULT 1
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (Jahr, Tag)
    ) ;

LOAD DATA LOCAL 
INFILE '/tmp/SterbefaelleT.csv'      
INTO TABLE STag
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

create table SterbefaelleTag (
      Datum DATE
    , Jahr INT DEFAULT 2021
    , Tag INT DEFAULT 0
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (Datum)
    )
    
select 
    adddate(concat(Jahr,'-01-01'),Tag) as Datum
    , Jahr as Jahr
    , Tag as Tag
    , Anzahl as Anzahl
from  STag; 

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

drop table if exists SterbeAGW;
drop table if exists SterbeAGM;

create table SterbeAGW
    ( Jahr INT(11)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , primary key ( Jahr, AlterVon )
    )
select distinct 
    Jahr,
    AlterVon,
    AlterBis 
from SterbefaelleWoche;

create table SterbeAGM
    ( Jahr INT(11)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , primary key ( Jahr, AlterVon )
    )
select distinct 
    Jahr,
    AlterVon,
    AlterBis 
from SterbefaelleMonat;

drop table if exists DT124110006mod;

create table DT124110006mod
    ( Jahr INT(11)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , Male BIGINT(20)
    , Female BIGINT(20)
    , primary key ( Jahr, AlterVon )
    )
select 
    Jahr as Jahr
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select sum(Male) from DT124110006 as B where B.Alter>=M.AlterVon and B.Alter<=M.AlterBis and year(B.Stichtag)=M.Jahr -1 ) as Male 
    , ( select sum(Female) from DT124110006 as B where B.Alter>=M.AlterVon and B.Alter<=M.AlterBis and year(B.Stichtag)=M.Jahr -1 ) as Female 
from SterbeAGM as M 
    where M.AlterVon < 85 
union 
select 
    Jahr as Jahr
    , 85 as AlterVon
    , 100 as AlterBis
    , (select sum(Male) from DT124110006 as B where B.Alter>=85 and year(B.Stichtag)=M.Jahr-1) as Male
    , (select sum(Female) from DT124110006 as B where B.Alter>=85 and year(B.Stichtag)=M.Jahr-1) as Female
from SterbeAGM as M
where
    AlterVon>=85;

create or replace view SterbefaelleWocheBev as

select * from (
select 
      M.Jahr as Jahr
    , M.Kw as Kw
    , M.AlterVon
    , M.AlterBis
    , M.Male
    , M.Female
    , D.Male as BevMale
    , D.Female as BevFemale
from SterbefaelleWoche as M
join DT124110006mod as D
on
    D.Jahr = M.Jahr
    and
    D.AlterVon = M.AlterVon
where 
    D.AlterVon < 85

UNION
select 
      M.Jahr as Jahr
    , M.Kw as Kw
    , 85 as  AlterVon
    , 100 as AlterBis
    , sum(M.Male)
    , sum(M.Female)
    , D.Male as BevMale
    , D.Female as BevFemale
from SterbefaelleWoche as M
join DT124110006mod as D
on
    D.Jahr = M.Jahr
    and
    D.AlterVon = 85
where 
    M.AlterVon >= 85
group by
   M.Jahr, M.Kw
) as B
order by
  Jahr
  , Kw
  , AlterVon
  , AlterBis
;

create or replace view SterbefaelleMonatBev as
select * from (
select 
    str_to_date(concat(M.Jahr, '-', M.Monat, '-',1),'%Y-%c-%e') as Datum
    , M. Jahr as Jahr
    , M.Monat as Monat
    , M.AlterVon as AlterVon
    , M.AlterBis as AlterBis
    , M.Male as Male
    , M.Female as Female
    , D.Male as BevMale
    , D.Female as BevFemale
from SterbefaelleMonat as M
join DT124110006mod as D
on
    D.Jahr = M.Jahr
    and
    D.AlterVon = M.AlterVon
where 
    D.AlterVon < 85
UNION
select 
    str_to_date(concat(M.Jahr, '-', M.Monat, '-',1),'%Y-%c-%e') as Datum
    , M.Jahr as Jahr
    , M.Monat as Monat
    , 85 as  AlterVon
    , 100 as AlterBis
    , sum(M.Male)
    , sum(M.Female)
    , D.Male as BevMale
    , D.Female as BevFemale
from SterbefaelleMonat as M
join DT124110006mod as D
on
    D.Jahr = M.Jahr
    and
    D.AlterVon = 85
where 
    M.AlterVon >= 85

group by
   M.Jahr, M.Monat
) as B

order by
  Jahr
  , Monat
  , AlterVon
  , AlterBis
;
