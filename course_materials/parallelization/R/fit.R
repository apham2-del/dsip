#' Fit a random forest model with sample `i` left out
#'
#' @param i Index of the observation to leave out
#' @param x Covariate data
#' @param y Response variable
#' @param ... Additional arguments to pass to `ranger::ranger()`
#'
#' @return Predicted class of the left out sample `i`
fit_rf_loo <- function(i, x, y, ...) {
  fit <- ranger::ranger(
    x = x[-i, , drop = FALSE],
    y = y[-i],
    num.threads = 1,
    ...
  )
  preds <- as.character(predict(fit, x[i, , drop = FALSE])$predictions)
  return(preds)
}


#' Fit a k-nearest neighbors model with sample `i` left out
#'
#' @param i Index of the observation to leave out
#' @param x Covariate data
#' @param y Response variable
#' @param ... Additional arguments to pass to `caret::train()`
#'
#' @return Predicted class of the left out sample `i`
fit_knn_loo <- function(i, x, y, ...) {
  train_control <- caret::trainControl(
    method = "cv",
    number = 5
  )
  # hyperparameter grid for k
  tune_grid <- expand.grid(k = c(5, 10, 15))
  fit <- caret::train(
    x = x[-i, , drop = FALSE],
    y = y[-i],
    method = "knn",
    ...,
    trControl = train_control,
    tuneGrid = tune_grid,
  )
  preds <- as.character(predict(fit, x[i, , drop = FALSE]))
  return(preds)
}
