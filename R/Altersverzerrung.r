#!/usr/bin/env Rscript
#
#
# Script: SterblichkeitMonat.r
#
# Stand: 2021-10-21
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Altersverzerrung"

library(data.table)
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
library(Cairo)

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

citation <- "© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021"

options( 
  digits = 7
  , scipen = 7
  , OutDec = "."
  , max.print = 3000
)

today <- Sys.Date()
heute <- format(today, "%d %b %Y")


max_weeks = 53
max_doses = 100000
prio      = 0.9
vax_weeks = 6
  
SQL <- paste( 
    'select sum(`Both`) as Population from DT124110006 '
  , 'where `Alter` > 79 and `Alter` < 85 and Stichtag = "2020-12-31"'
  , 'union'
  , 'select sum(`Both`) from DT124110006 '
  , 'where `Alter` > 84 and Stichtag = "2020-12-31"'
  , ';'
)

Bev <- RunSQL( SQL )

VT <- data.table(
  Kw = 1:max_weeks
  , VaccinDoses = rep(max_doses,max_weeks)
  , P1 = rep(0,max_weeks)
  , P2 = rep(0,max_weeks)
  
)  

MT <- data.table (
  Kw = 1:max_weeks
  , Mortality = rep(0,max_weeks)
  , Mortality_All = rep(0,max_weeks)
  , Mortality1 = rep(0,max_weeks)
  , Mortality2 = rep(0,max_weeks)
  , Mortality_1Dose = rep(0,max_weeks)
  , Mortality_Vaccinated = rep(0,max_weeks)
  , Mortality_Unvaccinated = rep(0,max_weeks)
)


SQL <- paste( 
  'select 
        AlterVon
      , Kw
      , sum(Male+Female)/sum(BevMale+BevFemale) * 100000 as Mort
   from SterbefaelleWocheBev where AlterVon >79 
   group by Kw;'
)

Mort <- RunSQL( SQL )

SQL <- paste( 
  'select 
        AlterVon
      , Kw
      , sum(Male+Female)/sum(BevMale+BevFemale) * 100000 as Mort
   from SterbefaelleWocheBev where AlterVon >79 and AlterBis < 85 
   group by Kw;'
)

Mort1 <- RunSQL( SQL )

SQL <- paste( 
  'select 
        AlterVon
      , Kw
      , sum(Male+Female)/sum(BevMale+BevFemale) * 100000 as Mort
   from SterbefaelleWocheBev where AlterVon >84 
   group by Kw;'
)

Mort2 <- RunSQL( SQL )

MT$Mortality <- Mort$Mort
MT$Mortality2 <- Mort2$Mort
MT$Mortality1 <- Mort1$Mort
MT$Mortality2 <- Mort2$Mort

P1Pop <- matrix( rep( 0, max_weeks*vax_weeks ), ncol = vax_weeks)
P2Pop <- matrix( rep( 0, max_weeks*vax_weeks ), ncol = vax_weeks)

P1Deaths <- matrix( rep( 0, max_weeks*vax_weeks ), ncol = vax_weeks)
P2Deaths <- matrix( rep( 0, max_weeks*vax_weeks ), ncol = vax_weeks)
# 
# colnames(P1Pop)    <-c('Unvaccinated','D1','D2','D3','D4','Vaccinated')
# colnames(P2Pop)    <- c('Unvaccinated','D1','D2','D3','D4','Vaccinated')
# 
# colnames(P1Deaths) <- c('Unvaccinated','D1','D2','D3','D4','Vaccinated')
# colnames(P2Deaths) <- c('Unvaccinated','D1','D2','D3','D4','Vaccinated')

P1Pop[1,1] <- Bev$Population[1]
P2Pop[1,1] <- Bev$Population[2]


for (k in 1:53) {
  
  if ( k > 1) {
    
    # Unvaccinated population in next week
    P1Pop[k,1] <- P1Pop[k-1,1] - P1Deaths[k-1,1] - VT$P1[k-1]
    P2Pop[k,1] <- P2Pop[k-1,1] - P2Deaths[k-1,1] - VT$P2[k-1]
    
    # Vaccinated Population in next week
    
    P1Pop[k,vax_weeks] <- P1Pop[k-1,vax_weeks] - P1Deaths[k-1,vax_weeks] + P1Pop[k-1,vax_weeks-1] - P1Deaths[k-1,vax_weeks-1]
    P2Pop[k,vax_weeks] <- P2Pop[k-1,vax_weeks] - P2Deaths[k-1,vax_weeks] + P2Pop[k-1,vax_weeks-1] - P2Deaths[k-1,vax_weeks-1]
    
    for ( j in (vax_weeks-1):3) {
      P1Pop[k,j] <- P1Pop[k-1,j-1] - P1Deaths[k-1,j-1]
      P2Pop[k,j] <- P2Pop[k-1,j-1] - P2Deaths[k-1,j-1]
    }
    
    P1Pop[k,2] <- VT$P1[k-1]
    P2Pop[k,2] <- VT$P2[k-1]
    
  }
  
  VT$P1[k] <- round(VT$VaccinDoses[k] * P1Pop[k,1] * (1-prio) /( P1Pop[k,1] * (1-prio) + P2Pop[k,1] * prio),0)
  VT$P2[k] <- VT$VaccinDoses[k] - VT$P1[k]

  for (i in 1:vax_weeks ) {
    
    P1Deaths[k,i] <- round(MT$Mortality1[k] / 100000 * P1Pop[k,i])
    P2Deaths[k,i] <- round(MT$Mortality2[k] / 100000 * P2Pop[k,i])
  }
  
  MT$Mortality_1Dose[k] <- ( sum(P1Deaths[k,2:(vax_weeks-1)]) + sum(P2Deaths[k,2:(vax_weeks-1)] ) ) /  ( sum(P1Pop[k,2:(vax_weeks-1)]) + sum(P2Pop[k,2:(vax_weeks-1)]) ) * 100000

  MT$Mortality_Vaccinated[k] <- ( P1Deaths[k,vax_weeks] + P2Deaths[k,vax_weeks]) / ( P1Pop[k,vax_weeks] + P2Pop[k,vax_weeks]) * 100000
  
  MT$Mortality_Unvaccinated[k] <- ( P1Deaths[k,1] + P2Deaths[k,1] ) / ( P1Pop[k,1] + P2Pop[k,1] ) * 100000
  
  MT$Mortality_All[k] <- ( sum(P1Deaths[k,]) + sum(P2Deaths[k,]) ) /  ( sum(P1Pop[k,]) + sum(P2Pop[k,]) ) * 100000
  
}


MT %>% ggplot(
  aes( x = Kw )) +
  # geom_line( aes( y = Mortality1, colour = 'Mortalität 80-84' )) +
  # geom_line( aes( y = Mortality2, colour = 'Mortalität 85+' )) +
  #geom_line( aes( y = Mortality, colour = '80+ Real' ), size = 1) +
  geom_line( aes( y = Mortality_All, colour = '80+' ), size = 2) +
  geom_line( aes( y = Mortality_1Dose, colour = '80+ 1st Dose' )) +
  geom_line( aes( y = Mortality_Vaccinated, colour = '80+ Vaccinated' )) +
  geom_line( aes( y = Mortality_Unvaccinated, colour = '80+ Unvaccinated' )) +
  expand_limits( y = 0) + 
  theme_ipsum() +
  labs(  title = paste('Mortality during a vaccination campaign with priority based on age')
         , subtitle= paste('Simulation, Priority older ', prio, 'to younger', (1-prio))
         , colour  = 'Mortality'
         , x = 'Kw'
         , y = 'Mortalität 1/100000'
         , caption = citation ) +
  scale_y_continuous(labels=function(x) format(x, big.mark = ".", decimal.mark= ',', scientific = FALSE)) -> pp

ggsave(paste('png/Altersverzerrung-Prio',prio*10,'.png', sep='')
       , type = "cairo-png",  bg = "white"
       , width = 29.7, height = 21, units = "cm", dpi = 300
)
