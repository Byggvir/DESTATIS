#!/usr/bin/env Rscript
#
#
# Script: DT126130003.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130003"

require(data.table)
library(tidyverse)
library(grid)
library(gridExtra)
library(gtable)
library(lubridate)
library(ggplot2)
library(ggrepel)
library(viridis)
library(hrbrthemes)
library(scales)
library(ragg)
library(ggplottimeseries)
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

WD <- paste(SD[1:(length(SD)-2)],collapse='/')

setwd(WD)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

options( 
  digits = 10
  , scipen = 10
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0003/Scatterplots/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2021-2022\nQuelle: © Statistisches Bundesamt (12613-3, 12411-6 +WPP)\nStand:", heute)

CI <- 0.95

SQL <- 'select * from SterberateJahr;'

DT126130003 <- RunSQL( SQL )

DT126130003$Geschlecht <- factor(DT126130003$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126130003$Altersjahr <- factor(DT126130003$Alter)
DT126130003$Geburtsjahr <- DT126130003$Jahr - DT126130003$Alter
DT126130003$Jahrgang <- factor(DT126130003$Geburtsjahr)


GJ <- unique( DT126130003$Geburtsjahr)
CITab <- data.table(
  Jahrgang = c()
  , Geschlecht = c()
  , a = c()
  , b = c()
  , a_lower = c()
  , a_upper = c()
  , b_lower = c()
  , b_upper = c()
  , r2 =c()
  
)
  
Vergleiche_Jahrgang <- function( data, Jahrgang_1, Jahrgang_2) {
  
  for ( GE in c('Männer', 'Frauen') ){
    
    G1 <- min(Jahrgang_1,Jahrgang_2)
    G2 <- max(Jahrgang_1,Jahrgang_2)
    
    maxA <- min(2020 - G2, 99 )
    minA <- max(1991 - G1 ,1)
    
    xy <- data.table(
      Alter = ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Alter
      , x = ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Gestorbene 
      / ( data %>% filter( ( Geburtsjahr == G1 ) & Alter >= minA & Alter <= maxA  & Geschlecht == GE ))$Einwohner
      
      , y = (DT126130003 %>% filter( (Geburtsjahr == G2 ) & Alter >= minA & Alter <= maxA & Geschlecht == GE ))$Gestorbene
      / (DT126130003 %>% filter( (Geburtsjahr == G2 ) & Alter >= minA & Alter <= maxA & Geschlecht == GE ))$Einwohner
      
    )
    
    #
    # Regressionsanalyse
    #
    
    ra <- lm (data = xy , formula = 'y ~ x')
    ci <- confint(ra,level = CI)
    print(ci)
    
    #
    # Plot
    #
    
    xy %>% ggplot(
      aes( x = x, y = y ) 
    ) +
      geom_abline( intercept = 0
                   , slope = 1
                   , linewidth = 0.2
                   , linetype = 'dotted'
      ) +
      geom_smooth( method = 'glm' 
                  , formula = 'y ~ x'
                  , aes( colour = 'Smooth y~x' ), alpha = 0.2 ) +
      geom_point( aes( colour = 'Sterberate' ) ) +
      geom_text_repel( aes( label = Alter, colour = 'Alter' ), size = 3, max.overlaps = 100 ) +
      coord_fixed( expand = TRUE ) +
      scale_x_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
      theme_ipsum() +
      theme(
        axis.text.x = element_text( angle = 90, size = 8 )
      ) +
      labs(  title = paste( "Scatterplot", GE)
             , subtitle = paste( "Vergleich der Jahrgänge", G1 ,"und", G2, "\nf(x) = a + b * x mit"
                                 , "a =", round(ra$coefficients[1],4)
                                 , "; b =", round(ra$coefficients[2],4)
                                 , "\nCI 95 % a = ["
                                 , round(ci[1,1],4)
                                 , ";"
                                 , round(ci[1,2],4)
                                 , "]; b = ["
                                 , round(ci[2,1],4)
                                 , ";"
                                 , round(ci[2,2],4)
                                 , "]" ) 
             , x = paste( "Sterberate Jahrgang", G1 )
             , y = paste( "Sterberate Jahrgang", G2 )
             , colour = 'Legende'
             , caption = '' )  -> P
 
    ggsave(  paste(outdir, GE, '_', G1, '_', G2,'.png', sep = '' )
             , plot = P
             , device = "png"
             , bg = "white"
             , width = 1920
             , height = 1080
             , units = "px"
             , dpi = 144
    )
    
  }  
  
}
  

for ( G in 1940:1950) {

  print(G)
  
  for (i in 1:5) {
    Vergleiche_Jahrgang (DT126130003, G, G + i)
  }
}
