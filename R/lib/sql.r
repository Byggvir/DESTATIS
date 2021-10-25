library(bit64)
library(RMariaDB)
library(data.table)

RunSQL <- function (
  SQL = 'select * from Faelle;'
  , prepare="set @i := 1;") {
  
  rmariadb.settingsfile <- "/home/thomas/git/R/DESTATIS/SQL/DESTATIS.cnf"
  
  rmariadb.db <- "DESTATIS"
  
  DB <- dbConnect(
    RMariaDB::MariaDB()
    , default.file=rmariadb.settingsfile
    , group=rmariadb.db
    , bigint="numeric"
  )
  dbExecute(DB, prepare)
  rsQuery <- dbSendQuery(DB, SQL)
  dbRows<-dbFetch(rsQuery)

  # Clear the result.
  
  dbClearResult(rsQuery)
  
  dbDisconnect(DB)
  
  return(dbRows)
}

ExecSQL <- function (
  SQL 
) {
  
  rmariadb.settingsfile <- "/home/thomas/git/R/DESTATIS/SQL/DESTATIS.cnf"
  
  rmariadb.db <- "DESTATIS"
  
  DB <- dbConnect(
    RMariaDB::MariaDB()
    , default.file=rmariadb.settingsfile
    , group=rmariadb.db
    , bigint="numeric"
  )
  
  count <- dbExecute(DB, SQL)

  dbDisconnect(DB)
  
  return (count)
  
}
