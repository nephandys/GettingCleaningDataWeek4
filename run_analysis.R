library(data.table)
library(dplyr)

path <- getwd()

url <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
file <- 'Dataset.zip'
if(!file.exists(file)) {
        download.file(url,file)
}
data <- 'UCI HAR Dataset'
if(!file.exists(data)) {
        unzip(file)
}

# read the subjects 
dtSubjectectTrain <- data.table(read.table(file.path(path, data, 'train', 'subject_train.txt')))
dtSubjectectTest <- data.table(read.table(file.path(path, data, 'test', 'subject_test.txt')))
dtSubject <- rbind(dtSubjectectTrain, dtSubjectectTest)
names(dtSubject) <- c('Subject')
remove(dtSubjectectTrain,dtSubjectectTest)

# read the activities
dtActivityivityTrain <- data.table(read.table(file.path(path, data, 'train','Y_train.txt')))
dtActivityivityTest <- data.table(read.table(file.path(path,data,'test','Y_test.txt')))
dtActivity <- rbind(dtActivityivityTrain,dtActivityivityTest)
names(dtActivity) <- c('Activity')
remove(dtActivityivityTrain,dtActivityivityTest)

# combine the subjects and the activities
dtSubject <- cbind(dtSubject,dtActivity)
remove(dtActivity)

# read the feature data
dtTrain <- data.table(read.table(file.path(path,data,'train','X_train.txt')))
dtTest <- data.table(read.table(file.path(path,data,'test','X_test.txt')))
dt <- rbind(dtTrain,dtTest)
remove(dtTrain,dtTest)

# merge subject, activity, and feature into a single table
dt <- cbind(dtSubject,dt)

# set the key to subject/activity
setkey(dt,Subject,Activity)
remove(dtSubject)

# read each of the feature names and get only the std and mean features
dtFeatures <- data.table(read.table(file.path(path,data,'features.txt'))) 
names(dtFeatures) <- c('ftNum','ftName')
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)",ftName)]
dtFeatures$ftCode <- paste('V', dtFeatures$ftNum, sep = "")

# select only the filtered features 
dt <- dt[,c(key(dt), dtFeatures$ftCode),with=F]

# rename each of the columns
setnames(dt, old=dtFeatures$ftCode, new=as.character(dtFeatures$ftName))

# read the activity names
dtActivityNames <- data.table(read.table(file.path(path, data, 'activity_labels.txt')))
names(dtActivityNames) <- c('Activity','ActivityName')
dt <- merge(dt,dtActivityNames,by='Activity')
remove(dtActivityNames)

# merge in ftName
dtTidy <- dt %>% group_by(Subject, ActivityName) %>% summarise_each(funs(mean))

dtTidy$Activity <- NULL

# start separating out featName column to separate columns
names(dtTidy) <- gsub('^t', 'time', names(dtTidy))
names(dtTidy) <- gsub('^f', 'frequency', names(dtTidy))
names(dtTidy) <- gsub('Acc', 'Accelerometer', names(dtTidy))
names(dtTidy) <- gsub('Gyro','Gyroscope', names(dtTidy))
names(dtTidy) <- gsub('mean[(][)]','Mean',names(dtTidy))
names(dtTidy) <- gsub('std[(][)]','Std',names(dtTidy))
names(dtTidy) <- gsub('-','',names(dtTidy))


write.table(dtTidy, file.path(path, 'tidyData.txt'), row.names=FALSE)