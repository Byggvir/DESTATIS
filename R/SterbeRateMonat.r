#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SterbeRateMonat-ExcessMortatlity"

library(tidyverse)
library(REST)
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

outdir <- 'png/ExcessMortality/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")


require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

citation <- "© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022, Sonderauswertung"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

for (BisJahr in 2019:2019) {
  
# SQL <- paste( 'select *, concat("A",AlterVon,"-",AlterBis) as AG from SterbefaelleMonatBev where Jahr <= ', BisJahr + 1, ' ;')
SQL <- paste( 'select *, concat("A",AlterVon,"-",AlterBis) as AG from SterbefaelleMonatBev ;')

SterbeRate <- RunSQL( SQL )

SterbeRate$Geschlecht <- factor(SterbeRate$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))

#
# Excess mortality bestimmen
#

EX <- data.table(
  Jahr = seq(2000,BisJahr - 3,1)
  , mean = rep(0,BisJahr - 2 - 2000)
  , SD = rep(0,BisJahr - 2 - 2000)
)


mJahr = SterbeRate$Jahr[nrow(SterbeRate)]
mMonat = SterbeRate$Monat[nrow(SterbeRate)]

fcMonate <- nrow(SterbeRate %>% filter(Jahr > BisJahr & Geschlecht == 'Frauen' & AlterVon == 0))

for (AbJahr in EX$Jahr ) {
  
  i = AbJahr - 2000 + 1
  
for ( G in c('Frauen', 'Männer') ) {
  
  for ( A in unique(SterbeRate$AG) ) {
    
    rm(fcdata)
    rm(PS)
    rm(TS)
    
    sJahr <- AbJahr
    sMonat <-1
    
    fcdata <- data.table (
      Datum = (SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Datum
      , Jahr = (SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Jahr
      , Monat = (SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Monat
      , Gestorbene = as.numeric((SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Gestorbene)
      , Einwohner  = as.numeric((SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Einwohner)
      , Rate = as.numeric((SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Gestorbene
                          / (SterbeRate %>% filter(Geschlecht == G & AG == A & Jahr >= AbJahr ))$Einwohner)
    )
    
    # Create time series
    
    TS <- ts( fcdata$Rate[fcdata$Jahr <= BisJahr], start = c(sJahr,sMonat), frequency = 12 ) 
    
    # Forecast 
    
    FC <- forecast(TS, h = fcMonate)
    
    # Combine data and forecast
    
    fcdata$forecast <- c(FC$fitted,FC$mean) 
    fcdata$upper <- c(FC$x,FC$upper[,1]) 
    fcdata$lower <- c(FC$x,FC$lower[,1]) 
    
    EX$mean[i] <- EX$mean[i] + sum(fcdata$Gestorbene[fcdata$Jahr > BisJahr] - fcdata$forecast[fcdata$Jahr > BisJahr]*fcdata$Einwohner[fcdata$Jahr > BisJahr])
    EX$SD[i] <- sqrt(EX$SD[i]^2 + sum( ( (FC$upper[,2]-FC$mean) / 2 * fcdata$Einwohner[fcdata$Jahr > BisJahr] )^2 ) )
    
    fcdata %>% filter( Jahr >= BisJahr - 4 ) %>% ggplot() +
      geom_line( aes( x = Datum, y = Gestorbene, colour = 'Gestorbene'), size = 2 ) +
      geom_line( aes( x = Datum, y = forecast * Einwohner, colour = 'Forecast fitted' ) , size = 1 ) +
      geom_line( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, y = upper * Einwohner, colour = 'Forecast Upper (80 %)' ), linetype = 'dotted' ) +
      geom_line( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, y = lower * Einwohner, colour = 'Forecast Lower (80 %)' ), linetype = 'dotted' ) +
      geom_ribbon( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, ymin=lower * Einwohner, ymax = upper * Einwohner), alpha = 0.2)  +
      scale_x_date( date_labels = "%Y-%b", guide = guide_axis(angle = 90) ) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      labs(  title = paste( 'Sterbefälle / geschätzte Sterbefälle', G, 'Alter', A, 'Januar /', BisJahr + 1, 'bis', mMonat,'/', mJahr )
             , subtitle = paste( 'Zeitreihe von' , AbJahr, 'bis', BisJahr)
             , axis.text.x = element_text(angle = -90, hjust = 0)
             , x = "Jahr / Monat"
             , y = "Gestorbene"
             , colour = ""
             , caption = citation ) -> PS
    
    ggsave(  paste(outdir, 'EM_', mJahr, ' ', AbJahr, '_', BisJahr , '_', G,'_',A,'.png', sep='')
             , plot = PS
             , device = "png"
             , bg = "white"
             , width = 3840, height = 2160
             , units = "px"
    )
  }
} 

}

EX %>% ggplot(
  aes( x = Jahr, y = mean )) +
  geom_bar(  stat="identity"
             , color="black"
             , position=position_dodge() ) +
  geom_hline(aes(yintercept = median(mean)), color = 'red') +
  geom_label( aes(label = round(mean)), size = 2 ) +
  scale_x_continuous(breaks = seq(2000,BisJahr - 3) ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste('Geschätzte Übersterblichkeit Januar /', BisJahr + 1, 'bis', mMonat,'/', mJahr)
         , subtitle= paste(  'Geschlechts- und altersstratifizierte Schätzungen anhand monatlicher Sterbefälle\nZeitreihe jeweils von Jahr n bis ', BisJahr
         )
         , x = 'Jahr'
         , y = 'Übersterblichkeit'
         , caption = citation ) -> POverview

ggsave(paste( outdir, 'EX_Overview_', BisJahr, '_' , mJahr, '.png', sep='')
       , plot = POverview
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

print(EX)

}
