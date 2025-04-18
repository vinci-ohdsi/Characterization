#' viewCharacterization - Interactively view the characterization results
#'
#' @description
#' This is a shiny app for viewing interactive plots and tables
#' @details
#' Input is the output of ...
#' @param resultFolder   The location of the csv results
#' @param cohortDefinitionSet  The cohortDefinitionSet extracted using webAPI
#' @family Shiny
#'
#' @return
#' Opens a shiny app for interactively viewing the results
#'
#' @examples
#'
#' conDet <- exampleOmopConnectionDetails()
#'
#' drSet <- createDechallengeRechallengeSettings(
#'   targetIds = c(1,2),
#'   outcomeIds = 3
#' )
#'
#' cSet <- createCharacterizationSettings(
#'   dechallengeRechallengeSettings = drSet
#' )
#'
#' runCharacterizationAnalyses(
#'   connectionDetails = conDet,
#'   targetDatabaseSchema = 'main',
#'   targetTable = 'cohort',
#'   outcomeDatabaseSchema = 'main',
#'   outcomeTable = 'cohort',
#'   cdmDatabaseSchema = 'main',
#'   characterizationSettings = cSet,
#'   outputDirectory = file.path(tempdir(),'view')
#' )
#'
#' viewCharacterization(
#'   resultFolder = file.path(tempdir(),'view')
#' )
#'
#'
#' @export
viewCharacterization <- function(
    resultFolder,
    cohortDefinitionSet = NULL) {

  # check there are csv files in resultFolder
  if(length(dir(resultFolder, pattern = '.csv')) > 0 ){

  databaseSettings <- prepareCharacterizationShiny(
    resultFolder = resultFolder,
    cohortDefinitionSet = cohortDefinitionSet
  )

  viewChars(databaseSettings)
  } else{
    message('No csv results to view via shiny')
    return(FALSE)
  }

}

prepareCharacterizationShiny <- function(
    resultFolder,
    cohortDefinitionSet,
    sqliteLocation = file.path(tempdir(), "results.sqlite"),
    tablePrefix = "",
    csvTablePrefix = "c_") {
  if (!dir.exists(dirname(sqliteLocation))) {
    dir.create(dirname(sqliteLocation), recursive = TRUE)
  }

  # create sqlite connection
  server <- sqliteLocation
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "sqlite",
    server = server
  )

  # create the tables
  createCharacterizationTables(
    connectionDetails = connectionDetails,
    resultSchema = "main",
    targetDialect = "sqlite",
    deleteExistingTables = TRUE,
    createTables = TRUE,
    tablePrefix = paste0(tablePrefix, csvTablePrefix)
  )

  # upload the results
  insertResultsToDatabase(
    connectionDetails = connectionDetails,
    schema = "main",
    resultsFolder = resultFolder,
    tablePrefix = tablePrefix,
    csvTablePrefix = csvTablePrefix
  )

  # add extra tables (cohorts and databases)
  con <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(con))

  tables <- tolower(DatabaseConnector::getTableNames(con, "main"))

  # this now works for different prefixes
  if (!"cg_cohort_definition" %in% tables) {
    cohortIds <- unique(
      c(
        DatabaseConnector::querySql(con, paste0("select distinct TARGET_COHORT_ID from ", tablePrefix, csvTablePrefix, "cohort_details where COHORT_TYPE = 'Target';"))$TARGET_COHORT_ID,
        DatabaseConnector::querySql(con, paste0("select distinct OUTCOME_COHORT_ID from ", tablePrefix, csvTablePrefix, "cohort_details where COHORT_TYPE = 'TnO';"))$OUTCOME_COHORT_ID,
        DatabaseConnector::querySql(con, paste0("select distinct TARGET_COHORT_DEFINITION_ID from ", tablePrefix, csvTablePrefix, "time_to_event;"))$TARGET_COHORT_DEFINITION_ID,
        DatabaseConnector::querySql(con, paste0("select distinct OUTCOME_COHORT_DEFINITION_ID from ", tablePrefix, csvTablePrefix, "time_to_event;"))$OUTCOME_COHORT_DEFINITION_ID,
        DatabaseConnector::querySql(con, paste0("select distinct TARGET_COHORT_DEFINITION_ID from ", tablePrefix, csvTablePrefix, "rechallenge_fail_case_series;"))$TARGET_COHORT_DEFINITION_ID,
        DatabaseConnector::querySql(con, paste0("select distinct OUTCOME_COHORT_DEFINITION_ID from ", tablePrefix, csvTablePrefix, "rechallenge_fail_case_series;"))$OUTCOME_COHORT_DEFINITION_ID
      )
    )

    DatabaseConnector::insertTable(
      connection = con,
      databaseSchema = "main",
      tableName = "cg_COHORT_DEFINITION",
      data = data.frame(
        cohortDefinitionId = cohortIds,
        cohortName = getCohortNames(cohortIds, cohortDefinitionSet)
      ),
      camelCaseToSnakeCase = TRUE
    )
  }

  if (!"database_meta_data" %in% tables) {
    dbIds <- unique(
      c(
        DatabaseConnector::querySql(con, paste0("select distinct DATABASE_ID from ", tablePrefix, csvTablePrefix, "analysis_ref;"))$DATABASE_ID,
        DatabaseConnector::querySql(con, paste0("select distinct DATABASE_ID from ", tablePrefix, csvTablePrefix, "dechallenge_rechallenge;"))$DATABASE_ID,
        DatabaseConnector::querySql(con, paste0("select distinct DATABASE_ID from ", tablePrefix, csvTablePrefix, "time_to_event;"))$DATABASE_ID
      )
    )

    DatabaseConnector::insertTable(
      connection = con,
      databaseSchema = "main",
      tableName = "DATABASE_META_DATA",
      data = data.frame(
        databaseId = dbIds,
        cdmSourceAbbreviation = paste0("database ", dbIds)
      ),
      camelCaseToSnakeCase = TRUE
    )
  }

  # create the settings for the database
  databaseSettings <- list(
    connectionDetailsSettings = list(
      dbms = "sqlite",
      server = server
    ),
    schema = "main",
    tablePrefix = paste0(tablePrefix, csvTablePrefix),
    cohortTablePrefix = "cg_",
    databaseTable = "DATABASE_META_DATA"
  )

  return(databaseSettings)
}

viewChars <- function(
    databaseSettings,
    testApp = F
    ) {
  ensure_installed("OhdsiShinyAppBuilder")

  connectionDetails <- do.call(
    DatabaseConnector::createConnectionDetails,
    databaseSettings$connectionDetailsSettings
  )
  connection <- ResultModelManager::ConnectionHandler$new(connectionDetails)
  databaseSettings$connectionDetailsSettings <- NULL

    # use new method
    config <- ParallelLogger::loadSettingsFromJson(
      fileName = system.file(
        "shinyConfigUpdate.json",
        package = "Characterization"
      )
    )
    databaseSettings$cTablePrefix <- databaseSettings$tablePrefix
    databaseSettings$cgTablePrefix <- databaseSettings$cohortTablePrefix
    databaseSettings$databaseTable <- "DATABASE_META_DATA"
    databaseSettings$databaseTablePrefix <- ""
    databaseSettings$cgTable <- "cohort_definition"

      OhdsiShinyAppBuilder::viewShiny(
        config = config,
        connection = connection,
        resultDatabaseSettings = databaseSettings
      )
}



getCohortNames <- function(cohortIds, cohortDefinitionSet) {

  if(is.null(cohortIds)){
    warning('cohortIds is NULL')
    return(NULL)
  }

  if (!is.null(cohortDefinitionSet)) {
    cohortNames <- sapply(
      cohortIds,
      function(x) {
        cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == x]
      }
    )
  } else {
    cohortNames <- paste0("cohort ", cohortIds)
  }

  return(cohortNames)
}


# Borrowed from devtools: https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L44
is_installed <- function(pkg) {
  installed_version <- tryCatch(utils::packageVersion(pkg),
    error = function(e) NA
  )
  !is.na(installed_version)
}

# Borrowed and adapted from devtools: https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L74
ensure_installed <- function(pkg) {
  if (!is_installed(pkg)) {
    msg <- paste0(sQuote(pkg), " must be installed for this functionality.")
    if (interactive()) {
      message(msg, "\nWould you like to install it?")
      if (utils::menu(c("Yes", "No")) == 1) {
          utils::install.packages(pkg)
      } else {
        stop(msg, call. = FALSE)
      }
    } else {
      stop(msg, call. = FALSE)
    }
  }
}
