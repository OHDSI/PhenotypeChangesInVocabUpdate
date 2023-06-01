#' This function resolves concept sets in a SQl database, it needs an input of
#' cohort_id - conceptSet - NodeConcept(the concept used in ConceptSetDefinition) - IsIncluded - includeDescendants,
#' it then detects non-standard concepts used as part of concept set definition
#' also detects the following changes in included concepts due to a vocabulary version change:
#' 1) added or excluded source concepts with changed mapping to standard concepts
#' 2) hierarchy changes are shown as peak concepts added or removed. the peak concept is the concept above which the hierarchy is altered
#' 3) domain changes of included standard concepts
#' The result is stored as an excel file with the tab for each check
#'
#'
#' @param connectionDetails An R object of type\cr\code{connectionDetails} created using the
#'                                     function \code{createConnectionDetails} in the
#'                                     \code{DatabaseConnector} package.
#' @param Concepts_in_cohortSet dataframe which stores cohorts and concept set definitions in a tabular format,
#'                              it should have the following columns:
#'                              "ConceptID","isExcluded","includeDescendants","conceptsetId","conceptsetName","cohortId"
#' @param workSchema            schema with a write access where tables are stored when executing the query
#' @param newVocabSchema        schema containing a new vocabulary version
#' @param oldVocabSchema        schema containing an older vocabulary version
#' @param resultSchema          schema containing Achilles results
#' @param excl_node             dataframe with nodes excluded from analysis !! turn it into vector?
#' @param source_concept_rules  dataframe containing domain_id and vocabuary_id of source concepts excluded or included only in the output
#' @export


resultToExcel <-function( connectionDetails,
                          Concepts_in_cohortSet,
                          workSchema,
                          newVocabSchema,
                          oldVocabSchema,
                          resultSchema,
                          excl_node,
                          source_concept_rules )
{
#use databaseConnector to run SQL and extract tables into data frames

conn <- DatabaseConnector::connect(connectionDetails)

#insert tables obtained in a previous steps, +tables with output filter parameters
#for Redshift ask your administrator for a key for bulk load
DatabaseConnector::insertTable(connection = conn,
                               tableName = paste0(workSchema,".Concepts_in_cohortSet"), # this should reflect the schema and table you'd like to insert into.
                               data = Concepts_in_cohortSet, # the data frame you would like to insert into Redshift.
                               dropTableIfExists = TRUE,
                               createTable = TRUE,
                               tempTable = FALSE,
                               bulkLoad = TRUE)

DatabaseConnector::insertTable(connection = conn,
                               tableName = paste0(workSchema, ".excl_node"), # this should reflect the schema and table you'd like to insert into.
                               data = excl_node, # the data frame you would like to insert into Redshift.
                               dropTableIfExists = TRUE,
                               createTable = TRUE,
                               tempTable = FALSE,
                               bulkLoad = TRUE)

DatabaseConnector::insertTable(connection = conn,
                               tableName = paste0(workSchema, ".source_concept_rules"), # this should reflect the schema and table you'd like to insert into.
                               data = source_concept_rules, # the data frame you would like to insert into Redshift.
                               dropTableIfExists = TRUE,
                               createTable = TRUE,
                               tempTable = FALSE,
                               bulkLoad = TRUE)


# read SQL from file

InitSql <- read_file("inst/sql/sql_server/AllFromNodes.sql")
#! check if it works after documentation is done and is exported properly
#InitSql <- read_file("AllFromNodes.sql")

DatabaseConnector::renderTranslateExecuteSql (connection = conn,
                                              InitSql,
                                              workSchema= workSchema,
                                              newVocabSchema=newVocabSchema,
                                              oldVocabSchema= oldVocabSchema,
                                              resultSchema = resultSchema
)

#get SQL tables into dataframes

#source concepts resolved and their mapping in the old vocabulary
oldMap <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                      "select * from @workSchema.oldmap",workSchema= workSchema, snakeCaseToCamelCase = F)

#source concepts resolved and their mapping in the new vocabulary
newMap <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                      "select * from @workSchema.newmap", workSchema= workSchema,snakeCaseToCamelCase = F)

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
select cohortid, action, sum (totalcount) from @workSchema.resolv_dif_sc
--if concept appears in different nodes, it will be counted several times, but for an evaluation it's probably ok
group by cohortid, action
order by sum (totalcount) desc", workSchema= workSchema, snakeCaseToCamelCase = T)

nonStNodes <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                          "select * from @workSchema.non_st_Nodes
order by drc desc",workSchema= workSchema, snakeCaseToCamelCase = T) # to evaluate the best way of naming

peakDif <- DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                       "select * from @workSchema.resolv_dif_peaks order by drc desc",workSchema= workSchema, snakeCaseToCamelCase = T)

domainChange <-DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                           "select * from
                                           @workSchema.resolv_dom_dif order by drc desc", workSchema= workSchema, snakeCaseToCamelCase = T)
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
