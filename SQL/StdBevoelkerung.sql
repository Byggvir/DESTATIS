use DESTATIS;

delimiter //

# Anlegen zweier Tabellen zur Standdard Bevölkerung

drop procedure if exists CreateStdBev //

create procedure CreateStdBev ()
begin

drop table if exists StdBev6BL ;

create table StdBev6BL (
      IdBundesland INT DEFAULT 1 
    , Geschlecht CHAR (1) DEFAULT 'M'
    , Altersgruppe CHAR(8) DEFAULT 'A00-A04'
    , AltersgruppeL INT DEFAULT 0
    , AltersgruppeU INT DEFAULT 120
    , Anzahl BIGINT DEFAULT 0
    , PRIMARY KEY (IdBundesland,Geschlecht,Altersgruppe)
    )

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A00-A04' as Altersgruppe
  , 0 as AltersgruppeL
  , 4 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 0 and Altersgruppe <= 4
group by IdBundesland, Geschlecht

union

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A05-A14' as Altersgruppe
  , 5 as AltersgruppeL
  , 14 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 5 and Altersgruppe <= 14
group by IdBundesland, Geschlecht

union

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A15-A34' as Altersgruppe
  , 15 as AltersgruppeL
  , 34 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 15 and Altersgruppe <= 34
group by IdBundesland, Geschlecht

union

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A34-A59' as Altersgruppe
  , 34 as AltersgruppeL
  , 59 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 35 and Altersgruppe <= 59
group by IdBundesland, Geschlecht

union

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A60-A79' as Altersgruppe
  , 60 as AltersgruppeL
  , 79 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 60 and Altersgruppe <= 79
group by IdBundesland, Geschlecht

union

select
    IdBundesland as IdBundesland
  , Geschlecht as Geschlecht
  , 'A80+' as Altersgruppe
  , 80 as AltersgruppeL
  , 120 as AltersgruppeU
  , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
where Altersgruppe >= 80
group by IdBundesland, Geschlecht
;

drop table if exists StdBev6 ;

create table StdBev6 (
      Geschlecht CHAR(1) DEFAULT 'M'
    , Altersgruppe CHAR(8) DEFAULT '' 
    , AltersgruppeL INT DEFAULT 0
    , AltersgruppeU INT DEFAULT 120
    , Anzahl BIGINT
    , PRIMARY KEY(Geschlecht,Altersgruppe))
select 
      Geschlecht as Geschlecht
    , Altersgruppe as Altersgruppe
    , AltersgruppeL as AltersgruppeL
    , AltersgruppeU as AltersgruppeU
    , sum(Anzahl) as Anzahl
from StdBev6BL
group by 
    Geschlecht, Altersgruppe
;

drop table if exists StdBev10 ;

create table StdBev10 (
      Altersgruppe INT DEFAULT 0 
    , Anzahl BIGINT
    , PRIMARY KEY( Altersgruppe ))
select 
      Altersgruppe as Altersgruppe
    , sum(Anzahl) as Anzahl
from DESTATIS.DT124110013
group by 
    Altersgruppe div 10 * 10
;

end

//

delimiter ; 
