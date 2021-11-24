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
