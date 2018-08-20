# Number Generation
# Example showing different ways to generate number from 5 to 25
NoGen <- 5:25
NoGen2 <- seq(5, 25,1)

# create a vector
strGen <- c("1", "2", "100")

#Convertion functions
lgNoGen <- as.logical(NoGen)
lgNoGen 

chrNoGen <- as.character(NoGen)
chrNoGen 

NumberstrGen <- as.numeric(strGen)
NumberstrGen 

##### Histogram Sample

# Create data for the graph.
dummydata <-  c(4,23,11,18,6,21,41,43,29)
hist(dummydata, xlab = "Weight", col = "blue", border = "black")

# Install required R packages
install.packages(c("dplyr","ggplot2","randomForest","reshape2","stringr"), 
lib = "C:\\Program Files\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\R_SERVICES\\library")

# Load the required R packages
library(dplyr)
library(ggplot2)
library(stringr)
library(reshape2)
library(randomForest)

# See the help page of any package
library(help = ggplot2)

# Set a working directory
setwd( "c:/foldername/" )

# Load the data source into a dataframe
data <- read.csv('filename.csv', header=TRUE, sep=",")

# Print the structure of the dataframe
str(data)
dim(data)
names(data)
head(data)

# All objects has 2 intrinsic attributes - Length & Mode
length(data)
mode(data$columnName)

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


