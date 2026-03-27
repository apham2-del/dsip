library(readr)
library(dplyr)
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
  filter(label !=0) %>%
  mutate(
    cloud = factor(
      ifelse(label == 1, "Cloud", "Not Cloud"),
      levels = c("Not Cloud", "Cloud")
    )
  )

set.seed(331)
fold_ids <- sample(rep(1:K, length.out = nrow(cloud_data)))

start_time <- Sys.time()

img1 <- img1 %>% mutate(image = "Image 1")
img2 <- img2 %>% mutate(image = "Image 2")
img3 <- img3 %>% mutate(image = "Image 3")
