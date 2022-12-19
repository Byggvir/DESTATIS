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

outdir <- 'png/DT23211/0004/' 
dir.create( outdir , showWarnings = FALSE, recursive = TRUE, mode = "0777")
dir.create( paste0(outdir,'Abs/') , showWarnings = FALSE, recursive = TRUE, mode = "0777")
dir.create( paste0(outdir,'Bev/') , showWarnings = FALSE, recursive = TRUE, mode = "0777")
dir.create( paste0(outdir,'Rel/') , showWarnings = FALSE, recursive = TRUE, mode = "0777")

require(data.table)

source("R/lib/myfunctions.r")
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

SQL <- paste( 'select Jahr, Geschlecht,sum(Anzahl) as Anzahl, sum(PersonenZahl) as PersonenZahl from Selbstmorde where AlterVon > 0 and AlterVon < 90', Ab,'group by Jahr, Geschlecht;', sep = ' ')
Selbstmorde <- RunSQL( SQL )

print(Selbstmorde)

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

Selbstmorde %>% ggplot(
  aes( x = Jahr, y = Anzahl, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x' ) +
  expand_limits( y = 0 ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))+
  theme_ipsum() +
  labs(  title = paste('Selbstmorde, Deutschland ', Von, 'bis', Bis  )
         , subtitle= paste( 'Alle Altersgruppen' )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) -> p

ggsave( paste( outdir,'Abs_Insgesamt', '.png', sep='')
        , plot = p
        , device = "png"
        , bg = "white"
        , width = 1920
        , height = 1080
        , units = "px"
        , dpi = 144
)

Selbstmorde %>% ggplot(
  aes( x = Jahr, y = Anzahl / PersonenZahl * 100000, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x') +
  expand_limits(y = 0) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  theme_ipsum() +
  labs(  title = paste('Selbstmordrate, Deutschland ', Von, 'bis', Bis  )
         , subtitle= paste( 'Alle Altersgruppen' )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen pro 100.000  pro Jahr]"
         , caption = citation ) -> P

ggsave(  paste( outdir,'Rel_Insgesamt', '.png', sep='' )
         , plot = P
         , device = "png"
         , bg = "white"
         , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

Selbstmorde %>% ggplot( aes( x = Jahr, y = PersonenZahl ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x' ) +
  # expand_limits(y = 0) +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Bevölkerung Deutschland', Von, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) -> P

ggsave(   paste( outdir, 'Bevoelkerung', '.png', sep='')
        , plot = P
        , device = "png"
        , bg = "white"
        , width = 1920
        , height = 1080
        , units = "px"
        , dpi = 144
)

SQL <- paste( 'select * from StdSelbstmordeJahr where Jahr > 1990;', sep = ' ')
Selbstmorde <- RunSQL( SQL )

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

Selbstmorde %>% ggplot( aes( x = Jahr, y = StdAnzahl, colour = Geschlecht ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x' ) +
  expand_limits(y = 0)  +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Standardisierte Selbstmorde Deutschland', Von, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) -> P
  
ggsave(  paste( outdir, 'Std_Insgesamt', '.png', sep='' )
        , plot = P
        , device = "png"
        , bg = "white"
        , width = 1920
        , height = 1080
        , units = "px"
        , dpi = 144
)


SQL <- paste( 'select * from Selbstmorde where AlterVon > 0', Ab,';', sep = ' ')
Selbstmorde <- RunSQL( SQL )

Von <- min(Selbstmorde$Jahr)
Bis <- max(Selbstmorde$Jahr)

Selbstmorde$Jahre = factor(Selbstmorde$Jahr)

Selbstmorde %>% filter ( Jahr > 2017) %>% ggplot( aes( x = Altersgruppe, y = Anzahl, group = Jahre, fill = Jahre) ) +
  geom_bar( stat = 'identity', position = position_dodge2() ) +
  expand_limits(y = 0)  +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  facet_wrap(vars(Geschlecht)) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90 , vjust = 0.5, hjust = 0.5)
  ) +
  labs(  title = paste('Selbstmorde Deutschland', 2019, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Jahr"
         , x = "Altersgruppe"
         , y = "Suizide [Personen]"
         , caption = citation ) -> P

ggsave(  paste( outdir, 'Barplot 2019-2021', '.png', sep='' )
         , plot = P
         , device = "png"
         , bg = "white"
           , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

Selbstmorde %>% filter ( Jahr > 2017) %>% ggplot( aes( x = Altersgruppe, y = SuizidRate, group = Jahre, fill = Jahre) ) +
  geom_bar( stat = 'identity', position = position_dodge2() ) +
  expand_limits(y = 0)  +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  facet_wrap(vars(Geschlecht)) +
  theme_ipsum() +
  theme(
    axis.text.x = element_text( angle = 90 , vjust = 0.5, hjust = 0.5)
  ) +
  labs(  title = paste('Selbstmordrate Deutschland', 2018, 'bis', Bis )
         , subtitle= paste( 'Alle Altersgruppen'  )
         , colour  = "Jahr"
         , x = "Altersgruppe"
         , y = "Suizidrate [Personen pro 100.000]"
         , caption = citation ) -> P

ggsave(  paste( outdir, 'Barplot 2019-2021 Rate', '.png', sep='' )
         , plot = P
         , device = "png"
         , bg = "white"
           , width = 1920
         , height = 1080
         , units = "px"
         , dpi = 144
)

AG <- unique(Selbstmorde$Altersgruppe)

for (A in AG ) {
  
Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot(
  aes( x = Jahr, y = Anzahl ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x' ) +
  expand_limits(y = 0) +
    scale_x_continuous(labels=function(x) format(x, big.mark = "", decimal.mark= ',', scientific = FALSE)) +
    scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  theme_ipsum() +
  labs(  title = paste('Jährliche Sebstmorde')
         , subtitle= paste( 'Altersgruppe', A  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) -> p1

ggsave(  paste( outdir,'Abs/',A, '.png', sep='' )
       , plot = p1
       , device = "png"
       , bg = "white"
       , width = 1920
       , height = 1080
       , units = "px"
       , dpi = 144
       
)

Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot(
  aes( x = Jahr, y = SuizidRate ) ) +
  geom_line( aes( colour = Geschlecht ) ) +
  geom_smooth( aes( colour = Geschlecht ), method = 'loess', formula = 'y ~ x' ) +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste('Sebstmordrate pro 100.000')
         , subtitle= paste( 'Altersgruppe', A )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Rate [Personen pro Jahr pro 100.000]"
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE))  -> p2

ggsave( paste( outdir,'Rel/', A, '.png', sep='' )
        , plot = p2
        , device = "png"
        , bg = "white"
        , width = 1920
        , height = 1080
        , units = "px"
        , dpi = 144
)

Selbstmorde %>% filter(Altersgruppe == A) %>% ggplot( ) +
  geom_line( aes( x = Jahr, y = PersonenZahl, colour = Geschlecht ), linewidth = 2) +
  expand_limits(y = 0) +
  scale_y_continuous( 
    labels = function ( x ) format( x, big.mark = ".", decimal.mark = ',', scientific = FALSE ) ) +
  theme_ipsum() +
  labs(  title = paste('Bevölkerung' )
         , subtitle= paste( 'Altersgruppe', A  )
         , colour  = "Geschlecht"
         , x = "Jahr"
         , y = "Anzahl [Personen]"
         , caption = citation ) -> p3

ggsave(  paste( outdir,'Bev/', A, '.png', sep='' )
       , plot = p3
       , device = "png"
       , bg = "white"
       , width = 1920
       , height = 1080
       , units = "px"
       , dpi = 144
)

}
