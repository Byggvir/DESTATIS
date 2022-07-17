#!/usr/bin/env Rscript
#
#
# Script: Verkehrstote.r
#
# Stand: 2022-11-23
# (c) 2020 by Thomas Arend, Rheinbach
# E-Mail: thomas@arend-rhb.de
#

MyScriptName <- "Verkehrstote"

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
library(htmltab)
library(readODS)

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

today <- Sys.Date()
heute <- format(today, "%d %b %Y")

citation <- paste('© Thomas Arend, 2021\nQuelle: © Statistisches Bundesamt (Destatis), 2021\nTabelle 23211-0006\nStand', heute)

options( 
  digits = 7
  , scipen = 7
  , Outdec = "."
  , max.print = 3000
)


url <- "https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Verkehrsunfaelle/Tabellen/verkehrstote-nach-alter.html"
verkehrstote <- htmltab(doc = url, which = 1)
write_ods(
  x = verkehrstote,
  path = '/tmp/verkehrstote2.ods',
  sheet = "Sheet1",
  append = FALSE,
  update = FALSE,
  row_names = FALSE,
  col_names = TRUE,
  verbose = FALSE,
  overwrite = NULL
)
