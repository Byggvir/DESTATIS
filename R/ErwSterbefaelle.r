#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "ErwSterbefaelle"

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

citation <- paste("© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2022\nStand", heute)


SQL <- paste( 'select Jahr, Monat, Geschlecht, sum(Gestorbene) as Gestorbene, sum(ErwGestorbene) as ErwGestorbene from SchaetzeSterbefaelle where Jahr > 2020 group by Jahr, Monat, Geschlecht;')

Sterbefaelle <- RunSQL( SQL )

Sterbefaelle %>% ggplot(
  aes( x = Monat ) ) +
  geom_line( aes( y = ErwGestorbene, colour = Geschlecht), linetype = 'dotted'  ) +
  geom_line( aes( y = Gestorbene, colour = Geschlecht)) +

#  expand_limits(y = 0) +
  facet_wrap(vars(Jahr)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle und erwartete Sterbefälle")
         , subtitle= paste("Deutschland, Stand:", heute, 'auf Basis der Sterbefälle 2016 - 2019')
         , colour  = "Geschlecht"
         , x ="Monat"
         , y = "Anzahl"
         , caption = citation ) +
  scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'ErwSterbefaelle', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
