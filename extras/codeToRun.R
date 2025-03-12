######################################
## PhenotypeChangesInVocabUpdate code to run ##
######################################

# install libraries, if not installed
#remotes::install_github("OHDSI/PhenotypeChangesInVocabUpdate")
#remotes::install_github("OHDSI/DatabaseConnector")

library (dplyr)
library (openxlsx)
library (readr)
library (tibble)
library (DatabaseConnector)
library (PhenotypeChangesInVocabUpdate)

#set the BaseUrl of your Atlas instance
#baseUrl <- "https://yourSecureAtlas.ohdsi.org/"

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")


# specify cohorts you want to run the comparison for
# you can define the cohorts as vector:
cohorts <-c(1, 2, 3)

#excluded nodes is a text string with nodes you want to exclude from the analysis, it's set to 0 by default
# for example now some CPT4 and HCPCS are mapped to Visit concepts and we didn't implement this in the ETL,
#so we don't want these in the analysis (note, the tool doesn't look at the actual CDM, but on the mappings in the vocabulary)
#this way, the excludedNodes are defined in this way:
excludedVisitNodes <- "9202, 2514435,9203,2514436,2514437,2514434,2514433,9201"

#you can restrict the output by using specific source vocabularies (only those that exist in your data as source concepts)
includedSourceVocabs <- "'ICD10', 'ICD10CM', 'CPT4', 'HCPCS', 'NDC', 'ICD9CM', 'ICD9Proc', 'ICD10PCS', 'ICDO3', 'JMDC'"



#set connectionDetails,
#you can use keyring to store your credentials,
#see how to configure keyring to use with the example below in ~/PhenotypeChangesInVocabUpdate/extras/KeyringSetup.R

# you can also define connectionDetails directly, see the DatabaseConnector documentation https://ohdsi.github.io/DatabaseConnector/

# connectionDetailsVocab = DatabaseConnector::createConnectionDetails(
#   dbms = keyring::key_get("YourDatabase", "dbms" ),
#   connectionString = keyring::key_get("YourDatabase", "connectionString"),
#   user = keyring::key_get("YourDatabase", "username"),
#   password = keyring::key_get("YourDatabase", "password" )
# )

#specify schemas with vocabulary versions you want to compare
newVocabSchema <-'v20240229' #schema containing a new vocabulary version
oldVocabSchema <-'v20220909' #schema containing an older vocabulary


#get the concept count table
#see to generate here
# https://github.com/OHDSI/WebAPI/blob/master/src/main/resources/ddl/achilles/achilles_result_concept_count.sql
# and store it in the same database as the Vocabulary tables, please specify schema as result schema

resultSchema <-'scratch_ddymshyt' #schema containing Achilles results

# set schema to which temp tables should be written
tempEmulationSchema <- resultSchema

#create the dataframe with concept set expressions using the getNodeConcepts function
Concepts_in_cohortSet<-getNodeConcepts(cohorts, baseUrl)

#resolve concept sets, compare the outputs on different vocabulary versions, write results to the Excel file
#for Redshift ask your administrator for a key for bulk load, since the function uploads the data to the database
resultToExcel(connectionDetails = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              resultSchema = resultSchema,
              includedSourceVocabs = includedSourceVocabs,
              tempEmulationSchema = tempEmulationSchema,
              outputFileName = "cs_changes",
              outputFolder = "output")

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))
