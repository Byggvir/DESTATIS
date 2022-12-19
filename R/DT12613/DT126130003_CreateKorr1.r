#!/usr/bin/env Rscript
#
#
# Script: DT126130006_CreateKorr1.r

# Jährliche Sterberate in Deutschland nach Alter und Geschlecht 
# Quellen:
#   DT12613-0003
#   DT12411-0006
#   World Population Prospect 2022
#
#
# Stand: 2022-12-15
# (c) 2022 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130003_CreateKorr1"

require(data.table)
library(tidyverse)
library(grid)
library(gridExtra)
library(gtable)
library(lubridate)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(scales)
library(ragg)
# library(ggplottimeseries)
# library(forecast)

#
# Set Working directory to git root
#

if (rstudioapi::isAvailable()){
  
  # When executed in RStudio
  SD <- unlist(str_split(dirname(rstudioapi::getSourceEditorContext()$path),'/'))
  
} else {
  
  #  When executing on command line 
  SD = (function() return( if(length(sys.parents())==1) getwd() else dirname(sys.frame(1)$ofile) ))()
  SD <- unlist(str_split(SD,'/'))
  
}

WD <- paste(SD[1:(length(SD) - 2 )],collapse='/')

setwd(WD)

#
# End of set working directory
#

# Load own routines

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

options( 
  digits = 10
  , scipen = 10
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0003/Scatterplots/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-3, 12411-6 +WPP)\nStand:", heute)

CI <- 0.95

MaxJahr = 2021

SQL <- paste('select * from DeathRateYear where Jahr <=', MaxJahr, ';')
DT126130003 <- RunSQL( SQL )

MinJahr = min(DT126130003$Jahr)
  
#DT126130003$Geschlecht <- factor(DT126130003$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126130003$Geburtsjahr <- DT126130003$Jahr - DT126130003$Alter

#
# Tabelle der Ergebnisse der Regressionsanalyse
#

CITab <- data.table(
  Jahrgang = c()
  , Folgejahrgang = c()
  , Geschlecht = c()
  , a = c()
  , b = c()
  , a_lower = c()
  , a_upper = c()
  , b_lower = c()
  , b_upper = c()
  , r2 = c()
  
)

Vergleiche_Jahrgang <- function( data, Jahrgang, Folgejahrgang ) {
  
  RTab <- data.table(
    Jahrgang = c()
    , Folgejahrgang = c()
    , Geschlecht = c()
    , a = c()
    , b = c()
    , a_lower = c()
    , a_upper = c()
    , b_lower = c()
    , b_upper = c()
    , r2 =c()
    
  )

  G1 <- min(Jahrgang,Folgejahrgang)
  G2 <- max(Jahrgang,Folgejahrgang)
  
  maxA <- min(MaxJahr - G2, 99 )
  minA <- max(MinJahr - G1, 5)

  delta <- G2 - G1
  
  for ( GE in c('M', 'F') ){
    
    
    xy <- data.table(
      Alter = ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Alter
      , x = ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Gestorbene 
      / ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Einwohner
      
      , y = (DT126130003 %>% filter( (Geburtsjahr == G2 ) & Alter >= minA & Alter <= maxA & Geschlecht == GE ))$Gestorbene
      / (DT126130003 %>% filter( (Geburtsjahr == G2 ) & Alter >= minA & Alter <= maxA & Geschlecht == GE ))$Einwohner
      
    )

    #
    # Regressionsanalyse
    #
    
    ra <- lm (data = xy , formula = 'y ~ x')
    ci <- confint(ra,level = CI)
    # print(ci)
    
    if ( is.na(ra$coefficients[1])) { P_a = 0 } else { P_a = ra$coefficients[1] }
    if ( is.na(ra$coefficients[2])) { P_b = 1 } else { P_b = ra$coefficients[2] }
    if ( is.na(ci[1,1]) ) { P_c11 = 0 } else { P_c11 = ci[1,1] }
    if ( is.na(ci[1,2]) ) { P_c12 = 0 } else { P_c12 = ci[1,2] }
    if ( is.na(ci[2,1]) ) { P_c21 = 1 } else { P_c21 = ci[2,1] }
    if ( is.na(ci[2,2]) ) { P_c22 = 1 } else { P_c22 = ci[2,2] }
    
    RTab <- rbind( RTab,
                    data.table( 
                      Jahrgang = G1
                      , Folgejahrgang = G2
                      , Geschlecht = GE
                      , a = P_a
                      , b = P_b
                      , a_lower = P_c11
                      , a_upper = P_c12
                      , b_lower = P_c21
                      , b_upper = P_c22
                      , r2 = summary(ra)$r.squared
                    )
    )    
  
  }
  
  return ( RTab )

}

for ( G in 1900:2005 ) {

  print( G )
  for ( i in 1:10 ) {
    
    CITab <- rbind( CITab
                    , Vergleiche_Jahrgang ( DT126130003, G, G + i )
    )
  
  }
  
}
  
for ( G in 2006:2021 ) {
  for ( i in 1:4 ) {
    
    CITab <- rbind( CITab
                    , data.table(
                      Jahrgang = c(G,G)
                      , Folgejahrgang = c(G+i,G+i)
                      , Geschlecht = c('M','F')
                      , a = c(0,0)
                      , b = c(1,1)
                      , a_lower = c(0,0)
                      , a_upper = c(0,0)
                      , b_lower = c(1,1)
                      , b_upper = c(1,1)
                      , r2 =c(1)
                    )
    )
  }
}

write.csv(CITab,file= paste0( outdir, 'Regressionsanalyse.csv' ), row.names = FALSE )
write.csv(CITab,file= paste0( '/tmp/Regressionsanalyse.csv' ), row.names = FALSE )
