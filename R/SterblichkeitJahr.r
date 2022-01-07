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

fPrefix <- "Fallzahlen_Wo_"

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

plotit <- function (Alter =c(60,120) ) { 

SQL <- paste( 'select Jahr, sum(Male) as Male, sum(Female) as Female , sum(BevMale) as BevMale, sum(BevFemale) as BevFemale from SterbefaelleMonatBev'
  , 'where'
  , 'AlterVon >=', Alter[1]
  , 'and'
  , 'AlterBis <=', Alter[2]
  ,'group by Jahr;'
)

Sterbefaelle <- RunSQL( SQL )

Sterbefaelle %>% ggplot(
  aes( x = Jahr )) +
  geom_line( aes(y= Male/BevMale * 1000000, colour = 'Männer')) +
  geom_line( aes(y= Female/BevFemale * 1000000, colour= 'Frauen')) +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro 1 Mio im Jahr in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x ="Jahr"
         , y = "Anzahl pro 1 Mio"
         , caption = citation ) +
  scale_x_continuous(minor_breaks = 1) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste('png/SterblichkeitJ_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

Sterbefaelle %>% ggplot(
  aes( x = Jahr )) +
  geom_line( aes( y= Male, colour = 'Männer')) +
  geom_line( aes( y= Female, colour= 'Frauen')) +
  geom_smooth(aes( y= Male, colour = 'Männer'), method= 'lm' ) +
  geom_smooth(aes( y= Female, colour = 'Frauen') ,method= 'lm' ) +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle im Jahr in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x ="Jahr"
         , y = "Anzahl"
         , caption = citation ) +
  scale_x_continuous(minor_breaks = 1) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste('png/SterblichkeitJS_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

data <- data.frame(
  Jahr = c(Sterbefaelle$Jahr,Sterbefaelle$Jahr)
  , Fall = c(Sterbefaelle$Male,Sterbefaelle$Female)
  , Bev = c(Sterbefaelle$BevMale,Sterbefaelle$BevFemale)
  , Geschlecht = rep(c('Männer','Frauen'),nrow(Sterbefaelle))
)

data %>% ggplot(
  aes( x = Jahr, y= Fall / Bev * 1000000, fill=Geschlecht )) +
  geom_bar(position='dodge', stat = 'identity') +
  expand_limits(y = 0) +
  theme_ipsum() +
  labs(  title = paste("Sterbefälle pro 1 Mio im Jahr in der Altersgruppe", Alter[1], 'bis' , Alter[2],'Jahre')
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Geschlecht"
         , x ="Jahr"
         , y = "Anzahl pro 1 Mio"
         , caption = citation ) +
#  scale_x_continuous(breaks=1:12,minor_breaks = seq(1, 12, 1),labels=c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste('png/SterblichkeitJB_A', Alter[1] ,'-A', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)

}

SQL <- 'select distinct AlterVon, AlterBis from SterbefaelleMonatBev;'
AG <- RunSQL(SQL)

plotit (Alter = c(0,59))
plotit (Alter = c(0,100))
plotit (Alter = c(60,100))

for (i in 1:(nrow(AG))) {

  plotit(Alter=AG[i,])

}
