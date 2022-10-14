use DESTATIS;

create or replace view ExcessMortalityWeekDESTATIS as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , round(median(B.Gestorbene) over (partition by Kw, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleWoche as A
    join SterbefaelleWoche as B
    on 
     
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view ExcessMortalityMonthDESTATIS as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , round(median(B.Gestorbene) over (partition by Monat, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleMonat as A
    join SterbefaelleMonat as B
    on 
     
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view ExcessMortalityWeekNormalised as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , A.Einwohner as Einwohner
        , round(median(B.Gestorbene/B.Einwohner * A.Einwohner) over (partition by Kw, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleWocheBev as A
    join SterbefaelleWocheBev as B
    on 
     
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view ExcessMortalityMonthNormalised as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , A.Einwohner as Einwohner
        , round(median(B.Gestorbene/B.Einwohner * A.Einwohner) over (partition by Monat, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleMonatBev as A
    join SterbefaelleMonatBev as B
    on 
     
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view ExcessMortalityWeekWPP as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , A.Einwohner as Einwohner
        , round(median(B.Gestorbene/B.Einwohner * A.Einwohner) over (partition by Kw, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleWocheWPP as A
    join SterbefaelleWocheWPP as B
    on 
     
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view ExcessMortalityMonthWPP as
select 
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , round((`Gestorbene` - `Median`) / `Median` *100,1) as ResExcessMortality
from (
    select distinct
          A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , A.Einwohner as Einwohner
        , round(median(B.Gestorbene/B.Einwohner * A.Einwohner) over (partition by Monat, Geschlecht, AlterVon),1) as `Median`
    from SterbefaelleMonatWPP as A
    join SterbefaelleMonatWPP as B
    on 
     
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    where A.Jahr = 2022
) as EM
;

create or replace view OverViewWeekExcessMortality as
select 
    Kw
    , Methode
    , (Gestorbene - `Median` ) / `median` as EM 
from (
    select 
        Kw
        , 'DESTATIS' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityWeekDESTATIS 
    group by Kw
    union
    select 
        Kw
        , 'Standadisiert' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityWeekNormalised 
    group by Kw
    union
    select 
        Kw
        , 'WPP' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityWeekWPP 
    group by Kw
    ) as D
    
    ;

create or replace view OverViewMonthExcessMortality as
select 
    Monat
    , Methode
    , (Gestorbene - `Median` ) / `median` as EM 
from (
    select 
        Monat
        , 'DESTATIS' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityMonthDESTATIS 
    group by Monat
    union
    select 
        Monat
        , 'Standadisiert' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityMonthNormalised 
    group by Monat
    union
    select 
        Monat
        , 'WPP' as Methode
        , sum(`Median`) as `Median`
        , sum(Gestorbene) as Gestorbene 
    from ExcessMortalityMonthWPP 
    group by Monat
    ) as D
    
    ;
