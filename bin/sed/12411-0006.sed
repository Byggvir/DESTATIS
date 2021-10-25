# SED
# Transform 12411-0006.csv for import

1,8d;
s#-Jährige##;
s# Jahre und mehr##;
s#unter 1 Jahr#0#;
/Insgesamt/d;
/___*/,$d;
s#\([0-9]\{2\}\)\.\([0-9]\{2\}\)\.\([0-9]\{4\}\);#\3-\2-\1;#
