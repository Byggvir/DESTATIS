# AWK
# Generate SQL CSV from 23211-0002.csv for import

BEGIN {
}

{ 
    print( $1 "," $3 "," $4 )

}
