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

outdir <- 'png/DT12411/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12411-0006)\nStand:", heute)

SQL <- 'select year(Stichtag) +1 as Jahr, Geschlecht, sum( `Alter` * Einwohner ) / sum(Einwohner) - `Alter` div 5 * 5 as MittleresAlter, `Alter` div 5 * 5 as AG from DT124110006 group by Stichtag, Geschlecht, AG;'

DT124110006 <- RunSQL( SQL )

DT124110006$Geschlecht <- factor(DT124110006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT124110006$Altersgruppe <- 
  factor( DT124110006$AG
          , levels = unique(DT124110006$AG)
          , labels = paste( 'A',unique(DT124110006$AG),'-A',unique(DT124110006$AG)+4, sep = ''))

  DT124110006 %>% filter ( Jahr > 2017 & AG > 50 & AG < 85 ) %>% ggplot(
      aes( x = Jahr, y = MittleresAlter, group = Geschlecht, colour = Geschlecht)) +
      geom_line( alpha = 0.7 ) +
      facet_wrap(vars(Altersgruppe)) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      theme_ipsum() +
      labs(  title = paste("Mittleres Alter der 5er Altersgruppen")
            , subtitle = paste( 'Differenz zur unteren Alter')
            , colour  = "Geschlecht"
            , x = "Jahr (Jahresanfang)"
            , y = "Mittleres Alter - unterers Alter [Jahre]"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, 'DT124110006_MittleresAlter-2018.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )
