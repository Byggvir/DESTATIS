#!/usr/bin/env Rscript
#
#
# Script: DT126130003_Korr.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "DT126130003_Korr"

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
  digits = 10
  , scipen = 10
  , Outdec = "."
  , max.print = 3000
)

outdir <- 'png/DT12613/0003/Korrelation/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste("© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (12613-3, 12411-6 +WPP)\nStand:", heute)

CI <- 0.95

SQL <- 'select * from DeathRateYear;'

DT126130003 <- RunSQL( SQL )

DT126130003$Geschlecht <- factor(DT126130003$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))
DT126130003$Altersjahr <- factor(DT126130003$Alter)
DT126130003$Geburtsjahr <- DT126130003$Jahr - DT126130003$Alter
DT126130003$Jahrgang <- factor(DT126130003$Geburtsjahr)

CITab <- read.csv(file= paste( outdir, "Regressionsanalyse.csv", sep = '' ))

CITab$Folgejahr <- CITab$Folgejahrgang - CITab$Jahrgang
CITab$Folgejahr <- factor( CITab$Folgejahr, labels = paste0("+", unique(CITab$Folgejahr), ' Jahre später') )

CITab %>% ggplot(
  aes( x = Jahrgang, y = a, colour = Folgejahr ) 
) +
  geom_ribbon( aes( ymin = a_lower
                    , ymax = a_upper
                    , fill = 'CI 95 %'
  )
  , linetype = 'dotted'
  , linewidth = 0.1
  , alpha = 0.1
  ) +
  geom_line( ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  guides( fill = guide_legend( title="Legende" ) ) +
  facet_wrap( vars( Geschlecht )) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 8 )
  ) +
  labs(  title = paste( "Intercept a der Korrelation der Jahressterberate\nGeburtsjahrgang j und (j + n)" )
         , subtitle = paste( "s(Alter,j+n) = a(j) + b(j) * s(Alter,j)" )
         , x = paste( "Jahrgang" )
         , y = paste( "Intercept a" )
         , caption = citation )  -> P


ggsave(  paste(outdir, 'Jahrgang_Kor_a.png', sep = '' )
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

CITab %>% filter( ( ( Folgejahrgang == Jahrgang + 1 ) | ( Folgejahrgang == Jahrgang + 4) ) & Jahrgang < 1995  ) %>% ggplot(
  aes( x = Jahrgang, y = b, colour = Folgejahr ) 
) +
  geom_ribbon( aes( ymin = b_lower
                    , ymax = b_upper
                    , fill = 'CI 95%'
  )
  , linetype = 'dotted'
  , linewidth = 0.1
  , alpha = 0.1
  ) +
  geom_line( ) +
  scale_x_continuous( labels = function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  guides( fill = guide_legend( title="Legende" ) ) +
  facet_wrap( vars(Geschlecht)) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 8 )
  ) +
  labs(  title = paste( "Steigung b der Korrelation der Jahressterberate\nGeburtsjahrgang j und (j + n)" )
         , subtitle = paste( "s(Alter,j+n) = a(j) + b(j) * s(Alter,j)" )
         , x = paste( "Jahrgang" )
         , y = paste( "Slope b" )
         , caption = citation )  -> P

ggsave(  paste(outdir, 'Jahrgang_Kor_b.png', sep = '' )
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

CITab %>% filter( ( ( Folgejahrgang == Jahrgang + 1 ) | ( Folgejahrgang == Jahrgang + 4) ) & Jahrgang < 1995 ) %>% ggplot(
  aes( x = Jahrgang, y = r2, colour = Folgejahr ) 
) +
  geom_line( ) +
  scale_x_continuous( labels = function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE ) ) +
  scale_y_continuous( labels = function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE ) ) +
  guides( fill = guide_legend( title="Legende" ) ) +
  facet_wrap( vars(Geschlecht) ) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90, size = 8 )
  ) +
  labs(  title = paste( "R² der Korrelation der Jahressterberate\nGeburtsjahrgang j und (j + n)" )
         , subtitle = paste( "s(Alter,j+n) = a(j) + b(j) * s(Alter,j)" )
         , x = paste( "Jahrgang" )
         , y = paste( "Slope b" )
         , caption = citation )  -> P

ggsave(  paste(outdir, 'Jahrgang_R2.png', sep = '' )
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

