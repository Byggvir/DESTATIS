#!/usr/bin/env Rscript
#
#
# Script: SonderAuswMonat.r
#
# Stand: 2022-10-18
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SonderAuswMonat"

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
library(patchwork)
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

citation <- paste("© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt / WPP\nStand:", heute)

ForYear = 2022

diagramme <- function (data, method = 'DESTATIS', title = 'Rohdaten DESTATIS' ) {
  
  data$Geschlechter <- factor(data$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate)
  data$AG <- factor( data$AlterVon
                       , levels = unique(data$AlterVon)
                       , labels = paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),'') 
                       )
  
  data%>% filter( Monat > 6 & Jahr == ForYear ) %>% ggplot(
    aes( x = AG, y = RelExcessMortality, fill = Geschlechter )) +
    geom_bar(  stat="identity"
             , color="black"
             , position=position_dodge() 
             , alpha = 0.5 
             , width = 0.8 ) +
    #geom_label( aes(label = AbsExcessMortality ), size = 1 ) +
    facet_wrap(vars(Monate)) +
    scale_y_continuous( labels = scales::percent ) +
    # scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
    ) +
    labs(  title = paste('Geschätzte Über- / Untersterblichkeit', ForYear,'- Monate')
           , subtitle= paste('Methode', title )
           , x = 'Altersband'
           , y = 'Sterblichkeit Sterbefälle - Median'
           , caption = citation ) -> POverview
  
  ggsave(paste( outdir, 'SonderAusw_M',ForYear,'_', method,'.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  Altersgruppen <- paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),sep ='')
  Alter <- unique(data$AlterVon)
  
  for (a in 1:length(Altersgruppen) ) {
    
    
    data %>% filter( AlterVon == Alter[a] & Jahr == ForYear ) %>% ggplot(
      aes( x = Monate, y = AbsExcessMortality, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5
                 , width = 0.8 ) +
      #geom_label( aes(label = AbsExcessMortality ), size = 1 ) +
      # facet_wrap(vars(Woche)) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
      ) +
      labs(  title = paste('Altersband', Altersgruppen[a], '- absolut')
             , subtitle= paste('Methode', title )
             , x = 'Kalenderwoche'
             , y = 'Sterblichkeit Sterbefälle - Median'
             , caption = citation ) -> POverview1
    
    data %>% filter( AlterVon == Alter[a] & Jahr == ForYear ) %>% ggplot(
      aes( x = Monate, y = RelExcessMortality, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5
                 , width = 0.8 ) +
      #geom_label( aes(label = RelExcessMortality ), size = 1 ) +
      # facet_wrap(vars(Woche)) +
      scale_y_continuous( labels = scales::percent ) +
      # scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
      ) +
      labs(  title = paste('Altersband', Altersgruppen[a], '- relativ')
             , subtitle= paste('Methode', title )
             , x = 'Kalenderwoche'
             , y = 'Sterblichkeit Sterbefälle - Median'
             , caption = citation ) -> POverview2
    
    POverview <- POverview1 + POverview2 + plot_annotation( title = paste("Geschätzte Über- / Untersterblichkeit", ForYear) )
    
    
    ggsave(paste( outdir, 'SonderAusw_M',ForYear, '_', method,'_', Altersgruppen[a], '.png', sep='')
           , plot = POverview
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
    
    )
  }
}

SQL <- paste('select * from ExcessMortalityMonthDESTATIS;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'DESTATIS', title = 'Median der absoluten Sterbefälle der vier Vorjahre')

SQL <- paste('select * from ExcessMortalityMonthNormalised ;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'Std', title = paste('Median der auf',ForYear,'normierten Sterbefällen der vier Vorjahre DESTATIS' ) )

SQL <- paste('select * from ExcessMortalityMonthWPP ;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'WPP', title = paste('Median der auf',ForYear,'normierten Sterbefällen der vier Vorjahre WPP' ))
