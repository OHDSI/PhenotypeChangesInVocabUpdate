#' Get cohortIds, concpetSet names and concept set expressions in a tabular format
#'
#' @description
#' This function extracts the table with the following values:
#' "ConceptID", "isExcluded", "includeDescendants", "conceptsetId", "conceptsetName", "cohortId"
#' "ConceptID" is a concept used in concept set Expression
#'
#'
#' @param cohorts  vector that contains cohorts to be evaluated
#' @param baseUrl  the BaseUrl of your Atlas instance
#'
#' @examples
#' \dontrun{
#'  getNodeConcepts(cohorts = c(12822, 12824, 12825),
#'                  baseUrl = "https://yourSecureAtlas.ohdsi.org/" )
#' }
#' @export

getNodeConcepts <- function(cohorts, baseUrl)
{

#initial empty tibble that will be filled by the cycle
Concepts_in_cohortSet <- tibble(
  conceptId = numeric(),
  isExcluded = logical(),
  includeDescendants =logical(),
  conceptsetId = numeric (),
  conceptsetName = character(),
  cohortDefinitionId = numeric()
)

#loop trough cohorts getting concept set list
for (cohortDefinitionId in cohorts) {
  tryCatch({
    cohortDefinition <- ROhdsiWebApi::getCohortDefinition(cohortDefinitionId, baseUrl)
    cohortDefinitionExpression <- cohortDefinition$expression
    conceptsetList <- cohortDefinitionExpression$ConceptSets

    # skip any cohort definition that has no concept sets
    if (length(conceptsetList) == 0) {
      next
    }

#empty tibble for conceptset - concept set expression
    Concepts_in_cohort <- tibble(
      conceptId = numeric(),
      isExcluded = logical(),
      includeDescendants =logical(),
      conceptsetId = numeric (),
      conceptsetName = character()
    )

    #loop through concept sets
    for (conceptSetIndex in 1:length(conceptsetList)) {
      conceptSet<- conceptsetList[[conceptSetIndex]]$expression$items

      # skip any concept set that has no items
      if (length(conceptSet) == 0) {
        next
      }

      #each inner circle starts from empty addedConcepts_agg table
      addedConcepts_agg <- tibble(
        conceptId = numeric(),
        isExcluded = logical(),
        includeDescendants =logical()
      )

      #loop through the Node concepts getting ConceptID, isExcluded, includeDescendants values
      for (conceptSetNodeIdex in 1:length(conceptSet)) {
        conceptSetNode <- conceptSet[[conceptSetNodeIdex]]$concept$CONCEPT_ID
        addedConcepts <-data.frame(ConceptID = conceptSetNode)
        addedConcepts$isExcluded <-conceptSet[[conceptSetNodeIdex]]$isExcluded
        addedConcepts$includeDescendants <-conceptSet[[conceptSetNodeIdex]]$includeDescendant
#bind with previous run
        addedConcepts_agg<-rbind(addedConcepts_agg, addedConcepts)
      }
      #bind with previous run
      t1 <-addedConcepts_agg
      t1$conceptsetId <-conceptsetList[[conceptSetIndex]]$id
      t1$conceptsetName <-conceptsetList[[conceptSetIndex]]$name
      Concepts_in_cohort <- rbind (Concepts_in_cohort, t1)
    }
    #bind with previous run
    t2<-Concepts_in_cohort
    t2$cohortId<-cohortDefinitionId
    Concepts_in_cohortSet<-rbind(Concepts_in_cohortSet, t2)
  }
#trycatch argument what to do in error
  , error = function (err) {
    print(err)
    print(paste("cohort not found:",cohortDefinitionId)) }
  )
}
#function returns one dataframe
return(Concepts_in_cohortSet)
}

