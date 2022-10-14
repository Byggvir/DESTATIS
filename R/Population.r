#!/usr/bin/env Rscript

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

WD <- paste(SD[1:(length(SD)-1)],collapse='/')

setwd(WD)
require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")


options(scipen=10)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")
citation <- paste("© 2022 by Thomas Arend\nQuelle: DESTATIS Stand:", heute )

SQL <- 'select year(Stichtag) as Jahr, Geschlecht, sum(Einwohner) as Einwohner from DT124110006 where `Alter` >= 80 group by Jahr, Geschlecht;'
germany <- RunSQL (SQL)

germany %>% ggplot(
    aes( x = Jahr ) ) +
    geom_line(aes( y = Einwohner, colour = Geschlecht )) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    theme_ta() +
    labs(  title = "Bevölkerung älter als 80 Jahre"
           , subtitle= paste("Deutschland, Stand:", heute)
           , colour = "Geschlecht"
           , fill = "Geschlecht"
           , legend = "Geschlecht"
           , x ="Jahr"
           , y = "Anzahl"
           , caption = citation ) -> pp1

ggsave("png/DEPopulationAge.png"
       , plot = pp1
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

SQL <- 'select year(Stichtag) as Jahr, Geschlecht, sum(Einwohner) as Einwohner from DT124110006 where `Alter` >= 80 and `Alter` < 85 and Stichtag >= "2015-12-31" group by Jahr, Geschlecht;'
germany_alter <- RunSQL (SQL)

germany_alter %>% ggplot(
    aes( x = Jahr ) ) +
    geom_line(aes( y = Einwohner, colour = Geschlecht ) ) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
#    facet_wrap(vars(Jahr)) +
    theme_ta() +
    labs(  title = "Bevölkerung 80 - 84 Jahre alt"
           , subtitle= paste("Deutschland, Stand:", heute)
           , x = "Alter"
           , y = "Anzahl"
           , colour = 'Geschlecht'
           , caption = citation ) -> pp2

ggsave("png/DEPopulationAge2.png"
       , plot = pp2
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
