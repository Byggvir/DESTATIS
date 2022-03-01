# awk Script zur Umformatierung der Tabellenblätter 5,6,8,9 
# Die Variable s = Sex / Geschlecht muss auf der Komandozeile gesetzt werden.
# s = 'M' : Männlich
# s = 'F' : Weiblich

{
    
    print( j "," s "," $1 "," $2 );

}
