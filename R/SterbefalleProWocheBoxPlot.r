#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Sterbefaelle pro Woche"

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

outdir <- 'png/Sterblichkeit/' 
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")
source("R/lib/color_palettes.r")

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste('© Thomas Arend,',year(today), '\nQuelle: © Statistisches Bundesamt (Destatis) Stand:', heute)

SQL <- paste( 'select Jahr,Kw, sum(Gestorbene) as Anzahl, sum(Einwohner) as Einwohner from SterbefaelleWocheBev group by Jahr, Kw;')
Sterbefaelle <- RunSQL( SQL )

Sterbefaelle$Jahre <- factor( Sterbefaelle$Jahr, levels = unique(Sterbefaelle$Jahr), labels = unique(Sterbefaelle$Jahr))
Sterbefaelle$Wochen <- factor( Sterbefaelle$Kw, levels = 1:53, labels = paste('Kw', 1:53))

Sterbefaelle %>% ggplot(
  aes( x = Kw, y = Anzahl , group = Kw )) +
  geom_boxplot( data = Sterbefaelle %>% filter( Jahr < 2022 & Jahr > 2017 )) +
  geom_point(data = Sterbefaelle %>% filter ( Jahr > 2017 ), aes(colour = Jahre), alpha = 0.5) +
 # expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro Woche 2018 - 2021 (Boxplots) und 2022 (Punkte)")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Jahr"
         , x = "Kw"
         , y = "Anzahl"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'SterbefaelleProWoche-BoxPlot', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

Sterbefaelle %>% ggplot(
  aes( x = Kw, y = Anzahl / Einwohner * 1000000 , group = Kw )) +
  geom_boxplot( data = Sterbefaelle %>% filter ( Jahr < 2020 )) +
  geom_point(data = Sterbefaelle %>% filter ( Jahr > 2019 ), aes(colour = Jahre), alpha = 0.5) +
  # expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterberate pro Woche pro 1 Mio Einwohner 2000 - 2019 (Boxplots) und 2020 - 2022 (Punkte) ")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Jahr"
         , x = "Kw"
         , y = "Anzahl"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'SterbeRateProWoche-BoxPlot', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
