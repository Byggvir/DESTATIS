Wochentage <- c("Mo","Di","Mi","Do","Fr","Sa","So")
WochentageLang <- c("Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag","Sonntag")
Monate <- c("Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember")

library(lubridate)

limbounds <- function (x, zeromin=TRUE) {
  
  if (zeromin == TRUE) {
    range <- c(0,max(x,na.rm = TRUE))
  } else
  { range <- c(min(x, na.rm = TRUE),max(x,na.rm = TRUE))
  }
  if (range[1] != range[2])
  {  factor <- 10^(floor(log10(range[2]-range[1])))
  } else {
    factor <- 1
  }
  
  # print(factor)
  return ( c(floor(range[1]/factor),ceiling(range[2]/factor)) * factor) 
}

KwToDate <- function ( Jahr , Kw ) {
  
  R <- as.Date (paste(Jahr,'-01-01',sep = ''))
  
  w <- lubridate::wday(R, week_start = 1)
  
  R[ w > 4 ] <- R[ w > 4 ] + Kw[ w > 4 ] * 7 + 4  - w[ w > 4 ]
  R[ w <= 4 ] <- R[ w <= 4 ] + ( Kw[ w <= 4 ] - 1 ) * 7 + (4 - w [ w <= 4 ]) 
  return (R)
    
}
