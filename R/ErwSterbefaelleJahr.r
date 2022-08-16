#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "ErwSterbefaelle"

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

WD <- paste(SD[1:(length(SD)-1)],collapse='/')

setwd(WD)

outdir <- 'png/Sterblichkeit/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")


require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

citation <- "© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nStand 07.10.2021"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)


today <- Sys.Date()
heute <- format(today, "%d %b %Y")

SQL <- paste( 'select Jahr,sum(Gestorbene) as Gestorbene from SterbefaelleJahr where Jahr > 2011 group by Jahr;')
Sterbefaelle <- RunSQL( SQL )
Sterbefaelle$LfdJahr <-Sterbefaelle$Jahr -min(Sterbefaelle$Jahr)

ra <- lm( Gestorbene ~ LfdJahr , data = Sterbefaelle %>% filter(Jahr < 2020))

CI <- 0.95
ci <- confint(ra, level = CI)

a <- c( ci[1,1], ra$coefficients[1] , ci[1,2])
b <- c( ci[2,1], ra$coefficients[2] , ci[2,2])
 print(a)
 print(b)


Sterbefaelle %>% filter(Jahr < 2022) %>% ggplot(
  aes( x = Jahr ) ) +
  geom_line( aes( y = Gestorbene) ) +
  geom_smooth( aes( y = Gestorbene), method = 'lm', color = 'red') +
  geom_smooth( aes( y = Gestorbene), method = 'lm', color = 'blue', data =  Sterbefaelle %>% filter(Jahr < 2020)) +

  theme_ipsum() +
  expand_limits( y = a[1] ) +
  expand_limits( y = a[3] ) +

  labs(  title = paste("Sterbefälle pro Jahr")
         , subtitle= paste("Deutschland, Stand:", heute, 'auf Basis der Sterbefälle 2016 - 2019')
         , colour  = "Geschlecht"
         # , x = "Monat"
         , y = "Anzahl"
         , caption = citation ) +
  scale_x_continuous(labels=function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE)) -> pp

  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'ErwSterbefaelleJahr2', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
