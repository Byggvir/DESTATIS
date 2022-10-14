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

outdir <- 'png/DT12411/AG/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12411-0006)\nStand:", heute)

SQL <- 'select year(Stichtag) + 1 as Jahr, Geschlecht, (`Alter` div 5) * 5 as AG, sum(Einwohner) as Einwohner from DT124110006 group by `Jahr`, `Geschlecht`, `AG`;'

DT124110006 <- RunSQL( SQL )

DT124110006$Geschlecht <- factor(DT124110006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT124110006$Jahre <- factor( DT124110006$Jahr, levels = unique(DT124110006$Jahr), labels = unique(DT124110006$Jahr) )

for (J in c(2016)) {

 for ( A in unique (DT124110006$AG)) {
    
    B = A + 4
    if (B>85) { B = '∞'}
    
    DT124110006 %>% filter( Jahr >= J & AG == A ) %>% ggplot(
      aes( x = Jahre, y = Einwohner, group = Geschlecht, colour = Geschlecht, fill = Geschlecht)) +
      geom_bar( alpha = 0.7, stat = 'identity', position = position_dodge() ) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
 #     facet_wrap (vars( AG ), nrow = 3) +
      theme_ipsum() +
      theme (
        axis.text.x = element_text( angle = 90, hjust = 0.5, vjust = 0.5 ) 
      ) +
      labs(  title = paste("Einwohner Bundesrepublik Deutschland")
            , subtitle = paste ('Alter von', A, 'bis', B, 'Jahre')
            , colour  = "Geschlecht"
            , x = "Stichtag: Jahresende"
            , y = "Einwohner"
            , caption = citation )  -> P

    ggsave(   filename = paste(outdir, 'AG', A, '-', J, '.png', sep='')
            , plot = P
            , device = "png"
            , bg = "white"
            , width = 3840, height = 2160
            , units = "px"
    )
  }

}
