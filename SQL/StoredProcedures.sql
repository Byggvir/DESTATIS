use DESTATIS;

delimiter //

-- Berechnen des Datum des Donnerstages einer Kalenderwoche 
--
create or replace

function KwToDate ( Jahr INT, Kw INT ) returns DATE
begin
    
    set @JBegin = date(concat(Jahr,'-01-01'));
    set @WD = weekday(@JBegin);
    
    if ( @WD > 3 ) 
    then
        set @c = 3 - @WD;
    else
        set @c = - 4 - @WD ;
    end if; 
    return (adddate(@JBegin, @c + 7 * Kw));
    
end

//
