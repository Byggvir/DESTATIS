#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitWoche.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "SterblichkeitWoche"

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


options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

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
dir.create( outdir , showWarnings = FALSE, recursive = FALSE, mode = "0777")

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste('© Thomas Arend, 2022\nQuelle: © Statistisches Bundesamt (Destatis), 2022\nStand' , heute)


plotit <- function (Alter =c(60,120) ) { 

  SQL <- paste( 'select Jahr, Kw, Geschlecht, sum(Gestorbene) as Gestorbene , sum(Einwohner) as Einwohner from SterbefaelleWocheBev'
                , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'group by Jahr, Kw, Geschlecht;'
)

Sterbefaelle <- RunSQL( SQL )
Sterbefaelle$Geschlecht[Sterbefaelle$Geschlecht == 'M'] <- 'Männer'
Sterbefaelle$Geschlecht[Sterbefaelle$Geschlecht == 'F'] <- 'Frauen'

Sterbefaelle %>% filter(Jahr >= 2017 ) %>% ggplot(
  aes( x = Kw )) +
  geom_line( aes(y= Gestorbene / Einwohner * 1000000, colour = Geschlecht)) +
  expand_limits(y = 0) +
  facet_wrap(vars(Jahr)) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro 1 Mio pro Woche in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "Woche"
         , y = "Anzahl pro 1 Mio"
         , caption = citation ) +
#  scale_x_continuous(breaks=1:53,minor_breaks = seq(1, 53, 1) ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste( outdir, 'Woche_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)
}

SQL <- 'select distinct AlterVon, AlterBis from SterbefaelleWocheBev;'
AG <- RunSQL(SQL)

plotit (Alter = c(0,59))
plotit (Alter = c(0,44))
plotit (Alter = c(0,100))
plotit (Alter = c(60,100))

for (i in 1:nrow(AG)) {
  
  plotit(Alter=AG[i,])

}
