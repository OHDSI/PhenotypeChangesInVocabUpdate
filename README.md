# Utility to compare cohorts run in different vocabulary versions by resolving their concept sets
### Compares source codes captured, hierarchy changes and domain changes; identifies Non-standard concepts used in concept set expressions

## Step by Step Example

#install package
remotes::install_github("dimshitc/phenotypeChangeVocab")

```r
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
#the example file is located in "~/PhenotypeChangesInVocabUpdate/extras/Cohorts.csv"
# also you can define the cohorts as vector directly:
#cohorts <-c(12822, 12824, 12825)

#you must specify the full file name with cohortIds
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

connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = keyring::key_get("YourDatabase", "dbms" ),
  connectionString = keyring::key_get("YourDatabase", "connectionString"),
  user = keyring::key_get("YourDatabase", "username"),
  password = keyring::key_get("YourDatabase", "password" )
)

newVocabSchema <-'vocab_schema_n1' #schema containing a new vocabulary version
oldVocabSchema <-'vocab_schema_n0' #schema containing an older vocabulary version
resultSchema <-'achilles_results' #schema containing Achilles results

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


```

# The output description:

Writes an Excel file with a separate tab for each type of comparison.


## Definitions/column names used:

**"Node concept"** is a concept directly used in Concept Set Expression

**"includedescendants"**: indicates whether descendants of "Node concept" are included in concept set, 0 stands for False, 1 stands for True

**"isexcluded"**: indicates whether "Node concept" and it's descendants if "includedescendants" = 1 are excluded from a concept set, 0 stands for False, 1 stands for True

**"drc"**: descendant record count - summary number of 

**"source concept":** the concept set definition is usually done through standard concepts. 

Different clinical events might be captured with the same set of included standard concepts if mapping was changed, that's why the tool tracks source concepts related.

**“Action”:** flags whether concept or hierarchy branch is added or removed


## The Excel file has the following tabs:


### 1. summaryTable 

sum of added or removed source concepts occurrences in a dataset

- for example, the cohort_id 123 doesn't pick up source codes X and Y when using newer vocabulary version. X appears 10 times in the data, Y appears 15 times.

In this situation you'll get the following output:


<table>
  <tr>
   <td>cohortid
   </td>
   <td>123
   </td>
  </tr>
  <tr>
   <td>action
   </td>
   <td>Removed
   </td>
  </tr>
  <tr>
   <td>sum
   </td>
   <td>25
   </td>
  </tr>
</table>



### 2. nonStNodes

lists non-standard concepts used in the concept set definition.

Note, the concept set definition JSON isn't updated with the vocabulary update, so you will not see concept changes in Atlas.

This way you need to run this tool to see if concepts changed to non-standard.

- For example, the cohort_id 10729 has conceptset =’Malignancies that spread to liver’ which has Node concept = "4324190|History of malignant neoplasm of breast" with descendants included, 

this concept is non-standard and mapped this way:

Maps to "1340204|History of event"

Maps to value "4112853|Malignant tumor of breast".

In this situation you'll get the output below, which gives you the **target concepts you need to use** to capture the same clinical events while using a new vocabulary version.


<table>
  <tr>
   <td>cohortid
   </td>
   <td>10729
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Malignancies that spread to liver
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>15
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>4324190
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>History of malignant neoplasm of breast
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>20284048
   </td>
  </tr>
  <tr>
   <td><strong>mapsToConceptId</strong>
   </td>
   <td><strong>1340204</strong>
   </td>
  </tr>
  <tr>
   <td><strong>mapsToConceptName</strong>
   </td>
   <td><strong>History of event</strong>
   </td>
  </tr>
  <tr>
   <td><strong>mapsToValueConceptId</strong>
   </td>
   <td><strong>4112853</strong>
   </td>
  </tr>
  <tr>
   <td><strong>mapsToValueConceptName</strong>
   </td>
   <td><strong>Malignant tumor of breast</strong>
   </td>
  </tr>
</table>



### 3. mapDif

Tab shows related source concepts that were added or removed. Mapping in both vocabulary versions is shown. 

Note, source codes from the user's database only are included into the analysis.

This way the user knows why the difference in related source concepts occurs and might modify the concept set expression adding or removing mapped concepts.

- In the example below, events with ICD9CM “Neural hearing loss concept, unilateral” are now captured because of the mapping change. OLD_MAPPED_CONCEPT “Unilateral neural hearing loss” didn’t have the proper hierarchy, and wasn’t captured.


<table>
  <tr>
   <td>COHORTID
   </td>
   <td>12822
   </td>
  </tr>
  <tr>
   <td>CONCEPTSETNAME
   </td>
   <td>Cranial nerve disorder
   </td>
  </tr>
  <tr>
   <td>CONCEPTSETID
   </td>
   <td>28
   </td>
  </tr>
  <tr>
   <td>ISEXCLUDED
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>INCLUDEDESCENDANTS
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>NODE_CONCEPT_ID
   </td>
   <td>441848
   </td>
  </tr>
  <tr>
   <td>NODE_CONCEPT_NAME
   </td>
   <td>Cranial nerve disorder
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_ID
   </td>
   <td>44823107
   </td>
  </tr>
  <tr>
   <td>sourceCodesCount
   </td>
   <td>7115
   </td>
  </tr>
  <tr>
   <td>ACTION
   </td>
   <td>Added
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_NAME
   </td>
   <td>Neural hearing loss, unilateral
   </td>
  </tr>
  <tr>
   <td>SOURCE_VOCABULARY_ID
   </td>
   <td>ICD9CM
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_CODE
   </td>
   <td>389.13
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_ID
   </td>
   <td>379831
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_NAME
   </td>
   <td>Unilateral neural hearing loss
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_VOCABULARY_ID
   </td>
   <td>SNOMED
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_CODE
   </td>
   <td>425601005
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_ID
   </td>
   <td>381312
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_NAME
   </td>
   <td>Neural hearing loss
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_VOCABULARY_ID
   </td>
   <td>SNOMED
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_CODE
   </td>
   <td>73371001
   </td>
  </tr>
</table>



### 4.peakDif

Hierarchy change is reflected at "Peak concept" level, the common parent concept of added or removed standard concepts above which the hierarchy is changed.

- In the example below, the **375527|Headache disorder** and all its descendants were added to the concept **Headache** concept set. This is quite a big change since **drc** (descendant record count)= 34219562, and now a researcher has to decide whether the new, more broad, definition fits well.


<table>
  <tr>
   <td>cohortid
   </td>
   <td>12825
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>23
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Headache
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>378253
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>Headache
   </td>
  </tr>
  <tr>
   <td>action
   </td>
   <td>Added
   </td>
  </tr>
  <tr>
   <td><strong>peakConceptId</strong>
   </td>
   <td><strong>375527</strong>
   </td>
  </tr>
  <tr>
   <td><strong>peakName</strong>
   </td>
   <td><strong>Headache disorder</strong>
   </td>
  </tr>
  <tr>
   <td>peakCode
   </td>
   <td>230461009
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>34219562
   </td>
  </tr>
</table>



### 5. domainChange

This tab shows included concepts that changed their domain, so the different event table should be used.

- In the example below “2108163|Therapeutic apheresis; for plasma pheresis” concept changed its domain from **Procedure** to **Measurement**, so the concept set “Treatment or investigation for TMA” needs to be used with Measurement table as well to include the “2108163|Therapeutic apheresis; for plasma pheresis” events.


<table>
  <tr>
   <td>cohortid
   </td>
   <td>10656
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Treatment or investigation for TMA
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>20
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>4182536
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>Transfusion
   </td>
  </tr>
  <tr>
   <td>conceptId
   </td>
   <td>2108163
   </td>
  </tr>
  <tr>
   <td>conceptName
   </td>
   <td>Therapeutic apheresis; for plasma pheresis
   </td>
  </tr>
  <tr>
   <td>vocabularyId
   </td>
   <td>CPT4
   </td>
  </tr>
  <tr>
   <td>conceptCode
   </td>
   <td>36514
   </td>
  </tr>
  <tr>
   <td><strong>oldDomainId</strong>
   </td>
   <td><strong>Procedure</strong>
   </td>
  </tr>
  <tr>
   <td><strong>newDomainId</strong>
   </td>
   <td><strong>Measurement</strong>
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>1010478
   </td>
  </tr>
</table>
