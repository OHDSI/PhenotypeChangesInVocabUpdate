#' This function resolves concept sets in a SQL database and writes the result to the Excel file
#'
#' @description This function resolves concept sets in a SQL database
#' it uses an input of \code{getNodeConcepts()} funcion,
#' it detects
#' 1) non-standard concepts used in concept set expression;
#' 2) added or excluded source concepts due to changed mapping to standard concepts
#' 3) domain changes of included standard concepts
#' The result is written to an excel file with the tab for each check
#'
#'
#' @param connectionDetails An R object of type\cr\code{connectionDetails} created using the
#'                                     function \code{createConnectionDetails} in the
#'                                     \code{DatabaseConnector} package.
#' @param Concepts_in_cohortSet dataframe which stores cohorts and concept set definitions in a tabular format,
#'                              it should have the following columns:
#'                              "ConceptID","isExcluded","includeDescendants","conceptsetId","conceptsetName","cohortId"
#' @param newVocabSchema        schema containing a new vocabulary version
#' @param oldVocabSchema        schema containing an older vocabulary version
#' @param resultSchema          schema containing Achilles results
#' @param excludedNodes         text string with excluded nodes, for example: "9201, 9202, 9203"; 0 by default
#' @param includedSourceVocabs  text string with included source vocabularies, for example: "'ICD10CM', 'ICD9CM', 'HCPCS'"; 0 by default, which is treated as ALL vocabularies
#' @param projName              project name - used to name the output file
#' @examples
#' \dontrun{
#'  resultToExcel(connectionDetails = YourconnectionDetails,
#'  Concepts_in_cohortSet = Concepts_in_cohortSet, # is returned by getNodeConcepts function
#'  newVocabSchema = "omopVocab_v1", #schema containing newer vocabulary version
#'  oldVocabSchema = "omopVocab_v0", #schema containing older vocabulary version
#'  resultSchema = "achillesresults") #schema with achillesresults
#' }
#' @export


resultToExcel <-function( connectionDetailsVocab,
                          Concepts_in_cohortSet,
                          newVocabSchema,
                          oldVocabSchema,
                          resultSchema,
                          excludedNodes = 0,
						              includedSourceVocabs =0,
					             	  projName  = '')
{
  #use databaseConnector to run SQL and extract tables into data frames



  #connect to the vocabulary server
  conn <- DatabaseConnector::connect(connectionDetailsVocab)


  #insert Concepts_in_cohortSet into the SQL database where concepts sets will be resolved
  #for Redshift ask your administrator for a key for bulk load
  DatabaseConnector::insertTable(connection = conn,
                                 tableName = "#ConceptsInCohortSet",
                                 data = Concepts_in_cohortSet,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = T,
                                 bulkLoad = F)


  # read SQL from file
 pathToSql <- system.file("sql/sql_server", "AllFromNodes.sql", package = "PhenotypeChangesInVocabUpdate")
 InitSql <- read_file(pathToSql)


  #run the SQL creating all tables needed for the output
  DatabaseConnector::renderTranslateExecuteSql (connection = conn,
                                                InitSql,
                                                newVocabSchema=newVocabSchema,
                                                oldVocabSchema= oldVocabSchema,
                                                resultSchema = resultSchema,
                                                excludedNodes = excludedNodes,
												includedSourceVocabs = includedSourceVocabs
  )

  #get SQL tables into dataframes

  #comparison on source codes can't be done on SQL, since the SQL render used in DatabaseConnector::renderTranslateQuerySql doesn't support STRING_AGG function
  # so this is done in R
  #source concepts resolved and their mapping in the old vocabulary
  oldMap <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                                       "select * from #oldmap", snakeCaseToCamelCase = F)

  #source concepts resolved and their mapping in the new vocabulary
  newMap <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                                       "select * from #newmap", snakeCaseToCamelCase = F)

  #aggregate the target concepts into one row so we can compare old and new mapping, newMap
  newMapAgg <-
    newMap %>%
    arrange(CONCEPT_ID) %>%
    group_by(COHORTID,COHORTNAME, CONCEPTSETNAME, CONCEPTSETID, SOURCE_CONCEPT_ID, ACTION) %>%
    summarise(
      NEW_MAPPED_CONCEPT_ID = paste(CONCEPT_ID, collapse = '-'),
      NEW_MAPPED_CONCEPT_NAME = paste(CONCEPT_NAME, collapse = '-'),
      NEW_MAPPED_VOCABULARY_ID = paste(VOCABULARY_ID, collapse = '-'),
      NEW_MAPPED_CONCEPT_CODE = paste(CONCEPT_CODE, collapse = '-')
    )

  #aggregate the target concepts into one row so we can compare old and new mapping, oldMap
  oldMapAgg <-
    oldMap %>%
    arrange(CONCEPT_ID) %>%
    group_by(COHORTID,COHORTNAME, CONCEPTSETNAME, CONCEPTSETID, SOURCE_CONCEPT_ID, RECORD_COUNT, ACTION,
             SOURCE_CONCEPT_NAME, SOURCE_VOCABULARY_ID, SOURCE_CONCEPT_CODE
    ) %>%
    summarise(
      OLD_MAPPED_CONCEPT_ID = paste(CONCEPT_ID, collapse = '-'),
      OLD_MAPPED_CONCEPT_NAME = paste(CONCEPT_NAME, collapse = '-'),
      OLD_MAPPED_VOCABULARY_ID = paste(VOCABULARY_ID, collapse = '-'),
      OLD_MAPPED_CONCEPT_CODE = paste(CONCEPT_CODE, collapse = '-')
    )

  #join oldMap and newMap to see the mappings of added or removed source concepts
  mapDif <- oldMapAgg %>%
    inner_join(newMapAgg, by = c("COHORTID", "COHORTNAME", "CONCEPTSETNAME", "CONCEPTSETID", "SOURCE_CONCEPT_ID", "ACTION")) %>%
   arrange(desc(RECORD_COUNT))

  #get the non-standard concepts used in concept set definitions
  nonStNodes <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                                           "select * from #non_st_Nodes
order by drc desc", snakeCaseToCamelCase = T) # to evaluate the best way of naming


  #get the standard concepts changed domains and their mapped counterparts
  domainChange <-DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                                            "select * from
                                           #resolv_dom_dif order by source_concept_record_count desc",  snakeCaseToCamelCase = T)
  #disconnect
  DatabaseConnector::disconnect(conn)

  # put the results in excel, each dataframe goes to a separate tab
  wb <- createWorkbook()

  addWorksheet(wb, "nonStNodes")
  writeData(wb, "nonStNodes", nonStNodes)

  addWorksheet(wb, "mapDif")
  writeData(wb, "mapDif", mapDif)

  addWorksheet(wb, "domainChange")
  writeData(wb, "domainChange", domainChange)

  saveWorkbook(wb, paste0(projName, "PhenChange.xlsx"), overwrite = TRUE)
}
