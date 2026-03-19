#' Collapse rare survey responses into an "other" category
#'
#' @param ling_data the linguistics data
#' @param qa_key the question-answer key
#' @param min_prop collapse responses with a proportion less than this value
#'   into an "other" category
#'
#' @returns A list of two: (1) the collapsed data frame and (2) the updated
#'   question-answer key
#'
#' @examples
#' collapse_survey_responses(ling_data, qa_key, min_prop = 0.01)
collapse_survey_responses <- function(ling_data, qa_key, min_prop = 0.05) {
  # identify rare responses
  qa_key <- qa_key |>
    dplyr::mutate(
      answer = stringr::str_trim(answer),
      new_answer = dplyr::case_when(
        percentage < (min_prop * 100) ~ "other",
        TRUE ~ answer
      )
    ) |>
    dplyr::arrange(-percentage)

  collapsed_ling_data <- ling_data |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::starts_with("Q"),
        function(x) {
          cur_qid <- as.numeric(stringr::str_remove(dplyr::cur_column(), "^Q"))
          qid_key <- qa_key |>
            dplyr::filter(qid == cur_qid)
          # merge rare responses into the same category/factor
          factor(x, levels = qid_key$answer_num, labels = qid_key$new_answer) |>
            as.numeric() |>
            tidyr::replace_na(0)
        }
      )
    )
  # update question-answer key to reflect collapsed categories
  collapsed_qa_key <- qa_key |>
    dplyr::group_by(qid) |>
    dplyr::mutate(
      answer_num = 1:dplyr::n()
    ) |>
    dplyr::group_by(
      qid, question, new_answer
    ) |>
    dplyr::summarise(
      answer_num = min(answer_num),
      percentage = sum(percentage),
      .groups = "drop"
    ) |>
    dplyr::rename(
      answer = new_answer
    )
  return(list(ling_data = collapsed_ling_data, qa_key = collapsed_qa_key))
}


#' One-hot encoding of categorical variables
#'
#' @param ling_data the linguistics data
#' @param remove_zeros whether to remove columns corresponding to missing
#'   responses
#'
#' @returns A one-hot-encoded data matrix
#'
#' @examples
#' one_hot_ling_data(ling_data)
#' one_hot_ling_data(ling_data, remove_zeros = TRUE)
one_hot_ling_data <- function(ling_data, remove_zeros = FALSE) {
  # do one hot encoding of survey responses
  require(caret)
  X <- ling_data |>
    dplyr::select(tidyselect::starts_with("Q")) |>
    dplyr::mutate(
      dplyr::across(tidyselect::everything(), as.factor)
    )
  dummy_fit <- caret::dummyVars(~ ., data = X)
  X_bin <- predict(dummy_fit, X)

  # add metadata back in
  X_bin <- ling_data |>
    dplyr::select(-tidyselect::starts_with("Q")) |>
    dplyr::bind_cols(X_bin)

  # remove NA columns
  if (remove_zeros) {
    X_bin <- X_bin |>
      dplyr::select(-tidyselect::ends_with(".0"))
  }
  return(X_bin)
}


#' Remove samples with too many missing values
#'
#' @param ling_data the linguistics data
#' @param min_answers the minimum number of answers required for a sample
#'   to be retained
#'
#' @returns A data frame with samples removed
remove_samples <- function(ling_data, min_answers = 50) {
  X <- ling_data |>
    dplyr::select(tidyselect::starts_with("Q"))
  num_answered <- rowSums(X != 0)
  ling_data <- ling_data[num_answered >= min_answers, , drop = FALSE]
  return(ling_data)
}


#' Aggregate survey responses by county
#'
#' @param ling_data the linguistics data
#'
#' @returns A data frame with one row per county and each column is a question.
#'   The (i, j) value in this data frame is the most popular response to
#'   question j in county i.
aggregate_survey_response_by_county <- function(ling_data) {
  is_onehot <- all(
    as.matrix(ling_data |> dplyr::select(tidyselect::starts_with("Q"))) %in% c(0, 1)
  )
  if (!isTRUE(is_onehot)) {
    stop(
      "Input data must be one-hot encoded to aggregate by county. ",
      "Run one_hot_ling_data(ling_data) first."
    )
  }
  if (!("county" %in% names(ling_data)) ||
      !("state" %in% names(ling_data))) {
    stop(
      "Input data must have county and state columns.",
      "Try running one_hot_ling_data(ling_data) first."
    )
  }
  ling_data_by_county <- ling_data |>
    # aggregate response by county
    dplyr::group_by(county, state) |>
    dplyr::summarise(
      dplyr::across(tidyselect::starts_with("Q"), mean),
      lat = mean(lat),
      long = mean(long),
      state_abb = dplyr::first(state_abb),
      .groups = "drop"
    )
  return(ling_data_by_county)
}
