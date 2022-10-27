use DESTATIS;

create or replace view StdBevRKIAG as 

select
    IdBundesland as IdBundesland
    , Altersgruppe as Altersgruppe
    , sum(Anzahl) as Bev 
from StdBev6BL
where
    Stichtag = "2020-12-31"
group by
    IdBundesland
    , Altersgruppe;

create or replace view `SterbefaelleJahr` as
select 
      `M`.`Jahr` AS `Jahr`
    , `M`.`Geschlecht` AS `Geschlecht`
    , `M`.`AlterVon` AS `AlterVon`
    , `M`.`AlterBis` AS `AlterBis`
    , sum(`M`.`Gestorbene`) AS `Gestorbene`
from
    `DESTATIS`.`SterbefaelleMonat` as `M` 
group by
 `M`.`Jahr`
 , `M`.`Geschlecht`
 , `M`.`AlterVon`
order by
    Jahr
    , Geschlecht
    , AlterVon
;

create or replace view `SterbefaelleJahrBev` as

select 
      `M`.`Jahr` AS `Jahr`
    , `M`.`Geschlecht` AS `Geschlecht`
    , `M`.`AlterVon` AS `AlterVon`
    , `M`.`AlterBis` AS `AlterBis`
    , `M`.`Gestorbene` AS `Gestorbene`
    , `B`.`Einwohner` AS `Einwohner`
from `DESTATIS`.`SterbefaelleJahr` `M`
join `DESTATIS`.`DT124110006M` AS `B`
on
    `B`.`Jahr` = `M`.`Jahr`
    and `B`.`Geschlecht` = `M`.`Geschlecht`
    and `B`.`AlterVon` = `M`.`AlterVon`
    and `B`.`AlterBis` = `M`.`AlterBis`
;

create or replace view `SterbefaelleProWoche` AS 
select 
    `SterbefaelleWoche`.`Jahr` AS `Jahr`
    , `SterbefaelleWoche`.`Kw` AS `Kw`
    , sum(`SterbefaelleWoche`.`Gestorbene`) AS `Anzahl` 
from `SterbefaelleWoche` 
group by 
    `SterbefaelleWoche`.`Jahr`
    , `SterbefaelleWoche`.`Kw`
;

create or replace view `SterbefaelleWocheMedian15_20` AS 
select distinct
      `Kw` AS `Kw`
    , median(Anzahl) over (partition by Kw) AS Median15_20 
from `SterbefaelleProWoche` 
where 
    Jahr > 2015
    and Jahr < 2020

;

create or replace view `SterbefaelleWocheMedian` AS 
select distinct
      `Kw` AS `Kw`
    , median(Anzahl) over (partition by Kw) AS Median 
from `SterbefaelleProWoche` 
;

create or replace view SterbeRateMonat as 
    select 
        Monat
        , Geschlecht as Geschlecht
        , AlterVon
        , AlterBis
        , Gestorbene
        , Einwohner
        , avg(Gestorbene/Einwohner) as SterbeRate
        , stddev(Gestorbene/Einwohner) as StdDevSterbeRate
    from SterbefaelleMonatBev
    where 
        Jahr < 2020
        and Jahr > 2015
    group by
          Monat
        , Geschlecht
        , AlterVon
        , AlterBis
;

create or replace view SchaetzeSterbefaelle as

    select
          M.Jahr as Jahr
        , M.Monat
        , M.AlterVon
        , M.AlterBis
        , M.Geschlecht
        , M.Einwohner as Einwohner
        , M.Gestorbene as Gestorbene
        , S.SterbeRate * M.Einwohner as ErwGestorbene
        , S.StdDevSterbeRate * M.Einwohner as Abweichung
        
    from SterbefaelleMonatBev as M
    join SterbeRateMonat as S 
    on 
            M.Monat = S.Monat
        and M.Geschlecht = S.Geschlecht
        and M.AlterVon = S.AlterVon
        and M.AlterBis = S.AlterBis
    group by
        M.Jahr
        , M.Monat
        , M.AlterVon
        , M.AlterBis
        , M.Geschlecht
;
    
create or replace view SchaetzeSterbefaelleJahr as

    select 
        Jahr as Jahr
        , sum(Gestorbene) as Gestorbene
        , round(sum(ErwGestorbene)) as ErwGestorbene
        , sqrt(sum(Abweichung^2)) as Abweichung
    from SchaetzeSterbefaelle
    group by
        Jahr;
        
# select * from SchaetzeSterbefaelleJahr where Jahr > 2017;

create or replace view AvgSterbefaelle as 

select 
    Jahr as Jahr
    , avg(Anzahl) as Durchschnitt
from SterbefaelleTag
group by 
    Jahr
;
