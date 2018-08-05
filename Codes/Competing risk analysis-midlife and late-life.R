################ Load the packages
library(rms)
library(mi)
library(dplyr)
library(tidyverse)
library(cmprsk)

#########################	Midlife blood pressure
dementia <- read.csv("/home/mpeng/midlife_output_htn/midlife_final",header=F);

#########################	late blood pressure
dementia <- read.csv("/home/mpeng/latelife_output_htn/latelife_final",header=F);

########### add the column names
colnames(dementia) <- c("combid", "sex", "yobyear", "regdate", "exitdate", "diastolic", "systolic", "pulse_bp","age_followup", "count", 
"ahd_date", "bp_status", "ad_indexdate", "ad", 
"vd_indexdate", "vd", "dementia", "dementia_indexdate", "stroke", 
"stroke_indexdate", "mi", "mi_indexdate", "diabete", "MI_new", 
"stroke_new", "ckd", "head", "depression", 
"parkinson", "ad_years", "vd_years", "dementia_years", 
"stroke_years", "mi_years", "smoking_status", "alcohol_status", "BMI_cat", 
"deathdate_new", "death_status","ahdyear","TIA","year_reg","htn_new","htn_before","death_years")

##### Data Prepreration before the analysis
##########	Create new variables
dementia$sex <- ifelse(dementia$sex==1,0,1)

dementia$alcohol_status[dementia$alcohol_status=="\\N"] <- NA
dementia$alcohol_status <- as.character(dementia$alcohol_status)
dementia$alcohol_status <- as.factor(dementia$alcohol_status)

dementia$smoking_status[dementia$smoking_status=="\\N"] <- NA 
dementia$smoking_status <- as.character(dementia$smoking_status)
dementia$smoking_status <- as.factor(dementia$smoking_status)

dementia$BMI_cat[dementia$BMI_cat=="\\N"] <- NA 
dementia$BMI_cat <- as.character(dementia$BMI_cat)
dementia$BMI_cat <- as.factor(dementia$BMI_cat)

dementia$BMI_cat <- relevel(dementia$BMI_cat,ref="Normal")
dementia$smoking_status <- relevel(dementia$smoking_status,ref="N")
dementia$alcohol_status <- relevel(dementia$alcohol_status,ref="N")

########### create a new bp_status
dementia$bp_status <- BP_cat(dementia)
dementia$bp_status <- as.factor(dementia$bp_status)
dementia$bp_status <- relevel(dementia$bp_status, ref = "Normal")

########## Recode the BP status: remove the hypotension and hypertension crisis
dementia$bp_status[dementia$bp_status=="Hypotension"] <- "Normal"
dementia$bp_status[dementia$bp_status=="HTN_crisis"] <- "HTN_S2"
dementia$bp_status <- as.character(dementia$bp_status)
dementia$bp_status <- as.factor(dementia$bp_status)
dementia$bp_status <- relevel(dementia$bp_status, ref = "Normal")

############	change the date variable to character variable
dementia$deathdate_new <- as.character(dementia$deathdate_new)
dementia$ad_indexdate <- as.character(dementia$ad_indexdate)
dementia$diff_reg <- dementia$ahdyear-dementia$year_reg

######################	diastolic and systolic blood pressure
dementia$diastolic_cat <- cut(dementia$diastolic,c(30,80,85,90,300))
table(dementia$diastolic_cat)

dementia$systolic_cat <- cut(dementia$systolic,c(30,120,140,160,300))
table(dementia$systolic_cat)

##########	Categorize the pulse blood pressure
pp_4 <- c(0,50,60,70,200)
dementia$pulsepressure <- cut(dementia$pulse_bp,breaks=pp_4,levels.mean=T, include.lowest = T ,labels = c("Q1","Q2","Q3","Q4"))
table(dementia$pulsepressure,useNA ="always")

summary(dementia$pulse_bp)

######################	Cohort 1 - refine the study cohort
### for midlife, the age_followup must be between 60 and 65; 
### for latelife, the age_followup must be between 70 and 75
dementia	<- subset(dementia,dementia_years > 1 & ahdyear > 1989 & diff_reg > 2 & age_followup > 59)
dementia_new <- dementia

##############  Late-life 
dementia	<- subset(dementia,dementia_years > 1 & ahdyear > 1989 & diff_reg > 2 & age_followup > 69)
dementia_new <- dementia

################### Analysis
############# event type
t1_vd <- table(fstatus,dementia$bp_status,useNA ="ifany")
t1_vd
round(chisq.test(t1_vd,simulate.p.value = T)$p.value,3)
round(prop.table(t1_vd, 2)*100,1)

dementia <- data.frame(dementia,fstatus,ftime)

by_bp <- group_by(dementia, bp_status,fstatus)
age_bp <- summarise(by_bp,
  time_median = round(median(ftime),2),time_25 = round(quantile(ftime,probs=0.25),2),time_75=round(quantile(ftime,probs=0.75),2))
  
data.frame(table(dementia_new$bp_status,dementia_new$pulsepressure,fstatus))



###########################		Vascular dementia
########################### exclude the cases with missing value
dementia_new <- na.omit(dementia_new)

### status of vd
dementia_new$vd <- ifelse(dementia_new$vd_years >20,0,dementia_new$vd)
dementia_new$vd_years <- ifelse(dementia_new$vd_years >20,20,dementia_new$vd_years)
dementia_new$death_status<- ifelse(dementia_new$death_years >20,0,dementia_new$death_status)

#### Check the index of vd is same as the 
Death_new <- dementia_new$deathdate_new ==dementia_new$vd_indexdate
Death <- Death_new+dementia_new$death_status

Death <- ifelse(Death < 2,0,2)
DEM <- Death+dementia_new$vd
DEM <- ifelse(DEM >1,2,DEM)

fstatus <- DEM
ftime <- dementia_new$vd_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,1] <- ifelse(dementia_new$bp_status=="HTN_pre",1,0)
dem_matrix[,2] <- ifelse(dementia_new$bp_status=="HTN_S1",1,0)
dem_matrix[,3] <- ifelse(dementia_new$bp_status=="HTN_S2",1,0)
dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

###	Systolic blood pressure categories
 dem_matrix[,1] <- ifelse(dementia_new$pulsepressure=="Q2",1,0)
 dem_matrix[,2] <- ifelse(dementia_new$pulsepressure=="Q3",1,0)
 dem_matrix[,3] <- ifelse(dementia_new$pulsepressure=="Q4",1,0)

#######	Crude hazard ratio 
z <- crr(ftime,fstatus,dem_matrix[,1:5])
summary(z)
print("with the death as outcome of interest")
z <- crr(ftime,fstatus,dem_matrix[,1:5],failcode=2)
summary(z)

z <- crr(ftime,fstatus,dem_matrix)
print("with death as the outcome of interest")
z <- crr(ftime,fstatus,dem_matrix,failcode=2)
summary(z)

######################		Create the cumulative incidence curve 
fstatus_all <- ifelse(fstatus==0,0,1)
fstatus_vd <- ifelse(fstatus==1,1,0)

surv_all <- survfit(Surv(ftime, fstatus_all)~ dementia_new$bp_status, conf.type="none")
surv_all$time
surv_all$surv

surv_vd <- survfit(Surv(ftime, fstatus_vd)~ dementia_new$bp_status, conf.type="none")
surv_vd$time
surv_vd$n.risk
surv_vd$n.event

##########		For cumulative incidence rate curve
library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix[,1:3])
z.p <- predict(z,rbind(c(0,0,0),c(1,0,0),c(0,1,0),c(0,0,1)))
plot(z.p,lty=1,color=2:4)

table(dementia_new$bp_status,fstatus)

######	Summarize the year of follow up 
bp_status <- dementia$bp_status
dd <- data.frame(bp_status,fstatus,ftime)
by_bp <- group_by(dd, bp_status,fstatus)

delay <- summarise(by_bp, IQR = IQR(ftime),median_age =median(ftime))
delay

##########	multiple imputation to fill in missing values
##########	Adjusted for all covariates, incomplete dataset
###		Genearte new full dataset
index <- c("sex","diastolic","systolic","pulse_bp","age_followup","count","bp_status","ad","dementia",
"diabete","MI_new","stroke_new","ckd","head","depression","parkinson","ad_years","vd_years",
"dementia_years","stroke_years","mi_years","smoking_status","alcohol_status","BMI_cat","death_status")

dementia_MI <- dementia[,index]
library(mi);

###################		How to use the MI package
## Step 1: missing_data.frame  - define the data.frame with missing 
## Step 2: change

###########################	
D_mi <- missing_data.frame(dementia_MI)
IMP_MI <- mi(D_mi)

data.frames_mi <- complete(IMP_MI, 1)
dementia_mi <- data.frames_mi[[1]]

######################		Loop through the iteration 
for (i in 1:5){

dementia_mi <- data.frames_mi[[i]]
dementia_new$BMI_cat <- dementia_mi$BMI_cat
dementia_new$smoking_status <- dementia_mi$smoking_status

###########################		Vascular dementia
########################### exclude the cases with missing value
Death_new <- dementia_new$deathdate_new ==dementia_new$vd_indexdate
Death <- Death_new+dementia_new$death_status
Death <- ifelse(Death < 2,0,2)
DEM <- Death+dementia_new$vd
DEM <- ifelse(DEM >1,2,DEM)

fstatus <- DEM
ftime <- dementia_new$vd_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,1] <- ifelse(dementia_new$bp_status=="HTN_pre",1,0)
dem_matrix[,2] <- ifelse(dementia_new$bp_status=="HTN_S1",1,0)
dem_matrix[,3] <- ifelse(dementia_new$bp_status=="HTN_S2",1,0)
dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix)

print(summary(z))
print ("########################################  Vascular dementia with BP_status ")
print(i)
}



print (
"
##########################################################################################################
##########################################################################################################
##########################################################################################################
"
)

for (i in 2:5){

dementia_mi <- data.frames_mi[[i]]
dementia_new$BMI_cat <- dementia_mi$BMI_cat
dementia_new$smoking_status <- dementia_mi$smoking_status

###########################		Vascular dementia
########################### exclude the cases with missing value
Death_new <- dementia_new$deathdate_new ==dementia_new$vd_indexdate
Death <- Death_new+dementia_new$death_status
Death <- ifelse(Death < 2,0,2)
DEM <- Death+dementia_new$vd
DEM <- ifelse(DEM >1,2,DEM)
fstatus <- DEM
ftime <- dementia_new$vd_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

###	Systolic blood pressure categories
dem_matrix[,1] <- ifelse(dementia_new$systolic_cat=="(120,140]",1,0)
dem_matrix[,2] <- ifelse(dementia_new$systolic_cat=="(140,160]",1,0)
dem_matrix[,3] <- ifelse(dementia_new$systolic_cat=="(160,300]",1,0)

library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix)

print(summary(z))
print ("########################################  Vascular dementia with systolic_cat status ")
print(i)
}


print (
"
##########################################################################################################
##########################################################################################################
##########################################################################################################
"
)

for (i in 2:5){

dementia_mi <- data.frames_mi[[i]]
dementia_new$BMI_cat <- dementia_mi$BMI_cat
dementia_new$smoking_status <- dementia_mi$smoking_status

###########################		Vascular dementia
########################### exclude the cases with missing value
Death_new <- dementia_new$deathdate_new ==dementia_new$vd_indexdate
Death <- Death_new+dementia_new$death_status
Death <- ifelse(Death < 2,0,2)
DEM <- Death+dementia_new$vd
DEM <- ifelse(DEM >1,2,DEM)

fstatus <- DEM
ftime <- dementia_new$vd_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

###	Systolic blood pressure categories
dem_matrix[,1] <- ifelse(dementia_new$diastolic_cat=="(80,85]",1,0)
dem_matrix[,2] <- ifelse(dementia_new$diastolic_cat=="(85,90]",1,0)
dem_matrix[,3] <- ifelse(dementia_new$diastolic_cat=="(90,300]",1,0)

library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix)

print(summary(z))
print ("########################################  Vascular dementia with diastolic_cat status ")
print(i)
}



####### Create Tables for results presentation
####################################	Table 1- clinical characteristics
table1 <-  matrix(0,22,5)
t1_sex <- table(dementia$sex,dementia$bp_status,useNA ="ifany")
t1_sex
table1[1,5] <- round(chisq.test(t1_sex,simulate.p.value = T)$p.value,3)
t1_sex <- round(prop.table(t1_sex, 2)*100,1)
t1_sex <- data.frame(t1_sex)
t1_sex<- matrix(t1_sex$Freq,2,4)
table1[1,1:4] <- t1_sex[1,]


t1_smoking<- table(dementia$smoking_status,dementia$bp_status,useNA="ifany")
table1[3,5] <- round(chisq.test(t1_smoking,simulate.p.value = T)$p.value,3)
t1_smoking <- round(prop.table(t1_smoking, 2)*100,1)
t1_smoking <- data.frame(t1_smoking)
t1_smoking <- matrix(t1_smoking$Freq,4,4)
table1[3:6,1:4] <- t1_smoking[c(1,2,3,4),]

t1_alcohol<- table(dementia$alcohol_status,dementia$bp_status,useNA="ifany")
table1[8,5] <- round(chisq.test(t1_alcohol,simulate.p.value = T)$p.value,3)
t1_alcohol <- round(prop.table(t1_alcohol, 2)*100,1)
t1_alcohol <- data.frame(t1_alcohol)
t1_alcohol <- matrix(t1_alcohol$Freq,4,4)
table1[8:11,1:4] <- t1_alcohol[c(1,2,3,4),]

t1_BMI_cat<- table(dementia$BMI_cat,dementia$bp_status,useNA="ifany")
table1[13,5] <- round(chisq.test(t1_BMI_cat,simulate.p.value = T)$p.value,3)
t1_BMI_cat <- round(prop.table(t1_BMI_cat, 2)*100,1)
t1_BMI_cat <- data.frame(t1_BMI_cat)
t1_BMI_cat <- matrix(t1_BMI_cat$Freq,4,4)
table1[13:16,1:4] <- t1_BMI_cat[c(1,3,2,4),]

t1_diabete <- table(dementia$diabete,dementia$bp_status,useNA ="ifany")
t1_diabete
table1[17,5] <- round(chisq.test(t1_diabete,simulate.p.value = T)$p.value,3)
t1_diabete <- round(prop.table(t1_diabete, 2)*100,1)
t1_diabete <- data.frame(t1_diabete)
t1_diabete<- matrix(t1_diabete$Freq,2,4)
table1[17,1:4] <- t1_diabete[2,]

t1_stroke_new <- table(dementia$stroke_new,dementia$bp_status,useNA ="ifany")
t1_stroke_new
table1[18,5] <- round(chisq.test(t1_stroke_new,simulate.p.value = T)$p.value,3)
t1_stroke_new <- round(prop.table(t1_stroke_new, 2)*100,1)
t1_stroke_new <- data.frame(t1_stroke_new)
t1_stroke_new<- matrix(t1_stroke_new$Freq,2,4)
table1[18,1:4] <- t1_stroke_new[2,]
######	head injury
t1_head <- table(dementia$head,dementia$bp_status,useNA ="ifany")
t1_head
table1[19,5] <- round(chisq.test(t1_head,simulate.p.value = T)$p.value,3)
t1_head <- round(prop.table(t1_head, 2)*100,1)
t1_head <- data.frame(t1_head)
t1_head <- matrix(t1_head$Freq,2,4)
table1[19,1:4] <- t1_head[2,]

##### Depression
t1_depression <- table(dementia$depression,dementia$bp_status,useNA ="ifany")
t1_depression
table1[20,5] <- round(chisq.test(t1_depression,simulate.p.value = T)$p.value,3)
t1_depression <- round(prop.table(t1_depression, 2)*100,1)
t1_depression <- data.frame(t1_depression)
t1_depression<- matrix(t1_depression$Freq,2,4)
table1[20,1:4] <- t1_depression[2,]

####### parkinson

t1_parkinson <- table(dementia$parkinson,dementia$bp_status,useNA ="ifany")
t1_parkinson
table1[21,5] <- round(chisq.test(t1_parkinson,simulate.p.value = T)$p.value,3)
t1_parkinson <- round(prop.table(t1_parkinson, 2)*100,1)
t1_parkinson <- data.frame(t1_parkinson)
t1_parkinson<- matrix(t1_parkinson$Freq,2,4)
table1[21,1:4] <- t1_parkinson[2,]

####### TIA

t1_TIA <- table(dementia$TIA,dementia$bp_status,useNA ="ifany")
t1_TIA
table1[22,5] <- round(chisq.test(t1_TIA,simulate.p.value = T)$p.value,3)
t1_TIA <- round(prop.table(t1_TIA, 2)*100,1)
t1_TIA <- data.frame(t1_TIA)
t1_TIA<- matrix(t1_TIA$Freq,2,4)
table1[22,1:4] <- t1_TIA[2,]

##### Final table1 exclude the alcohol_status

table1[-8:11,]

library(dplyr)

by_bp <- group_by(dementia, bp_status)
delay <- summarise(by_bp, IQR = IQR(age_followup),median_age =median(age_followup))

##########	Number of BP meausrement
dementia$count_binary <- ifelse(dementia$count > 1, 1,0)

t1_count <- table(dementia$count_binary,dementia$bp_status,useNA ="ifany")
round(chisq.test(t1_count,simulate.p.value = T)$p.value,3)
round(prop.table(t1_count, 2)*100,1)
 #### function to extract hte 

IQR <- function(data){
median = round(median(data),1)
p25=round(quantile(data,0.25),1)
p75=round(quantile(data,0.75),1)
IQR_output <- paste(median,"(",p25,",",p75,")",sep="")
return(IQR_output)
}


### proprotion of hypertension diagnosis
htn <- dementia$htn_new+dementia$htn_before
table(htn)
table(htn,dementia$bp_status)
prop.table(table(htn,dementia$bp_status),margin=2)


##########################		subanalysis on the risk of Stroke
dementia_new <- subset(dementia,stroke_years >0)
Death_new <- dementia_new$deathdate_new ==dementia_new$stroke_indexdate
Death <- Death_new+dementia_new$death_status

Death <- ifelse(Death < 2,0,2)

DEM <- Death+dementia_new$stroke
DEM <- ifelse(DEM >1,2,DEM)

fstatus <- DEM
ftime <- dementia_new$stroke_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,1] <- ifelse(dementia_new$bp_status=="HTN_pre",1,0)
dem_matrix[,2] <- ifelse(dementia_new$bp_status=="HTN_S1",1,0)
dem_matrix[,3] <- ifelse(dementia_new$bp_status=="HTN_S2",1,0)
dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

dem_matrix <- dem_matrix[,-11]

library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix)

print(summary(z))
print ("########################################  Vascular dementia with diastolic_cat status ")
print(i)

######################		Loop through the iteration 

for (i in 1:5){
dementia_new <- dementia
dementia_mi <- data.frames_mi[[i]]
dementia_new$BMI_cat <- dementia_mi$BMI_cat
dementia_new$smoking_status <- dementia_mi$smoking_status

###########################		Vascular dementia
########################### exclude the cases with missing value

dementia_new <- subset(dementia_new,stroke_years >0)

Death_new <- dementia_new$deathdate_new ==dementia_new$stroke_indexdate
Death <- Death_new+dementia_new$death_status

Death <- ifelse(Death < 2,0,2)
DEM <- Death+dementia_new$stroke
DEM <- ifelse(DEM >1,2,DEM)

fstatus <- DEM
ftime <- dementia_new$stroke_years

N <- dim(dementia_new)[1]
dem_matrix <- matrix(0,N,15)

dem_matrix[,1] <- ifelse(dementia_new$bp_status=="HTN_pre",1,0)
dem_matrix[,2] <- ifelse(dementia_new$bp_status=="HTN_S1",1,0)
dem_matrix[,3] <- ifelse(dementia_new$bp_status=="HTN_S2",1,0)
dem_matrix[,4] <- dementia_new$sex
dem_matrix[,5] <- dementia_new$age_followup
dem_matrix[,6] <- dementia_new$diabete
dem_matrix[,7] <- ifelse(dementia_new$smoking_status=="Y",1,0)
dem_matrix[,8] <- ifelse(dementia_new$smoking_status=="D",1,0)
dem_matrix[,9] <- ifelse(dementia_new$BMI_cat=="Overweight",1,0)
dem_matrix[,10] <- ifelse(dementia_new$BMI_cat=="Obesity",1,0)
dem_matrix[,11] <- dementia_new$stroke_new
dem_matrix[,12] <- dementia_new$head
dem_matrix[,13] <- dementia_new$depression
dem_matrix[,14] <- dementia_new$parkinson
dem_matrix[,15] <- dementia_new$TIA

dem_matrix <- dem_matrix[,-11]
library(cmprsk)
z <- crr(ftime,fstatus,dem_matrix)

print(summary(z))
print ("########################################  stroke with BP_status ")
print(i)
}
