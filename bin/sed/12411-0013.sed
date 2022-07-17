# SED
# Splitt line of 12411-0013.csv for AWK

# Delete line 1 - 6
1,6d;
#delete all lines after data end

/^___/,$d;

# Reformat age to number
s#unter 1 Jahr#0#;
s#-Jährige##;
s# Jahre und mehr##;

# If date in format "DD.MM.YYYY" then reformat to "YYYY-MM-DD"
s#\([0-9]\{2\}\)\.\([0-9]\{2\}\)\.\([0-9]\{4\}\)#\3-\2-\1#g;

# Change ; to ,
s#;#,#g;

# Splitt line after age and mark begin of a new age
s#^\([0-9]\{4\}\)\-\([0-9]\{2\}\)\-\([0-9]\{2\}\),\([^,]*\),#NEWAGE,\1-\2-\3\,\4\n#;

# Splitt rest of line
s#\(\([0-9]*,\)\{3\}\)#\1\n#g;
