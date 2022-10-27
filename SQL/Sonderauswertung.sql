use DESTATIS;

--
-- Importieren der Tabelle mit den Sterbefällen pro Tag
-- 

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

--
-- Import der Sterbefälle pro Woche
--

drop table if exists SterbefaelleWoche ;

create table if not exists SterbefaelleWoche (
      Jahr INT DEFAULT 2021
    , Kw INT DEFAULT 1
    , Geschlecht CHAR(1) DEFAULT 'M' 
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Gestorbene BIGINT DEFAULT 0
    , PRIMARY KEY (Jahr, Kw, Geschlecht, AlterVon, AlterBis)
    ) ;

LOAD DATA LOCAL 
INFILE '/tmp/SterbefaelleW.csv'      
INTO TABLE SterbefaelleWoche
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

--
-- Initialisieren der Tabelle mit den Sterbefällen pro Monat
--

drop table if exists SterbefaelleMonat ;

create table if not exists SterbefaelleMonat (
      Jahr INT DEFAULT 2021
    , Monat INT DEFAULT 1
    , Geschlecht CHAR(1) DEFAULT 'M' 
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 15
    , Gestorbene BIGINT DEFAULT 0
    , PRIMARY KEY (Jahr, Monat, Geschlecht, AlterVon, AlterBis)
    ) ;
    
LOAD DATA LOCAL 
INFILE '/tmp/SterbefaelleM.csv'      
INTO TABLE SterbefaelleMonat
FIELDS TERMINATED BY ','
IGNORE 0 ROWS;

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

--
-- Erstellen der modifizierten Tabelle der Bevölkerung 
-- zur Anpassung an die Altersstruktur der Sterbefälle
-- 

drop table if exists DT124110006M;

create table DT124110006M
    ( Jahr INT(11)
    , Geschlecht CHAR(1)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , Einwohner BIGINT(20)
    , primary key ( Jahr, Geschlecht, AlterVon )
    , index (AlterVon, AlterBis)
    )
    
select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006 as B 
        where 
            B.Alter>=M.AlterVon 
            and B.Alter<=M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner 
from SterbeAGM as M 
    where M.AlterVon < 85

union

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006 as B 
        where 
            B.`Alter` >= M.AlterVon 
            and B.`Alter` <= M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGM as M 
    where M.AlterVon < 85 

union 

select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , 85 as AlterVon
    , 100 as AlterBis
    , ( select 
            sum(Einwohner) 
        from DT124110006 as B
        where
            B.`Alter` >= 85
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner
from SterbeAGM as M
where
    AlterVon >= 85

union 

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , 85 as AlterVon
    , 100 as AlterBis
    , ( select 
            sum(Einwohner) 
        from DT124110006 as B
        where
            B.`Alter` >= 85
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner
from SterbeAGM as M
where
    AlterVon >= 85
;

--
-- Erstellen der modifizierten Tabelle der Bevölkerung 
-- zur Anpassung an die Altersstruktur der Sterbefälle
-- 

drop table if exists DT124110006XM;

create table DT124110006XM
    ( Jahr INT(11)
    , Geschlecht CHAR(1)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , Einwohner BIGINT(20)
    , primary key ( Jahr, Geschlecht, AlterVon )
    , index (AlterVon, AlterBis)
    )
    
select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006X as B 
        where 
            B.Alter>=M.AlterVon 
            and B.Alter<=M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner 
from SterbeAGM as M 

union

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006X as B 
        where 
            B.`Alter` >= M.AlterVon 
            and B.`Alter` <= M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGM as M 

;

--
--
-- 

drop table if exists DT124110006W;

create table DT124110006W
    ( Jahr INT(11)
    , Geschlecht CHAR(1)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , Einwohner BIGINT(20)
    , primary key ( Jahr, Geschlecht, AlterVon )
    , index (AlterVon, AlterBis)
    )

select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006 as B 
        where 
            B.`Alter` >= W.AlterVon 
            and B.`Alter` <= W.AlterBis 
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner 
from SterbeAGW as W 
    where W.AlterVon < 85

union

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006 as B 
        where 
            B.`Alter` >= W.AlterVon 
            and B.`Alter` <= W.AlterBis 
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGW as W 
    where W.AlterVon < 85

union 

select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , 85 as AlterVon
    , 100 as AlterBis
    , ( select 
            sum(Einwohner) 
        from DT124110006 as B
        where
            B.`Alter` >= 85
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner
from SterbeAGW as W
where
    AlterVon >= 85

union 

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , 85 as AlterVon
    , 100 as AlterBis
    , ( select 
            sum(Einwohner) 
        from DT124110006 as B
        where
            B.`Alter` >= 85
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner
from SterbeAGW as W
where
    AlterVon >= 85
;

--
--
-- 

drop table if exists DT124110006XW;

create table DT124110006XW
    ( Jahr INT(11)
    , Geschlecht CHAR(1)
    , AlterVon INT(11)
    , AlterBis INT(11)
    , Einwohner BIGINT(20)
    , primary key ( Jahr, Geschlecht, AlterVon )
    , index (AlterVon, AlterBis)
    )

select 
    Jahr as Jahr
    , 'M' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006X as B 
        where 
            B.`Alter` >= W.AlterVon 
            and B.`Alter` <= W.AlterBis 
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner 
from SterbeAGW as W 

union

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from DT124110006X as B 
        where 
            B.`Alter` >= W.AlterVon 
            and B.`Alter` <= W.AlterBis 
            and year(B.Stichtag) = W.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGW as W 

;

--
--
--

create or replace view SterbefaelleWoche15 as

select 
      M.Jahr as Jahr
    , M.Kw as Kw
    , M.Geschlecht as Geschlecht
    , M.AlterVon
    , M.AlterBis
    , M.Gestorbene
from SterbefaelleWoche as M
where M.AlterVon < 85
UNION
select 
      M.Jahr as Jahr
    , M.Kw as Kw
    , M.Geschlecht as Geschlecht
    , 85 as  AlterVon
    , 100 as AlterBis
    , sum(M.Gestorbene)
from SterbefaelleWoche as M
where 
    M.AlterVon >= 85
group by
   M.Jahr, M.Kw, M.Geschlecht
;

--
-- Sterbefälle pro Woche mit Bevölkerung
--

create or replace view SterbefaelleWocheBev as

select S.*,D.Einwohner
from SterbefaelleWoche15 as S
join DT124110006W as D
on 
    D.Jahr = S.Jahr
    and D.Geschlecht = S.Geschlecht
    and D.AlterVon = S.AlterVon
order by
  S.Jahr
  , S.Kw
  , S.AlterVon
  , S.AlterBis
;


--
-- Sterbefälle pro Woche mit Bevölkerung
--

create or replace view SterbefaelleWocheBevX as

select S.*,D.Einwohner
from SterbefaelleWoche as S
join DT124110006XW as D
on 
    D.Jahr = S.Jahr
    and D.Geschlecht = S.Geschlecht
    and D.AlterVon = S.AlterVon
order by
  S.Jahr
  , S.Kw
  , S.AlterVon
  , S.AlterBis
;

--
--
--

create or replace view SterbefaelleMonatBev as
select 
    * 
from (
    select 
        str_to_date(concat(M.Jahr, '-', M.Monat, '-',1),'%Y-%c-%e') as Datum
        , M.Jahr as Jahr
        , M.Monat as Monat
        , M.Geschlecht as Geschlecht
        , M.AlterVon as AlterVon
        , M.AlterBis as AlterBis
        , M.Gestorbene as Gestorbene
        , D.Einwohner as Einwohner
    from SterbefaelleMonat as M
    join DT124110006M as D
    on
        D.Jahr = M.Jahr
        and
        D.AlterVon = M.AlterVon
        and 
        D.Geschlecht = M.Geschlecht
    where 
        D.AlterVon < 85
    group by
        M.Jahr, M.Monat, M.Geschlecht, AlterVon

    union

    select 
        str_to_date(concat(M.Jahr, '-', M.Monat, '-',1),'%Y-%c-%e') as Datum
        , M.Jahr as Jahr
        , M.Monat as Monat
        , M.Geschlecht as Geschlecht
        , 85 as AlterVon
        , 100 as AlterBis
        , sum(M.Gestorbene) as Gestorbene
        , D.Einwohner as Einwohner
    from SterbefaelleMonat as M
    join DT124110006M as D
    on
        D.Jahr = M.Jahr
        and
        D.AlterVon = 85
        and 
        D.Geschlecht = M.Geschlecht
    where 
        M.AlterVon >= 85

    group by
        M.Jahr, M.Monat, M.Geschlecht
    ) as B

order by
  Jahr
  , Monat
  , Geschlecht
  , AlterVon
  , AlterBis
;


--
--
--

create or replace view SterbefaelleMonatBevX as
select 
    * 
from (
    select 
        M.Jahr as Jahr
        , M.Monat as Monat
        , M.Geschlecht as Geschlecht
        , M.AlterVon as AlterVon
        , M.AlterBis as AlterBis
        , M.Gestorbene as Gestorbene
        , D.Einwohner as Einwohner
    from SterbefaelleMonat as M
    join DT124110006XM as D
    on
        D.Jahr = M.Jahr
        and
        D.AlterVon = M.AlterVon
        and 
        D.Geschlecht = M.Geschlecht
    group by
        M.Jahr, M.Monat, M.Geschlecht, AlterVon
    ) as B
order by
  Jahr
  , Monat
  , Geschlecht
  , AlterVon
  , AlterBis
;

select max(Kw) from SterbefaelleWoche where Jahr = 2022;
