require(tidyverse)
require(gridExtra)

parse.well <- function(csvfile,traceID){
  temp <- str_extract(csvfile %>% select({{traceID}}) %>% unlist(), "Well__[A-Z]_\\d{3}") %>% str_remove(.,"Well__")
  csvfile$well.letter <- substr(temp,start = 1,stop=1)
  csvfile$well.number <- substr(temp,start = 4,stop=5)
  csvfile$well <- paste0(csvfile$well.letter,csvfile$well.number)
  csvfile  
}
make.plate.names <- function(csvfile,traceID){
  # Remove the well string
  temp <- str_remove(csvfile %>% select({{traceID}}) %>% unlist(), "Well__[A-Z]_\\d{3}")
  csvfile$plate.name <- temp
  csvfile
}


parse_trace <- function(traceString){
  # Remove the {} 
  c<-gsub(x=traceString,pattern = "[{]",replacement = "")
  c<-gsub(x=c,pattern = "[}]",replacement = "")
  # Split by ;
  c <- strsplit(c,split=";",fixed=TRUE) %>% unlist()
  c <- c %>% as.numeric()
  c
}

tidyTraceFromCSV <- function(csvfile,traceID,xCol, yCol){
  b <- csvfile %>% 
    group_by({{traceID}}) %>% 
    dplyr::select({{traceID}},{{xCol}},{{yCol}}) %>% 
    group_split()
  trace.df <- b[[1]]
  bbb <- lapply(b,function(trace.df){
    ID <- trace.df %>% dplyr::select({{traceID}}) %>% unlist()
    x <- parse_trace(trace.df %>% dplyr::select({{xCol}}))
    y <- parse_trace(trace.df %>% dplyr::select({{yCol}}))
    df <- data.frame(ID, x, y) %>%
      rename({{traceID}} := ID,
             {{xCol}}    := x,
             {{yCol}} := y)
  })
  df <- bind_rows(bbb)
  df
}
