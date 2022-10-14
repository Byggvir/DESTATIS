#!/usr/bin/env Rscript
#
#
# Script: DT126130006-ExcessMortality.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SonderAuswWoche"

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

WD <- paste(SD[1:(length(SD)-2)],collapse='/')

setwd(WD)

fPrefix <- "SonderAusw"

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

outdir <- 'png/SonderAusw/Median/' 
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-0006)\nStand:", heute)

SQL <- paste('select * from OverViewWeekExcessMortality ;')
data <- RunSQL( SQL )

  data$Woche <- factor(data$Kw, levels = 1:53, labels = paste( 'Kalenderwoche', 1:53 ) )

  data %>%  ggplot(
    aes( x = Kw, y = EM, group = Methode, colour = Methode ) 
    ) +
    geom_line() +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90 )
    ) +
    labs(  title = paste('Über- / Untersterblichkeit 2022 - Kalenderwochen')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Kalenderwoche'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview
  
  ggsave(paste( outdir, 'Overview_Woche.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  SQL <- paste('select * from OverViewMonthExcessMortality ;')
  data <- RunSQL( SQL )
  
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate )
  
  data %>%  ggplot(
    aes( x = Monate, y = EM, group = Methode, colour = Methode ) 
  ) +
    geom_line() +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90 )
    ) +
    labs(  title = paste('Über- / Untersterblichkeit 2022 - Monate')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Monat'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview
  
  ggsave(paste( outdir, 'Overview_Monat.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  
