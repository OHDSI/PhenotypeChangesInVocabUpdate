#' This function resolves concept sets in a SQL database and writes the result to the Excel file
#'
#' @description This function resolves concept sets in a SQL database
#' it uses an input of #' getNodeConcepts() funcion,
#' it detects non-standard concepts used in concept set expression;
#' also detects the changes in included concepts due to a vocabulary version change:
#' 1) added or excluded source concepts due to changed mapping to standard concepts
#' 2) added or excluded standard concepts due to hierarchy changes, only the "peak concepts" are shown
#'  "peak concept" is a concept above which the hierarchy is altered
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
#'
#' @examples
#' \dontrun{
#'  resultToExcel(connectionDetails = YourconnectionDetails,
#'  Concepts_in_cohortSet = Concepts_in_cohortSet, # is returned by getNodeConcepts function
#'  newVocabSchema = "omopVocab_v1", #schema containing newer vocabulary version
#'  oldVocabSchema = "omopVocab_v0", #schema containing older vocabulary version
#'  resultSchema = "achillesresults") #schema with achillesresults
#' }
#' @export


resultToExcel <-function( connectionDetails,
                          Concepts_in_cohortSet,
                          newVocabSchema,
                          oldVocabSchema,
                          resultSchema,
                          excludedNodes = 0 )
{
#use databaseConnector to run SQL and extract tables into data frames

conn <- DatabaseConnector::connect(connectionDetails)

#insert tables obtained in a previous steps, +tables with output filter parameters
#for Redshift ask your administrator for a key for bulk load
DatabaseConnector::insertTable(connection = conn,
                               tableName = "#ConceptsInCohortSet", # this should reflect the schema and table you'd like to insert into.
                               data = Concepts_in_cohortSet, # the data frame you would like to insert into Redshift.
                               dropTableIfExists = TRUE,
                               createTable = TRUE,
                               tempTable = TRUE,
                               bulkLoad = TRUE)

# read SQL from file
pathToSql <- system.file("sql/sql_server", "AllFromNodes.sql", package = "PhenotypeChangesInVocabUpdate")
InitSql <- read_file(pathToSql)

DatabaseConnector::renderTranslateExecuteSql (connection = conn,
                                              InitSql,
                                              newVocabSchema=newVocabSchema,
                                              oldVocabSchema= oldVocabSchema,
                                              resultSchema = resultSchema,
                                              excludedNodes = excludedNodes
)

#get SQL tables into dataframes

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
  group_by(COHORTID, CONCEPTSETNAME, CONCEPTSETID, ISEXCLUDED, INCLUDEDESCENDANTS, NODE_CONCEPT_ID, NODE_CONCEPT_NAME, SOURCE_CONCEPT_ID, TOTALCOUNT, ACTION) %>%
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
  group_by(COHORTID, CONCEPTSETNAME, CONCEPTSETID, ISEXCLUDED, INCLUDEDESCENDANTS, NODE_CONCEPT_ID, NODE_CONCEPT_NAME, SOURCE_CONCEPT_ID, TOTALCOUNT, ACTION,
           SOURCE_CONCEPT_NAME, SOURCE_VOCABULARY_ID, SOURCE_CONCEPT_CODE
  ) %>%
  summarise(
    OLD_MAPPED_CONCEPT_ID = paste(CONCEPT_ID, collapse = '-'),
    OLD_MAPPED_CONCEPT_NAME = paste(CONCEPT_NAME, collapse = '-'),
    OLD_MAPPED_VOCABULARY_ID = paste(VOCABULARY_ID, collapse = '-'),
    OLD_MAPPED_CONCEPT_CODE = paste(CONCEPT_CODE, collapse = '-')
  )

#join oldMap and newMap where targets are not equal
mapDif <- oldMapAgg %>%
  inner_join(newMapAgg, by = c("COHORTID", "CONCEPTSETNAME", "CONCEPTSETID", "ISEXCLUDED", "INCLUDEDESCENDANTS", "NODE_CONCEPT_ID", "NODE_CONCEPT_NAME", "SOURCE_CONCEPT_ID", "TOTALCOUNT", "ACTION")) %>%
  filter(if_else(is.na(OLD_MAPPED_CONCEPT_ID), '', OLD_MAPPED_CONCEPT_ID) != if_else(is.na(NEW_MAPPED_CONCEPT_ID), '', NEW_MAPPED_CONCEPT_ID))%>%
  arrange(desc(TOTALCOUNT))

summaryTable <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                            "--summary table
select cohortid, action, sum (totalcount) from #resolv_dif_sc
--if concept appears in different nodes, it will be counted several times, but for an evaluation it's probably ok
group by cohortid, action
order by sum (totalcount) desc", snakeCaseToCamelCase = T)

nonStNodes <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                          "select * from #non_st_Nodes
order by drc desc", snakeCaseToCamelCase = T) # to evaluate the best way of naming

peakDif <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                       "select * from #resolv_dif_peaks order by drc desc", snakeCaseToCamelCase = T)

domainChange <-DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                           "select * from
                                           #resolv_dom_dif order by drc desc",  snakeCaseToCamelCase = T)
DatabaseConnector::disconnect(conn)

# put the tables in excel
wb <- createWorkbook()

addWorksheet(wb, "summaryTable")
writeData(wb, "summaryTable", summaryTable)

addWorksheet(wb, "nonStNodes")
writeData(wb, "nonStNodes", nonStNodes)

addWorksheet(wb, "mapDif")
writeData(wb, "mapDif", mapDif)

addWorksheet(wb, "peakDif")
writeData(wb, "peakDif", peakDif)

addWorksheet(wb, "domainChange")
writeData(wb, "domainChange", domainChange)

saveWorkbook(wb, "PhenChange.xlsx", overwrite = TRUE)
}
