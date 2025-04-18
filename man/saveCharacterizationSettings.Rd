% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RunCharacterization.R
\name{saveCharacterizationSettings}
\alias{saveCharacterizationSettings}
\title{Save the characterization settings as a json}
\usage{
saveCharacterizationSettings(settings, fileName)
}
\arguments{
\item{settings}{An object of class characterizationSettings created using \code{createCharacterizationSettings}}

\item{fileName}{The location to save the json settings}
}
\value{
Returns the location of the directory containing the json settings
}
\description{
This function converts the settings into a json object and saves it
}
\details{
Input the characterization settings and output a json file to a file named 'characterizationSettings.json' inside the saveDirectory
}
\examples{
drSet <- createDechallengeRechallengeSettings(
  targetIds = c(1,2),
  outcomeIds = 3
)

cSet <- createCharacterizationSettings(
  dechallengeRechallengeSettings = drSet
)

saveCharacterizationSettings(
  settings = cSet,
  fileName = file.path(tempdir(), 'cSet.json')
)

}
\seealso{
Other LargeScale: 
\code{\link{createCharacterizationSettings}()},
\code{\link{loadCharacterizationSettings}()},
\code{\link{runCharacterizationAnalyses}()}
}
\concept{LargeScale}
