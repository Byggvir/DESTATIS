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

outdir <- 'png/DT12612/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12612-0002)\nStand:", heute)


SQL <- 'select Jahr, Geschlecht, sum(Anzahl) as Anzahl from DT126120002 group by Jahr, Geschlecht;'
DT126120002B <- RunSQL( SQL )


SQL <- 'select Jahr, Monat, DATE(CONCAT(Jahr,"-",Monat,"-",1)) as Datum, Geschlecht, Anzahl from DT126120002 order by Jahr, Monat, Geschlecht;'

DT126120002 <- RunSQL( SQL )

DT126120002$Geschlecht <- factor(DT126120002$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126120002$FMonat <- factor(DT126120002$Monat, levels = 1:12, labels = Monate)

for (J in c(2010)) {

  DT126120002B %>% filter( Jahr >= J & Jahr < 2022) %>% ggplot(
    aes( x = Jahr, y = Anzahl, colour = Geschlecht ) ) +
    geom_line() +
    # geom_bar(   aes( fill = Geschlecht )
    #           , stat= "identity"
    #           , position = position_stack()
    #           
    # ) +
    scale_x_continuous( breaks = DT126120002B$Jahr[DT126120002B$Jahr %% 2 == 1] ) +
    scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
    theme_ipsum() +
    labs(  title = paste("Lebendgeborene pro Jahr")
           , subtitle = paste(  "Zeitreihe ab " , J)
           , colour  = "Geschlecht"
           , x = "Jahr"
           , y = "Anzahl"
           , caption = citation )  -> P
  
  ggsave(  paste(outdir, '0002_', J, '.png', sep='')
           , plot = P
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
  )
  
  DT126120002 %>% filter( Jahr >= J ) %>% ggplot(
    aes( x = Jahr, y = Anzahl, colour = Geschlecht)) +
    geom_line() +
    # geom_bar( mapping = aes ( fill = Geschlecht )
    #         , stat= "identity"
    #         , position = position_stack() 
    #         ) +
    # # geom_smooth() + 
    facet_wrap(vars(FMonat)) +
    scale_x_continuous( breaks = DT126120002$Jahr[DT126120002$Jahr %% 2 == 1] ) +
    scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
    theme_ipsum() +
    theme ( 
      axis.text.x = element_text (angle = 90 ) 
      ) +
    labs(  title = paste("Lebendgeborene pro Monat")
           , subtitle = paste(  "Zeitreihe ab Januar" , J)
           , colour  = "Geschlecht"
           , x = "Jahr"
           , y = "Anzahl"
           , caption = citation )  -> P
  
  ggsave(  paste(outdir, '0002_', J, 'A.png', sep='')
           , plot = P
           , device = "png"
           , bg = "white"
           , width = 3840, height = 2160
           , units = "px"
  )

DT126120002 %>% filter( Jahr >= J ) %>% ggplot(
  aes( x = Datum, y = Anzahl, colour = Geschlecht)) +
  geom_line() +
  # geom_smooth() + 
  scale_x_date(date_labels = '%Y-%b') +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste("Lebendgeborene pro Monat")
         , subtitle = paste(  "Zeitreihe ab Januar" , J)
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl"
         , caption = citation )  -> P

ggsave(  paste(outdir, '0002_', J, 'B.png', sep='')
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 3840, height = 2160
         , units = "px"
)

}

