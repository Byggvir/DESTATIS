# SED
# Prepare lines of 23211-0002.csv for AWK

1,7 d;
/__________/,$ d;
s#;#,#g;
s#-#0#g;
