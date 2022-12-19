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

ThisKw <- 46

AG <- RunSQL( 'select distinct AlterVon, AlterBis from SterbefaelleWocheBevX;')

AbJahr <- 2018
SQL1 <- paste( 
  'select Jahr, Kw, AlterVon, AlterBis, concat( "A",AlterVon,"-",AlterBis) as AG, Geschlecht, '
  , ' Gestorbene, Einwohner, Gestorbene/Einwohner * 100000 as Mortality' 
  , 'from SterbefaelleWocheBevX'
  , 'where'
  , 'Jahr >=', AbJahr
  , 'and Kw =', ThisKw
  ,';'
)

WSterbefaelle <- RunSQL( SQL1 )

WSterbefaelle$Geschlechter <- factor(WSterbefaelle$Geschlecht, levels = c('F','M'), labels = c('Frauen','Männer' ))
WSterbefaelle$Jahre <- factor( WSterbefaelle$Jahr, levels = unique(WSterbefaelle$Jahr), labels = unique(WSterbefaelle$Jahr))

for ( A in unique(WSterbefaelle$AG)) {
  
  daten = WSterbefaelle %>% filter( AG == A )
  scl = max(daten$Gestorbene) / max(daten$Einwohner)
  MF = median( (daten %>% filter( Jahr < 2022 & Geschlecht == 'F' ))$Mortality)
  MM = median( (daten %>% filter( Jahr < 2022 & Geschlecht == 'M' ))$Mortality)             
  
  daten %>%  ggplot(
    aes( x = Jahre, group = Geschlechter, colour = Geschlechter)) +
    geom_line ( aes( y = Mortality ) )  +
    # geom_hline( yintercept = MF ) +
    # geom_hline( yintercept = MM ) +
    # 
    expand_limits( y = 0 ) +
    # facet_wrap( vars(Geschlechter)) +
    scale_y_continuous(  labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)
                       #, sec.axis = sec_axis( ~./ scl, name = 'Einwohner', labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE) )
                       
                       ) +
    theme_ipsum() +
    labs(  title = paste( 'Sterberate in der Kw', ThisKw, 'pro 100.000' )
         , subtitle= paste('Altersgruppe ', A, '; Ab', AbJahr,'; Deutschland')
         , colour  = 'Geschlecht'
         , x = 'Altersgruppe'
         , y = 'Anzahl [1 / (Woche * 100.000)]'
         , caption = citation )

  ggsave(  paste(outdir, 'W',ThisKw,'-', AbJahr, '-', A, '.png', sep='')
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
  )

}
