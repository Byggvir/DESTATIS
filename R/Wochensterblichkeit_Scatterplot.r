#!/usr/bin/env Rscript
#
# Project: DESTATIS 
# Script: Wochensterblichkeit.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Wochensterblichkeit"

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

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")
source("R/lib/color_palettes.r")

outdir <- 'png/WochenSterblichkeit/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

fPrefix <- "Woche"


options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")
citation <- paste('© Thomas Arend,', year(today),'\nQuelle: © Statistisches Bundesamt (Destatis) Stand', heute)

AG <- RunSQL( 'select distinct AlterVon, AlterBis from SterbefaelleWocheBevX;')

AbJahr <- 2000
SQL1 <- paste( 
  'select Jahr, Kw, AlterVon, AlterBis, Geschlecht, '
  , ' Gestorbene, Einwohner, Gestorbene/Einwohner * 100000 as Mortality' 
  , 'from SterbefaelleWocheBevX'
  , 'where'
  , 'Jahr >=', AbJahr
  ,';'
)

WSterbefaelle <- RunSQL( SQL1 )

ThisKw = 46

WSterbefaelle$Geschlechter <- factor(WSterbefaelle$Geschlecht, levels = c('F','M'), labels = c('Frauen','Männer' ))
WSterbefaelle$Jahre <- factor( WSterbefaelle$Jahr, levels = unique(WSterbefaelle$Jahr), labels = unique(WSterbefaelle$Jahr))

for (i in 1:nrow(AG) ) {
  
Alter <- c(AG[i,])

WSterbefaelle %>% filter( AlterVon == Alter[1] & AlterBis == Alter[2] & Kw == ThisKw ) %>% ggplot(
  aes( x = Einwohner, y = Gestorbene, group = Kw )) +
  geom_point( ) +
  geom_point( data = WSterbefaelle %>% filter( AlterVon == Alter[1] & AlterBis == Alter[2] & Kw == ThisKw & Jahr == 2022 ), size = 3, color = 'blue' ) +
  
  # expand_limits( y = 0 ) +
  scale_x_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  facet_wrap(vars(Geschlechter), ncol = 1) +
  theme_ipsum() +
  labs(  title = paste( 'Sterbefälle in der Woche Kw', ThisKw )
         , subtitle= paste( 'Alter von', Alter[1], 'bis' , Alter[2], 'Jahre')
         , colour  = 'Jahr'
         , x = 'Einwohnwer'
         , y = 'Anzahl'
         , caption = citation )

ggsave(paste(outdir, 'SP-',AbJahr, '-A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 1920
       , height = 1080
       , units = "px"
       , dpi = 144
)

}
