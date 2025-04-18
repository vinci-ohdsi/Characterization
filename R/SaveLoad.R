# Copyright 2024 Observational Health Data Sciences and Informatics
#
# This file is part of Characterization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

exportTimeToEventToCsv <- function(
    result,
    saveDirectory,
    minCellCount = 0) {
  if (!dir.exists(saveDirectory)) {
    dir.create(
      path = saveDirectory,
      recursive = TRUE
    )
  }

  Andromeda::batchApply(
    tbl = result$timeToEvent,
    fun = function(x) {
      append <- file.exists(
        file.path(
          saveDirectory,
          "time_to_event.csv"
        )
      )

      dat <- as.data.frame(
        x %>%
          dplyr::collect()
      )

      colnames(dat) <- SqlRender::camelCaseToSnakeCase(
        string = colnames(dat)
      )

      if (sum(dat$num_events < minCellCount) > 0) {
        ParallelLogger::logInfo(paste0("Removing num_events less than ", minCellCount))
        dat$num_events[dat$num_events < minCellCount] <- -minCellCount
      }

      readr::write_csv(
        x = formatDouble(x = dat),
        file = file.path(
          saveDirectory,
          "time_to_event.csv"
        ),
        append = append
      )
    }
  )

  invisible(
    file.path(
      saveDirectory,
      "time_to_event.csv"
    )
  )
}


exportDechallengeRechallengeToCsv <- function(
    result,
    saveDirectory,
    minCellCount = 0) {
  countN <- dplyr::pull(
    dplyr::count(result$dechallengeRechallenge)
  )
  message("Writing ", countN, " rows to csv")

  if (!dir.exists(saveDirectory)) {
    dir.create(saveDirectory, recursive = TRUE)
  }

  Andromeda::batchApply(
    tbl = result$dechallengeRechallenge,
    fun = function(x) {
      append <- file.exists(
        file.path(
          saveDirectory,
          "dechallenge_rechallenge.csv"
        )
      )
      dat <- as.data.frame(
        x %>%
          dplyr::collect()
      )

      colnames(dat) <- SqlRender::camelCaseToSnakeCase(
        string = colnames(dat)
      )

      removeInd <- dat$num_exposure_eras < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring num_exposure_eras counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$num_exposure_eras[removeInd] <- -minCellCount
        }
      }

      removeInd <- dat$num_persons_exposed < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring num_persons_exposed counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$num_persons_exposed[removeInd] <- -minCellCount
        }
      }

      removeInd <- dat$num_cases < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring num_cases counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$num_cases[removeInd] <- -minCellCount
        }
      }

      removeInd <- dat$dechallenge_attempt < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring/removing dechallenge_attempt counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$dechallenge_attempt[removeInd] <- -minCellCount
          dat$pct_dechallenge_attempt[removeInd] <- NA
        }
      }

      removeInd <- dat$dechallenge_fail < minCellCount | dat$dechallenge_success < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring/removing DECHALLENGE FAIL or SUCCESS counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$dechallenge_fail[removeInd] <- -minCellCount
          dat$dechallenge_success[removeInd] <- -minCellCount
          dat$pct_dechallenge_fail[removeInd] <- NA
          dat$pct_dechallenge_success[removeInd] <- NA
        }
      }

      removeInd <- dat$rechallenge_attempt < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring/removing rechallenge_attempt counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$rechallenge_attempt[removeInd] <- -minCellCount
          dat$pct_rechallenge_attempt[removeInd] <- NA
        }
      }

      removeInd <- dat$rechallenge_fail < minCellCount | dat$rechallenge_success < minCellCount
      if (sum(removeInd) > 0) {
        ParallelLogger::logInfo(paste0("Censoring/removing rechallenge_fail or rechallenge_success counts less than ", minCellCount))
        if (sum(removeInd) > 0) {
          dat$rechallenge_fail[removeInd] <- -minCellCount
          dat$rechallenge_success[removeInd] <- -minCellCount
          dat$pct_rechallenge_fail[removeInd] <- NA
          dat$pct_rechallenge_success[removeInd] <- NA
        }
      }

      readr::write_csv(
        x = formatDouble(x = dat),
        file = file.path(
          saveDirectory,
          "dechallenge_rechallenge.csv"
        ),
        append = append
      )
    }
  )

  invisible(
    file.path(
      saveDirectory,
      "dechallenge_rechallenge.csv"
    )
  )
}


exportRechallengeFailCaseSeriesToCsv <- function(
    result,
    saveDirectory) {
  if (!dir.exists(saveDirectory)) {
    dir.create(
      path = saveDirectory,
      recursive = TRUE
    )
  }

  countN <- dplyr::pull(
    dplyr::count(result$rechallengeFailCaseSeries)
  )

  message("Writing ", countN, " rows to csv")

  Andromeda::batchApply(
    tbl = result$rechallengeFailCaseSeries,
    fun = function(x) {
      append <- file.exists(
        file.path(
          saveDirectory,
          "rechallenge_fail_case_series.csv"
        )
      )

      dat <- as.data.frame(
        x %>%
          dplyr::collect()
      )

      colnames(dat) <- SqlRender::camelCaseToSnakeCase(
        string = colnames(dat)
      )

      readr::write_csv(
        x = formatDouble(x = dat),
        file = file.path(
          saveDirectory,
          "rechallenge_fail_case_series.csv"
        ),
        append = append
      )
    }
  )

  invisible(
    file.path(
      saveDirectory,
      "rechallenge_fail_case_series.csv"
    )
  )
}
