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

outdir <- 'png/SonderAusw/Monat/' 
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt / WPP\nStand:", heute)

ForYear = 2022

vergleich <- function (data, method = 'DESTATIS', title = 'Rohdaten DESTATIS' ) {
  
  data$Geschlechter <- factor(data$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate)
  data$AG <- factor( data$AlterVon
                     , levels = unique(data$AlterVon)
                     , labels = paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),'') 
  )
  
  data %>% filter( Jahr > 2004 ) %>% ggplot() +
    geom_point( aes (x = Mittelwert, y = Gestorbene, colour = AG, group = AG ), alpha = 0.1 ) +
    coord_equal() + 
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    facet_wrap( vars(Geschlechter)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
    ) +
    labs(  title = paste('Vergleich Mittelwert - Gestorbene' )
           , subtitle = paste( 'Monate -', title )
           , x = 'Mittelwert'
           , y = 'Gestorbene'
           , caption = citation
    ) -> PVergleich1
  
  
  data %>% filter( Jahr > 2004 ) %>% ggplot() +
    geom_point( aes (x = Median, y = Gestorbene, colour = AG, group = AG ), alpha = 0.1 ) +
    coord_equal() + 
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    facet_wrap( vars(Geschlechter)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
    ) +
    labs(  title = paste('Vergleich Median - Gestorbene' )
           , subtitle = paste( 'Monate -', title )
           , x = 'Mittelwert'
           , y = 'Median'
           , caption = citation
    ) -> PVergleich2

  data %>% filter( Jahr > 2004 ) %>% ggplot() +
    geom_point( aes (x = Mittelwert, y = Median, colour = AG, group = AG ), alpha = 0.1 ) +
    coord_equal() + 
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    facet_wrap( vars(Geschlechter)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
    ) +
    labs(  title = paste('Vergleich Mittelwert - Median' )
           , subtitle = paste( 'Monate -', title )
           , x = 'Mittelwert'
           , y = 'Median'
           , caption = citation
    ) -> PVergleich3
  
#  PV <- grid.arrange(PVergleich1, PVergleich2, ncol = 2, top = textGrob(title ,gp=gpar(fontsize=18, font=3)))
  
  ggsave(paste( outdir, 'Vergleich_', method,'-1.png', sep='')
         , plot = PVergleich1
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )

  ggsave(paste( outdir, 'V_', method,'-2.png', sep='')
         , plot = PVergleich2
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
    
  ggsave(paste( outdir, 'V_', method,'-3.png', sep='')
         , plot = PVergleich3
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
    )
    
}

diagramme <- function (data, method = 'DESTATIS', title = 'Rohdaten DESTATIS' ) {
  
  data$Geschlechter <- factor(data$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate)
  data$AG <- factor( data$AlterVon
                       , levels = unique(data$AlterVon)
                       , labels = paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),'') 
                       )
  
  data%>% filter( Monat > 7 & Jahr == ForYear ) %>% ggplot(
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
  
  ggsave(paste( outdir, 'M', ForYear, '_', method,'.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
  Altersgruppen <- paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),sep ='')
  Alter <- unique(data$AlterVon)
  
  for (a in 1:length(Altersgruppen) ) {
    
    data %>% filter( AlterVon == Alter[a] & Jahr > 2016 ) %>% ggplot(
      aes( x = Monate, y = Median - Mittelwert, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5
                 , width = 0.8 ) +
      # facet_wrap(vars(Woche)) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      facet_wrap( vars(Jahr)) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
      ) +
      labs(  title = paste('Altersband', Altersgruppen[a], '- absolut')
             , subtitle= paste('Vergleich Median - Mittelwert:', title )
             , x = 'Kalenderwoche'
             , y = 'Median -  Mittelwert'
             , caption = citation
      ) -> PMedianMittelwert

    ggsave(paste( outdir, 'R',ForYear, '_', method,'_', Altersgruppen[a], '.png', sep='')
           , plot = PMedianMittelwert
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"

    )
      
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
    
    
    ggsave(paste( outdir, 'M',ForYear, '_', method,'_', Altersgruppen[a], '.png', sep='')
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

vergleich(EM, method = 'DESTATIS', title = 'Absolute Sterbefälle der vier Vorjahre')
diagramme(EM, method = 'DESTATIS', title = 'Median der absoluten Sterbefälle der vier Vorjahre')

SQL <- paste('select * from ExcessMortalityMonthNormalised ;')
EM <- RunSQL( SQL )

vergleich(EM, method = 'Std', title = paste('Normierte Sterbefällen der vier Vorjahre DESTATIS' ) )
diagramme(EM, method = 'Std', title = paste('Median der auf',ForYear,'normierten Sterbefällen der vier Vorjahre DESTATIS' ) )

SQL <- paste('select * from ExcessMortalityMonthWPP ;')
EM <- RunSQL( SQL )

vergleich(EM, method = 'WPP', title = paste('Normierte Sterbefällen der vier Vorjahre WPP' ))
diagramme(EM, method = 'WPP', title = paste('Median der auf',ForYear,'normierten Sterbefällen der vier Vorjahre WPP' ))
