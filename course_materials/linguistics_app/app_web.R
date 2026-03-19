# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

# pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
# options("golem.app.prod" = TRUE)
require(maps)
# here::i_am("app_web.R")
source(here::here("app_web", "app_clustering.R"))
run_app() # add parameters here (if any)

# uncomment below to deploy app to shinyapps.io
# rsconnect::deployApp(
#   appFiles = c(
#     "app_web.R",
#     "app_web/app_clustering.R",
#     "app_web/app_clustering_utils.R",
#     "data/ling_county_data_cleaned.rds",
#     "R/utils.R",
#     "R/plot.R",
#     "R/jaccard.R"
#   ),
#   appPrimaryDoc = "app_web.R",
#   appName = "dsip_linguistics",
#   appMode = "shiny"
# )
