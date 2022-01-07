#!/usr/bin/env Rscript
#
#
# Script: RKI.r
#
# Stand: 2020-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Ueberstreblichkeit"

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
heute <- format(today, "%d.%b.%Y")


plotit <- function (Alter =c(60,120) ) { 
  
SQL <- paste( 'select * from OverMortality2020;')

Sterbefaelle <- RunSQL( SQL )

SQL <- 'select Kw,Geschlecht,sum(M) as Anzahl from ( select Kw,case when Geschlecht=1 then "Männer" else "Frauen" end as Geschlecht, AlterVon,median(Anzahl) OVER (PARTITION BY Kw,Geschlecht,AlterVon) as M from SterbefaelleKw where Jahr <2020 group by Geschlecht,Kw,AlterVon) as B group by Kw,Geschlecht;'
M <- RunSQL( SQL )

Sterbefaelle$Median <- M$Anzahl

Sterbefaelle %>% ggplot(
  aes( x = Kw )) +
  geom_line( aes(y= Median, colour = 'Median 2000-2019')) +
  geom_line( aes(y= Mittelwert, colour = 'Mittelwert 2016-2019')) +
  geom_line( aes(y= Anzahl, colour= '2021')) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) +
  expand_limits(y = 0) +
  facet_wrap(vars(Geschlecht)) +
  theme_ipsum() +
  labs(  title = paste("Über-/ Untersterblichkeit je Woche; Alter über 60 Jahre")
         , subtitle= paste("Deutschland, Stand:", heute)
         , colour  = "Vergleich"
         , x ="Kalenderwoche"
         , y = "Sterbefälle"
         , caption = citation ) -> pp6

ggsave(paste('png/OverMortKwA', Alter[1], '-', Alter[2], '.png', sep='')
       , device = "png"
       , bg = "white"
       , width = 3840, height = 2160
       , units = "px"
)
}

SQL <- 'select distinct AlterVon,AlterBis from SterbeAGW'
AG <- RunSQL(SQL)

plotit (Alter = c(0,59))
plotit (Alter = c(85,120))
plotit (Alter = c(60,120))

for (i in 1:(nrow(AG)-2)) {
  plotit(Alter=AG[i,])
}
