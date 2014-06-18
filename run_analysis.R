##First we have to load the packages that we need##
packages <- c("data.table","reshape2","plyr")
sapply(packages, require, character.only = TRUE, quietly = TRUE)
##Set the working directory
getwd("C:/Users/Alexandra/coursera-getting-and-cleaning-data")
##Read the train and test data
xTrain = read.table("./train/X_train.txt")
xTrain = as.data.table(xTrain)
yTrain = read.table("./train/y_train.txt")
yTrain = as.data.table(yTrain)
subjectTrain = read.table("./train/subject_train.txt")
subjectTrain= as.data.table(subjectTrain)

xTest = read.table("./test/X_test.txt")
xTest = as.data.table(xTest)
yTest = read.table("./test/y_test.txt")
yTest = as.data.table(yTest)
subjectTest = read.table("./test/subject_test.txt")
subjectTest = as.data.table(subjectTest)

##merge the training and test sets 
## First of all to concatenate all the data tables.
Subject <- rbind(subjectTrain,subjectTest)
setnames(Subject,"V1","subject")

Activity <-rbind(yTrain,yTest)
setnames(Activity,"V1","activityNum")

##Convert the data frame to a data table and merge the training and test set
fileToDataTable <- function(f) 
  df <- read.table(f)
  dT <- data.table(df)
dtTrain<- fileToDataTable("./train/X_train.txt")
dtTrain = as.data.table(dtTrain)
dtTest <- fileToDataTable("./test/X_test.txt")
dtTest = as.data.table(dtTest)
dataTable <- rbind(dtTrain,dtTest)

##Now we are going to mrge the columns
Subject <- cbind(Subject,Activity)
dataTable <- cbind(Subject,dataTable)
## And setthe key
setkey(dataTable,subject,activityNum)

##Next step for extracting the mean and standard deviation
##Use the features.text file
Features <- read.table("./features.txt")
Features <- as.data.table(Features)
setnames(Features, names(Features), c("featureNum", "featureName"))
##only measurements for the mean and standard deviation
Features <- Features[grepl("mean\\(\\)|std\\(\\)", featureName)]
##convert the column numbers in a vector of variable names in our 
## data table
Features$featureCode <- Features[, paste0("V", featureNum)]
##subset the variables
select <- c(key(dataTable), Features$featureCode)

dataTable <- dataTable[, select, with = FALSE]

## Now read activity_labels.txt
ActivityLabels <- read.table("./activity_labels.txt")
ActivityLabels <- as.data.table(ActivityLabels)
setnames(ActivityLabels, names(ActivityLabels), c("activityNum", "activityName"))
##Merge activity labels
dataTable <- merge(dataTable, ActivityLabels, by = "activityNum", all.x = TRUE)
##ActivityName is a key
setkey(dataTable, subject, activityNum, activityName)
##Melt the data table to reshape it from a short and wide format to a tall and narrow format.
dataTable <- data.table(melt(dataTable, key(dataTable), variable.name = "featureCode"))
##Merge activity name
dataTable <- merge(dataTable, Features[, list(featureNum, featureCode, featureName)], by = "featureCode", 
            all.x = TRUE)

## Create new variables as factor
dataTable$Activity <- factor(dataTable$activityName)
dataTable$feature <- factor(dataTable$featureName)
grepthis <- function(regex) {
  grepl(regex, dataTable$feature)
}
## Features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("^t"), grepthis("^f")), ncol = nrow(y))
dataTable$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
x <- matrix(c(grepthis("Acc"), grepthis("Gyro")), ncol = nrow(y))
dataTable$featInstrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepthis("BodyAcc"), grepthis("GravityAcc")), ncol = nrow(y))
dataTable$featAcceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
x <- matrix(c(grepthis("mean()"), grepthis("std()")), ncol = nrow(y))
dataTable$featVariable <- factor(x %*% y, labels = c("Mean", "SD"))
## Features with 1 category
dataTable$featJerk <- factor(grepthis("Jerk"), labels = c(NA, "Jerk"))
dataTable$featMagnitude <- factor(grepthis("Mag"), labels = c(NA, "Magnitude"))
## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol = nrow(y))
dataTable$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))

##Create a tidy data set
setkey(dataTable, subject, Activity, featDomain, featAcceleration, featInstrument, 
       featJerk, featMagnitude, featVariable, featAxis)
tableTidy <- dataTable[, list(count = .N, average = mean(value)), by = key(dataTable)]

write.table(tableTidy,"./tableTidy.txt")
