#' Load in question and answer key
#'
#' @param path the path to the data
#'
#' @returns A data frame containing the question and answer key
load_q_and_a_key <- function(path = here::here("data")) {
  readr::read_csv(
    file.path(path, "q_and_a_key.csv"),
    show_col_types = FALSE
  ) |>
    tibble::as_tibble()
}


#' Load in lingusitics data
#'
#' @param path the path to the data
#'
#' @returns A data frame containing the linguistics survey data
load_ling_data <- function(path = here::here("data")) {
  readr::read_csv(
    file.path(path, "ling_data.csv"),
    col_types = readr::cols(
      ZIP = readr::col_character()
    ),
    show_col_types = FALSE
  ) |>
    tibble::as_tibble()
}
