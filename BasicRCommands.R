# Install required R packages
install.packages(c("dplyr","ggplot2","randomForest","reshape2","stringr"), 
lib = "C:\\Program Files\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\R_SERVICES\\library")

# Load the required R packages
library(dplyr)
library(ggplot2)
library(stringr)
library(reshape2)
library(randomForest)

# Set a working directory
setwd( "c:/lendingclub/" )

# Load the data source into a dataframe
data <- read.csv('filename.csv', header=TRUE, sep=",")

# Print the structure of the dataframe
str(data)
dim(data)
names(data)
head(data)

# Check for the NA values
any(is.na(data))

# Copying the content to a new dataframe to play with!
mydata <- data

# Drop a column
mydata$columnName <- NULL

# Remove columns that are majorly NA
junk <- sapply(mydata, function(x) 
{
  c <- 1 - sum(is.na(x)) / length(x)
  c < 0.8
})
mydata <- mydata[,junk==FALSE]

# Add new column to the dataframe
mydata$newcolumn <- 0
