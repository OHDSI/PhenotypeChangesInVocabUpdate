#' Run the query to get source concepts counts across all CDM tables
#'
#'
#' @param connectionDetails  An R object of type\cr\code{connectionDetails} created using the
#'                                     function \code{createConnectionDetails} in the
#'                                     \code{DatabaseConnector} package.
#' @param resSchema           The schema with the Achilles Results
#' @export


sourceCodesCount <- function(resSchema,connectionDetails)
{
  conn <- DatabaseConnector::connect(connectionDetails)

rsql <- SqlRender::render(
  "--get counts of source codes
-- when source code is mapped to multiple tables (if source code is mapped to several concepts it's counted several times as well), so we look at source table with least occurrences
--where probably it's mapped to one concept, in theory we can devide the numeric value to the number of target concepts per source concept
select stratum_1 as source_concept_id, min (count_value) as count_value
from
@res_schema.achilles_results
where analysis_id in (425 -- condition_source_concept_id
,625 -- procedure_source_concept_id
,725 -- drug_source_concept_id
,825 -- observation_source_concept_id
,1825 -- measurement_source_concept_id
,2125 -- device_source_concept_id
)
group by  stratum_1",
res_schema = resSchema)

sourceCodesCnt <- DatabaseConnector::querySql(connection = conn,
                                              sql = rsql)
#sum up the value_counts
#sourceConceptCountAllSum <-sourceConceptCountAll %>% group_by (source_concept_id) %>% summarise(totalCount= sum(count_value))

sourceCodesCnt <- rename(sourceCodesCnt, totalCount = COUNT_VALUE)

DatabaseConnector::disconnect(conn)
return (sourceCodesCnt)
}
