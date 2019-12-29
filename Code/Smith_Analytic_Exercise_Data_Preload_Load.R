# Analytics Exercise Data
# Preload and Load Processing
# Erica Smith
# July 11, 2019

# Set working directory
setwd("/Users/ericabadger/Desktop/Aledade/Input Data/")

# Set global options
options(scipen = 999, stringsAsFactors = FALSE)

# Read in data, and perform pre-load quality checks

### PHYSICIAN COMPARE ###
physician_compare <- read.csv("physician_compare.csv")

# Check for nulls
pc_null <- as.data.frame(sapply(physician_compare,function(x) sum(is.na(x))), stringsAsFactors = FALSE)

# Check data types
pc_dt <- as.data.frame(sapply(physician_compare, class))
colnames(pc_dt) <- 'data_type'

# Correct data types
pc_text <- c('npi','pac_id','secondary_specialty_4','group_practice_pac_id','zip_code','phone_number','hospital_affiliation_ccn_1','hospital_affiliation_ccn_2','hospital_affiliation_ccn_3','hospital_affiliation_ccn_4','hospital_affiliation_ccn5')

for (i in pc_text) {
  physician_compare[,c(i)] <- as.character(physician_compare[,c(i)])
}

### PHYSICIAN SUPPLIER AGG ###
physician_supplier_agg <- read.csv("physician_supplier_agg.csv")

# Check for nulls
psa_null <- as.data.frame(sapply(physician_supplier_agg,function(x) sum(is.na(x))))

# Check data types
psa_dt <- as.data.frame(sapply(physician_supplier_agg, class))
colnames(psa_dt) <- 'data_type'

# Correct data types
psa_text <- c('npi','nppes_provider_zip','drug_suppress_indicator')

for (i in psa_text) {
  physician_supplier_agg[,c(i)] <- as.character(physician_supplier_agg[,c(i)])
}

### PHYSICIAN SUPPLIER HCPCS ###
physician_supplier_hcpcs <- read.csv("physician_supplier_hcpcs.csv")

# Check for nulls
psh_null <- as.data.frame(sapply(physician_supplier_hcpcs,function(x) sum(is.na(x))))

# Check data types
psh_dt <- as.data.frame(sapply(physician_supplier_hcpcs, class))
colnames(psh_dt) <- 'data_type'

# Correct data types
psh_text <- c('npi','nppes_provider_zip')

for (i in psh_text) {
  physician_supplier_hcpcs[,c(i)] <- as.character(physician_supplier_hcpcs[,c(i)])
}

### LOAD TO DB ###

# Enable packages
library(DBI)
library(RMySQL)

# Connect to database
con <- dbConnect(MySQL(),
                 user = 'root',
                 password = 'UC2010rn',
                 dbname = 'aledade',
                 host = 'mydbinstance.cmjefngzerfh.us-east-2.rds.amazonaws.com')

# Load tables
dbWriteTable(con,"physician_compare",physician_compare)
dbWriteTable(con,"physician_supplier_agg",physician_supplier_agg)
dbWriteTable(con,"physician_supplier_hcpcs",physician_supplier_hcpcs)

# Disconnect from database
dbDisconnect(con)
