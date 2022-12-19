#!/usr/bin/env Rscript
#
#
# Script: DT232110004.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT232110004"

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

WD <- paste(SD[1:(length(SD)-1)],collapse='/')

setwd(WD)

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

outdir <- 'png/DT23211/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (23211-0004)\nStand:", heute)

SQL <- 'select *, concat("A",AlterVon,"-A",AlterBis) as Altersgruppe from DT232110004 order by `Jahr`, `AlterVon`;'

DT232110004 <- RunSQL( SQL )

DT232110004 %>% ggplot() +
      geom_line( aes( x = Jahr, y = Male, colour = 'Männer' ) ) +
      geom_line( aes( x = Jahr, y = Female, colour = 'Frauen' ) ) + 
      geom_smooth( aes( x = Jahr, y = Male, colour = 'Männer' ) ) +
      geom_smooth( aes( x = Jahr, y = Female, colour = 'Frauen' ) ) + 
      scale_x_continuous( labels = function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE ) ) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      facet_wrap(vars(Altersgruppe)) +
      theme_ipsum() +
      labs(  title = paste("Selbstmorde Bundesrepublik Deutschland")
            , subtitle = paste( 'Nach Alter und Geschlecht')
            , colour  = "Geschlecht"
            , x = "Jahr"
            , y = "Anzahl"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, '0004.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )
