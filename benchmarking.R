#' Benchmark ml models
#' 
#' Hany Nagaty
#' May-2021

library(tidyverse)
library(glmnet)
library(microbenchmark)
library(doParallel)
library(doFuture)

data_file <- "processedData.rds"
data <- readRDS(data_file)

# Split data into X & y, needed for glmnet
X <- as.matrix(data[, -1])
y <- data[[1]]

set.seed(123)

cores <- detectCores() - 1
message("Using ", cores, " cores for parallel backend.")

# benchmark
bench <- microbenchmark(
  glm = glm(y ~ ., data = data, family = "poisson"),
  glmnet = glmnet(X, y, family = "poisson"),
  cv.glmnet = cv.glmnet(X, y, family = "poisson"),
  cv.glmnet.doPar = {
    registerDoParallel(cores)
    cv.glmnet(X, y, family = "poisson", parallel = TRUE)},
  cv.glmnet.doFur = {
    plan(multisession, workers = cores)
    cv.glmnet(X, y, family = "poisson", parallel = TRUE)},
  times = 10L,
  control = list(order = "inorder"))

bench

# save results
save_name <- paste0(
  "bechmark_",
  str_extract(Sys.info()["nodename"], ".+?(?=\\.)"),
  "_",
  gsub("-", "", Sys.Date()),
  ".rds")

message("Saving results to: ", save_name)

saveRDS(
  list(
    SysInfo = Sys.info(),
    Date = Sys.Date(),
    SessionInfo = sessionInfo(),
    Cores = cores,
    Benchmark = bench),
  file = save_name)

