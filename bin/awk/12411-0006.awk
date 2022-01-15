# AWK
# Generate SQL CSV from 124110006.csv for import

BEGIN {
}

{ 
    print( $1 "," $2 "," $3 "," $4 "," $5)

}
