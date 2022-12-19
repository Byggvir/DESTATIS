#!/usr/bin/env Rscript
#
#
# Script: DT126130006.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130006"

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
library(ggplottimeseries)
library(forecast)

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

fPrefix <- "Fallzahlen_Wo_"

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0006/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-0006)\nStand:", heute)


SQL <- 'select Jahr, Monat, DATE(CONCAT(Jahr,"-",Monat,"-",1)) as Datum, Geschlecht, Gestorbene from DT126130006 order by Jahr, Monat, Geschlecht;'

DT126130006 <- RunSQL( SQL )

DT126130006$Geschlecht <- factor(DT126130006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126130006$Monat <- factor(DT126130006$Monat, levels = 1:12, labels = Monate)

for (J in c(1950,2000,2010,2015,2016)) {

DT126130006 %>% filter( Jahr >= J ) %>% ggplot(
  aes( x = Datum, y = Gestorbene, group = Geschlecht, colour = Geschlecht)) +
  geom_step( alpha = 0.7 ) +
  geom_smooth() + 
  #facet_wrap(vars(Monat)) +
  # expand_limits( y = 0 ) +
  scale_x_date( date_labels = "%Y-%m" ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro Monat")
         , subtitle = paste(  "Zeitreihe ab Januar" , J)
         , colour  = "Geschlecht"
         , x = "Monat"
         , y = "Anzahl"
         , caption = citation )  -> P

ggsave(  paste(outdir, J, '.png', sep='')
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

}


