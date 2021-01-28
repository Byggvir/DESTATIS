# SED
# Splitt line of 12411-0013.csv for AWK

1,6d
/^___/,$d
s#^[^;]*;[^;]*;#NEWAG\n#
s#\(\([0-9]*;\)\{3\}\)#\1\n#g
