#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "ErwSterbefaelle_ab_2000"

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

citation <- "© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)


today <- Sys.Date()
heute <- format(today, "%d %b %Y")

SQL <- paste( 'select * from SchaetzeSterbefaelleJahr;')
Sterbefaelle <- RunSQL( SQL )

Sterbefaelle %>% ggplot(
  aes( x = Jahr ) ) +
  geom_line( aes( y = Gestorbene, colour = "Gestorbene") ) +
  geom_line( aes( y = ErwGestorbene, colour = "Erwartet" ) ) +
  theme_ipsum() +
 
  labs(  title = paste("Erwartete und geschätze Sterbefälle pro Jahr")
         , subtitle= paste("Deutschland, Stand:", heute, '\nBasis: stratifizierte Sterberate (Alter/Geschlecht) 2016 - 2019')
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl"
         , caption = citation ) +
  scale_x_continuous(labels=function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE)) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'ErwSterbefaelleJahr_ab_2000', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)
