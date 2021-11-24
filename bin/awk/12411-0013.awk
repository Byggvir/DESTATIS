# AWK
# Generate SQL INSERT statements from splited 12411-0013.csv

BEGIN {
    i = 1 ;
    AG = -1;
    NL = "NEWAG";
    DATUM=""
    BL[1]=8;
    BL[2]=9;
    BL[3]=11;
    BL[4]=12;
    BL[5]=4;
    BL[6]=2;
    BL[7]=6;
    BL[8]=13;
    BL[9]=3;
    BL[10]=5;
    BL[11]=7;
    BL[12]=10;
    BL[13]=14;
    BL[14]=15;
    BL[15]=1;
    BL[16]=16;
}
{
    if ( $1 == "NEWAG" ) {
        if ( DATUM == $2 ) {
            AG = AG + 1 ;
        } else {
            DATUM = $2 ;
            AG = 0;
        }
        i = 1;
    } else {
        if ( AG < 91) {
            print ( DATUM "," BL[i] ",M," AG "," $1 ) ;
            print ( DATUM "," BL[i] ",W," AG "," $2 ) ;
#            print ( BL[i] ",b," AG "," $3 ) ;
        }
        i = i + 1 ;
    }
}
