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

WD <- paste(SD[1:(length(SD)-1)],collapse='/')

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

outdir <- 'png/' 
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2022\nQuellen: WPP\nStand:", heute)

  SQL <- paste('select `Time` as Jahr, AgeGrp div 5 * 5 as AG, sum(PopTotal) as Einwohner from WPP.population where LocId = 908 and AgeGrp < 15 and `Time` > 2015 group by `Time`, AG;')
  data <- RunSQL( SQL )
  
  A <- unique(data$AG)
  
  data$Altersgruppe <- factor(data$AG, levels = A, labels = paste0('A',A,'-A',A+4))
  
  data$Jahre <- factor(data$Jahr, levels = unique(data$Jahr), labels = unique(data$Jahr))
  data %>%  ggplot(
    aes( x = Jahre , y = Einwohner, group = Altersgruppe , colour = Altersgruppe, fill = Altersgruppe ) 
    ) +
    geom_bar( stat = 'identity', position = position_dodge(), width = 0.9 ) +
    scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90,  hjust = 1, vjust = 0.5 )
    ) +
    labs(  title = paste('Population Europe')
           , subtitle = 'Agegroup < 15 yo'
           , x = 'AgeGroup'
           , y = 'Population'
           , caption = citation ) -> POverview1
  
  ggsave(paste( outdir, 'WPP_AG_Europe.png', sep='')
         , plot = POverview1
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
  )
  
