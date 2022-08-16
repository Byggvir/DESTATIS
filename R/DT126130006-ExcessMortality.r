#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "MonatsSterblichkeit"

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

fPrefix <- "Fallzahlen_Wo_"

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

outdir <- 'png/DT/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-0006)\nStand:", heute)

for (BisJahr in 2013:2020) {

SQL <- paste('select Jahr, Monat, DATE(CONCAT(Jahr,"-",Monat,"-",1)) as Datum, Geschlecht, Gestorbene from DT126130006 where Jahr <= ', BisJahr + 1, ' order by Jahr, Monat, Geschlecht;')

DT126130006 <- RunSQL( SQL )

DT126130006$Geschlecht <- factor(DT126130006$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126130006$Monat <- factor(DT126130006$Monat, levels = 1:12, labels = Monate)

EX <- data.table(
  Jahr = seq(2000,BisJahr - 3,1)
  , mean = rep(0,BisJahr - 2 - 2000)
  , SD = rep(0,BisJahr - 2 - 2000)
)


mJahr = DT126130006$Jahr[nrow(DT126130006)]
mMonat = DT126130006$Monat[nrow(DT126130006)]

fcMonate <- nrow(DT126130006 %>% filter(Jahr > BisJahr & Geschlecht == 'Frauen'))

for (AbJahr in EX$Jahr ) {
  
  i = AbJahr - 2000 + 1
  
  for ( G in c('Frauen', 'Männer') ) {
  
    rm(fcdata)
    rm(PS)
    rm(TS)
    
    sJahr <- AbJahr
    sMonat <-1
    
    fcdata <- data.table (
      Datum = (DT126130006 %>% filter(Geschlecht == G & Jahr >= AbJahr ))$Datum
      , Jahr = (DT126130006 %>% filter(Geschlecht == G & Jahr >= AbJahr ))$Jahr
      , Monat = (DT126130006 %>% filter(Geschlecht == G & Jahr >= AbJahr ))$Monat
      , Gestorbene = as.numeric((DT126130006 %>% filter(Geschlecht == G & Jahr >= AbJahr ))$Gestorbene)
    )
    
    TS = ts((DT126130006 %>% filter(Jahr >= AbJahr & Jahr <= BisJahr & Geschlecht== G) )$Gestorbene, start=c(AbJahr,1), frequency = 12)

    TS_data <- dts2(TS)

    FC <- forecast(TS, h = fcMonate)
    
    fcdata$forecast <- c(FC$fitted,FC$mean) 
    fcdata$upper <- c(FC$x,FC$upper[,1]) 
    fcdata$lower <- c(FC$x,FC$lower[,1]) 
    
    EX$mean[i] <- EX$mean[i] + sum(fcdata$Gestorbene[fcdata$Jahr > BisJahr] - fcdata$forecast[fcdata$Jahr > BisJahr])
    EX$SD[i] <- sqrt(EX$SD[i]^2 + sum(((FC$upper[,2]-FC$mean)/2)^2) )
    
    fcdata %>% filter( Jahr >= BisJahr - 4 ) %>% ggplot() +
      geom_line( aes( x = Datum, y = Gestorbene, colour = 'Gestorbene'), size = 2 ) +
      geom_line( aes( x = Datum, y = forecast, colour = 'Forecast fitted' ) , size = 1 ) +
      geom_line( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, y = upper, colour = 'Forecast Upper (80 %)' ), linetype = 'dotted' ) +
      geom_line( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, y = lower, colour = 'Forecast Lower (80 %)' ), linetype = 'dotted' ) +
      geom_ribbon( data = fcdata %>% filter ( Jahr > BisJahr ),aes( x = Datum, ymin=lower, ymax = upper), alpha = 0.2)  +
      scale_x_date( date_labels = "%Y-%b", guide = guide_axis(angle = 90) ) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      labs(  title = paste( 'Sterbefälle / geschätzte Sterbefälle', G, 'Januar /', BisJahr + 1, 'bis', mMonat,'/', mJahr )
           , subtitle = paste( 'Zeitreihe von' , AbJahr, 'bis', BisJahr)
           , colour  = 'Legende'
           , x = "Monat"
           , y = "Gestorbene"
           , caption = citation )  -> PS
  
    ggsave(  paste(outdir, 'DT126130006_', mJahr, ' ', AbJahr, '_', BisJahr , '_', G,'_EM.png', sep='')
             , plot = PS
             , device = "png"
             , bg = "white"
             , width = 3840, height = 2160
             , units = "px"
    )

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
         , subtitle= paste(  'Geschlechtsstratifizierte Schätzungen anhand monatlicher Sterbefälle\nZeitreihe jeweils von Jahr n bis ', BisJahr
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
