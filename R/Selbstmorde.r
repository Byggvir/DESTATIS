#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Ueberstreblichkeit"

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
library(Cairo)

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
source("R/lib/sql.r")
source("R/lib/color_palettes.r")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste('© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nTabelle 23211-0006\nStand', heute)

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

SQL <- paste( 'select * from DT232110002;', sep = ' ')

Selbstmorde <- RunSQL( SQL )

Selbstmorde %>% ggplot(
  aes( x = Jahr ) ) +
  geom_line( aes( y = Male, colour = 'Männer' ) ) +
  geom_line( aes( y = Female, colour= 'Frauen' ) ) +
  geom_smooth( aes( y = Male )) +
  geom_smooth( aes( y = Female )) +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste('Sebstmorde pro Jahr und Geschlecht')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp6

ggsave(paste('png/Selbstmorde', '.png', sep='')
       , type = "cairo-png",  bg = "white"
       , width = 29.7, height = 21, units = "cm", dpi = 300
)
