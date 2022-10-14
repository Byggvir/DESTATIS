#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Kuhbandner"

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

# Set Working directory to git root

if (rstudioapi::isAvailable()){
  
  # When executed in RStudio
  SD <- unlist(str_split(dirname(rstudioapi::getSourceEditorContext()$path),'/'))
  
} else {
  
  #  When executi on command line 
  SD = (function() return( if(length(sys.parents())==1) getwd() else dirname(sys.frame(1)$ofile) ))()
  SD <- unlist(str_split(SD,'/'))
  
}

WD <- paste(SD[1:(length(SD)-2)],collapse='/')

setwd(WD)

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")

outdir <- 'png/Humbug/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")
citation <- paste('© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis) und Robert-Koch-Institut (RKI)\nStand', heute)

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)


if ( ! exists("Impfungden")) {
  
  SQL <- 'select * from RKI.ImpfungenProWoche;'
  Impfungen <- RunSQL(SQL)
  
}

# Durchschnittlichen Sterbefälle pro Tag

SQL <- 'select avg(Anzahl) as Durchschnitt from SterbefaelleTag where Datum > "2015-12-31" and Datum < "2021-01-01";'
mSF1 <- RunSQL(SQL)

if ( ! exists("Sterbefaelle")) {
  SQL <- paste( 'select Datum, S.Anzahl as Anzahl, C.AnzahlTodesfall as CoViD19 from SterbefaelleTag as S join RKI.FaelleProTag as C on S.Datum = C.Meldedatum where year(S.Datum) = 2021; ')
  Sterbefaelle <- RunSQL( SQL )
}

Sterbefaelle %>% ggplot(
  aes( x = Datum ) ) +
  geom_line( aes(y = Anzahl, colour = 'Sterbefälle 2021' )) +
# geom_smooth( aes(y = Anzahl, colour = 'Sterbefälle 2021' )) +
# geom_line( aes(y = Anzahl - CoViD19, colour = 'Sterbefälle 2021 ohne COViD19' )) +
  geom_hline ( aes(yintercept = mSF1$Durchschnitt, colour = "Durchschnitt 2016 - 2020" ) ) +
  scale_y_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ta() +
  labs(  title = paste('Sterbefälle 2021')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Sterbefälle"
         , x = "Datum"
         , y = "Sterbefälle pro Tag"
         , caption = citation ) +
  
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( color = 'blue', size = 12)
          , axis.title.y = element_text ( color='blue', size = 12)
          , axis.text.y.right = element_text ( color = 'red', size = 12 )
          , axis.title.y.right = element_text ( color='red', size = 12 )
  )

ggsave(paste(outdir,'Kuhbandner-001.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

SQL <- 'select avg(Anzahl) as Durchschnitt from SterbefaelleProWoche where Jahr > 2015 and Jahr < 2021;'
mSF2 <- RunSQL(SQL)

if ( ! exists("SterbefaelleWoche")) {
  
  SQL <- paste( 'select S.Kw, S.Anzahl as Anzahl , C.AnzahlTodesfall as CoViD19, M.Median  as Median, I.Anzahl as Impfungen from SterbefaelleProWoche as S'
    , 'join RKI.FaelleProWoche as C on C.Jahr = S.Jahr and C.Kw = S.Kw'
    , 'join SterbefaelleWocheMedian as M on C.Kw = M.Kw'
    , 'join RKI.ImpfungenProWoche as I on S.Jahr = I.Jahr and S.Kw = I.Kw'
    , 'where S.Jahr = 2021 and S.Jahr = I.Jahr and ImpfSchutz = 1; ')
  SterbefaelleWoche <- RunSQL( SQL )

}

scl <-  max(SterbefaelleWoche$Impfungen) / max(SterbefaelleWoche$Anzahl)

SterbefaelleWoche %>% ggplot(
  aes( x = Kw ) ) +
  geom_line( aes( y = Anzahl - CoViD19, colour = 'Sterbefälle 2021 ohne CoViD19' )) +
  geom_line( aes( y = Anzahl, colour = 'Sterbefälle 2021' )) +
  geom_line( aes( y = Median, colour = 'Sterbefälle Median 2016 - 2019' ), size = 1.5) +
  geom_hline ( aes(yintercept = mSF2$Durchschnitt, colour = "Durchschnitt 2016 - 2020" ) ) +
  scale_y_continuous( sec.axis = sec_axis( ~.*scl, name = "Impfungen pro Woche", labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) )
                      , labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ta() +
  labs(  title = paste('Sterbefälle 2021')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Sterbefälle"
         , x = "Woche"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( color = 'blue', size = 12)
          , axis.title.y = element_text ( color='blue', size = 12)
          , axis.text.y.right = element_text ( color = 'red', size = 12 )
          , axis.title.y.right = element_text ( color='red', size = 12 )
  )

ggsave(paste(outdir,'Kuhbandner-003.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

scl <-  max(SterbefaelleWoche$Impfungen) / ( max(SterbefaelleWoche$Anzahl - SterbefaelleWoche$CoViD19 - SterbefaelleWoche$Median ) )

SterbefaelleWoche %>% filter(Kw < 20) %>% ggplot(
  aes( x = Kw ) ) +
  geom_line( aes( y = Anzahl - CoViD19 - Median, colour = 'Übersterblichkeit' )) +
  geom_line( aes( y = Impfungen / scl, colour = 'Impfungen' )) +
  scale_y_continuous( sec.axis = sec_axis( ~.*scl, name = "Impfungen pro Woche", labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) )
                      , labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ta() +
  labs(  title = paste('Übersterbefälle ~ Impfungen 2021')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Sterbefälle"
         , x = "Woche"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( color = 'blue', size = 12)
          , axis.title.y = element_text ( color='blue', size = 12)
          , axis.text.y.right = element_text ( color = 'red', size = 12 )
          , axis.title.y.right = element_text ( color='red', size = 12 )
  )

ggsave(paste(outdir,'Kuhbandner-004.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)


SterbefaelleWoche %>% ggplot( ) +
  geom_point( aes( x = Impfungen, y = Anzahl - CoViD19 - Median ) ) +
  geom_smooth( aes( x = Impfungen, y = Anzahl - CoViD19 - Median ), method = 'lm') +
  scale_x_continuous( labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ta() +
  labs(  title = paste('Übersterbefälle ~ Impfungen 2021')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Sterbefälle"
         , x = "Impfungen pro Woche"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( color = 'blue', size = 12)
          , axis.title.y = element_text ( color='blue', size = 12)
          , axis.text.y.right = element_text ( color = 'red', size = 12 )
          , axis.title.y.right = element_text ( color='red', size = 12 )
  )

ggsave(paste(outdir,'Kuhbandner-005.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

ra <- lm(Impfungen ~ Anzahl - CoViD19 - Median , data = SterbefaelleWoche %>% filter (Kw < 21))

print (summary (ra))
