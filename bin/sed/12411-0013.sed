# SED
# Splitt line of 12411-0013.csv for AWK

1,6d
/^___/,$d
s#unter 1 Jahr#0#
s#-Jährige##
s# Jahre und mehr##
s#^\([0-9]\{2\}\)\.\([0-9]\{2\}\)\.\([0-9]\{4\}\);[^;]*;#NEWAG;\3-\2-\1\n#
s#\(\([0-9]*;\)\{3\}\)#\1\n#g
