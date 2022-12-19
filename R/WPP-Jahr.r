#!/usr/bin/env Rscript
#
#
# Script: DT124110006.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT124110006"

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

outdir <- 'png/WPP/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © World Puplication Prospects\nStand:", heute)

SQL <- 'select *, "WPP" as Quelle, year(Stichtag) + 1 as Jahr from   WPP union select *, "DESTATIS" as Quelle, year(Stichtag) + 1 as Jahr from DT124110006;'

WPP <- RunSQL( SQL )

WPP$Jahre <- factor ( WPP$Jahr, levels = unique(WPP$Jahr), labels = unique(WPP$Jahr))

WPP$Geschlecht <- factor( WPP$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer') )

  WPP %>% filter( year(Stichtag) > 2016 & Alter < 85 ) %>% ggplot(
      aes( x = Alter, y = Einwohner, group = Jahre, colour = Jahre ) ) +
      geom_line( alpha = 0.7 ) +
      facet_wrap( vars(Quelle, Geschlecht), nrow = 2) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      theme_ipsum() +
      labs(  title = paste("Einwohner Bundesrepublik Deutschland  DESTATIS / World Population Prospects")
            , subtitle = paste( 'Altersstruktur')
            , colour  = "Geschlecht"
            , x = "Stichtag 31.12. Vorjahr"
            , y = "Einwohner"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, 'WPP.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )
