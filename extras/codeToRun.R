######################################
## PhenotypeChangesInVocabUpdate code to run ##
######################################

library (dplyr)
library (openxlsx)
library (readr)
library (tibble)
library (PhenotypeChangesInVocabUpdate)

#set the BaseUrl of your Atlas instance
#baseUrl <- "https://yourSecureAtlas.ohdsi.org/"

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")


#specify cohorts you want to run the comparison for, in my example I import it from the CSV with one column containing cohortIds
# or you can define it as a vector directly: cohorts <-c(12822, 12824, 12825)
cohortsDF <- readr::read_delim("~/CohortChangeInVocabUpdate/Cohorts.csv", delim = "\t", show_col_types = FALSE)
cohorts <-cohortsDF[[1]]

#excluded nodes is a text string with nodes you want to exclude from the analysis, it's set to 0 by default
# for example now some CPT4 and HCPCS are mapped to Visit concepts and we didn't implement this in the ETL,
#so we don't want these in the analysis (note, the tool doesn't look at the actual CDM, but on the mappings in the vocabulary)
#this way, the excludedNodes are defined in this way:
#excludedNodes <-"9201, 9202, 9203"

connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = keyring::key_get("ohdaProdCCAE", "dbms" ),
  connectionString = keyring::key_get("ohdaProdCCAE", "connectionString"),
  user = keyring::key_get("ohdaProdCCAE", "username"),
  password = keyring::key_get("ohdaProdCCAE", "password" )
)

newVocabSchema <-'cdm_truven_ccae_v2324' #schema containing a new vocabulary version
oldVocabSchema <-'cdm_truven_ccae_v2182' #schema containing an older vocabulary version
resultSchema <-'results_truven_ccae_v2435' #schema containing Achilles results

#create the dataframe with concept set expressions using the getNodeConcepts function
Concepts_in_cohortSet<-getNodeConcepts(cohorts, baseUrl)

#resolve concept sets, compare the outputs on different vocabulary versions, write results to the Excel file
resultToExcel(connectionDetails = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              resultSchema = resultSchema)

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))
