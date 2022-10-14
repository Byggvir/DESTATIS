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

SQL <- 'select year(A.Stichtag) + 1 as Jahr,A.`Geschlecht`, A.`Alter`, (A.Einwohner) as Einwohner_A, (B.Einwohner) as Einwohner_B from DT124110006 as A join WPP as B on A.Stichtag = B.Stichtag and A.`Alter` = B.`Alter` and A.`Geschlecht` = B.`Geschlecht` ;'

WPP <- RunSQL( SQL )

WPP$Jahre <- factor ( WPP$Jahr, levels = unique(WPP$Jahr), labels = unique(WPP$Jahr))

WPP$Geschlecht <- factor( WPP$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer') )

  WPP %>% filter( Jahr == 2022 & Alter < 85 ) %>% ggplot(
      aes( x = Alter, y = (Einwohner_A - Einwohner_B) / Einwohner_B, group = Geschlecht, colour = Geschlecht ) ) +
      geom_step( alpha = 0.7 ) +
      scale_y_continuous( labels = scales::percent ) +
      # scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      theme_ipsum() +
      labs(  title = paste("Einwohner Bundesrepublik Deutschland 2022")
            , subtitle = paste( 'DESTATIS / World Population Prospects nahc Altersjahren')
            , colour  = "Geschlecht"
            , x = "Alter"
            , y = "Differenz zwischen WPP - DESTATIS [%]"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, 'WPP-DESTATIS.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )
