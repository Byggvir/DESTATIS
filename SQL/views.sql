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
select * from (
select 
      `M`.`Jahr` AS `Jahr`
    , `M`.`Geschlecht` AS `Geschlecht`
    , `M`.`AlterVon` AS `AlterVon`
    , `M`.`AlterBis` AS `AlterBis`
    , sum(`M`.`Gestorbene`) AS `Gestorbene`
from
    `DESTATIS`.`SterbefaelleMonat` `M` 
where 
    `M`.`AlterBis` < 85
group by
 `M`.`Jahr`
 , `M`.`Geschlecht`
 , `M`.`AlterVon`
 , `M`.`AlterBis`
union 
select 
      `M`.`Jahr` AS `Jahr`
    , `M`.`Geschlecht` AS `Geschlecht`
    , 85 AS `AlterVon`
    , 100 AS `AlterBis`
    , sum(`M`.`Gestorbene`) AS `Gestorbene`
from
    `DESTATIS`.`SterbefaelleMonat` `M` 
where 
    `M`.`AlterVon` >= 85
group by
 `M`.`Jahr`
 , `M`.`Geschlecht`
) AS J
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
join `DESTATIS`.`DT124110006mod` AS `B`
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


create or replace view SterbeRateMonat as 
    select 
        Monat
        , AlterVon
        , AlterBis
        , Geschlecht as Geschlecht
        , avg(Gestorbene/Einwohner) as SterbeRate
        , stddev(Gestorbene/Einwohner) as StdDevSterbeRate
    from SterbefaelleMonatBev 
    where 
        Jahr < 2020 
        and Jahr > 2009 
    group by 
          Geschlecht
        , AlterVon
        , AlterBis
        , Monat 
;

create or replace view SchaetzeSterbefaelle as

    select
          adddate(B.Stichtag,1) as Jahr
        , S.Monat
        , B.AlterVon
        , B.AlterBis
        , B.Geschlecht
        , B.Anzahl as Einwohner
        , M.Gestorbene as Gestorbene
        , SterbeRate * B.Anzahl as AnzahlSterbefall
        , StdDevSterbeRate * B.Anzahl as Abweichung
        
    from StdBev18 as B 

    join SterbeRateMonat as S 
    on 
            B.AlterVon = S.AlterVon
        and B.AlterBis = S.AlterBis
        and B.Geschlecht = S.Geschlecht
    join SterbefaelleMonat as M
    on
            M.Jahr = adddate(B.Stichtag,1)
        and M.AlterVon = S.AlterVon
        and M.AlterBis = S.AlterBis
        and M.Geschlecht = S.Geschlecht

    group by
        Jahr
        , Monat
        , B.AlterVon
        , B.AlterBis
        , B.Geschlecht
;
    
create or replace view SchaetzeSterbefaelleJahr as

    select 
        Jahr as Jahr
        , round(sum(AnzahlSterbefall)) as Anzahl
        , sqrt(sum(Abweichung^2)) as Abweichung
    from SchaetzeSterbefaelle
    group by
        Jahr;

select * from SchaetzeSterbefaelleJahr;
        
