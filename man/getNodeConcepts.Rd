% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getNodeConcepts.R
\name{getNodeConcepts}
\alias{getNodeConcepts}
\title{Get cohortIds, concpetSet names and concept set expressions in a tabular format}
\usage{
getNodeConcepts(cohorts, baseUrl)
}
\arguments{
\item{cohorts}{vector that contains cohorts to be evaluated}

\item{baseUrl}{the BaseUrl of your Atlas instance}
}
\description{
This function extracts the table with the following values:
"ConceptID", "isExcluded", "includeDescendants", "conceptsetId", "conceptsetName", "cohortId"
"ConceptID" is a concept used in concept set Expression
}
\examples{
\dontrun{
 getNodeConcepts(cohorts = c(12822, 12824, 12825),
                 baseUrl = "https://yourSecureAtlas.ohdsi.org/" )
}
}
