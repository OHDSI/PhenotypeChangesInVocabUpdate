library (jsonlite)
library (tibble)
library (PhenotypeChangesInVocabUpdate)
library (PhenotypeLibrary)
library(dplyr)
library (readr)
library (openxlsx)

#get all concept sets
allConceptSets<-getPlConceptDefinitionSet(cohortIds = getPhenotypeLog()$cohortId)

#initial table
Concepts_in_cohort <- tibble(
  conceptId = numeric(),
  isExcluded = logical(),
  includeDescendants =logical(),
  conceptsetId = numeric (),
  conceptsetName = character(),
  cohortId = numeric()
)

#loop through all the concept sets
for (i in 1:nrow(allConceptSets)) {
  # Apply the function to each row of the data frame
  result_df <- fromJSON(allConceptSets[i, ]$conceptSetExpression, flatten = TRUE) %>% select (concept.CONCEPT_ID, isExcluded , includeDescendants)
  result_df$conceptsetId <- allConceptSets[i, ]$conceptSetId
  result_df$conceptsetName <- allConceptSets[i, ]$conceptSetName
  result_df$cohortId <- allConceptSets[i, ]$cohortId
  # Append the result to the dataframe
  Concepts_in_cohort  <- rbind (Concepts_in_cohort,result_df )
}

#append cohort names
cohIdInfo <-getPhenotypeLog() %>% select (cohortId, cohortName, createdDate)

Concepts_in_cohortSet_all_dates <- inner_join(Concepts_in_cohort, cohIdInfo, by = "cohortId")

Concepts_in_cohortSet_all_dates <- Concepts_in_cohortSet_all_dates %>% rename (conceptID= concept.CONCEPT_ID)

# run the actual comparison through different vocabulary versions

#connectionDetailsVocab = set connectionDetailsVocab

excludedVisitNodes <- "9202, 2514435,9203,2514436,2514437,2514434,2514433,9201"
includedSourceVocabs <- "'ICD10', 'ICD10CM', 'CPT4', 'HCPCS', 'NDC', 'ICD9CM', 'ICD9Proc', 'ICD10PCS', 'ICDO3', 'JMDC'"
newVocabSchema <-'v20240229' #schema containing a new vocabulary version
oldVocabSchema <-'v20230116' #schema containing an older vocabulary
#oldVocabSchema <-'v20220909' #schema containing an older vocabulary
#oldVocabSchema <-'v20220409' #schema containing an older vocabulary
#oldVocabSchema <-'v20210617' #schema containing an older vocabulary

resultSchema <-'scratch_ddymshyt' #schema containing Achilles results

#filter cohorts being analysed by date of creation
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>% dplyr::filter(createdDate>'2023-02-01')
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter(createdDate > as.Date('2022-10-01') & createdDate <= as.Date('2023-02-01'))
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter(createdDate > as.Date('2022-05-01') & createdDate <= as.Date('2022-10-01'))
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter(createdDate > as.Date('2022-01-01') & createdDate <= as.Date('2022-05-01')) # none
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter(createdDate > as.Date('2021-07-01') & createdDate <= as.Date('2022-01-01'))
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter(createdDate > as.Date('2021-03-01') & createdDate <= as.Date('2021-07-01')) #none
#Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates  %>%  filter( createdDate <= as.Date('2021-03-01')) #none

#by default we don't need to stratify by dates, we assume that we have the latest version of cohorts working on the previous version of the vocabylary
Concepts_in_cohortSet<-Concepts_in_cohortSet_all_dates

PhenotypeChangesInVocabUpdate::resultToExcel(connectionDetailsVocab = connectionDetailsVocab,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              excludedNodes = excludedVisitNodes,
              resultSchema = resultSchema,
			  includedSourceVocabs = includedSourceVocabs
)

#open the excel file
#Windows
shell.exec("PhenChange.xlsx")
