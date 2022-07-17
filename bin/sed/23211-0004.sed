# SED
# Splitt line of 12411-0013.csv for AWK

1,10 d;
/__________/,$ d;
s#;#,#g;
s#Intentional self-harm,##g;
s#Vors.*tzliche Selbstbesch.*digung,##g;
s#-#0#g
