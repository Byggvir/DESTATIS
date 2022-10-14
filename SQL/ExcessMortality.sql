use DESTATIS

create or replace view SterbefaelleWocheBevAG as
select 
    Jahr
    , Kw
    , sum(`G_A00A29`) as `Gestorbene A00A29`

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
    , sum(`G_A85+`) as `Gestorbene A85+`

    , sum(`E_A00A29`) as `Einwohner A00A29`

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
    , sum(`E_A85+`) as `Einwohner A85+`
from (    
    select 
        Jahr
        , Kw
        , case when AlterVon = 0 then G else 0 end as `G_A00A29`

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
        , case when AlterVon = 85 then G else 0 end as `G_A85+`

        , case when AlterVon = 0 then E else 0 end as `E_A00A29`

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
        , case when AlterVon = 85 then E else 0 end as `E_A85+`
        
        from ( 
            select 
                Jahr
                , Kw
                , AlterVon
                , AlterBis
                , sum(Gestorbene) as G 
                , sum(Einwohner) as E 
            from SterbefaelleWocheBev 
            group by 
                Jahr
                , Kw
                , AlterVon 
        ) as A
    ) as B 
group by 
    Jahr
    , Kw
;

create or replace view SterbefaelleMonatBevAG as
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
    , sum(`G_A85+`) as `Gestorbene A85+`

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
    , sum(`E_A85+`) as `Einwohner A85+`
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
        , case when AlterVon = 85 then G else 0 end as `G_A85+`

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
        , case when AlterVon = 85 then E else 0 end as `E_A85+`
        
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
