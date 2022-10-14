#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SterblichkeitMonat"

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

outdir <- 'png/Sterblichkeit/' 
dir.create( outdir , showWarnings = TRUE, recursive = FALSE, mode = "0777")


require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

citation <- "© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

plotit <- function (Alter =c(60,120) ) { 

SQL <- paste( 'select Jahr, Monat, Geschlecht, sum(Gestorbene) as Gestorbene , sum(Einwohner) as Einwohner from SterbefaelleMonatBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'and Jahr > 2015'
  ,'group by Jahr, Monat, Geschlecht;'
)

Sterbefaelle <- RunSQL( SQL )

S <- Sterbefaelle %>% filter( Jahr < 2020 )

Sterbefaelle$Geschlecht <- factor(Sterbefaelle$Geschlecht,levels = c( 'F','M'), labels = c('Frauen','Männer'))

meanMale <- mean(S$Gestorbene[S$Geschlecht == 'Männer'] / S$Einwohner[S$Geschlecht == 'Männer']) * 1000000
meanFemale <- mean(S$Gestorbene[S$Geschlecht == 'Frauen'] / S$Einwohner[S$Geschlecht == 'Frauen']) * 1000000

Sterbefaelle %>% ggplot(
  aes( x = Monat, y = Gestorbene / Einwohner *1000000, colour = Geschlecht )) +
  geom_line( aes( colour = Geschlecht) ) +

  geom_hline( yintercept = meanMale, linetype ='dotted', show.legend = TRUE ) +
  geom_hline( yintercept = meanFemale, linetype ='dotted', show.legend = TRUE ) +
  
  expand_limits(y = 0) +
  facet_wrap(vars(Jahr)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro 1 Mio im Monat in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x ="Monat"
         , y = "Anzahl pro 1 Mio"
         , caption = citation ) +
  scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'Monat_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

# data %>% ggplot() +
#   geom_bar( aes( x = Monat, y = Rate, fill = Geschlecht ), position='dodge', stat = 'identity') +
#   expand_limits(y = 0) +
#   facet_wrap(vars(Jahr)) +
#   theme_ipsum() +
#   labs(  title = paste("Sterbefälle pro 1 Mio im Monat in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
#          , subtitle= paste("Deutschland, Stand:", heute)
#          , colour  = "Geschlecht"
#          , x ="Monat"
#          , y = "Anzahl pro 1 Mio"
#          , caption = citation ) +
#   scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
#   scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp
# 
# ggsave(paste( outdir, 'Monat_bar_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
#        , device = "png"
#        , bg = "white"
#        , width = 3840, height = 2160
#        , units = "px"
# )
# 
}

SQL <- 'select distinct AlterVon, AlterBis from SterbefaelleMonatBev;'
AG <- RunSQL(SQL)

plotit (Alter = c(0,59))
plotit (Alter = c(0,100))
plotit (Alter = c(60,100))
plotit (Alter = c(80,100))

for (i in 1:(nrow(AG))) {
  
  plotit(Alter=AG[i,])

}

