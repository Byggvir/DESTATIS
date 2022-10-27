use DESTATIS;

create or replace view SterbefaelleWocheMedian as
select
    Jahr
    , Kw
    , Geschlecht
    , AlterVon
    , AlterBis
    , Gestorbene
    , median(Gestorbene2) over (partition by Jahr, Kw, Geschlecht, AlterVon) as `Median`
from (
    select 
        A.Jahr as Jahr
        , A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , B.Gestorbene as Gestorbene2
    from SterbefaelleWoche as A
    join SterbefaelleWoche as B
    on
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
) as M
;

create or replace view SterbefaelleMonatMedian as

select 
    Jahr
    , Monat
    , Geschlecht
    , AlterVon
    , AlterBis
    , GestorbeneA as Gestorbene
    , GestorbeneB
    , median(GestorbeneB) over (partition by Jahr, Monat, Geschlecht, AlterVon) as `Median`
    
from (
    select 
        A.Jahr as Jahr
        , A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , case when not (A.Monat = 2 and mod(A.Jahr,4) = 0) then A.Gestorbene else A.Gestorbene / 29 * 28 end as GestorbeneA
        , case when not (B.Monat = 2 and mod(B.Jahr,4) = 0) then B.Gestorbene else B.Gestorbene / 29 * 28 end as GestorbeneB
    from SterbefaelleMonat as A
    join SterbefaelleMonat as B
    on
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
) as M
;


create or replace view ExcessMortalityWeekDESTATIS as
select distinct
    *
    , round(`Gestorbene` - `Median`,1) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleWocheMedian;

create or replace view ExcessMortalityMonthDESTATIS as
select distinct
    *
    , round( `Gestorbene` - `Median`, 1 ) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleMonatMedian;

--
--
--

create or replace view SterbefaelleWocheMedianX as
select
    Jahr
    , Kw
    , Geschlecht
    , AlterVon
    , AlterBis
    , Gestorbene
    , median(Gestorbene2) over (partition by Jahr, Kw, Geschlecht, AlterVon) as `Median`
from (
    select 
        A.Jahr as Jahr
        , A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , B.Gestorbene / D.Einwohner * C.Einwohner as Gestorbene2
    from SterbefaelleWoche as A
    join SterbefaelleWoche as B
    on
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    join DT124110006XW as C
    on
        C.Jahr = A.Jahr
        and
        C.AlterVon = A.AlterVon
        and 
        C.Geschlecht = A.Geschlecht
    join DT124110006XW as D
    on
        D.Jahr = B.Jahr
        and
        D.AlterVon = B.AlterVon
        and 
        D.Geschlecht = B.Geschlecht

) as M
;

--
--
--

create or replace view SterbefaelleMonatMedianX as

select 
    Jahr
    , Monat
    , Geschlecht
    , AlterVon
    , AlterBis
    , GestorbeneA as Gestorbene
    , median(GestorbeneB) over (partition by Jahr, Monat, Geschlecht, AlterVon) as `Median`
    
from (
    select 
        A.Jahr as Jahr
        , A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , case when not (A.Monat = 2 and mod(A.Jahr,4) = 0) then A.Gestorbene else A.Gestorbene / 29 * 28 end as GestorbeneA
        , case when not (B.Monat = 2 and mod(B.Jahr,4) = 0) then B.Gestorbene / D.Einwohner * C.Einwohner else B.Gestorbene / D.Einwohner * C.Einwohner / 29 * 28 end as GestorbeneB
    from SterbefaelleMonat as A
    join SterbefaelleMonat as B
    on
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    join DT124110006XM as C
    on
        C.Jahr = A.Jahr
        and
        C.AlterVon = A.AlterVon
        and 
        C.Geschlecht = A.Geschlecht       
    join DT124110006XM as D
    on
        D.Jahr = B.Jahr
        and
        D.AlterVon = B.AlterVon
        and 
        D.Geschlecht = B.Geschlecht       
) as M
;

create or replace view ExcessMortalityWeekNormalised as
select distinct 
    *
    , round( `Gestorbene` - `Median`, 1 ) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleWocheMedianX;

create or replace view ExcessMortalityMonthNormalised as
select distinct
    *
    , round(`Gestorbene` - `Median`,1 ) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleMonatMedianX;

--
-- World Population Prospects
--


create or replace view SterbefaelleWocheMedianWPP as
select
    Jahr
    , Kw
    , Geschlecht
    , AlterVon
    , AlterBis
    , Gestorbene
    , median(Gestorbene2) over (partition by Jahr, Kw, Geschlecht, AlterVon) as `Median`
from (
    select 
        A.Jahr as Jahr
        , A.Kw as Kw
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , A.Gestorbene as Gestorbene
        , B.Gestorbene / D.Einwohner * C.Einwohner as Gestorbene2
    from SterbefaelleWoche as A
    join SterbefaelleWoche as B
    on
        A.Kw = B.Kw
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    join WPPW as C
    on
        C.Jahr = A.Jahr
        and
        C.AlterVon = A.AlterVon
        and 
        C.Geschlecht = A.Geschlecht
    join WPPW as D
    on
        D.Jahr = B.Jahr
        and
        D.AlterVon = B.AlterVon
        and 
        D.Geschlecht = B.Geschlecht

) as M
;

create or replace view SterbefaelleMonatMedianWPP as

select 
    Jahr
    , Monat
    , Geschlecht
    , AlterVon
    , AlterBis
    , GestorbeneA as Gestorbene
    , median(GestorbeneB) over (partition by Jahr, Monat, Geschlecht, AlterVon) as `Median`
    
from (
    select 
        A.Jahr as Jahr
        , A.Monat as Monat
        , A.Geschlecht as Geschlecht
        , A.AlterVon as AlterVon
        , A.AlterBis as AlterBis
        , case when not (A.Monat = 2 and mod(A.Jahr,4) = 0) then A.Gestorbene else A.Gestorbene / 29 * 28 end as GestorbeneA
        , case when not (B.Monat = 2 and mod(B.Jahr,4) = 0) then B.Gestorbene / D.Einwohner * C.Einwohner else B.Gestorbene / D.Einwohner * C.Einwohner / 29 * 28 end as GestorbeneB
    from SterbefaelleMonat as A
    join SterbefaelleMonat as B
    on
        A.Monat = B.Monat
        and A.Geschlecht = B.Geschlecht
        and A.AlterVon = B.AlterVon
        and A.AlterBis = B.AlterBis
        and B.Jahr > A.Jahr - 5
        and B.Jahr < A.Jahr
    join WPPM as C
    on
        C.Jahr = A.Jahr
        and
        C.AlterVon = A.AlterVon
        and 
        C.Geschlecht = A.Geschlecht       
    join WPPM as D
    on
        D.Jahr = B.Jahr
        and
        D.AlterVon = B.AlterVon
        and 
        D.Geschlecht = B.Geschlecht       
) as M
;

create or replace view ExcessMortalityWeekWPP as
select distinct 
    *
    , round( `Gestorbene` - `Median`, 1 ) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleWocheMedianWPP;

create or replace view ExcessMortalityMonthWPP as
select distinct
    *
    , round(`Gestorbene` - `Median`,1 ) as AbsExcessMortality
    , ( `Gestorbene` - `Median` ) / `Median` as RelExcessMortality
from SterbefaelleMonatMedianWPP;

create or replace view OverViewWeekExcessMortality as
select 
    Jahr
    , Kw
    , Methode
    , ( Gestorbene - `Median` ) / `Median` as EM 
from (
    select
          Jahr
        , Kw
        , 'DESTATIS' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekDESTATIS 
    group by Jahr, Kw
    union
    select 
          Jahr
        , Kw
        , 'Standadisiert' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekNormalised 
    group by Jahr, Kw
    union
    select 
          Jahr
        , Kw
        , 'WPP' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekWPP 
    group by Jahr, Kw
    ) as D
    
    ;

create or replace view OverViewMonthExcessMortality as
select
      Jahr
    , Monat
    , Methode
    , ( Gestorbene - `Median` ) / `Median` as EM 
from (
    select
          Jahr
        , Monat
        , 'DESTATIS' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityMonthDESTATIS 
    group by Jahr, Monat
    union
    select
          Jahr
        , Monat
        , 'Standadisiert' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityMonthNormalised 
    group by Jahr, Monat
    union
    select 
          Jahr
        , Monat
        , 'WPP' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityMonthWPP 
    group by Jahr, Monat
    ) as D
    
    ;

create or replace view OverViewYearExcessMortality as
select 
    Jahr
    , Methode
    , ( Gestorbene - `Median` ) / `Median` as EM 
from (
    select
          Jahr
        , 'DESTATIS' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekDESTATIS 
    group by Jahr
    union
    select 
          Jahr
        , 'Standadisiert' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekNormalised 
    group by Jahr
    union
    select 
          Jahr
        , 'WPP' as Methode
        , sum( `Median` ) as `Median`
        , sum( `Gestorbene` ) as Gestorbene 
    from ExcessMortalityWeekWPP 
    group by Jahr
    ) as D
    
    ;
