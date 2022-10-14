#!/usr/bin/env Rscript
#
#
# Script: Periodensterbetafeln.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Periodensterbetafeln"

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
library(stringr)
library(ragg)

# library(extrafont)
# extrafont::loadfonts()

# Set Working directory to git root

if (rstudioapi::isAvailable()){
  
  # When executed in RStudio
  SD <- unlist(str_split(dirname(rstudioapi::getSourceEditorContext()$path),'/'))
  
} else {
  
  #  When executing on command line 
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

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

outdir <- 'png/Periodentafeln/' 

dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

citation <- paste( "© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nStand:", heute )

SQL <- 'select * from Periodensterbetafeln;'

Periodentafeln <- RunSQL( SQL )

Periodentafeln$Geschlecht[Periodentafeln$Geschlecht=='F'] <- 'Frauen'
Periodentafeln$Geschlecht[Periodentafeln$Geschlecht=='M'] <- 'Männer'

for (A in unique(Periodentafeln$Alter)) {
  

Periodentafeln %>% filter( Alter == A ) %>% ggplot(
  aes( x = Jahr, y = p, colour = Geschlecht )) +
  geom_line() +
  geom_smooth(  method = 'loess') +
#  expand_limits( y = 0 ) +
  #  scale_x_continuous(breaks=1:12,labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  #  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))
  scale_y_continuous(labels = scales::percent ) +
#  facet_wrap(vars(Geschlecht)) +
  theme_ta() +
  labs(  title = paste("Sterbewahrscheinlichkeit im Alter", A , "Jahre")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "1. Jahr der Periodensterbetafel"
         , y = "Sterbewahrscheinlichket [%]"
         , caption = citation ) -> p

ggsave(  paste(outdir, 'Alter', str_pad(A, 3, pad = 0),  '.png', sep='')
         , plot = p
         , device = "png"
         , bg = "white"
         , width = 3840
         , height = 2160
         , units = "px"
)
}

Periodentafeln %>% filter( Alter > 59 & Alter < 80) %>% ggplot(
  aes( x = Alter, y = p, colour = Geschlecht )) +
  geom_line() +
 # geom_smooth() +
 # expand_limits( y = 0 ) +
  facet_wrap(vars(Jahr)) +
  theme_ta() +
  labs(  title = paste("Sterbewahrscheinlichkeit nach Alter")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "Alter"
         , y = "Sterbewahrscheinlichket [%]"
         , caption = citation ) +
  #  scale_x_continuous(breaks=1:12,labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  #  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))
  scale_y_continuous( # trans='log10' , 
                      labels = scales::percent ) -> p

ggsave(  paste(outdir, 'Jahre','.png', sep='')
         , plot = p
         , device = "png"
         , bg = "white"
         , width = 3840
         , height = 2160
         , units = "px"
)
