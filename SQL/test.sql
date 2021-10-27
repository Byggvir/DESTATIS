use DESTATIS;

create or replace view OverMortality2021B as
select 
    Kw, 
    case when Geschlecht = 1 then 'Männer' else 'Frauen' end as Geschlecht
    , sum(Mittelwert) as Mittelwert
    , sum(Anzahl) as Anzahl
from (
select 
        Kw
        , Geschlecht
        , case when Hint='A' then Anzahl else 0 end as Mittelwert
        , case when Hint='R' then Anzahl else 0 end as Anzahl
    from ( 
        select 
            Kw
            , Geschlecht
            , 'A' as Hint
            , sum(Anzahl)/4 as Anzahl 
        from SterbefaelleWoche
        where
            Jahr > 2016 and Jahr < 2021 and AlterVon >= 60 
        group by 
            Kw, Geschlecht
        union 
        select 
            Kw
            , Geschlecht
            , 'R' as Hint
            , sum(Anzahl) as Anzahl 
        from SterbefaelleWoche
        where
            Jahr=2021 and AlterVon >=60 
        group by Kw, Geschlecht
        ) as B 
        )
        as C 
        group by 
            Kw
            , Geschlecht
;
       
