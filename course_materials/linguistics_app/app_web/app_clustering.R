#' Run hierarchical clustering Shiny application
#'
#' @param ... Additional arguments to pass to [shiny::shinyApp()]
#'
#' @returns A shiny application
#'
#' @export
run_app <- function(...) {

  # source all functions from R/ folder
  for (fname in list.files(here::here("R"), pattern = "*.R")) {
    source(here::here(file.path("R", fname)))
  }
  source(here::here("app_web", "app_clustering_utils.R"))


  DATA_PATH <- here::here("data")

  # Load data
  ling_df <- readRDS(
    file.path(DATA_PATH, "ling_county_data_cleaned.rds")
  )

  title <- "Linguistics Data Survey: Clustering"

  # picker_width <- "97.5%"

  # UI -------------------------------------------------------------------------
  ui <- shinydashboard::dashboardPage(
    title = title,

    # Header -------------------------------------------------------------------
    shinyWrappers::prettyDashboardHeader(
      title = title,
      title_position = "center",
      title_style = list(
        `font-variant` = "small-caps", `font-size` = "26px",
        `font-family` = "'Quattrocento Sans'"
      )
    ),

    # Sidebar ------------------------------------------------------------------
    shinydashboard::dashboardSidebar(disable = TRUE),

    # Body ---------------------------------------------------------------------
    shinydashboard::dashboardBody(
      shinyWrappers::use_pretty_style(),
      shinyjs::useShinyjs(),
      bslib::layout_columns(
        shinyWrappers::prettyBox(
          clusteringOptionsUI(1),
          title = "Pipeline v1"
        ),
        shinyWrappers::prettyBox(
          clusteringOptionsUI(2),
          title = "Pipeline v2"
        )
      ),
      bslib::layout_columns(
        shinyWrappers::prettyBox(
          clusteringOptionsUI(3),
          title = "Pipeline v3"
        ),
        shinyWrappers::prettyBox(
          clusteringOptionsUI(4),
          title = "Pipeline v4"
        )
      )
    )
  )

  # Server ---------------------------------------------------------------------
  server <- function(input, output, session) {
    updateClusteringOptions(1)
    updateClusteringOptions(2)
    updateClusteringOptions(3)
    updateClusteringOptions(4)

    runClustering(1, ling_df)
    runClustering(2, ling_df)
    runClustering(3, ling_df)
    runClustering(4, ling_df)
  }

  shiny::shinyApp(ui, server, ...)
}
