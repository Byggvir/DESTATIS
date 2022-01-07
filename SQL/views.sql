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

create or replace view `SterbefaelleWocheBev` AS 
    select 
        `B`.`Jahr` AS `Jahr`
        , `B`.`Kw` AS `Kw`
        , `B`.`AlterVon` AS `AlterVon`
        , `B`.`AlterBis` AS `AlterBis`
        , `B`.`Male` AS `Male`
        , `B`.`Female` AS `Female`
        , `B`.`BevMale` AS `BevMale`
        , `B`.`BevFemale` AS `BevFemale` 
    from (
        select 
            `M`.`Jahr` AS `Jahr`
            , `M`.`Kw` AS `Kw`
            , `M`.`AlterVon` AS `AlterVon`
            , `M`.`AlterBis` AS `AlterBis`
            , `M`.`Male` AS `Male`
            , `M`.`Female` AS `Female`
            , `D`.`Male` AS `BevMale`
            , `D`.`Female` AS `BevFemale` 
        from ( 
            `DESTATIS`.`SterbefaelleWoche` `M` 
        join `DESTATIS`.`DT124110006mod` `D` 
        on (`D`.`Jahr` = `M`.`Jahr` and `D`.`AlterVon` = `M`.`AlterVon`)) 
        where 
            `D`.`AlterVon` < 85 
        union 
        select 
            `M`.`Jahr` AS `Jahr`
            , `M`.`Kw` AS `Kw`
            , 85 AS `AlterVon`
            , 100 AS `AlterBis`
            , sum(`M`.`Male`) AS `sum(M.Male)`
            , sum(`M`.`Female`) AS `sum(M.Female)`
            , `D`.`Male` AS `BevMale`
            , `D`.`Female` AS `BevFemale` 
        from (
            `DESTATIS`.`SterbefaelleWoche` `M` 
        join `DESTATIS`.`DT124110006mod` `D` 
        on ( 
            `D`.`Jahr` = `M`.`Jahr` and `D`.`AlterVon` = 85) )
        where 
            `M`.`AlterVon` >= 85
        group by `M`.`Jahr`,`M`.`Kw`
        ) AS `B` 
        order by 
            `B`.`Jahr`
            , `B`.`Kw`
            , `B`.`AlterVon`
            , `B`.`AlterBis` ;


create or replace view `SterbefaelleMonatBev` AS 

select 
    `B`.`Datum` AS `Datum`
    , `B`.`Jahr` AS `Jahr`
    , `B`.`Monat` AS `Monat`
    , `B`.`AlterVon` AS `AlterVon`
    , `B`.`AlterBis` AS `AlterBis`
    , `B`.`Male` AS `Male`
    , `B`.`Female` AS `Female`
    , `B`.`BevMale` AS `BevMale`
    , `B`.`BevFemale` AS `BevFemale`
    from (
        select 
            str_to_date(concat(`M`.`Jahr`,'-',`M`.`Monat`,'-',1),'%Y-%c-%e') AS `Datum`
            , `M`.`Jahr` AS `Jahr`
            , `M`.`Monat` AS `Monat`
            , `M`.`AlterVon` AS `AlterVon`
            , `M`.`AlterBis` AS `AlterBis`
            , `M`.`Male` AS `Male`
            , `M`.`Female` AS `Female`
            , `D`.`Male` AS `BevMale`
            , `D`.`Female` AS `BevFemale`
        from (
            `DESTATIS`.`SterbefaelleMonat` `M` 
        join `DESTATIS`.`DT124110006mod` `D` 
        on (`D`.`Jahr` = `M`.`Jahr` and `D`.`AlterVon` = `M`.`AlterVon`))
        where 
            `D`.`AlterVon` < 85 
        union 
        select 
            str_to_date(concat(`M`.`Jahr`,'-',`M`.`Monat`,'-',1),'%Y-%c-%e') AS `Datum`
            , `M`.`Jahr` AS `Jahr`
            , `M`.`Monat` AS `Monat`
            , 85 AS `AlterVon`
            , 100 AS `AlterBis`
            , sum(`M`.`Male`) AS `sum(M.Male)`
            , sum(`M`.`Female`) AS `sum(M.Female)`
            , `D`.`Male` AS `BevMale`
            , `D`.`Female` AS `BevFemale`
        from (
            `DESTATIS`.`SterbefaelleMonat` `M` 
        join `DESTATIS`.`DT124110006mod` `D` 
        on ( `D`.`Jahr` = `M`.`Jahr` and `D`.`AlterVon` = 85) )
        where 
            `M`.`AlterVon` >= 85
        group by 
            `M`.`Jahr`
            , `M`.`Monat`
            ) AS `B` 
        order by 
            `B`.`Jahr`
            , `B`.`Monat`
            , `B`.`AlterVon`
            , `B`.`AlterBis`
;

create or replace view `SterbefaelleProWoche` AS 
select 
    `SterbefaelleWoche`.`Jahr` AS `Jahr`
    , `SterbefaelleWoche`.`Kw` AS `Kw`
    , sum(`SterbefaelleWoche`.`Male`) + sum(`SterbefaelleWoche`.`Female`) AS `Anzahl` 
from `SterbefaelleWoche` 
group by 
    `SterbefaelleWoche`.`Jahr`
    , `SterbefaelleWoche`.`Kw`
;
