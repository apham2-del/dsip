#' Get a numeric X matrix from the linguistic data
#'
#' @param ling_data the linguistic data
#'
#' @returns a numeric matrix
#'
#' @examples
#' get_X_matrix(ling_data)
get_X_matrix <- function(ling_data) {
  ling_data |>
    dplyr::select(tidyselect::starts_with("Q")) |>
    as.matrix()
}


#' Convert numeric answers to text
#'
#' @param x the numeric answers
#' @param qid the question ID
#' @param qa_key the question-answer key
#'
#' @returns a factor with text answers
#'
#' @examples
#' get_answers(ling_data$Q050, 50, qa_key)
get_answers <- function(x, qid, qa_key) {
  qid_key <- qa_key |>
    dplyr::filter(qid == !!qid)
  factor(
    x,
    levels = qid_key$answer_num,
    labels = qid_key$answer
  )
}


#' Extract latitude/longitude
#'
#' @param ling_data the linguistic data
#' @param what whether to extract latitude or longitude
#' @param show_contiguous_us whether to keep only the contiguous US
#'
#' @returns a numeric vector of latitude or longitude
#'
#' @examples
#' get_location(ling_data, "lat")
#' get_location(ling_data, "long")
get_location <- function(ling_data, what = c("lat", "long"),
                         show_contiguous_us = TRUE) {
  what <- match.arg(what)
  loc <- ling_data[[what]]
  if (show_contiguous_us) {
    # don't plot alaska and hawaii; otherwise, color scale is very skewed
    loc[ling_data$lat > 130] <- NA
    loc[ling_data$lat > 130] <- NA
  }
  return(loc)
}
