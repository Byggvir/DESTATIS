BEGIN {
    
    j=0;i=1;a=0;b=0;
}
{
    if ( $1 == "Jahr" ) {
        j=$2;
        i=1;
        a=$3;
        b=$4;
    }
    else {
        printf ( "%s,%d,%d,%d,%d,%d\n", s,j,i,a,b-1,$1 ) ;
        i = i + 1;
    }
    
    
}
