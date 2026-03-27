library(readr)
library(dplyr)
library(future)
library(furrr)
library(ranger)
library(yardstick)

source("fit_rf_fold.R")

DATA_PATH <- "data"
K <- 5

img1 <- read_table(file.path(DATA_PATH,"image1.txt"), col_names = FALSE)
img2 <- read_table(file.path(DATA_PATH,"image2.txt"), col_names = FALSE)
img3 <- read_table(file.path(DATA_PATH,"image3.txt"), col_names = FALSE)


colnames(img1) <- c("ycoord", "xcoord", "label", "NDAI", "SD", "CORR", "DF", "CF", "BF", "AF", "AN")
colnames(img2) <- c("ycoord", "xcoord", "label", "NDAI", "SD", "CORR", "DF", "CF", "BF", "AF", "AN")
colnames(img3) <- c("ycoord", "xcoord", "label", "NDAI", "SD", "CORR", "DF", "CF", "BF", "AF", "AN")


img1 <- img1 %>% mutate(image = "Image 1")
img2 <- img2 %>% mutate(image = "Image 2")
img3 <- img3 %>% mutate(image = "Image 3")


cloud_data <- bind_rows(img1, img2, img3) %>%
  filter(label != 0) %>%
  mutate(
    cloud = factor(
      ifelse(label == 1, "Cloud", "Not Cloud"),
      levels = c("Not Cloud", "Cloud")
    )
  )

set.seed(331)
fold_ids <- sample(rep(1:K, length.out = nrow(cloud_data)))

availableCores()

n_workers <- 5
plan(multicore, workers = n_workers)
start_time <- Sys.time()

futures <- list()
for (k in 1:K) {
  futures[[k]] <- future({
    fit_rf_fold(
      k,
      cloud_data,
      fold_ids,
      num.trees = 50,
      mtry = 3,
      probability = TRUE
    )
  }, seed = TRUE)
}

errors_parallel <- sapply(futures, value)

end_time <- Sys.time()
execution_time <- end_time - start_time

print(errors_parallel)
print(mean(errors_parallel))
print(var(errors_parallel))
print(execution_time)