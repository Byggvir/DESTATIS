#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT124110006"

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

outdir <- 'png/DT/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12411-0006)\nStand:", heute)

SQL <- 'select * from DT124110006 order by `Stichtag`, `Geschlecht`, `Alter`;'

DT124110006 <- RunSQL( SQL )

DT124110006$Geschlecht <- factor(DT124110006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))

for (J in c(1970,1991)) {

  for ( A in unique (DT124110006$Alter)) {
    
    DT124110006 %>% filter( year(Stichtag) >= J & Alter == A ) %>% ggplot(
      aes( x = Stichtag, y = Einwohner, group = Geschlecht, colour = Geschlecht)) +
      geom_step( alpha = 0.7 ) +
      geom_smooth() + 
      scale_x_date( date_labels = "%Y" ) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      theme_ipsum() +
      labs(  title = paste("Einwohner Bundesrepublik Deutschland")
            , subtitle = paste(  "Alter " , A , 'Jahre')
            , colour  = "Geschlecht"
            , x = "Stichtag 31.12."
            , y = "Einwohner"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, 'DT124110006_', J, '_', A, '.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )

  }

}
