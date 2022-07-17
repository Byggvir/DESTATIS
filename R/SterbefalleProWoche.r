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

outdir <- 'png/Sterblichkeit/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")


require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")
source("R/lib/color_palettes.r")

citation <- "© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nStand 07.10.2021"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

SQL <- paste( 'select S.Jahr, S.Kw, S.Anzahl, M.Median from SterbefaelleProWoche as S join SterbefaelleWocheMedian as M on S.Kw = M.Kw where S.Jahr > 2019 and S.Kw < 53 order by S.Jahr, S.Kw; ')
Sterbefaelle <- RunSQL( SQL )

# SQL <- paste( 'select * from SterbefaelleWocheMedian where Kw < 53 order by Kw;')
# Median <- RunSQL( SQL )

Sterbefaelle$Jahr <- paste('Jahr', Sterbefaelle$Jahr)

Sterbefaelle %>% ggplot(
  aes( x = Kw ) ) +
  geom_line( aes( y = Anzahl, group = Jahr, colour = Jahr)) +
  geom_line( aes( x = Kw, y = Median, colour = 'Median 2016 - 2019'), linetype = 'dashed', size = 1.5) +
  facet_wrap(vars(Jahr)) +
#  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro Woche")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Jahr"
         , x = "Kw"
         , y = "Anzahl"
         , caption = citation ) +
#  scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'SterbefaelleProWoche', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

Excess <- sum(Sterbefaelle$Anzahl - Sterbefaelle$Median)
print(sum(Sterbefaelle$Anzahl))
print(sum(Sterbefaelle$Median))
print(Excess)

Sterbefaelle %>% ggplot(
  aes( x = Kw ) ) +
  geom_line( aes( y = Anzahl - Median, group = Jahr, colour = Jahr)) +
  facet_wrap(vars(Jahr)) +
  #  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Übersterblichkeit pro Woche")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Jahr"
         , x = "Kw"
         , y = "Anzahl"
         , caption = citation ) +
  #  scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'SterbefaelleProWoche_X', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
