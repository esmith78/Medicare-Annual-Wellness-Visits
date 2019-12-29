# Analytics Exercise Data
# Preload and Load Processing
# Erica Smith
# July 13, 2019

# Enable packages
library(DBI)
library(RMySQL)
library(Hmisc)
library(corrplot)
library(data.table)

# Set global options
options(scipen = 999, stringsAsFactors = FALSE)

# Connect to database
con <- dbConnect(MySQL(),
                 user = 'root',
                 password = 'UC2010rn',
                 dbname = 'aledade',
                 host = 'mydbinstance.cmjefngzerfh.us-east-2.rds.amazonaws.com')

# Read in data
tmp_pc <- dbReadTable(con,'tmp_pc')

# Q1. Unique practices
q1 <- as.data.frame(as.numeric(length(unique(tmp_pc$group_practice))))
q1$Metric <- 'Primary Care Practices in Delaware'
q1 <- q1[,c(2:1)]
colnames(q1)[2] <- 'Unique Count'

# Q2. Practice with the most awv's
p <- aggregate(awv_count ~ group_practice + practice_name, data= tmp_pc, FUN = sum)
p <- p[order(-p$awv_count),]
q2 <- p[1,]
colnames(q2) <- c("Group Practice ID","Practice Name","Annual Wellness Visit Count")

# Q3. Opportunity analysis
q3_data <- dbGetQuery(con,
              "SELECT
                t1.group_practice,
                t1.practice_name,
                t1.npi,
                t2.nppes_provider_last_org_name AS last_name,
                t2.nppes_provider_first_name AS first_name,
                t2.nppes_credentials,
                t2.provider_type,
                SUM(t1.total_unique_benes) AS total_unique_benes,
                IFNULL(SUM(t1.awv_count),0) AS awv_count,
                IFNULL(ROUND(SUM(t1.awv_count) / SUM(t1.total_unique_benes),2),0) AS awv_prcnt
              FROM
                tmp_pc t1
                LEFT JOIN physician_supplier_agg t2 ON(t1.npi = t2.npi)
              GROUP BY
                1,2,3,4,5,6,7
              ORDER BY
                1 ASC, 10 DESC")

## Part 1: Performance by Provider within Practice
q3_1 <- subset(q3_data,!is.na(q3_data$total_unique_benes) | q3_data$total_unique_benes > 0)

colnames(q3_1) <- c("Group Practice","Practice Name","NPI","Last Name","First Name","Credential","Provider Type","Total Unique Beneficiaries","Annual Wellness Visit Count","Annual Wellness Visit Percent")

## Part 2: Performance by Practice
q3_2 <- aggregate(. ~ group_practice + practice_name, data = q3_data[,c(1:2,8:9)], FUN = sum)
q3_2$awv_prcnt <- round(q3_2$awv_count/q3_2$total_unique_benes,2)

# Calculate coefficient of variation measuring degree to which performance varies within practice
q3_mean <- aggregate(`Annual Wellness Visit Percent` ~ `Group Practice`, data = q3_1, FUN = mean)
q3_sd <- aggregate(`Annual Wellness Visit Percent` ~ `Group Practice`, data = q3_1, FUN = sd)
q3_cv <- merge(q3_mean,q3_sd, by = 'Group Practice')
colnames(q3_cv)[2:3] <- c("awv_prcnt_mean","awv_prcnt_sd")
q3_cv$awv_cv <- round(q3_cv$awv_prcnt_sd / q3_cv$awv_prcnt_mean,2)

q3_2 <- merge(q3_2,q3_cv[,c(1,4)], by.x = 'group_practice', by.y = 'Group Practice')

colnames(q3_2) <- c("Group Practice","Practice Name","Total Unique Beneficiaries","Annual Wellness Visit Count","Annual Wellness Visit Percent","Annual Wellness Visit Coefficient of Variation")

## Part 3: Create correlation matrix and look at correlation with awv percent
cm <-(rcorr(as.matrix(tmp_pc[4:9])))
cc <- as.data.frame(cm$r)[3,c(1,4:6)]
pv <- as.data.frame(cm$P)[3,c(1,4:6)]
q3_3 <- as.data.frame(t(rbind(cc,pv)))
colnames(q3_3) <- c('corr_coeff','p_value')
q3_3 <- round(q3_3,2)
q3_3 <- cbind(c("Total Unique Beneficiaries","Beneficiary Average Age","Beneficiary Average Risk Score","Percent of Beneficaries NonWhite"),q3_3)
colnames(q3_3) <- c("Metric","Correlation Coefficient","P Value")

# Clean up
rm(cc,p,pv,cm,q3,q3_mean,q3_sd,q3_cv,q3_data,tmp_pc)

# Output results to workbook
require(openxlsx)

output<- list("Q1- Practice Count" = q1,
       "Q2- Top AWV Practice" = q2,
       "Q3- AWV Performance by Provider" = q3_1,
       "Q3- AWV Perfomance by Practice" = q3_2,
       "Q3- AWV Correlation Analysis" = q3_3)

setwd("/Users/ericabadger/Desktop/Aledade/Analytics Exercise/Output/")

write.xlsx(output,"Smith_Analytic_Exercise_Results.xlsx")

# Disconnect from database
dbDisconnect(con)



