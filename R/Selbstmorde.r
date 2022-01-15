#!/usr/bin/env Rscript
#
#
# Script: Selbstmorde.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Selbstmorde"

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

outdir <- 'png/Selbstmorde/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")

fPrefix <- "Selbstmorde_"

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/mytheme.r")
source("R/lib/sql.r")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste('© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nTabelle 23211-0004\nStand', heute)

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

Ab <- 'and Jahr > 1990'

SQL <- paste( 'select Jahr,Geschlecht,sum(Anzahl) as Anzahl, sum(PersonenZahl) as PersonenZahl from Selbstmorde where AlterVon > 0', Ab,'group by Jahr, Geschlecht;', sep = ' ')
Selbstmorde <- RunSQL( SQL )

print(Selbstmorde)

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

Selbstmorde %>% ggplot(
  aes( x = Jahr, y = Anzahl, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ) ) +
  expand_limits( y = 0 ) +
  theme_ta() +
  labs(  title = paste('Selbstmorde, Deutschland ', Von, 'bis', Bis  )
         , subtitle= paste( 'Alle Altersgruppen' )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))

ggsave(paste( outdir,'Abs_Insgesamt', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

Selbstmorde %>% ggplot(
  aes( x = Jahr, y = Anzahl / PersonenZahl * 100000, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ) ) +
  expand_limits(y = 0) +
  theme_ta() +
  labs(  title = paste('Selbstmordrate, Deutschland ', Von, 'bis', Bis  )
         , subtitle= paste( 'Alle Altersgruppen' )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen pro 100.000  pro Jahr]"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))

ggsave(paste( outdir,'Rel_Insgesamt', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

Selbstmorde %>% ggplot( aes( x = Jahr, y = PersonenZahl ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ) ) +
  # expand_limits(y = 0) +
  theme_ta() +
  labs(  title = paste('Bevölkerung Deutschland', Von, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) )

ggsave(paste( outdir, 'Bevoelkerung', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)

SQL <- paste( 'select * from StdSelbstmordeJahr where Jahr > 1990;', sep = ' ')
Selbstmorde <- RunSQL( SQL )

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

Selbstmorde %>% ggplot( aes( x = Jahr, y = StdAnzahl, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ) ) +
  expand_limits(y = 0) +
  theme_ta() +
  labs(  title = paste('Standardisierte Sterbefälle Deutschland', Von, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) )

ggsave(paste( outdir, 'Std_Insgesamt', '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
)


SQL <- paste( 'select * from Selbstmorde where AlterVon > 0 ', Ab,';', sep = ' ')
Selbstmorde <- RunSQL( SQL )

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

AG <- unique(Selbstmorde$Altersgruppe)

for (A in AG ) {
  
Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot(
  aes( x = Jahr, y = Anzahl ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht )) +
  expand_limits(y = 0) +
theme_ta() +
  labs(  title = paste('Jährliche Sebstmorde, Deutschland', Von, 'bis', Bis)
         , subtitle= paste( 'Altersgruppe', A  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> p1

ggsave(  paste( outdir,'Abs_', A, '.png', sep='' )
       , plot = p1
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"

)

Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot(
  aes( x = Jahr, y = SuizidRate ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ) ) +
  expand_limits(y = 0) +
  theme_ta() +
  labs(  title = paste('Sebstmordrate pro 100.000, Deutschland ', Von, 'bis', Bis )
         , subtitle= paste( 'Altersgruppe', A )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Rate [Personen pro Jahr pro 100.000]"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))  -> p2

ggsave( paste( outdir,'Rel_', A, '.png', sep='' )
       , plot = p2
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
       , dpi = 300
)

Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot( ) +
  geom_line( aes( x = Jahr, y = PersonenZahl, colour = Geschlecht ), size = 2) +
  expand_limits(y = 0) +
  theme_ta() +
  labs(  title = paste('Bevölkerung, Deutschland', Von, 'bis', Bis )
         , subtitle= paste( 'Altersgruppe', A  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) +
  scale_y_continuous( 
     labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) -> p3

ggsave(  paste( outdir,'Bev_', A, '.png', sep='' )
       , plot = p3
       , device = "png"
       , bg = "white"
       , width = 3840
       , height = 2160
       , units = "px"
       , dpi = 300
)

p4 <- grid.arrange (p1,p2,p3, nrow = 2)

ggsave(  paste( outdir,'3in1_', A, '.png', sep='' )
       , plot = p4
       , device = "png"
       , bg = "white"
       , width = 3840 * 2
       , height = 2160 * 2
       , units = "px"
       , dpi = 300
)
}
