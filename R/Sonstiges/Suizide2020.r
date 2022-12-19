#!/usr/bin/env Rscript

MyScriptName <- 'RKI-Omikron.r'

require( data.table  )

library( tidyverse  )
library( gtable )
library( lubridate )
library( ggplot2 )
library( grid )
library( gridExtra )
library( ggpubr )
library( viridis )
library( hrbrthemes )
library( scales )
library( ragg )
library( htmltab )
library( readODS )
library( XML )


# library( extrafont )
# extrafont::loadfonts()

# Set Working directory to git root

if ( rstudioapi::isAvailable() ){
  
  # When executed in RStudio
  SD <- unlist( str_split( dirname( rstudioapi::getSourceEditorContext()$path ),'/' ) )
  
} else {
  
  #  When executing on command line 
  SD = ( function() return(  if( length( sys.parents() ) == 1 ) getwd() else dirname( sys.frame( 1 )$ofile )  ) )()
  SD <- unlist( str_split( SD,'/' ) )
  
}

WD <- paste( SD[1:( length( SD ) - 2 )],collapse='/' )

setwd( WD )

source( "R/lib/myfunctions.r" )
source( "R/lib/sql.r" )


citation <- "© 2021 by Thomas Arend\nQuelle: DESTATIS (2022) - Übersicht Suizide nach Altersgruppe"

options(  
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
 )

today <- Sys.Date()
heute <- format( today, "%d %b %Y" )

e <- function ( x, a = 0 , b = 1, xoffset = 0 ) {
  
  return ( exp( a + b *( x - xoffset ) ) )
  
}

s <- function ( y ) {
  
  return ( -log( y / ( 1 - y ) ) )
  
}

sigmoid <- function ( x, a = 0, b = 1, N = 1 ) {

  return (  N / ( 1 + exp( a+b*x ) ) )
  
}

sigmoid1s <- function ( x, a = 0, b = 1 , N = 1 ) {
  
  return (  - N * b * exp( a + b * x ) / ( 1 + exp( a + b * x ) ) ^ 2 )
  
}

tryAsNumeric = function(  node  ) {
  val = XML::xmlValue(  node  )
  ans = as.numeric(  gsub(  ",", "", val  )  )
  if(  is.na(  ans  ) )
    return( val )
  else
    return( "ans" )
}

bFun <- function(node) {
  x <- XML::xmlValue(node)
  gsub('\\+', '', x)
}

Jahr <- 2021
url <- "https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Gesundheit/Todesursachen/Tabellen/sterbefaelle-suizid-erwachsene-kinder.html"
SuizidTab = as.data.table( htmltab( url, which = 1, bodyFun = bFun, colNames = c( "Altergruppe","Gesamt","Male","Female" ) ) )

SuizidTab$Jahr <- Jahr

  SuizidTab[1, 2:4] <- '0'
  SuizidTab$Gesamt <- as.integer(SuizidTab$Gesamt)
  SuizidTab$Male <- as.integer(SuizidTab$Male)
  SuizidTab$Female <- as.integer(SuizidTab$Female)

SuizidTab$AlterVon <- c(0,as.integer(gsub(' bis.*','', SuizidTab$Altergruppe[2:(nrow(SuizidTab)-1)])),90)
SuizidTab$AlterBis <- c(0,as.integer(gsub('.*bis ','', SuizidTab$Altergruppe[2:(nrow(SuizidTab)-1)])),100)

SuizidTab$AlterBis[nrow(SuizidTab)-1] <- 100
SuizidTab$AlterBis[1] <- 0
SuizidTab$AlterVon[1] <- 14

SuizidTab$Male[nrow(SuizidTab)-1] <- SuizidTab$Male[nrow(SuizidTab)-1] + SuizidTab$Male[nrow(SuizidTab)]
SuizidTab$Female[nrow(SuizidTab)-1] <- SuizidTab$Female[nrow(SuizidTab)-1] + SuizidTab$Female[nrow(SuizidTab)]


write.csv(   x = SuizidTab[1:(nrow(SuizidTab)-1),c(5,6,7,3,4)]
            ,file = paste( 'data/23211-0004-',Jahr, '.csv', sep='')
            , row.names = FALSE
)
