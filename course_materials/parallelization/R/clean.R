#' Apply log transformation log(x + 1) to data
#'
#' @param data A data frame
#'
#' @returns A data frame with the log-transformed data
apply_log_transform <- function(data) {
  log_data <- log1p(data)
  return(log_data)
}
