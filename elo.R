# install.packages("welo")
library(welo)
library(foreign)
library(readr)

floc = "data/odds/"
tennis.data <- data.frame(stringsAsFactors = FALSE)
for(ff in 2007:2020) {
  fname = paste0(floc,ff,".csv")
  temp <- read.csv(fname,stringsAsFactors = FALSE)
  tennis.data <- rbind(tennis.data,temp[,c("Date","Winner","Loser")])
}

tennis.data$Date <- as.Date(tennis.data$Date,"%d/%m/%Y")
elorank.tennis <- list()
tennis.data$outcome <- 1
tennis.data <- tennis.data[order(tennis.data$Date),]
for(mm in c(1:NROW(tennis.data))) {
  if(!(tennis.data$Winner[mm] %in% names(elorank.tennis))) {
    elorank.tennis[[tennis.data$Winner[mm]]] <- 1000
  }
  if(!(tennis.data$Loser[mm] %in% names(elorank.tennis))) {
    elorank.tennis[[tennis.data$Loser[mm]]] <- 1000
  }

  tennis.data$elostrength1[mm] <- elorank.tennis[[tennis.data$Winner[mm]]]
  tennis.data$elostrength2[mm] <- elorank.tennis[[tennis.data$Loser[mm]]]
  tennis.data$elopredict[mm] <- 1/(1+(10^((elorank.tennis[[tennis.data$Loser[mm]]]-elorank.tennis[[tennis.data$Winner[mm]]])/400)))
  adjustment <- 40*(tennis.data$outcome[mm] - tennis.data$elopredict[mm])
  if(is.na(adjustment)==FALSE) {
    elorank.tennis[tennis.data$Winner[mm]] <- elorank.tennis[[tennis.data$Winner[mm]]] + adjustment
    elorank.tennis[tennis.data$Loser[mm]] <- elorank.tennis[[tennis.data$Loser[mm]]] - adjustment
  }
}

tennis.data$year <- format(tennis.data$Date, "%Y")
tennis.data$month <- format(tennis.data$Date, "%m")
tennis.data$day <- format(tennis.data$Date, "%d")
tennis.data[tennis.data==""]<-NA
names(tennis.data) <- tolower(names(tennis.data))
write.dta(tennis.data, paste0(floc,"../elo.dta"))

tennis = read.csv("data/tennis.csv")
db_clean<-clean(tennis, MNM = 10, MRANK = 5000)
res<-welofit(db_clean, W = "GAMES", SP = 1500, K = "Kovalchik", CI = FALSE,alpha = 0.05,B = 1000,new_data = NULL)
list2env(setNames(res,paste0("df",seq(res))),envir = .GlobalEnv)
df7$Date <- as.Date(df7$Date,"%d/%m/%Y")
df7$year <- format(df7$Date, "%Y")
df7$month <- format(df7$Date, "%m")
df7$day <- format(df7$Date, "%d")
df7[df7==""]<-NA
names(df7) <- tolower(names(df7))
write.dta(df7, paste0(floc,"../welo.dta"))


