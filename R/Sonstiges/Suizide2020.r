#!/usr/bin/env Rscript

MyScriptName <- 'RKI-Omikron.r'

require( data.table  )

library( tidyverse  )
library( REST )
library( gtable )
library( lubridate )
library( ggplot2 )
library( grid )
library( gridExtra )
library( ggpubr )
library( viridis )
library( hrbrthemes )
library( scales )
library( Cairo )
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
# source( "R/lib/mytheme.r" )
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

url <- "https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Gesundheit/Todesursachen/Tabellen/sterbefaelle-suizid-erwachsene-kinder.html"
Suizide2020 = as.data.table( htmltab( url, which = 1, bodyFun = bFun, colNames = c( "Altergruppe","Gesamt","Male","Female" ) ) )

Suizide2020$Jahr <- 2020

  Suizide2020[1, 2:4] <- '0'
  Suizide2020$Gesamt <- as.integer(Suizide2020$Gesamt)
  Suizide2020$Male <- as.integer(Suizide2020$Male)
  Suizide2020$Female <- as.integer(Suizide2020$Female)

Suizide2020$AlterVon <- c(0,as.integer(gsub(' bis.*','', Suizide2020$Altergruppe[2:(nrow(Suizide2020)-1)])),90)
Suizide2020$AlterBis <- c(0,as.integer(gsub('.*bis ','', Suizide2020$Altergruppe[2:(nrow(Suizide2020)-1)])) - 1,100)

write.csv(Suizide2020[,c(5,6,7,3,4)],file = paste( 'data/Suizide2020_', format( today, "%Y%m%d" ), '.csv',sep=''))
