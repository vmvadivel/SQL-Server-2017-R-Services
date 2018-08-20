# Install required R packages
install.packages(c("dplyr","ggplot2","randomForest","reshape2","stringr"), 
lib = "C:\\Program Files\\Microsoft SQL Server\\MSSQL14.MSSQLSERVER\\R_SERVICES\\library")

# Load the required R packages
library(dplyr)
library(ggplot2)
library(stringr)
library(reshape2)
library(randomForest)

# Set a working directory
setwd( "c:/lendingclub/" )

# Load the data source into a dataframe
data <- read.csv('loan.csv', header=TRUE, sep=",")

# Print the structure of the dataframe
str(data)
dim(data)
names(data)
head(data)

# Check for the NA values
any(is.na(data))

# Copying the content to a new dataframe to play with!
mydata <- data

# Desc column is not so useful
mydata$desc <- NULL

# Remove columns that are majorly NA
junk <- sapply(mydata, function(x) 
{
  c <- 1 - sum(is.na(x)) / length(x)
  c < 0.8
})
mydata <- mydata[,junk==FALSE]

seemsbad <- c("Late (16-30 days)", "Late (31-120 days)", "Default", "Charged Off")

# Add new column "is_bad" to classify loans as good/bad
mydata$is_bad <- ifelse(mydata$loan_status %in% seemsbad, 1,
                    ifelse(mydata$loan_status=="", NA, 0))

# Convert int_rate to float
#mydata$int_rate <- as.numeric(gsub("%", "", mydata$int_rate)) / 100
mydata$int_rate <- str_replace_all(mydata$int_rate, "[%]", "")
mydata$int_rate <- as.numeric(mydata$int_rate)
mydata$revol_util <- str_replace_all(mydata$revol_util, "[%]", "")
mydata$revol_util <- as.numeric(mydata$revol_util)

# Rechecking data structures
str(mydata)

# Find out numeric columns to see the distribution
numeric_cols <- sapply(mydata, is.numeric)

# Turn the data into long format
mydata.lng <- melt(mydata[,numeric_cols], id="is_bad")
head(mydata.lng)

# Plot the distribution of each variable for bad/good 
p <- ggplot(aes(x=value, group=is_bad, colour=factor(is_bad)), data=mydata.lng)

# Quick way to see if we have any good variables
p + geom_density() + facet_wrap(~variable, scales="free")

set.seed(123)

# Split the dataset as 75:25 for train:test
n = nrow(mydata)
trainIndex = sample(1:n, size = round(0.75*n), replace=FALSE)
train = mydata[trainIndex ,]
test = mydata[-trainIndex ,]

# Running a Randomforest model against the training data set
# Just using 3 columns as I am hardly using ~10K data. With original dataset we would find more columns!
model.rf <- randomForest(is_bad==TRUE ~ revol_util + int_rate + total_rec_prncp,
               data=train, na.action=na.omit)

# Using the model predict for the 25% test dataset
prediction <- predict(model.rf, test)
prediction