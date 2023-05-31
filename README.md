# Utility to compare cohorts run in different vocabulary versions by resolving their concept sets
## Compares source codes captured, hierarchy changes and domain changes; identifies Non-standard concepts used in concept set expressions



### Step by Step Example

```r
library (dplyr)
library (openxlsx)
library (readr)
library (tibble)

#if packages are not installed, please install
#install.packages("SqlRender")
#install.packages("DatabaseConnector")

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")

#list of cohorts to be evaluated
cohorts <- "~/CohortChangeInVocabUpdate/Cohorts2.csv"
#list of excluded nodes
exclNode <- "~/CohortChangeInVocabUpdate/excl_node.csv"
#Source concepts filtratoin rules
sourceConceptRules<-"~/CohortChangeInVocabUpdate/source_concept_rules.csv"


connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = keyring::key_get("ohdaProdCCAE", "dbms" ),
  connectionString = keyring::key_get("ohdaProdCCAE", "connectionString"),
  user = keyring::key_get("ohdaProdCCAE", "username"),
  password = keyring::key_get("ohdaProdCCAE", "password" )
)

resSchema <-'results_truven_ccae_v2435'
workSchema <-'scratch_ddymshyt' # schema where you're allowed to create tables
newVocabSchema <-'cdm_truven_ccae_v2324'
oldVocabSchema <-'cdm_truven_ccae_v2182'
resultSchema <-'scratch_ddymshyt' #schema with achillesresults, different from resSchema in JnJ


# Create statistics on the source codes
sourceCodesCnt<- sourceCodesCount()

#create the dataframe with cohort-conceptSet-NodeConcept-desc-incl
Concepts_in_cohortSet<-getNodeConcepts(cohorts)

#write results to the Excel file
resultToExcel()

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))

```
