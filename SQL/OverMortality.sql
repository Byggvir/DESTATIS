use DESTATIS;

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

select * from SterbefaelleMonatBev;
