getNodeConcepts <- function(cohorts=cohorts)
{
#specify cohorts you want to run the comparison for, file should have column called cohortId with cohortIds in it
selectedCohortDefinitionList <- readr::read_delim(cohorts, delim = "\t", show_col_types = FALSE)

#initial empty tibble that will be filled by the cycle
Concepts_in_cohortSet <- tibble(
  conceptId = numeric(),
  isExcluded = logical(),
  includeDescendants =logical(),
  conceptsetId = numeric (),
  conceptsetName = character(),
  cohortDefinitionId = numeric()
)

#loop trough cohortIs
for (cohortDefinitionId in selectedCohortDefinitionList$cohortId) {
  tryCatch({
    cohortDefinition <- ROhdsiWebApi::getCohortDefinition(cohortDefinitionId, baseUrl)
    cohortDefinitionExpression <- cohortDefinition$expression
    conceptsetList <- cohortDefinitionExpression$ConceptSets

    # skip any cohort definition that has no concept sets
    if (length(conceptsetList) == 0) {
      next
    }

    Concepts_in_cohort <- tibble(
      conceptId = numeric(),
      isExcluded = logical(),
      includeDescendants =logical(),
      conceptsetId = numeric (),
      conceptsetName = character()
    )

    #loop through concept sets
    for (conceptSetIndex in 1:length(conceptsetList)) {
      # conceptSet<- conceptsetList[[1]]$expression$items
      conceptSet<- conceptsetList[[conceptSetIndex]]$expression$items

      # skip any concept set that has no items
      if (length(conceptSet) == 0) {
        next
      }

      #each inner circe starts from empty addedConcepts_agg table
      addedConcepts_agg <- tibble(
        conceptId = numeric(),
        isExcluded = logical(),
        includeDescendants =logical()
      )

      #loop through the Node concepts
      for (conceptSetNodeIdex in 1:length(conceptSet)) {
        conceptSetNode <- conceptSet[[conceptSetNodeIdex]]$concept$CONCEPT_ID
        addedConcepts <-data.frame(ConceptID = conceptSetNode)
        addedConcepts$isExcluded <-conceptSet[[conceptSetNodeIdex]]$isExcluded
        addedConcepts$includeDescendants <-conceptSet[[conceptSetNodeIdex]]$includeDescendant

        addedConcepts_agg<-rbind(addedConcepts_agg, addedConcepts)
      }
      t1 <-addedConcepts_agg
      t1$conceptsetId <-conceptsetList[[conceptSetIndex]]$id
      t1$conceptsetName <-conceptsetList[[conceptSetIndex]]$name
      Concepts_in_cohort <- rbind (Concepts_in_cohort, t1)
    }
    t2<-Concepts_in_cohort
    t2$cohortId<-cohortDefinitionId
    Concepts_in_cohortSet<-rbind(Concepts_in_cohortSet, t2)
  }
  , error = function (err) {
    print(err)
    print(paste("cohort not found:",cohortDefinitionId)) }
  )
}
# store it as a file in case you want to review it
write.csv(Concepts_in_cohortSet, "Concepts_in_cohortSetTest.csv")
return(Concepts_in_cohortSet)
}

