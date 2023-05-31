resultToExcel <-function()
{
#tables with parameters
#you can exclude specific node concepts (for example Visits that were implemented differently than mappings)
excl_node<-read.csv(exclNode)

# you can exclude or include only specific source concepts
source_concept_rules<-read.csv(sourceConceptRules)

source_concept_rules$rule_name <- as.character(source_concept_rules$rule_name)

#use databaseConnector to run SQL and extract tables into data frames

conn <- DatabaseConnector::connect(connectionDetails)

#insert tables obtained in a previous steps, +tables with output filter parameters
#for Redshift ask your administrator for a key for bulk load
DatabaseConnector::insertTable(connection = conn,
                               tableName =paste0(workSchema, ".sourceConceptCountAllSum"), # this should reflect the schema and table you'd like to insert into.
                               data = sourceCodesCnt, # the data frame you would like to insert into Redshift.
                               dropTableIfExists = T,
                               createTable = T,
                               tempTable = FALSE,
                               bulkLoad = TRUE) #if postgresql, set to F, ask Martijn about other databases

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


DatabaseConnector::renderTranslateExecuteSql (connection = conn,
                                              InitSql,
                                              workSchema= workSchema,
                                              newVocabSchema=newVocabSchema,
                                              oldVocabSchema= oldVocabSchema,
                                              resultSchema = resultSchema
)

#get SQL tables into dataframes

#source concepts resolved and their mapping in the old vocabulary
oldMap <- DatabaseConnector::querySql(connection = conn,
                                      "select * from scratch_ddymshyt.oldmap", snakeCaseToCamelCase = F)

#source concepts resolved and their mapping in the new vocabulary
newMap <- DatabaseConnector::querySql(connection = conn,
                                      "select * from scratch_ddymshyt.newmap", snakeCaseToCamelCase = F)

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


# to do: change my schema to parameterize
summaryTable <- DatabaseConnector::querySql(connection = conn,
                                            "--summary table
select cohortid, action, sum (totalcount) from scratch_ddymshyt.resolv_dif_sc
--if concept appears in different nodes, it will be counted several times, but for an evaluation it's probably ok
group by cohortid, action
order by sum (totalcount) desc", snakeCaseToCamelCase = T)

nonStNodes <- DatabaseConnector::querySql(connection = conn,
                                          "select * from scratch_ddymshyt.non_st_Nodes
order by drc desc", snakeCaseToCamelCase = T) # to evaluate the best way of naming

peakDif <- DatabaseConnector::querySql(connection = conn,
                                       "select * from scratch_ddymshyt.resolv_dif_peaks order by drc desc", snakeCaseToCamelCase = T)

domainChange <-DatabaseConnector::querySql(connection = conn,
                                           "select * from
                                           scratch_ddymshyt.resolv_dom_dif order by drc desc", snakeCaseToCamelCase = T)
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
