use DESTATIS;

drop table if exists WPP;

create table WPP (
      `Stichtag` date
    , `Geschlecht` char(1)
    , `Alter` int(11)
    , `Einwohner` bigint(20)
    , primary key (`Stichtag`, `Geschlecht`, `Alter`)
)
select 
    date(concat(`Time`,'-12-31')) as `Stichtag`
    , 'F' as `Geschlecht`
    , `AgeGrp` as `Alter`
    , `PopFemale` as `Einwohner`
from WPP.population 
where LocId = 276
union
select 
    date(concat(`Time`,'-12-31')) as `Stichtag`
    , 'M' as `Geschlecht`
    , `AgeGrp` as `Alter`
    , `PopMale` as `Einwohner`
from WPP.population 
where LocId = 276
;

drop table if exists WPPM;

create table WPPM
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
        from WPP as B 
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
        from WPP as B 
        where 
            B.`Alter` >= M.AlterVon 
            and B.`Alter` <= M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGM as M 

;

drop table WPPW;

create table WPPW
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
        from WPP as B 
        where 
            B.Alter>=M.AlterVon 
            and B.Alter<=M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'M'
        ) as Einwohner 
from SterbeAGW as M 

union

select 
    Jahr as Jahr
    , 'F' as Geschlecht
    , AlterVon as AlterVon
    , AlterBis as AlterBis
    , ( select 
            sum(Einwohner)
        from WPP as B 
        where 
            B.`Alter` >= M.AlterVon 
            and B.`Alter` <= M.AlterBis 
            and year(B.Stichtag) = M.Jahr - 1
            and Geschlecht = 'F'
        ) as Einwohner 
from SterbeAGW as M 

;

create or replace view SterbefaelleWocheWPP as

select * from (
select 
      W.Jahr as Jahr
    , W.Kw as Kw
    , W.Geschlecht as Geschlecht
    , W.AlterVon as AlterVon
    , W.AlterBis as AlterBis
    , W.Gestorbene as Gestorbene
    , D.Einwohner as Einwohner
from SterbefaelleWoche as W
join WPPW as D
on
    D.Jahr = W.Jahr
    and
    D.AlterVon = W.AlterVon
    and 
    D.Geschlecht = W.Geschlecht
group by
    W.Jahr, W.Kw, W.Geschlecht, W.AlterVon
) as B

order by
  Jahr
  , Kw
  , Geschlecht
  , AlterVon
  , AlterBis
;


create or replace view SterbefaelleMonatWPP as

select * from (
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
join WPPM as D
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

select
    Stichtag
    , sum(E_A) as DESTATIS
    , sum(E_B) as WPP
from (
    select 
        Stichtag
        , case when Quelle = 'A' then Einwohner else 0 end as E_A
        , case when Quelle = 'B' then Einwohner else 0 end as E_B
    from (
        select 
            Stichtag
            , 'A' as Quelle
            , sum(Einwohner) as Einwohner 
        from DT124110006 
        group by Stichtag 
        union 
        select 
            Stichtag
            , 'B' as Quelle
            , sum(Einwohner)
        from WPP
        group by Stichtag ) as M
    ) as Q
    group by Stichtag;

create or replace view SterbefaelleMonatWPPAG as
select 
    Jahr
    , Monat
    , sum(`G_A00A14`) as `Gestorbene A00A14`
    , sum(`G_A15A29`) as `Gestorbene A15A29`

    , sum(`G_A30A34`) as `Gestorbene A30A34`
    , sum(`G_A35A39`) as `Gestorbene A35A39`

    , sum(`G_A40A44`) as `Gestorbene A40A44`
    , sum(`G_A45A49`) as `Gestorbene A45A49`

    , sum(`G_A50A54`) as `Gestorbene A50A54`
    , sum(`G_A55A59`) as `Gestorbene A55A59`

    , sum(`G_A60A64`) as `Gestorbene A60A64`
    , sum(`G_A65A69`) as `Gestorbene A65A69`

    , sum(`G_A70A74`) as `Gestorbene A70A74`
    , sum(`G_A75A79`) as `Gestorbene A75A79`

    , sum(`G_A80A84`) as `Gestorbene A80A84`
    , sum(`G_A85A89`) as `Gestorbene A85A89`

    , sum(`G_A90A94`) as `Gestorbene A90A94`
    , sum(`G_A95+`) as `Gestorbene A95+`

    , sum(`E_A00A14`) as `Einwohner A00A14`
    , sum(`E_A15A29`) as `Einwohner A15A29`

    , sum(`E_A30A34`) as `Einwohner A30A34`
    , sum(`E_A35A39`) as `Einwohner A35A39`

    , sum(`E_A40A44`) as `Einwohner A40A44`
    , sum(`E_A45A49`) as `Einwohner A45A49`

    , sum(`E_A50A54`) as `Einwohner A50A54`
    , sum(`E_A55A59`) as `Einwohner A55A59`

    , sum(`E_A60A64`) as `Einwohner A60A64`
    , sum(`E_A65A69`) as `Einwohner A65A69`

    , sum(`E_A70A74`) as `Einwohner A70A74`
    , sum(`E_A75A79`) as `Einwohner A75A79`

    , sum(`E_A80A84`) as `Einwohner A80A84`
    , sum(`E_A85A89`) as `Einwohner A85A89`
 
    , sum(`E_A90A94`) as `Einwohner A90A94`
    , sum(`E_A95+`) as `Einwohner A95+`

from (    
    select 
        Jahr
        , Monat
        , case when AlterVon = 0 then G else 0 end as `G_A00A14`
        , case when AlterVon = 15 then G else 0 end as `G_A15A29`

        , case when AlterVon = 30 then G else 0 end as `G_A30A34`
        , case when AlterVon = 35 then G else 0 end as `G_A35A39`

        , case when AlterVon = 40 then G else 0 end as `G_A40A44`
        , case when AlterVon = 45 then G else 0 end as `G_A45A49`

        , case when AlterVon = 50 then G else 0 end as `G_A50A54`
        , case when AlterVon = 55 then G else 0 end as `G_A55A59`

        , case when AlterVon = 60 then G else 0 end as `G_A60A64`
        , case when AlterVon = 65 then G else 0 end as `G_A65A69`

        , case when AlterVon = 70 then G else 0 end as `G_A70A74`
        , case when AlterVon = 75 then G else 0 end as `G_A75A79`

        , case when AlterVon = 80 then G else 0 end as `G_A80A84`
        , case when AlterVon = 85 then G else 0 end as `G_A85A89`

        , case when AlterVon = 90 then G else 0 end as `G_A90A94`
        , case when AlterVon = 95 then G else 0 end as `G_A95+`

        , case when AlterVon = 0 then E else 0 end as `E_A00A14`
        , case when AlterVon = 15 then E else 0 end as `E_A15A29`

        , case when AlterVon = 30 then E else 0 end as `E_A30A34`
        , case when AlterVon = 35 then E else 0 end as `E_A35A39`

        , case when AlterVon = 40 then E else 0 end as `E_A40A44`
        , case when AlterVon = 45 then E else 0 end as `E_A45A49`

        , case when AlterVon = 50 then E else 0 end as `E_A50A54`
        , case when AlterVon = 55 then E else 0 end as `E_A55A59`

        , case when AlterVon = 60 then E else 0 end as `E_A60A64`
        , case when AlterVon = 65 then E else 0 end as `E_A65A69`

        , case when AlterVon = 70 then E else 0 end as `E_A70A74`
        , case when AlterVon = 75 then E else 0 end as `E_A75A79`

        , case when AlterVon = 80 then E else 0 end as `E_A80A84`
        , case when AlterVon = 85 then E else 0 end as `E_A85A89`
        
        , case when AlterVon = 90 then E else 0 end as `E_A90A94`
        , case when AlterVon = 95 then E else 0 end as `E_A95+`
        from ( 
            select 
                Jahr
                , Monat
                , AlterVon
                , AlterBis
                , sum(Gestorbene) as G 
                , sum(Einwohner) as E 
            from SterbefaelleMonatBev 
            group by 
                Jahr
                , Monat
                , AlterVon 
        ) as A
    ) as B 
group by 
    Jahr
    , Monat
;
