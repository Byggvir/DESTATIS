#!/usr/bin/env Rscript
#
#
# Script: DT126130006_EstDeathsYear.r
#
# Deaths per year in Germany by age and sex 
#
# Quellen:
#   DT12613-0003
#   DT12411-0006
#   World Population Prospect 2022
#
# Stand: 2022-12-15
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130006_EstDeathsYear"

require(data.table)
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
# library(ggplottimeseries)
# library(forecast)

#
# Set Working directory to git root
#

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

#
# End of set working directory
#

# Load own routines

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0003/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-3, 12411-6 +WPP)\nStand:", heute)

#
# Compare methods
#

compare_methods <- function(   data, 
                               Adjustiert1 = 'adjustierter'
                               , Adjustiert2 = 'adjustierter'
                               , Methode1 = 'Median'
                               , Methode2 = 'Mittelwert'
) {
  
  print (c(Adjustiert1, Methode1, Adjustiert2, Methode2))
  
  xy <- data.table(
    Alter = ( data %>% filter( Adjustiert == Adjustiert1 & Methode == Methode1 ))$Alter
    , Geschlecht = ( data %>% filter( Adjustiert == Adjustiert1 & Methode == Methode1 ))$Geschlecht
    , x = ( data %>% filter( Adjustiert == Adjustiert1 & Methode == Methode1 ))$Erwartet
    
    , y = (data %>% filter( Adjustiert == Adjustiert2 & Methode == Methode2 ))$Erwartet
    
    , z = (data %>% filter( Adjustiert == Adjustiert1 & Methode == Methode1 ))$Gestorbene
  )
  
  xy2 <- data.table(
    Alter = xy$Alter
    , Geschlecht = xy$Geschlecht
    , x = (xy$z - xy$x)/xy$x
    , y = (xy$z - xy$y)/xy$y
    
  )
  
  for ( G in c('Männer', 'Frauen')) {
    
    print(G)
    
    ra <- lm ( data = xy2 %>% filter(Geschlecht == G & Alter > 49) , formula = y ~ x )
    print(ra$coefficients)
    print(summary(ra)$r.squared)
    
    # print ('Alter')
    # 
    # ra <- lm ( data = xy2 %>% filter(Geschlecht == G ) , formula = x ~ Alter )
    # print(ra$coefficients)
    # print(summary(ra)$r.squared)
    # 
    # ra <- lm ( data = xy2 %>% filter(Geschlecht == G ) , formula = y ~ Alter )
    # print(ra$coefficients)
    # print(summary(ra)$r.squared)
    
  }
  
  
  xy %>% filter( Alter > 69) %>% ggplot(
    aes( x = (z - x)/x , y = (z - y) / y )
  ) +
    # stat_ellipse( type = "t", geom = "polygon", alpha = 0.8 ) +
    geom_point( alpha = 0.1 ) +
    geom_smooth( method = 'lm' ) +
    expand_limits( y = 0 ) +
    scale_x_continuous( labels = scales::percent ) +
    scale_y_continuous( labels = scales::percent ) +
    coord_equal() +
    facet_wrap(vars(Geschlecht)) +
    theme_ipsum() +
    theme(
      axis.text.x = element_text( angle = 90, size = 12 )
    ) +
    labs(  title = paste("Korrelation Übersterblichkeit ")
           , subtitle = paste( 'seit  1991, alle Altersjahre - ', Adjustiert1, Methode1, 'mit', Adjustiert2, Methode2 )
           , colour  = 'Alter'
           , x = paste( 'Übersterblichkeit nach', Adjustiert1, Methode1,'[%]' )
           , y = paste( 'Übersterblichkeit nach', Adjustiert2, Methode2,'[%]' )
           , caption = citation )  -> P
  
  ggsave(  paste( outdir
                  , 'ExcessMortJahr_'
                  , Adjustiert1
                  , '_'
                  , Methode1
                  , '_'
                  , Adjustiert2
                  , '_'
                  , Methode2
                  , '.png', sep='')
           , plot = P
           , device = "png"
           , bg = "white"
           , width = 1920
           , height = 1080
           , units = "px"
           , dpi = 144
  )
  
}

#
# End of function
#

SQL <- 'select * from EDY;'

data <- RunSQL( SQL )

data$Geschlecht <- factor( data$Geschlecht, levels = c( 'F','M'), labels = c('Frauen','Männer'))
data$Adjustiert <- factor( data$Adjustiert, levels = 0:1, labels = c('absoluter', 'adjustierter'))
data$Altersjahr <- factor( data$Alter )

data %>% filter( Alter >= 50 ) %>% ggplot(
  aes( x = Altersjahr, y = ( Gestorbene - Erwartet ) / Erwartet,  fill = Geschlecht )) +
  geom_boxplot(  ) +
  facet_wrap( vars( Adjustiert, Methode ) ) +
  expand_limits( y = 0 ) +
  scale_x_discrete( )  +
  scale_y_continuous( labels = scales::percent ) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 12 )
  ) +
  labs(  title = paste("Verteilung der Übersterblichkeit anhand der Sterberaten")
         , subtitle = paste( "seit  1991" )
         , colour  = "Geschlecht"
         , x = "Altersjahr"
         , y = "Über-/Untersterblichkeit [%]"
         , caption = citation )  -> P

ggsave(  paste(outdir, 'ExcessMortJahr.png', sep='')
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 72
)

data %>% filter( Alter >= 50 ) %>% ggplot(
  aes( x = Alter, y = ( Gestorbene - Erwartet ) / Erwartet,  colour = Geschlecht )) +
  geom_point(  ) +
  geom_smooth( method = 'lm' ) +
  facet_wrap( vars( Adjustiert, Methode ) ) +
  expand_limits( y = 0 ) +
  scale_x_continuous( labels = scales::percent ) +
  scale_y_continuous( labels = scales::percent ) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 12 )
  ) +
  labs(  title = paste("Verteilung der Übersterblichkeit anhand der Sterberaten")
         , subtitle = paste( "seit  1991" )
         , colour  = "Geschlecht"
         , x = "Altersjahr"
         , y = "Über-/Untersterblichkeit [%]"
         , caption = citation )  -> P

ggsave(  paste(outdir, 'ExcessMortJahr-2.png', sep='')
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 72
)

compare_methods (  data = data
                 , Adjustiert1 = 'absoluter'
                 , Adjustiert2 = 'absoluter'
                 , Methode1 = 'Median'
                 , Methode2 = 'Mittelwert'
)
compare_methods (  data = data
                   , Adjustiert1 = 'adjustierter'
                   , Adjustiert2 = 'adjustierter'
                   , Methode1 = 'Median'
                   , Methode2 = 'Mittelwert'
)

compare_methods (  data = data
                   , Adjustiert1 = 'absoluter'
                   , Adjustiert2 = 'adjustierter'
                   , Methode1 = 'Median'
                   , Methode2 = 'Mittelwert'
)

compare_methods (  data = data
                   , Adjustiert1 = 'absoluter'
                   , Adjustiert2 = 'adjustierter'
                   , Methode1 = 'Median'
                   , Methode2 = 'Median'
)
