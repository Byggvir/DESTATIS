#
# Sonderauswertung Woche

1,/^Nr\./d;
/Insgesamt/d;
s#,,\+$##;
s#"95 u. mehr"#95-101#
s#-#,#;
s#,"X "##;
s#^\([0-9]*\),\([0-9]*\),\([0-9]*\),\([0-9]*\),#Jahr;\2;\3;\4,#;
s#,#\n#g;
