use DESTATIS;

delimiter //

# Anlegen zweier Tabellen zur Standdard Bevölkerung

drop procedure if exists CreateStdBev //

create procedure CreateStdBev ()
begin

drop table if exists StdBev6BL ;

create table StdBev6BL (
      Stichtag date NOT NULL
    , IdBundesland INT DEFAULT 1 
    , Geschlecht CHAR (1) DEFAULT 'M'
    , Altersgruppe CHAR(8) DEFAULT 'A00-A04'
    , AltersgruppeL INT DEFAULT 0
    , AltersgruppeU INT DEFAULT 120
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (Stichtag,IdBundesland,Geschlecht,Altersgruppe)
    )

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A00-A04' as Altersgruppe
  , 0 as AltersgruppeL
  , 4 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 0 and Altersgruppe <= 4
group by Stichtag,IdBundesland, Geschlecht

union

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A05-A14' as Altersgruppe
  , 5 as AltersgruppeL
  , 14 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 5 and Altersgruppe <= 14
group by Stichtag,IdBundesland, Geschlecht

union

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A15-A34' as Altersgruppe
  , 15 as AltersgruppeL
  , 34 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 15 and Altersgruppe <= 34
group by Stichtag,IdBundesland, Geschlecht

union

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A35-A59' as Altersgruppe
  , 35 as AltersgruppeL
  , 59 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 35 and Altersgruppe <= 59
group by Stichtag,IdBundesland, Geschlecht

union

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A60-A79' as Altersgruppe
  , 60 as AltersgruppeL
  , 79 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 60 and Altersgruppe <= 79
group by Stichtag,IdBundesland, Geschlecht

union

select
    Stichtag as Stichtag
  , IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A80+' as Altersgruppe
  , 80 as AltersgruppeL
  , 120 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 80
group by Stichtag,IdBundesland, Geschlecht
;

drop table if exists StdBev6 ;

create table StdBev6 (
      Stichtag date NOT NULL
    , Geschlecht CHAR(1) DEFAULT 'M'
    , Altersgruppe CHAR(8) DEFAULT '' 
    , AltersgruppeL INT DEFAULT 0
    , AltersgruppeU INT DEFAULT 120
    , Anzahl BIGINT
    , PRIMARY KEY(Stichtag,Geschlecht,Altersgruppe))
select
      Stichtag as Stichtag
    , Geschlecht as Geschlecht
    , Altersgruppe as Altersgruppe
    , AltersgruppeL as AltersgruppeL
    , AltersgruppeU as AltersgruppeU
    , sum(Anzahl) as Anzahl
from StdBev6BL
group by 
    Stichtag, Geschlecht, Altersgruppe
;

drop table if exists StdBev10 ;

create table StdBev10 (
      Stichtag date NOT NULL
    , Altersgruppe INT DEFAULT 0 
    , Anzahl BIGINT
    , PRIMARY KEY( Stichtag, Altersgruppe ))
select 
      Stichtag as Stichtag
    , Altersgruppe as Altersgruppe
    , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
group by 
    Stichtag,
    Altersgruppe div 10 * 10
;

drop table if exists StdBevImpfBL ;

create table StdBevImpfBL (
      IdBundesland INT DEFAULT 1 
    , Altersgruppe CHAR(8) DEFAULT 'A00-A04'
    , AlterVon INT DEFAULT 0
    , AlterBis INT DEFAULT 120
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (IdBundesland,Altersgruppe)
    , INDEX (IdBundesland,AlterVon)
    )

select
    IdBundesland as IdBundesland
  , 'A00-A04' as Altersgruppe
  , 0 as AlterVon
  , 4 as AlterBis
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where 
    Altersgruppe >= 0 and Altersgruppe <= 4
    and Stichtag = "2020-12-31"
group by IdBundesland

union

select
    IdBundesland as IdBundesland
  , 'A05-A11' as Altersgruppe
  , 5 as AlterVon
  , 11 as AlterBis
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 5 and Altersgruppe <= 11
    and Stichtag = "2020-12-31"
group by IdBundesland

union

select
    IdBundesland as IdBundesland
  , 'A12-A17' as Altersgruppe
  , 12 as AlterVon
  , 17 as AlterBis
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 12 and Altersgruppe <= 17
    and Stichtag = "2020-12-31"
group by IdBundesland

union

select
    IdBundesland as IdBundesland
  , 'A18-A59' as Altersgruppe
  , 18 as AlterVon
  , 59 as AlterBis
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 18 and Altersgruppe <= 59
    and Stichtag = "2020-12-31"
group by IdBundesland

union

select
    IdBundesland as IdBundesland
  , 'A60+' as Altersgruppe
  , 60 as AlterVon
  , 100 as AlterBis
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 60 and Altersgruppe <= 100
    and Stichtag = "2020-12-31"
group by IdBundesland

;

end

//

delimiter ; 

call CreateStdBev();
