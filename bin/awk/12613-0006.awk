# AWK
# Generate CSV from 12613-0006.csv for import

BEGIN {
    m=-1
}

{ 
    m=m+1;
    print ($1 "," m % 12 + 1 ",M," $3 "\n" $1 "," m % 12 + 1 ",F," $4 );

}
