######################################
## PhenotypeChangesInVocabUpdate code to run ##
######################################

#remotes::install_github("OHDSI/PhenotypeChangesInVocabUpdate")
#remotes::install_github("OHDSI/DatabaseConnector")


library (dplyr)
library (openxlsx)
library (readr)
library (tibble)
library (DatabaseConnector)
#library (PhenotypeChangesInVocabUpdate)

#set the BaseUrl of your Atlas instance
#baseUrl <- "https://yourSecureAtlas.ohdsi.org/"

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")


#specify cohorts you want to run the comparison for, in my example I import it from the CSV with one column containing cohortIds
#the example file is located in "~/PhenotypeChangesInVocabUpdate/extras/Cohorts.csv"
# also you can define the cohorts as vector directly:
#cohorts <-c(12822, 12824, 12825)

#comment this if you want to run against the list above
cohortsDF <- readr::read_delim("~/PhenotypeChangesInVocabUpdate/extras/Cohorts.csv", delim = "\t", show_col_types = FALSE)
cohorts <-cohortsDF[[1]]

#excluded nodes is a text string with nodes you want to exclude from the analysis, it's set to 0 by default
# for example now some CPT4 and HCPCS are mapped to Visit concepts and we didn't implement this in the ETL,
#so we don't want these in the analysis (note, the tool doesn't look at the actual CDM, but on the mappings in the vocabulary)
#this way, the excludedNodes are defined in this way:
#excludedNodes <-"9201, 9202, 9203"


#set connectionDetails,
#you can use keyring to store your credentials,
#see how to configure keyring to use with the example below in ~/PhenotypeChangesInVocabUpdate/extras/KeyringSetup.R

# you can also define connectionDetails directly, see the DatabaseConnector documentation https://ohdsi.github.io/DatabaseConnector/

 # connectionDetailsCC = DatabaseConnector::createConnectionDetails(
 #   dbms = keyring::key_get("YourDatabase", "dbms" ),
 #   connectionString = keyring::key_get("YourDatabase", "connectionString"),
 #   user = keyring::key_get("YourDatabase", "username"),
 #   password = keyring::key_get("YourDatabase", "password" )
 # )
 #
 # connectionDetailsVocab = DatabaseConnector::createConnectionDetails(
 #   dbms = keyring::key_get("YourDatabase", "dbms" ),
 #   connectionString = keyring::key_get("YourDatabase", "connectionString"),
 #   user = keyring::key_get("YourDatabase", "username"),
 #   password = keyring::key_get("YourDatabase", "password" )
 # )


newVocabSchema <-'v20230116' #schema containing a new vocabulary version
oldVocabSchema <-'v20220409' #schema containing an older vocabulary version
resultSchema <-'jnj_network' #schema containing Achilles results

excludedVisitNodes <- "9202, 2514435,9203,2514436,2514437,2514434,2514433,9201"

#get the concept count table
conn <- DatabaseConnector::connect(connectionDetailsCC)

achillesResultConceptCount <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                                         "select * from jnj_network.achilles_result_concept_count where concept_id <= 2147483647" # really big numbers excluded
                                                         , snakeCaseToCamelCase = F)

DatabaseConnector::disconnect(conn)


#upload it to the vocabulary server
conn <- DatabaseConnector::connect(connectionDetailsVocab)

DatabaseConnector::insertTable(connection = conn,
                               tableName = "#achilles_Result_CC",
                               data = achillesResultConceptCount,
                               dropTableIfExists = TRUE,
                               createTable = TRUE,
                               tempTable = TRUE,
                               bulkLoad = TRUE)



#create the dataframe with concept set expressions using the getNodeConcepts function
Concepts_in_cohortSet<-getNodeConcepts(cohorts, baseUrl)

#resolve concept sets, compare the outputs on different vocabulary versions, write results to the Excel file
#for Redshift ask your administrator for a key for bulk load, since the function uploads the data to the database
resultToExcel(connectionDetailsVocab = connectionDetailsVocab,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              excludedNodes = excludedVisitNodes
             # resultSchema = resultSchema # removed since concept count table is exported from another database
              )

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))
