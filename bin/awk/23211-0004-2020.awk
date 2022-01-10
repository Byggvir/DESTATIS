# AWK
# Generate SQL INSERT statements from splited 12411-0013.csv

{ 
    print( $1 "," $2 "," $3 "," $4 "," $5)
}
