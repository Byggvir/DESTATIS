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
library(patchwork)

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

citation <- paste("© Thomas Arend, 2022\nQuellen: © Statistisches Bundesamt / WPP\nStand:", heute)

  SQL <- paste('select * from OverViewWeekExcessMortality ;')
  data <- RunSQL( SQL )

  data$Woche <- factor(data$Kw, levels = 1:53, labels = paste( 'Kalenderwoche', 1:53 ) )

  data %>% filter ( Jahr > 2018 ) %>% ggplot(
    aes( x = Kw, y = EM, group = Methode, colour = Methode ) 
    ) +
    geom_line() +
    geom_point() +
    scale_y_continuous( labels = scales::percent ) +
    facet_wrap(vars(Jahr)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit (Median aus 4 Jahren)')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Kalenderwoche'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview1
  
  SQL <- paste('select * from OverViewMonthExcessMortality ;')
  data <- RunSQL( SQL )
  
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate )
  
  data %>%  filter ( Jahr > 2018 ) %>% ggplot(
    aes( x = Monate, y = EM, group = Methode, colour = Methode ) 
  ) +
    geom_line() +
    geom_point() +
    scale_y_continuous( labels = scales::percent ) +
    facet_wrap(vars(Jahr)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Monat'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview2

  SQL <- paste('select * from OverViewYearExcessMortality ;')
  data <- RunSQL( SQL )
  
  data$Jahre <- factor(data$Jahr, levels = 2000:2022, labels = 2000:2022 )
  
  data %>%  filter (Jahr > 2004) %>% ggplot(
    aes( x = Jahre, y = EM, group = Methode, colour = Methode ) 
  ) +
    geom_line() +
    geom_point() +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Jahr'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview3
  
#  POverview <- POverview1 / POverview2 + plot_annotation( title = "Geschätzte Über- / Untersterblichkeit 2022 - Kalenderwochen") 
  
  ggsave(paste( outdir, 'Overview_Wochen.png', sep='')
         , plot = POverview1
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  ggsave(paste( outdir, 'Overview_Monate.png', sep='')
         , plot = POverview2
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  ggsave(paste( outdir, 'Overview_Jahr.png', sep='')
         , plot = POverview3
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
