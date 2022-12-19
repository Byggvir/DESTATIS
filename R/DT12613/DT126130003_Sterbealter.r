#!/usr/bin/env Rscript
#
#
# Script: DT126130006_Alter.r
#
#
# Jährliche Sterberate in Deutschland nach Alter und Geschlecht 
# Quellen:
#   DT12613-0003
#   DT12411-0006
#   World Population Prospect 2022
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130003_Alter"

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

WD <- paste(SD[1:(length(SD)-2)],collapse='/')

setwd(WD)

#
# End of set working directory
#

# Load own routines

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0003/Sterberate/' 
dir.create( outdir, showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-3, 12411-6 +WPP)\nStand:", heute)

SQL <- 'select Jahr,Geschlecht,sum(`Alter`*Anzahl)/sum(Anzahl) + 0.5 as `Alter` from DT126130003 group by Jahr, Geschlecht;'
DT126130003 <- RunSQL(SQL)
DT126130003$Geschlecht <- factorGeschlecht(DT126130003$Geschlecht)

DT126130003 %>%  ggplot(
  aes( x = Jahr, y = Alter, group = Geschlecht, colour = Geschlecht )
  ) +
  geom_line( ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 8)
  ) +
  labs(  title = paste("Sterbealter Deutschland")
         , subtitle = paste( "Durchschnittsalter der Gestorbenen" )
         , x = "Jahr"
         , y = "Alter"
         , caption = citation )  -> P

ggsave(  paste(outdir, 'Sterbealter.png', sep='')
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)
