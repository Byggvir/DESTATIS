use DESTATIS;

drop table if exists StdBev19;

create table if not exists StdBev19 (
    Stichtag DATE
    , Geschlecht CHAR(1)
    , AlterVon INT
    , AlterBis INT
    , Anzahl BIGINT(20)
    , primary key(Stichtag,Geschlecht,AlterVon) 
    ) 
    select 
        Stichtag as Stichtag
        , Geschlecht as Geschlecht
        , Altersgruppe div 5 * 5 as AlterVon
        , case when Altersgruppe = 90 then 100 else Altersgruppe div 5 * 5 + 4 end as AlterBis
        , sum(Anzahl) as Anzahl 
    from DT124110013
    group by 
        Stichtag
        , Geschlecht
        , AlterVon
;
