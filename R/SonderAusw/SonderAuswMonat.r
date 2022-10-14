#!/usr/bin/env Rscript
#
#
# Script: SonderAuswMonat.r
#
# Stand: 2020-10-21
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


diagramme <- function (data, method = 'DESTATIS', title = 'Rohdaten DESTATIS' ) {
  
  data$Geschlechter <- factor(data$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
  data$Monate <- factor(data$Monat, levels = 1:12, labels = Monate)
  data$AG <- factor( data$AlterVon
                       , levels = unique(data$AlterVon)
                       , labels = paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),'') 
                       )
  
  data%>% filter( Monat > 6 ) %>% ggplot(
    aes( x = AG, y = AbsExcessMortality, fill = Geschlechter )) +
    geom_bar(  stat="identity"
             , color="black"
             , position=position_dodge() 
             , alpha = 0.5) +
    #geom_label( aes(label = AbsExcessMortality ), size = 1 ) +
    facet_wrap(vars(Monate)) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
    ) +
    labs(  title = paste('Geschätzte Über- / Untersterblichkeit 2022 - Monate')
           , subtitle= paste('Methode', title, 'Median 2018 - 2021' )
           , x = 'Altersband'
           , y = 'Sterblichkeit Sterbefälle - Median'
           , caption = citation ) -> POverview
  
  ggsave(paste( outdir, 'SonderAusw_Monat_', method,'.png', sep='')
         , plot = POverview
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  Altersgruppen <- paste('A', unique(data$AlterVon), '-A', unique(data$AlterBis),sep ='')
  Alter <- unique(data$AlterVon)
  
  for (a in 1:length(Altersgruppen) ) {
    
    
    data %>% filter( AlterVon == Alter[a] ) %>% ggplot(
      aes( x = Monate, y = AbsExcessMortality, fill = Geschlechter )) +
      geom_bar(  stat="identity"
                 , color="black"
                 , position=position_dodge() 
                 , alpha = 0.5) +
      #geom_label( aes(label = AbsExcessMortality ), size = 1 ) +
      # facet_wrap(vars(Woche)) +
      scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, vjust = 0.5, hjust = 0.5 )
      ) +
      labs(  title = paste('Geschätzte Über- / Untersterblichkeit 2022 Altersband', Altersgruppen[a])
             , subtitle= paste('Methode', title ,'Median 2018 - 2021' )
             , x = 'Kalenderwoche 2022'
             , y = 'Sterblichkeit Sterbefälle - Median'
             , caption = citation ) -> POverview
    
    
    ggsave(paste( outdir, 'SonderAusw_Monat_', method,'_', Altersgruppen[a], '.png', sep='')
           , plot = POverview
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
    
    )
  }
}

SQL <- paste('select * from ExcessMortalityMonthDESTATIS ;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'DESTATIS', title = 'Rohdaten DESTATS')

SQL <- paste('select * from ExcessMortalityMonthNormalised ;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'Std', title = 'Sterbefälle 2018 -2021 auf 2022 umgerechnet')

SQL <- paste('select * from ExcessMortalityMonthWPP ;')
EM <- RunSQL( SQL )

diagramme(EM, method = 'WPP', title ='Sterbefälle 2018 -2021 nach WPP auf 2022 umgerechnet')
