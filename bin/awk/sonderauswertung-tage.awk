# awk Script zur Umformatierung der Tabellenblätter 3

BEGIN {
    
    j=0; # Jahr 
}
{
    if ( $1 == "Jahr" ) {

        # Neues Jahr beginnt
        # In der MySQL Datenbank ist das AlterBis einschließlich, 
        # nicht wie in der Sonderauswertung ausschließlich.
        
        j = $2 ; # Jahreszahl steht an Stelle 2 
        i = 0 ;  # Zähler für Tage 1. Januar == 0
    }
    else {
        
        # Zeile enthält nur den Wert für einen Tag
        
        # Ausgabe für den Import aus einer CSV Datei
        # In der MySQL Datenbakn ist das AlterBis einschließlich, 
        # nicht wie in der Sonderauswertung ausschließlich.
        
        printf ( "%d,%d,%d\n", j, i, $1 ) ;
        i = i + 1;
    }
    
    
}
