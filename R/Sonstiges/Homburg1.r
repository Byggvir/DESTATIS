#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Homburg1"

library(tidyverse)
library(REST)
library(grid)
library(gridExtra)
library(gtable)
library(lubridate)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(scales)
library(ragg)

# library(extrafont)
# extrafont::loadfonts()

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
source("R/lib/sql.r")


today <- Sys.Date()
heute <- format(today, "%d %b %Y")
citation <- paste('© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis) und Robert-Koch-Institut (RKI)\nStand', heute)

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)


SQL <- paste( 'select A.Kw, A.Anzahl -B.Anzahl as Differenz, I.Anzahl as Impfungen from SterbefaelleProWoche as A 
  join SterbefaelleProWoche as B
  on A.Jahr = B.Jahr + 1 and A.Kw = B.Kw
  join RKI.ImpfungenProWoche as I
  on A.Jahr = I.Jahr and A.Kw = I.Kw
  where A.Jahr = 2021 and B.Jahr= 2020
  group by A.Jahr,A.Kw ;'
)

Sterbefaelle <- RunSQL( SQL )
scl <- (max(Sterbefaelle$Differenz)-min(Sterbefaelle$Differenz))/(max(Sterbefaelle$Impfungen)-min(Sterbefaelle$Impfungen))

Sterbefaelle %>% ggplot(
  aes( x = Kw ) ) +
  geom_line( aes(y= Differenz, colour = 'Sterbefälle' )) +
  geom_line( aes(y= Impfungen * scl , colour = 'Impfungen' )) +
  scale_y_continuous(  sec.axis = sec_axis(~./scl, name = "Impfungen pro Woche", labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ))
                       , labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Differenz Sterbefälle 2021 - 2020 ~ Impfungen')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Vergleich"
         , x = "Datum"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( color = 'blue', size = 12)
          , axis.title.y = element_text ( color='blue', size = 12)
          , axis.text.y.right = element_text ( color = 'red', size = 12 )
          , axis.title.y.right = element_text ( color='red', size = 12 )
  )

ggsave(paste('png/Humbug-001.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 29.7
       , height = 21
       , units = "cm"
       , dpi = 300
)

Sterbefaelle %>% ggplot() +
  geom_point( aes(x = Impfungen, y = Differenz)) +
  scale_x_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Differenz Sterbefälle 2021 - 2020 ~ Impfungen')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Vergleich"
         , x = "Impfungen pro Tag"
         , y = "Sterbefälle pro Tag"
         , caption = citation ) +
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( size = 12)
          , axis.title.y = element_text ( size = 12)
  )

ggsave(paste('png/Humbug-002.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 29.7
       , height = 21
       , units = "cm"
       , dpi = 300
)

ra <- lm(Differenz ~ Impfungen, data = Sterbefaelle)

SQL <- paste( 'select A.Kw, A.Anzahl as Sterbefall, B.AnzahlTodesfall as Corona, I.Anzahl as Impfung from SterbefaelleProWoche as A 
  join RKI.FaelleProWoche as B
  on A.Jahr = B.Jahr and A.Kw = B.Kw
  join RKI.ImpfungenProWoche as I
  on A.Jahr = I.Jahr and A.Kw = I.Kw
  where A.Jahr = 2021
  group by A.Jahr,A.Kw ;'
)

SterbefaelleImpfung <- RunSQL( SQL )

SterbefaelleImpfung %>% ggplot() +
  geom_point( aes(x = Impfung, y = Sterbefall - Corona )) +
  geom_smooth( aes(x = Impfung, y = Sterbefall - Corona )) +
  scale_x_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Sterbefälle 2021 (ohne Corona) ~ Impfungen')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Vergleich"
         , x = "Impfungen pro Woche"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( size = 12)
          , axis.title.y = element_text ( size = 12)
  )

ggsave(paste('png/Humbug-003.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 29.7
       , height = 21
       , units = "cm"
       , dpi = 300
)

SterbefaelleImpfung %>% ggplot() +
  geom_point( aes(x = Impfung, y = Sterbefall )) +
  geom_smooth( aes(x = Impfung, y = Sterbefall )) +
  scale_x_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function (x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Sterbefälle 2021 (inkl. Corona) ~ Impfungen')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Vergleich"
         , x = "Impfungen pro Woche"
         , y = "Sterbefälle pro Woche"
         , caption = citation ) +
  theme(  plot.title = element_text( size=24 )
          , axis.text.y  = element_text ( size = 12)
          , axis.title.y = element_text ( size = 12)
  )

ggsave(paste('png/Humbug-004.png', sep='')
       , device = 'png'
       , bg = "white"
       , width = 29.7
       , height = 21
       , units = "cm"
       , dpi = 300
)
