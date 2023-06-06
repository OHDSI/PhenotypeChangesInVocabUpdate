######################################
## PhenotypeChangesVocab code to run ##
######################################

library (dplyr)
library (openxlsx)
library (readr)
library (tibble)

#set the BaseUrl of your Atlas instance
#baseUrl <- "https://yourSecureAtlas.ohdsi.org/"

#if packages are not installed, please install
#install.packages("SqlRender")
#install.packages("DatabaseConnector")

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")


#specify cohorts you want to run the comparison for, in my example I import it from the CSV with one column containing cohortIds
# or you can define it as a vector directly: cohorts <-c(12822, 12824, 12825)
cohortsDF <- readr::read_delim("~/CohortChangeInVocabUpdate/Cohorts2.csv", delim = "\t", show_col_types = FALSE)
cohorts <-cohortsDF[[1]]

#exclude nodes
#excludedNodes <-"9201, 9202, 9203"

connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = keyring::key_get("ohdaProdCCAE", "dbms" ),
  connectionString = keyring::key_get("ohdaProdCCAE", "connectionString"),
  user = keyring::key_get("ohdaProdCCAE", "username"),
  password = keyring::key_get("ohdaProdCCAE", "password" )
)

workSchema <-'scratch_ddymshyt' # schema where you're allowed to create tables
newVocabSchema <-'cdm_truven_ccae_v2324'
oldVocabSchema <-'cdm_truven_ccae_v2182'
resultSchema <-'results_truven_ccae_v2435' #schema with achillesresults, different from resSchema in JnJ

#create the dataframe with cohort-conceptSet-NodeConcept-desc-incl
Concepts_in_cohortSet<-getNodeConcepts(cohorts, baseUrl)

#write results to the Excel file
resultToExcel(connectionDetails = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              workSchema = workSchema,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              resultSchema = resultSchema)

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))
