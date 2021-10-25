# awk Script zur Umformatierung der Tabellenblätter 5,6,8,9 
# Die Variable s = Sex / Geschlecht muss auf der Komandozeile gesetzt werden.
# s = 1 : Männlich
# s = 2 : Weiblich

BEGIN {
    
    j=0; # Jahr 
    i=1; # Monat oder Kalenderwoche
    a=0; # AlterVon
    b=0; # AlterBis
}
{
    if ( $1 == "Jahr" ) {

        # Neues Jahr beginnt
        # In der MySQL Datenbakn ist das AlterBis einschließlich, 
        # nicht wie in der Sonderauswertung ausschließlich.
        
        j = $2 ; # Jahreszahl steht an Stelle 1 
        i = 1 ;  # Zähler für Monate / Kalenderwochen
        a = $3 ; # AlterVon
        b = $4 - 1 ; # Wg einschließlich -1
    }
    else {
        
        # Zeile enthält nur den Wert für eine Monat / eine Kalenderwoche
        
        # Ausgabe für den Import aus einer CSV Datei
        # In der MySQL Datenbakn ist das AlterBis einschließlich, 
        # nicht wie in der Sonderauswertung ausschließlich.
        
        printf ( "%s,%d,%d,%d,%d,%d\n", s, j, i, a, b, $1 ) ;
        i = i + 1;
    }
    
    
}
