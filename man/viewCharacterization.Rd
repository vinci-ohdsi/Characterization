% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ViewShiny.R
\name{viewCharacterization}
\alias{viewCharacterization}
\title{viewCharacterization - Interactively view the characterization results}
\usage{
viewCharacterization(resultFolder, cohortDefinitionSet = NULL)
}
\arguments{
\item{resultFolder}{The location of the csv results}

\item{cohortDefinitionSet}{The cohortDefinitionSet extracted using webAPI}
}
\value{
Opens a shiny app for interactively viewing the results
}
\description{
This is a shiny app for viewing interactive plots and tables
}
\details{
Input is the output of ...
}
\examples{

conDet <- exampleOmopConnectionDetails()

drSet <- createDechallengeRechallengeSettings(
  targetIds = c(1,2),
  outcomeIds = 3
)

cSet <- createCharacterizationSettings(
  dechallengeRechallengeSettings = drSet
)

runCharacterizationAnalyses(
  connectionDetails = conDet,
  targetDatabaseSchema = 'main',
  targetTable = 'cohort',
  outcomeDatabaseSchema = 'main',
  outcomeTable = 'cohort',
  cdmDatabaseSchema = 'main',
  characterizationSettings = cSet,
  outputDirectory = file.path(tempdir(),'view')
)

viewCharacterization(
  resultFolder = file.path(tempdir(),'view')
)


}
\concept{Shiny}
