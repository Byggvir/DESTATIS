#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "MonatsSterblichkeit"

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

fPrefix <- "Fallzahlen_Wo_"

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")

citation <- "© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022\nStand 16.06.2022"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

SQL <- 'select Jahr, Monat, Geschlecht, AlterVon, Gestorbene / Einwohner Sterberate from SterbefaelleMonatBev where Jahr > 2015;'

Sterbefaelle <- RunSQL( SQL )

Sterbefaelle %>% ggplot(
  aes( x = AlterVon, y = Sterberate, colour = Geschlecht )) +
  geom_point() +
  geom_smooth() +
  facet_wrap(vars(Jahr)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro Monat pro 1.000")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "Alter"
         , y = "Anzahl [1/(Monat*1000)]"
         , caption = citation ) +
#  scale_x_continuous(breaks=1:12,labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp6

ggsave(  paste('png/MonatsSterblichkeit','.png', sep='')
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
)
