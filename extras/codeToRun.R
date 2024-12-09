######################################
## PhenotypeChangesInVocabUpdate code to run ##
######################################

# install libraries, if not installed
# remotes::install_github("OHDSI/PhenotypeChangesInVocabUpdate")
# remotes::install_github("OHDSI/DatabaseConnector")

library(dplyr)
library(openxlsx)
library(readr)
library(tibble)
library(DatabaseConnector)
library(PhenotypeChangesInVocabUpdate)

baseUrl <- Sys.getenv("BASEURL")
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "ad",
  webApiUsername = Sys.getenv("WEBAPIUSERNAME"),
  webApiPassword = Sys.getenv("WEBAPIPASSWORD")
)

# specify cohorts you want to run the comparison for
# you can define the cohorts as vector:
cohorts <- c()

# excluded nodes is a text string with concept IDs you want to exclude from the analysis; it's set to 0 by default
# excludedNodes <- "9202,2514435,9203,2514436,2514437,2514434,2514433,9201"

# you can restrict the output by using specific source vocabularies (e.g., only those that exist in your data as source concepts)
includedSourceVocabs <- "'CMS Place of Service', 'CPT4', 'CVX', 'Cancer Modifier', 'DRG', 'HCPCS', 'ICD10CM', 'ICD10PCS', 'ICD9CM', 'ICD9Proc', 'LOINC', 'Medicare Specialty', 'NDC', 'NUCC', 'OMOP Extension', 'Revenue Code', 'RxNorm', 'RxNorm Extension', 'SNOMED', 'UB04 Pt dis status', 'UB04 Typ bill', 'Visit', 'OPTUM_LAB_TXT', 'OPTUM_LAB_ABN', 'OPTUM_LAB_UNIT', 'OPTUM_ADM',  'OPTUM_DST'"

# specify your configBlock if you're using Ulysses
configBlock <- "optum_dod_202407"

# otherwise, set up connectionDetails however you prefer
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms", config = configBlock),
  user = config::get("user", config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)

executionSettings <- config::get(config = configBlock) |>
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))

# set schema to which temp tables should be written
tempEmulationSchema <- executionSettings$workDatabaseSchema

# specify schemas with the vocabulary versions you want to compare
newVocabSchema <-'OPTUM_DOD_OMOP_202407_RWESNOW_SCHEMA' #schema containing a new vocabulary version
oldVocabSchema <-'OPTUM_DOD_OMOP_202312_RWESNOW_SCHEMA' #schema containing an older vocabulary
resultSchema <-'OPTUM_DOD_OMOP_202407_ATLAS_RWESNOW_SCHEMA' #schema containing Achilles results (needed for concept counts table)

# create the dataframe with concept set expressions using the getNodeConcepts function
Concepts_in_cohortSet <- getNodeConcepts(cohorts, baseUrl)

# resolve concept sets, compare the outputs on different vocabulary versions, write results to the Excel file
resultToExcel(connectionDetails = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              resultSchema = resultSchema,
              includedSourceVocabs = includedSourceVocabs,
              tempEmulationSchema = tempEmulationSchema,
              outputFolder = here::here("extras"))
