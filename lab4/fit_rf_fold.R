fit_rf_fold <- function(k, x, fold_ids, ...) {
  train_data <- x[fold_ids != k, ]
  val_data <- x[fold_ids == k, ]
  
  fit <- ranger::ranger(
    cloud ~ NDAI + SD + CORR + DF + CF + BF + AF + AN,
    data = train_data,
    num.threads = 1,
    ...
  )
  
  preds <- predict(fit, data = val_data)$predictions[, "Cloud"]
  preds_class <- ifelse(preds > 0.5, "Cloud", "Not Cloud")
  preds_class <- factor(preds_class, levels = c("Not Cloud", "Cloud"))
  
  return(yardstick::accuracy_vec(val_data$cloud, preds_class))
}

