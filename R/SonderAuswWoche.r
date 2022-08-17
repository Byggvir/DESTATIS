#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SterblichkeitMonat"

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

outdir <- 'png/SonderAusw/' 
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

J = 2016

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

SQL <- paste( 'select *, KwToDate(Jahr,Kw) as Datum from SterbefaelleWoche;' )

Sterbefaelle <- RunSQL( SQL )
Sterbefaelle$Geschlecht <- factor(Sterbefaelle$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))

Sterbefaelle$AG <- paste( " A",Sterbefaelle$AlterVon,"-A", Sterbefaelle$AlterBis, sep = '' )

Sterbefaelle %>% filter(Jahr == J) %>% ggplot(
  aes( x = Datum, y = Gestorbene)) +
  geom_line( aes( colour =  AG) ) +
  scale_x_date( date_labels = "%Y-%b", guide = guide_axis(angle = 90) ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  expand_limits(y = 0) +
  facet_wrap(vars(Geschlecht)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle (Kalenderwoche) nach Altersgruppe und Geschlecht")
         , subtitle= paste("Deutschland, Stand:", heute)
         , axis.text.x = element_text(angle = -90, hjust = 0)
         , colour  = "Geschlecht"
         , x = "Kalenderwoche"
         , y = "Gestorbene"
         , caption = citation ) -> P1

ggsave(paste( outdir, 'SonderAuswWoche',J,'.png', sep='')
       , plot = P1
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)
