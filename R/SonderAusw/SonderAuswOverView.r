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


scatter_plot <- function ( data, Zeitraum = 'Wochen') {
  
  print (Zeitraum)
  
  scatter <- data.table(
    x = (data %>% filter (Methode == 'Absolut DESTATIS' & Jahr > 2004))$EM
    , y = (data %>% filter (Methode == 'Standardisiert DESTATIS' & Jahr > 2004))$EM
    
  )
  
  print(scatter)
  
  ra <- lm(data = scatter, formula = y ~ x )
  print(summary(ra))
  
  scatter %>% ggplot(
    aes( x = x, y = y ) 
  ) +
    geom_abline(slope = 1, intercept = 0, color = 'red', linetype = 'dotted') +
    geom_point() +
    geom_smooth() +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Vergleich der Methoden zur Bestimmung der ', Zeitraum,'-Sterblichkeit', sep = '')
           , subtitle = 'Absolute und alters- und geschlechtsadjustierte Werte ab 2005'
           , x = 'Absolute Übersterblichkeit'
           , y = 'Adjustierte Übersterblichkeit [%]'
           , caption = citation ) -> P
  
  return(P)
  
}  
  
#
# Overview weekly excess mortality DEU
#

  # Retrieve data for MariaDB

  SQL <- paste('select * from WeeklyExcessMortality ;')
  data <- RunSQL( SQL )

  data$Woche <- factor(data$Kw, levels = 1:53, labels = paste( 'Kalenderwoche', 1:53 ) )

  data %>% filter ( Jahr > 2018 ) %>% ggplot(
    
  ) +
    geom_line(aes( x = Kw, y = EM, group = Methode, colour = paste(Quelle, Adjustiert, Methode) ) ) +
    geom_point(aes( x = Kw, y = EM, group = Methode, colour = Methode ) ) +
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

  
  PScatter1 <- scatter_plot(data, 'Wochen')  

  #
  # Overview monthly excess mortality DEU
  #
  
  # Retrieve data for MariaDB
  
  SQL <- paste('select * from OverViewMonthExcessMortality ;')
  data <- RunSQL( SQL )
  
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate )
  
  #
  # Plot diagram
  #
  
  data %>%  filter ( Jahr > 2018 ) %>% ggplot(
    
  ) +
    geom_line(aes( x = Monate, y = EM, group = Methode, colour = Methode ) ) +
    geom_point(aes( x = Monate, y = EM, group = Methode, colour = Methode ) ) +
    geom_line(aes( x = Monate, y = EM2, group = Methode, colour = Methode ), linetype = 'dotted' ) +
    geom_point(aes( x = Monate, y = EM2, group = Methode, colour = Methode ) ) +
    geom_abline(slope = 1, intercept = 0, color = 'red', linetype = 'dotted') +
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

  PScatter2 <- scatter_plot(data, 'Monats')  
  
  #
  # Overview yearly excess mortality DEU
  #
  
  # Retrieve data for MariaDB
  
  SQL <- paste('select * from OverViewYearExcessMortality ;')
  data <- RunSQL( SQL )
  
  data$Jahre <- factor(data$Jahr, levels = 2000:2022, labels = 2000:2022 )

  #
  # Plot diagram
  #
  
  data %>%  filter (Jahr > 2004) %>% ggplot(
  
  ) +
    geom_line(aes( x = Jahre, y = EM, group = Methode, colour = Methode ) ) +
    geom_point(aes( x = Jahre, y = EM, group = Methode, colour = Methode ) ) +
    geom_line(aes( x = Jahre, y = EM2, group = Methode, colour = Methode ), linetype = 'dotted' ) +
    geom_point(aes( x = Jahre, y = EM2, group = Methode, colour = Methode ) ) +
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
  
  PScatter3 <- scatter_plot(data, 'Jahres')  
  
#  POverview <- POverview1 / POverview2 + plot_annotation( title = "Geschätzte Über- / Untersterblichkeit 2022 - Kalenderwochen") 
  
  ggsave(paste( outdir, 'Overview_Wochen.png', sep='')
         , plot = POverview1
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Overview_Monate.png', sep='')
         , plot = POverview2
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Overview_Jahr.png', sep='')
         , plot = POverview3
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Scatter_Week.png', sep='')
         , plot = PScatter1
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )

  ggsave(paste( outdir, 'Scatter_Month.png', sep='')
         , plot = PScatter2
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  ggsave(paste( outdir, 'Scatter_Year.png', sep='')
         , plot = PScatter3
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
