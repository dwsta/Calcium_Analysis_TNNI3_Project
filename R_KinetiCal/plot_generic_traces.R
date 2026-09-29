library(tidyverse)
library(RColorBrewer)
library(gridExtra)
source('utils.R')

filedir <- '.' # path to the folder containing the csv
filename <- 'example_calcium_whole_roi.csv' # name of the csv

# Load csv
df <- read_csv(file = file.path(filedir,filename))

# Trace data
traces <- tidyTraceFromCSV(df,traceID=alias,xCol = time, yCol = signal)

# Peak split data
peaks <- tidyTraceFromCSV(df,traceID=alias,xCol = time, yCol = peak_ID) %>%
  mutate(peak_ID = as_factor(peak_ID))

# Merge
traces <- left_join(traces,peaks)

# Add well, well.letter, well.number columns and guess platenames from the rest of the alias
traces <- traces %>%
  parse.well(.,traceID=alias) %>%
  make.plate.names(.,traceID=alias)
  

# Normalization
traces <- traces %>% 
  group_by(alias) %>%
  mutate(norm.signal = (signal -min(signal))/(max(signal) -min(signal)))%>%
  ungroup()
  
# Split by plates so we can plot a plate per page
per.plate <- traces %>%
  group_by(plate.name) %>%
  group_split()

# This function gets traces from a plate and arranges them by well.letter and well.number
# xCol will be used as x-axis and yCol will be used as y-axis
plot.a.plate <- function(tidyPlate,xCol,yCol,cCol){
  ncolors <- tidyPlate %>% select({{cCol}}) %>% distinct() %>% nrow()
  mycolors <- rep(brewer.pal(8,"Dark2"),length.out=ncolors)
  
  p <- ggplot(tidyPlate, aes(x={{xCol}} , y={{yCol}} , color={{cCol}}))+
    geom_line()+
    scale_colour_manual(values = mycolors)+
    facet_grid(cols=vars(well.number),rows=vars(well.letter))+
    ggtitle(tidyPlate$plate.name[1])+
    theme_classic()+
    theme(legend.position = 'none')
  p
}

# Test the function with the first plate
tidyPlate <- per.plate[[1]]
plot.a.plate(tidyPlate,xCol = time, yCol=signal, cCol = peak_ID)
plot.a.plate(tidyPlate,xCol = time,yCol=norm.signal,cCol = peak_ID)

# Apply to all plates
p.raws <- lapply(per.plate , plot.a.plate, xCol = time, yCol = signal,cCol = peak_ID)
p.norm <- lapply(per.plate , plot.a.plate, xCol = time, yCol = norm.signal,cCol = peak_ID)

# Save raw traces
nameout <- paste0('raw_traces_',
  gsub(x=filename,pattern='.csv',replacement = ''),
  '.pdf')
ggsave(filename = file.path(filedir,nameout),
       marrangeGrob(p.raws,ncol = 1,nrow = 1),
       width = 11, height = 8.5)
# Save normalized traces
nameout <- paste0('normalized_traces_',
                  gsub(x=filename,pattern='.csv',replacement = ''),
                  '.pdf')
ggsave(filename = file.path(filedir,nameout),
       marrangeGrob(p.norm,ncol = 1,nrow = 1),
       width = 11, height = 8.5)

