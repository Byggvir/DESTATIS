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

citation <- paste("© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt /WPP\nStand:", heute)

ForYear = 2022

diagramme <- function (data, method = 'DESTATIS', title = 'Rohdaten DESTATIS' ) {
  
  data$Geschlechter <- factor(data$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  data$Woche <- factor(data$Kw, levels = 1:53, labels = 1:53 )
  data$AG <- factor( data$AlterVon
                       , levels = unique(data$AlterVon)
                       , labels = paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),sep ='') 
                       )
  mKw <- max((data %>% filter (Jahr == ForYear))$Kw)
  
  data %>% filter( Kw == mKw & Jahr == ForYear ) %>% ggplot(
    aes( x = AG, y = AbsExcessMortality, fill = Geschlechter )) +
    geom_bar(  stat="identity"
             , color="black"
             , position=position_dodge() 
             , alpha = 0.5
             , width = 0.8 ) +
#    facet_wrap(vars(Woche)) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, size = 6, hjust = 0.5, vjust = 0.5 )
    ) +
    labs(  title = paste('Absolut')
           , subtitle= paste('Methode', title )
           , x = 'Altersband'
           , y = 'Sterblichkeit Sterbefälle - Median'
           , caption = citation ) -> POverview1
  
  data %>% filter( Kw == mKw & Jahr == ForYear ) %>% ggplot(
    aes( x = AG, y = RelExcessMortality, fill = Geschlechter )) +
    geom_bar(  stat="identity"
               , color="black"
               , position=position_dodge() 
               , alpha = 0.5
               , width = 0.8 ) +
 #   facet_wrap(vars(Woche)) +
    scale_y_continuous( labels = scales::percent ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, size = 6, hjust = 0.5, vjust = 0.5 )
    ) +
    labs(  title = paste('Relativ')
           , subtitle= paste('Methode', title )
           , x = 'Altersband'
           , y = 'Sterblichkeit Sterbefälle - Median'
           , caption = citation ) -> POverview2
  
  
  POverview <- POverview1 + POverview2 + plot_annotation( title = paste("Geschätzte Über- / Untersterblichkeit", ForYear, "- Kalenderwoche", mKw )) 
  
  ggsave(  filename = paste( outdir, 'SonderAusw_W', ForYear, '_', method,'.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  Altersgruppen <- paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),sep ='')
  Alter <- unique(data$AlterVon)
  
  for (a in 1:length(Altersgruppen) ) {
    
    data %>% filter( AlterVon == Alter[a] & Jahr == ForYear) %>% ggplot(
      aes( x = Woche, y = AbsExcessMortality, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5
                 , width = 0.8 ) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, size = 6, hjust = 0.5, vjust = 0.5 )
      ) +
      labs(  title = paste('Altersband', Altersgruppen[a], '- absolut' )
             , subtitle= paste( 'Methode', title )
             , x = 'Kalenderwoche'
             , y = 'Sterblichkeit Sterbefälle - Median'
             , caption = citation ) -> POverview1

    
    data %>% filter( AlterVon == Alter[a] & Jahr == ForYear) %>% ggplot(
      aes( x = Woche, y = RelExcessMortality, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5
                 , width = 0.8 ) +
      scale_y_continuous( labels = scales::percent ) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, size = 6 , hjust = 0.5, vjust = 0.5 )
      ) +
      labs(  title = paste('Altersband', Altersgruppen[a], '- relativ' )
             , subtitle= paste('Methode', title )
             , x = 'Kalenderwoche'
             , y = 'Sterblichkeit Sterbefälle - Median'
             , caption = citation ) -> POverview2
    
    POverview <- POverview1 + POverview2 + plot_annotation( title = paste("Geschätzte Über- / Untersterblichkeit", ForYear)) 
    ggsave(paste( outdir, 'SonderAusw_W', ForYear, '_', method, '_', Altersgruppen[a], '.png', sep='')
           , plot = POverview
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
    )
  }
}

SQL <- paste('select * from ExcessMortalityWeekDESTATIS ;')
data <- RunSQL( SQL )

diagramme(data, method = 'DESTATIS', title = 'Rohdaten DESTATS')

SQL <- paste('select * from ExcessMortalityWeekNormalised ;')
data <- RunSQL( SQL )

diagramme(data, method = 'Std', title = paste('Sterbefälle der vier Vorjahre nach DESTATIS auf',ForYear,'umgerechnet'))

SQL <- paste('select * from ExcessMortalityWeekWPP ;')
data <- RunSQL( SQL )

diagramme(data, method = 'WPP', title = paste('Sterbefälle der vier Vorjahre nach WPP auf',ForYear,'umgerechnet'))
