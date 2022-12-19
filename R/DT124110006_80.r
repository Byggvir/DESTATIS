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

outdir <- 'png/DT12411/0006/'
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12411-0006)\nStand:", heute)

SQL <- 'select * from DT124110006 order by `Stichtag`, `Geschlecht`, `Alter`;'

DT124110006 <- RunSQL( SQL )



DT124110006$Geschlecht <- factor(DT124110006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))


##
#
# Alter über n Jahre
#
##

for ( A in (c(60,70,80))) {
  
  SQL <- paste('select Stichtag,Geschlecht,sum(Einwohner) as Einwohner from DT124110006 where `Alter` >=', A, 'group by `Stichtag`, `Geschlecht`;')
  DT124110006 <- RunSQL( SQL )
  DT124110006$Geschlecht <- factor(DT124110006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  
  DT124110006 %>% filter( year(Stichtag) > 2014) %>% ggplot(
    aes( x = Stichtag, y = Einwohner, group = Geschlecht, colour = Geschlecht)) +
    geom_line( alpha = 0.7 ) +
    geom_smooth() + 
    expand_limits( y = 0 ) +
    scale_x_date( date_labels = "%Y" ) +
    scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
    theme_ipsum() +
    labs(  title = paste("Einwohner Bundesrepublik Deutschland")
           , subtitle = paste0( 'Alter ', A, '+ Jahre' )
           , colour  = "Geschlecht"
           , x = "Stichtag 31.12."
           , y = "Einwohner"
           , caption = citation )  -> P
  
  ggsave(   filename = paste(outdir, 'DT124110006_', A, 'plus.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
  )
  
}
