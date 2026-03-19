#' Load TCGA breast cancer data
#'
#' @param path Path to the data
#'
#' @returns A tibble with the TCGA breast cancer data
load_brca_data <- function(path = here::here("data")) {
  brca_data <- readr::read_csv(
    file.path(path, "tcga_brca_array_data_filtered.csv")
  ) |>
    tibble::as_tibble()
  return(brca_data)
}


#' Load TCGA breast cancer subtype data
#'
#' @param path Path to the data
#'
#' @returns A tibble with the TCGA breast cancer subtype data
load_subtype_data <- function(path = here::here("data")) {
  subtype_data <- readr::read_csv(
    file.path(path, "tcga_brca_subtypes.csv")
  ) |>
    tibble::as_tibble()
  return(subtype_data)
}
