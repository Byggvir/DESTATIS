#!/usr/bin/env Rscript
#
#
# Script: SonderAuswOverViewWoche.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SonderAuswOverViewMonat"

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
  
  #  When executing on command line 
  SD = (function() return( if(length(sys.parents())==1) getwd() else dirname(sys.frame(1)$ofile) ))()
  SD <- unlist(str_split(SD,'/'))
  
}

WD <- paste(SD[1:(length(SD)-2)],collapse='/')

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

outdir <- 'png/SonderAusw/Overview/' 
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2022\nQuellen: © Statistisches Bundesamt / WPP\nStand:", heute)


#
# Overview weekly excess mortality DEU
#

  # Retrieve data for MariaDB

  SQL <- paste('select * from MExM ;')
  data <- RunSQL( SQL )

  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate )
  data$Adj <- factor(data$Adjustiert, levels = 0:1, labels = c('Nicht adjustiert', 'Nach Alter und Geschlecht adjustiert') )
  
  data %>% filter ( Jahr >= 2005 )  %>% ggplot(
    
  ) +
    geom_line(aes( x = MonatToDate(Jahr,Monat), y = EM, group = Methode, colour = Methode ), alpha = 0.5 ) +
    geom_line(aes( x = MonatToDate(Jahr,Monat), y = EM, group = Methode, colour = Methode ), alpha = 0.5 ) +
    scale_y_continuous( labels = scales::percent ) +
    facet_wrap(vars(Adj)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland')
           , subtitle = 'Ergebnis der verschiedenen Methoden'
           , x = 'Monat'
           , y = 'Unter- / Übersterblichkeit [%]'
           , caption = citation ) -> POverview1

  xy <- data.table(
      x = (data %>% filter( Adjustiert == 1 & Methode == 'Mittelwert' ))$EM
    , y = (data %>% filter( Adjustiert == 0 & Methode == 'Mittelwert' ))$EM
      
  )
  
  print( 'Mittelwert: adjustiert, nicht adjustiert' )
  
  ra <- lm(data = xy , formula = y ~ x )
  print(summary(ra))
  
  xy %>% ggplot(
    aes( x = x, y = y )
  ) +
    geom_point ( alpha = 0.5 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( x = c(-0.25,0.5), y = c(-0.25,0.5)) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Methode Mittelwert der letzten vier Jahre'
           , x = 'Adjustiert[%]'
           , y = 'Nicht adjustiert [%]'
           , caption = citation ) -> PScatter1
  
  xy <- data.table(
    x = (data %>% filter( Adjustiert == 1 & Methode == 'Median' ))$EM
    , y = (data %>% filter( Adjustiert == 0 & Methode == 'Median' ))$EM
    
  )
  
  print( 'Median: Nicht adjustiert, adjustiert' )
  
  ra <- lm(data = xy , formula = y ~ x )
  print(summary(ra))
  
  xy %>% ggplot(
    aes( x = x, y = y )
  ) +
    geom_point ( alpha = 0.5 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( x = c(-0.25,0.5), y = c(-0.25,0.5)) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Methode Median der letzten vier Jahre'
           , x = 'Adjustiert[%]'
           , y = 'Nicht adjustiert [%]'
           , caption = citation ) -> PScatter2

  xy <- data.table(
      x = (data %>% filter( Adjustiert == 1 & Methode == 'Median' ))$EM
    , y = (data %>% filter( Adjustiert == 1 & Methode == 'Mittelwert' ))$EM
    
  )

  print( 'Adjustiert: Median, Mittelwert' )
  
  ra <- lm( data = xy , formula = y ~ x)
  
  print(summary(ra))
  
  xy %>% ggplot(
    aes( x = x, y = y )
  ) +
    geom_point ( alpha = 0.5 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( x = c(-0.25,0.5), y = c(-0.25,0.5)) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Adjustitierte Werte der letzten vier Jahre'
           , x = 'Median'
           , y = 'Mittelwert'
           , caption = citation ) -> PScatter3
 
  
  xy <- data.table(
    x = (data %>% filter( Adjustiert == 0 & Methode == 'Median' ))$EM
    , y = (data %>% filter( Adjustiert == 0 & Methode == 'Mittelwert' ))$EM
    
  )
  print( 'Nicht adjustiert: Median, Mittelwert' )
  
  ra <- lm( data = xy , formula = y ~ x)
  
  print(summary(ra))
  
  xy %>% ggplot(
    aes( x = x, y = y )
  ) +
    geom_point ( alpha = 0.5 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( x = c(-0.25,0.5), y = c(-0.25,0.5)) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Nicht adjustitierte Werte der letzten vier Jahre'
           , x = 'Median'
           , y = 'Mittelwert'
           , caption = citation ) -> PScatter4

  xy <- data.table(
    x = (data %>% filter( Adjustiert == 0 & Methode == 'Median' ))$EM
    , y = (data %>% filter( Adjustiert == 1 & Methode == 'Mittelwert' ))$EM
    
  )
  
  print( 'Nicht adjustiert: Median, adjustiert: Mittelwert' )
  
  ra <- lm( data = xy , formula = y ~ x)
  
  print(summary(ra))
  
  xy %>% ggplot(
    aes( x = x, y = y )
  ) +
    geom_point ( alpha = 0.5 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( x = c(-0.25,0.5), y = c(-0.25,0.5)) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Nicht adjustitierter Median / adjustierte Mittelwert der letzten vier Jahre'
           , x = 'Median nicht adjustiert'
           , y = 'Mittelwert adjustiert'
           , caption = citation ) -> PScatter5

  data %>% ggplot(  aes( x=Adj,  y = EM, fill = Methode),
  ) +
    geom_boxplot( ) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 0,  hjust = 0.5, vjust = 0.5 )
    ) +
    labs(  title = paste('Übersterblichkeit nach Monaten in Deutschland seit 2005')
           , subtitle = 'Vergleich der Methoden'
           , x = 'Adjustierung'
           , y = 'Unter-/Übersterblichkeit [%]'
           , caption = citation ) -> PBox1
  
#
#
#
  ggsave(paste( outdir, 'Overview_Monate_1.png', sep='')
         , plot = POverview1
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )

  ggsave(paste( outdir, 'Scatter_Month-1.png', sep='')
         , plot = PScatter1
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )

  ggsave(paste( outdir, 'Scatter_Month-2.png', sep='')
         , plot = PScatter2
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Scatter_Month-3.png', sep='')
         , plot = PScatter3
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Scatter_Month-4.png', sep='')
         , plot = PScatter4
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  
  ggsave(paste( outdir, 'Scatter_Month-5.png', sep='')
         , plot = PScatter5
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
  ggsave(paste( outdir, 'Box_Month-1.png', sep='')
         , plot = PBox1
         , device = "png"
         , bg = "white"
         , width = 1920, height = 1080
         , units = "px"
         , dpi = 144
  )
  
