#!/usr/bin/env Rscript
#
#
# Script: SonderAuswMonat-ExcessMortality
#
# Stand: 2022-12-18
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SonderAuswMonat-ExcessMortality"

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
library(forecast)

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

outdir <- 'png/ExcessMortality/Month/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")


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

AbJahr <- 2013
SQL <- paste( 'select *, date(concat(Jahr,"-",Monat,"-",1)) as Datum from SterbefaelleMonat where Jahr >= ', AbJahr, ';' )
citation <- paste( "© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022\nSQL=", SQL,"\nStand:", heute)

Sterbefaelle <- RunSQL( SQL )
Sterbefaelle$Geschlecht <- factor(Sterbefaelle$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))

sJahr <- min(Sterbefaelle$Jahr)
sMonat <-min((Sterbefaelle$Monat[Sterbefaelle$Jahr == sJahr]))


Sterbefaelle$AG <- paste( " A",Sterbefaelle$AlterVon,"-A", Sterbefaelle$AlterBis, sep = '' )


Sterbefaelle %>% filter( Jahr >= AbJahr ) %>% ggplot(
  aes( x = Datum, y = Gestorbene)) +
  geom_line( aes( colour =  AG) ) +
  scale_x_date( date_labels = "%Y-%b", guide = guide_axis(angle = 90) ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  expand_limits(y = 0) +
  facet_wrap(vars(Geschlecht)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle nach Altersgruppe und Geschlecht")
         , subtitle= paste("Deutschland, Stand:", heute)
         , axis.text.x = element_text(angle = -90, hjust = 0)
         , colour  = "Geschlecht"
         , x = "Monat"
         , y = "Gestorbene"
         , caption = citation ) -> P1

ggsave(paste( outdir, 'SonderAuswM.png', sep='')
       , plot = P1
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

#
# Caculate excess mortality with a time series
#

EX <- list(
    Jahr = AbJahr
  , mean = 0
  , upper = 0
  , lower = 0
)

for ( G in c('Frauen', 'Männer') ) {
  
  for ( A in unique(Sterbefaelle$AG) ) {
    
    if ( exists("fcdata" ) ) { rm(fcdata) }
    if ( exists("PS" ) ){ rm(PS) }
    if ( exists("TS" ) ) { rm(TS) }
    
    fcdata <- data.table (
      Datum = (Sterbefaelle %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Datum
      , Jahr = (Sterbefaelle %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Jahr
      , Monat = (Sterbefaelle %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Monat
      , Gestorbene = as.numeric((Sterbefaelle %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Gestorbene)
      )
    
    # Create time series
    
    TS <- ts( fcdata$Gestorbene[fcdata$Jahr < 2020], start = c(sJahr,sMonat), frequency = 12 ) 
    
    # Forecast 
    
    FC <- forecast(TS, h=34)
    
    # Combine data and forecast
    
    fcdata$forecast <- c(FC$fitted,FC$mean) 
    fcdata$upper <- c(FC$x,FC$upper[,1]) 
    fcdata$lower <- c(FC$x,FC$lower[,1]) 
    
    EX$mean <- EX$mean + sum(fcdata$Gestorbene[fcdata$Jahr > 2019] - fcdata$forecast[fcdata$Jahr > 2019])
    EX$upper <- EX$upper + sum(fcdata$Gestorbene[fcdata$Jahr > 2019] - fcdata$lower[fcdata$Jahr > 2019])
    EX$lower <- EX$lower + sum(fcdata$Gestorbene[fcdata$Jahr > 2019] - fcdata$upper[fcdata$Jahr > 2019])
    
    fcdata %>% filter( Jahr >= 2016 ) %>% ggplot() +
      geom_line( aes( x = Datum, y = Gestorbene, colour = 'Gestorbene' ), linewidth = 2 ) +
      geom_line( aes( x = Datum, y = forecast, colour = 'Fitted / Forecast' ) , linewidth = 1.5 ) +
      geom_line( data = fcdata %>% filter ( Jahr > 2019 ),aes( x = Datum, y = upper, colour = 'Upper (80 %)' ) ) +
      geom_line( data = fcdata %>% filter ( Jahr > 2019 ),aes( x = Datum, y = lower, colour = 'Lower (80 %)' ) ) +
      geom_ribbon( data = fcdata %>% filter ( Jahr > 2019 ),aes( x = Datum, ymin=lower, ymax = upper), alpha = 0.2)  +
      scale_x_date( date_labels = "%Y-%b", guide = guide_axis(angle = 90) ) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      labs(  title = paste("Übersterblichkeit anhand Zeitreihe ab ", AbJahr)
             , subtitle= paste("Geschlecht", G, "/ Altersgruppe",A)
             , axis.text.x = element_text(angle = -90, hjust = 0)
             , x = "Jahr / Monat"
             , y = "Gestorbene"
             , colour = "Gestorbene"
             , caption = citation ) -> PS
    
    ggsave(  paste( outdir, 'EM_Monat_', AbJahr,'_',G,"_",A,'.png', sep='')
           , plot = PS
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
    )
  }
} 

print(EX)
