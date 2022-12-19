#!/usr/bin/env Rscript
#
# Project: DESTATIS
# Script: MonatsSterblichkeit.r
#
# Stand: 2022-09-22
#
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "MonatsSterblichkeit"

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

fPrefix <- "Monat"

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")

outdir <- 'png/MonatsSterblichkeit/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")
citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (Destatis), WPP 2022\nStand:", heute)


SQL <- 'select Jahr, Monat, Geschlecht, AlterVon, AlterBis, Gestorbene / Einwohner * 1000000 as Sterberate from SterbefaelleMonatBevX ;'

Sterbefaelle <- RunSQL( SQL )
Sterbefaelle$Geschlecht <- factor(Sterbefaelle$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
Sterbefaelle$Jahre <- factor(Sterbefaelle$Jahr, levels = unique( Sterbefaelle$Jahr ), labels = unique( Sterbefaelle$Jahr ) )
Sterbefaelle$Monate <- factor(Sterbefaelle$Monat, levels = 1:12, labels = Monate)

AV <- unique(Sterbefaelle$AlterVon)
AB <- unique(Sterbefaelle$AlterBis)

Sterbefaelle$Alter <- factor( Sterbefaelle$AlterVon, levels = AV, labels = paste (AV, '-', AB ))

ThisMonth <- month(today) - 1

ra <- lm ( data = Sterbefaelle %>% filter( Monat == ThisMonth & Geschlecht == 'Männer'), formula = log(Sterberate) ~ AlterBis )
print(summary(ra))

  
Sterbefaelle %>% filter( Monat == ThisMonth ) %>% ggplot(
# Sterbefaelle %>% filter( Monat == 9 & AlterVon > 14 & AlterVon < 45) %>% ggplot(
    aes( x = Alter, y = Sterberate)) +
  geom_boxplot(aes(fill = Geschlecht ), alpha = 0.5) +
  # geom_point(data = Sterbefaelle %>% filter(Jahr ==2022 & Monat == 9 )
  #            , aes( x = Alter, y = Sterberate, colour = Geschlecht )
  #            , size = 2) +
  expand_limits( y = 0 ) +
  facet_wrap(vars(Geschlecht), ncol = 2) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, vjust = 0.5) 
  ) +
  scale_y_continuous( labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  labs(  title = paste("Sterbefälle pro Monat pro 1 Mio Einwohner")
         , subtitle= paste("Deutschland von", min(Sterbefaelle$Jahr), "bis", max(Sterbefaelle$Jahr),' Monat', Monate[ThisMonth])
         , colour  = "Geschlecht"
         , x = "Altersband"
         , y = "Anzahl [1/(Monat*1.000.000)]"
         , caption = citation )  -> pp6

ggsave(  filename =  paste( outdir, fPrefix,'-',Monate[ThisMonth], '.png', sep='')
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

AG <- unique(Sterbefaelle$AlterVon)
BG <- c(AG[AG>0]-1,100)

for ( a in 1:length(AG) ) {
  
Sterbefaelle %>% filter( AlterVon == AG[a] ) %>% ggplot(
  aes( x = Monate, y = Sterberate)) +
  geom_boxplot( alpha = 0.5 ) +
  geom_point(data = Sterbefaelle %>% filter( Jahr > 2019 & AlterVon == AG[a] )
             , aes( x = Monate, y = Sterberate, colour = Jahre )
             , size = 2 ) +
#  expand_limits( y = 0 ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  facet_wrap(vars(Geschlecht), nrow = 2) +
  theme_ipsum() +
  labs(  title = paste('Sterbefälle pro Monat pro 1 Mio Einwohner Alter von ', AG[a], 'bis', BG[a])
         , subtitle= paste("Deutschland von", min(Sterbefaelle$Jahr), "bis", max(Sterbefaelle$Jahr) )
         , colour  = "Jahr"
         , x = "Monat"
         , y = "Anzahl [1/(Monat*1.000.000)]"
         , caption = citation ) -> pp6

ggsave(  filename =  paste( outdir, fPrefix, '_', AG[a],'-', BG[a], '.png', sep='')
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)
}
