#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Uebersterblichkeit"

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

require(data.table)

source("R/lib/myfunctions.r")
source("R/lib/sql.r")
source("R/lib/color_palettes.r")

citation <- "© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nStand 07.10.2021"

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

Alter <- c(0,100)

SQL1 <- paste( 
    'select Jahr, Kw, concat("A",AlterVon,"-A",AlterBis) as AG, Geschlecht, '
  , ' Gestorbene/Einwohner * 100000 as Mortality' 
  , 'from SterbefaelleWocheBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'and Jahr > 2015'
  , 'union'
  , 'select Jahr, Kw, concat("A",AlterVon,"-A",AlterBis) as AG, "beide" as Geschlecht'
  , ' , sum(Gestorbene)/sum(Einwohner) * 100000 as Mortality'
  , 'from SterbefaelleWocheBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'and Jahr > 2015'
  , 'group by Jahr, Kw, AG'
  , 'union'
  , 'select Jahr, Kw, "All" as AG, Geschlecht'
  , ' , sum(Gestorbene)/sum(Einwohner) * 100000 as Mortality'
  , 'from SterbefaelleWocheBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'and Jahr > 2015'
  , 'group by Jahr, Kw, Geschlecht'
  , 'union'
  , 'select Jahr, Kw, "All" as AG, "beide" as Geschlecht'
  , ' , sum(Gestorbene)/sum(Einwohner) * 100000 as Mortality'
  , 'from SterbefaelleWocheBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  , 'and Jahr > 2015'
  , 'group by Jahr, Kw'
  ,';'
)

Sterbefaelle <- RunSQL( SQL1 )
Sterbefaelle$Geschlecht[Sterbefaelle$Geschlecht == 'M'] <- 'Männer'
Sterbefaelle$Geschlecht[Sterbefaelle$Geschlecht == 'F'] <- 'Frauen'


Sterbefaelle %>% filter(AG == 'All') %>% ggplot(
  aes( x = AG, y = Mortality, colour = Geschlecht)) +
  geom_boxplot() +
 # expand_limits( y = 0 ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  facet_wrap(vars(Geschlecht),ncol=3) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro Woche pro 100.000 in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x = "Woche"
         , y = "Anzahl [1/(Woche*100.000)]"
         , caption = citation )
#  scale_x_continuous(breaks=1:12,labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +

ggsave(paste('png/WochenSterblichkeit_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)
