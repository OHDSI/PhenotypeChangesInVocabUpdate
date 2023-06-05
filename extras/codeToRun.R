######################################
## PhenotypeChangesVocab code to run ##
######################################

library (dplyr)
library (openxlsx)
library (readr)
library (tibble)

#set the BaseUrl of your Atlas instance
baseUrl <- "https://yourSecureAtlas.ohdsi.org/"

#if packages are not installed, please install
#install.packages("SqlRender")
#install.packages("DatabaseConnector")

# if security is enabled authorize use of the webapi
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "windows")

#list of cohorts to be evaluated
# put examples into extras folder
#change to the

#! this doesn't work, talk to Clair
pathToCsv <- system.file("settings", "Cohorts.csv", package = "phenotypeChangeVocab")
selectedCohortDefinitionList <- read.csv(pathToCsv)

#specify cohorts you want to run the comparison for, in my example I import it from the CSV with one column containing cohortIds
# or you can define it as a vector directly: cohorts <-c(12822, 12824, 12825)
cohortsDF <- readr::read_delim("~/CohortChangeInVocabUpdate/Cohorts2.csv", delim = "\t", show_col_types = FALSE)
cohorts <-cohortsDF[[1]]

#tables with parameters
#you can exclude specific node concepts (for example Visits that were implemented differently than mappings)
excl_node<-read.csv(exclNode) #! these goes to extras folder

# you can exclude or include only specific source concepts
source_concept_rules<-read.csv(sourceConceptRules) #! these goes to extras folder
source_concept_rules$rule_name <- as.character(source_concept_rules$rule_name)

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

workSchema <-'scratch_ddymshyt' # schema where you're allowed to create tables
newVocabSchema <-'cdm_truven_ccae_v2324'
oldVocabSchema <-'cdm_truven_ccae_v2182'
resultSchema <-'results_truven_ccae_v2435' #schema with achillesresults, different from resSchema in JnJ

#create the dataframe with cohort-conceptSet-NodeConcept-desc-incl
Concepts_in_cohortSet<-getNodeConcepts(cohorts)

#write results to the Excel file
resultToExcel(connectionDetails = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              workSchema = workSchema,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              resultSchema = resultSchema,
              excl_node= excl_node,
              source_concept_rules = source_concept_rules)

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")

#MacOS
#system(paste("open", "PhenChange.xlsx"))
