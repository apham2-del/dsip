#' Widgets to set data and clustering options
clusteringOptionsUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(
    id = ns("options"),
    shiny::tagList(
      #' Dimension reduction options
      bslib::layout_column_wrap(
        shinyWrappers::picker_input(
          ns("dimred_method"),
          label = "Dimension Reduction Method",
          choices = c("PCA", "t-SNE", "UMAP"),
          selected = "PCA"
        ),
        shiny::numericInput(
          ns("dimred_n_components"),
          label = "Number of Components",
          min = 2, value = 100, step = 1
        ),
        shinyWrappers::radio_group_buttons(
          ns("dimred_scale"),
          label = "Scale Data?",
          choices = c("No", "Yes")
        ),
        shiny::conditionalPanel(
          condition = sprintf(
            "input[['%s-dimred_method']] == 't-SNE' || input[['%s-dimred_method']] == 'UMAP'",
            id, id
          ),
          shiny::numericInput(
            ns("dimred_perplexity"),
            label = "Perplexity",
            min = 2, max = 800, value = 30, step = 5
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf(
            "input[['%s-dimred_method']] == 'UMAP'", id
          ),
          shiny::numericInput(
            ns("dimred_min_dist"),
            label = "Minimum Distance",
            min = 0, max = 1, value = 0.1, step = 0.1
          )
        )
      ),
      # Clustering options
      bslib::layout_column_wrap(
        shinyWrappers::radio_group_buttons(
          ns("cluster_mode"),
          label = "Clustering Method",
          choices = c("K-means", "Hierarchical")
        ),
        # Hierarchical clustering options
        shiny::conditionalPanel(
          condition = sprintf("input[['%s-cluster_mode']] == 'Hierarchical'", id),
          shinyWrappers::picker_input(
            ns("linkage"),
            label = "Linkage Metric",
            choices = c("ward.D", "single", "complete", "average"),
            selected = "ward.D",
            width = "80%"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input[['%s-cluster_mode']] == 'Hierarchical'", id),
          shinyWrappers::picker_input(
            ns("distance"),
            label = "Distance Metric",
            choices = c("euclidean", "manhattan", "maximum", "canberra", "binary", "minkowski"),
            selected = "euclidean",
            width = "80%"
          )
        )
      ),
      # Specify number of clusters
      shiny::sliderInput(
        ns("k"),
        label = "Number of clusters",
        min = 2, max = 20, value = 2, step = 1,
        animate = shiny::animationOptions(interval = 2000)
      ),
      # Stability options
      bslib::layout_column_wrap(
        shinyWrappers::radio_buttons(
          ns("stability_metric"), 
          label = "Stability Metric",
          choices = c("ARI", "Jaccard"), 
          inline = TRUE
        ),
        shiny::numericInput(
          ns("subsamp_frac"),
          label = "Subsample Fraction",
          min = 0.1, max = 1, value = 0.8, step = 0.1
        ),
        shiny::numericInput(
          ns("B_stability"),
          label = "Number of Repeated Subsamples",
          min = 10, max = 100, value = 10, step = 10
        )
      ),
      # Choose plot type
      shiny::fluidRow(
        shiny::column(
          8,
          shinyWrappers::radio_group_buttons(
            ns("plot_mode"),
            label = "Plot Type",
            choices = c(
              "Map", "PCA", "t-SNE", "UMAP",
              "Tree", "Scree", "Silhouette", "Stability"
            )
          )
        ),
        shiny::column(
          4,
          # Choose number of components to plot
          shiny::conditionalPanel(
            condition = sprintf(
              "input[['%s-plot_mode']] == 'PCA'", id
            ),
            shiny::numericInput(
              ns("plot_components"),
              label = "Number of Components to Plot",
              min = 2, max = 8, value = 2, step = 1
            )
          )
        )
      ),
      # Run clustering button
      bslib::layout_column_wrap(
        shiny::actionButton(
          ns("submit"),
          label = "Run Clustering"
        )
      ),
      # Show plots
      shiny::conditionalPanel(
        condition = sprintf("input[['%s-plot_mode']] == 'Map'", id),
        shinyWrappers::plotUI(ns("map_plot"))
      ),
      shiny::conditionalPanel(
        condition = sprintf("input[['%s-plot_mode']] == 'Tree'", id),
        shinyWrappers::plotUI(ns("tree_plot"))
      ),
      shiny::conditionalPanel(
        condition = sprintf(
          "input[['%s-plot_mode']] == 'PCA' || input[['%s-plot_mode']] == 't-SNE' || input[['%s-plot_mode']] == 'UMAP'",
          id, id, id
        ),
        shinyWrappers::plotUI(ns("scatter_plot"))
      ),
      shiny::conditionalPanel(
        condition = sprintf(
          "input[['%s-plot_mode']] == 'Scree'", id
        ),
        shinyWrappers::plotUI(ns("scree_plot"))
      ),
      shiny::conditionalPanel(
        condition = sprintf(
          "input[['%s-plot_mode']] == 'Silhouette'", id
        ),
        shinyWrappers::plotUI(ns("silhouette_plot"))
      ),
      shiny::conditionalPanel(
        condition = sprintf(
          "input[['%s-plot_mode']] == 'Stability'", id
        ),
        shinyWrappers::plotUI(ns("stability_plot"))
      ),
    )
  )
}


#' Update clustering option widgets
updateClusteringOptions <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      if (input$dimred_method == "PCA") {
        value <- 100
      } else if (input$dimred_method %in% c("t-SNE", "UMAP")) {
        value <- 2
        if (input$dimred_method == "t-SNE") {
          shiny::updateNumericInput(
            session,
            "dimred_perplexity",
            label = "Perplexity",
            min = 2, max = 800, value = 30, step = 5
          )
        } else if (input$dimred_method == "UMAP") {
          shiny::updateNumericInput(
            session,
            "dimred_perplexity",
            label = "# Neighbors",
            min = 2, value = 15, step = 5
          )
        }
      }
      shiny::updateNumericInput(
        session,
        "dimred_n_components",
        min = 2, value = value, step = 1
      )
    })
  })
}


#' Run clustering
runClustering <- function(id, ling_df) {
  shiny::moduleServer(id, function(input, output, session) {
    # get cleaned linguistics data
    cleanLingData <- shiny::reactive({
      data <- ling_df
      if (input$dimred_scale == "Yes") {
        q_cols <- colnames(data)[stringr::str_starts(colnames(data), "Q")]
        data[, q_cols] <- scale(data[, q_cols], center = TRUE, scale = TRUE)
      }
      return(data)
    })

    # get data after possibly doing dimension reduction
    getData <- shiny::reactive({
      shiny::req(input$dimred_method, input$dimred_n_components)
      if (input$dimred_method == "PCA") {
        X <- doPCA()
      } else if (input$dimred_method == "t-SNE") {
        X <- dotSNE()
      } else if (input$dimred_method == "UMAP") {
        X <- doUMAP()
      }
      X <- X[, 1:input$dimred_n_components, drop = FALSE]
      return(X)
    })

    # do PCA
    doPCA <- shiny::reactive({
      X <- cleanLingData() |>
        get_X_matrix()
      pca_out <- prcomp(X)
      attr(pca_out$x, "sdev") <- pca_out$sdev
      return(pca_out$x)
    })

    # do tSNE
    dotSNE <- shiny::reactive({
      shiny::req(input$dimred_perplexity, input$dimred_n_components)
      X <- cleanLingData() |>
        get_X_matrix()
      tsne_out <- Rtsne::Rtsne(
        X,
        dims = input$dimred_n_components,
        perplexity = input$dimred_perplexity,
        normalize = FALSE
      )
      return(tsne_out$Y)
    })

    # do UMAP
    doUMAP <- shiny::reactive({
      shiny::req(
        input$dimred_perplexity,
        input$dimred_n_components,
        input$dimred_min_dist
      )
      X <- cleanLingData() |>
        get_X_matrix()
      umap_out <- umap::umap(
        X,
        n_components = input$dimred_n_components,
        n_neighbors = input$dimred_perplexity,
        min_dist = input$dimred_min_dist
      )
      return(umap_out$layout)
    })

    # compute distance matrix for hierarchical clustering
    getHclustDist <- shiny::reactive({
      shiny::req(input$distance)
      X <- getData()
      D <- dist(X, method = input$distance)
      return(D)
    })

    # do hierarchical clustering
    doHclust <- shiny::reactive({
      shiny::req(input$linkage, input$distance)
      X <- getData()
      D <- getHclustDist()
      hclust_out <- hclust(D, method = input$linkage)
      dendrogram <- ggdendro::ggdendrogram(hclust_out)
      return(
        list(
          hclust_out = hclust_out,
          dendrogram = dendrogram
        )
      )
    })

    # do kmeans clustering
    doKmeans <- shiny::reactive({
      shiny::req(input$k)
      X <- getData()
      kmeans_out <- stats::kmeans(X, centers = input$k)
      return(kmeans_out)
    })

    # get cluster membership vector
    getClusters <- shiny::reactive({
      shiny::req(input$k)
      if (input$cluster_mode == "Hierarchical") {
        cluster_out <- doHclust()
        clusters <- cutree(cluster_out$hclust_out, k = input$k)
      } else if (input$cluster_mode == "K-means") {
        cluster_out <- doKmeans()
        clusters <- cluster_out$cluster
      }
      return(clusters)
    })

    ## Map plot ---------------------------------------------------------------
    plot_map <- shiny::eventReactive(input$submit, {
      req(input$plot_mode == "Map")
      ling_data <- cleanLingData()
      clusters <- getClusters()
      plt <- plot_dr_map(
        as.numeric(clusters), ling_data, components = 1, by_county = TRUE,
        viridis_option = "C"
      ) +
        ggplot2::labs(
          fill = sprintf("%s Clusters", input$cluster_mode),
          color = sprintf("%s Clusters", input$cluster_mode),
          title = ""
        )
    })
    shinyWrappers::plotServer(
      id = "map_plot",
      plot_fun = plot_map,
      plot_options = FALSE,
      modes = "ggplot"
    )

    ## Tree plot --------------------------------------------------------------
    plot_tree <- shiny::eventReactive(input$submit, {
      req(input$cluster_mode == "Hierarchical", input$plot_mode == "Tree")
      hclust_out <- doHclust()
      return(hclust_out$dendrogram)
    })
    shinyWrappers::plotServer(
      id = "tree_plot",
      plot_fun = plot_tree,
      plot_options = FALSE,
      modes = "ggplot"
    )

    ## Scatter plot -----------------------------------------------------------
    get_dimred_df <- shiny::reactive({
      X <- cleanLingData() |>
        get_X_matrix()
      if (input$plot_mode == "PCA") {
        pca_out <- prcomp(X)
        X <- pca_out$x
      } else if (input$plot_mode == "t-SNE") {
        if (input$dimred_method == "t-SNE") {
          perplexity <- input$dimred_perplexity
        } else {
          perplexity <- 30
        }
        tsne_out <- Rtsne::Rtsne(
          X, dims = 2, perplexity = perplexity, normalize = FALSE
        )
        X <- tsne_out$Y
      } else if (input$plot_mode == "UMAP") {
        if (input$dimred_method == "UMAP") {
          n_neighbors <- input$dimred_perplexity
        } else {
          n_neighbors <- 15
        }
        if (input$dimred_method == "UMAP") {
          min_dist <- input$dimred_min_dist
        } else {
          min_dist <- 0.1
        }
        umap_out <- umap::umap(
          X, n_components = 2, n_neighbors = n_neighbors, min_dist = min_dist
        )
        X <- umap_out$layout
      }
      return(X)
    })
    plot_cluster_scatter <- shiny::eventReactive(input$submit, {
      req(input$plot_mode %in% c("PCA", "t-SNE", "UMAP"))
      X <- get_dimred_df() |>
        as.data.frame()
      clusters <- getClusters()
      if (input$plot_mode == "PCA") {
        n_components <- input$plot_components
      } else {
        n_components <- 2
      }
      plt <- plot_dr_scatter(X, components = 1:n_components, color = clusters) +
        ggplot2::scale_color_viridis_c(option = "C") +
        ggplot2::labs(
          color = sprintf("%s Clusters", input$cluster_mode)
        ) +
        ggplot2::theme_minimal()
      return(plt)
    })
    shinyWrappers::plotServer(
      id = "scatter_plot",
      plot_fun = plot_cluster_scatter,
      plot_options = FALSE,
      modes = "ggplot"
    )

    ## Scree plot -----------------------------------------------------------
    plot_scree <- shiny::eventReactive(input$submit, {
      req(input$dimred_method == "PCA", input$plot_mode == "Scree")
      X <- doPCA()
      scree_df <- data.frame(
        PC = seq_along(attr(X, "sdev")),
        PVE = cumsum(attr(X, "sdev")^2 / sum(attr(X, "sdev")^2))
      )
      plt <- ggplot2::ggplot(scree_df) +
        ggplot2::aes(x = PC, y = PVE) +
        ggplot2::geom_point() +
        ggplot2::geom_line() +
        ggplot2::labs(
          x = "Number of Principal Component",
          y = "Cumulative Proportion of Variance Explained"
        ) +
        ggplot2::theme_minimal()
      return(plt)
    })
    shinyWrappers::plotServer(
      id = "scree_plot",
      plot_fun = plot_scree,
      plot_options = FALSE,
      modes = "plotly"
    )

    ## Silhouette plot -----------------------------------------------------------
    plot_silhouette <- shiny::eventReactive(input$submit, {
      shiny::req(input$plot_mode == "Silhouette")
      k_values <- 2:8
      X <- getData()
      if (input$cluster_mode == "Hierarchical") {
        hclust_out <- doHclust()$hclust_out
      }
      sil_out <- purrr::map(
        k_values,
        function(k) {
          if (input$cluster_mode == "K-means") {
            kmeans_out <- stats::kmeans(X, centers = k)
            clusters <- kmeans_out$cluster
          } else if (input$cluster_mode == "Hierarchical") {
            clusters <- cutree(hclust_out, k = k)
          }
          data.frame(
            k = k,
            s = cluster::silhouette(clusters, dist(X))[, "sil_width"]
          )
        }
      ) |>
        dplyr::bind_rows()
      plt1 <- sil_out |>
        dplyr::group_by(k) |>
        dplyr::summarize(s = mean(s)) |>
        ggplot2::ggplot() +
        ggplot2::aes(x = k, y = s) +
        ggplot2::geom_point() +
        ggplot2::geom_line() +
        ggplot2::scale_x_continuous(breaks = k_values) +
        ggplot2::labs(
          x = "Number of Clusters",
          y = "Average Silhouette Width"
        ) +
        ggplot2::theme_minimal()
      plt2 <- sil_out |>
        ggplot2::ggplot() +
        ggplot2::aes(x = k, y = s, group = k) +
        ggplot2::geom_violin(
          fill = "grey86", color = "transparent", scale = "width"
        ) +
        ggplot2::geom_boxplot(width = 0.2, fill = NA) +
        ggplot2::scale_x_continuous(breaks = k_values) +
        ggplot2::labs(
          x = "Number of Clusters",
          y = "Silhouette Width"
        ) +
        ggplot2::theme_minimal()
      plt <- patchwork::wrap_plots(plt1, plt2, nrow = 1)
      return(plt)
    })
    shinyWrappers::plotServer(
      id = "silhouette_plot",
      plot_fun = plot_silhouette,
      plot_options = FALSE,
      modes = "ggplot"
    )

    # Stability plot -----------------------------------------------------------
    plot_stability <- shiny::eventReactive(input$submit, {
      shiny::req(input$plot_mode == "Stability")
      k_values <- 2:8
      X <- getData()
      if (input$cluster_mode == "Hierarchical") {
        D <- getHclustDist()
      }
      n_subsamp <- input$subsamp_frac * nrow(X)
      stability_out <- purrr::map(
        k_values,
        function(k) {
          js <- purrr::map_dbl(
            1:input$B_stability,
            function(b) {
              subsamp_idx1 <- sample(1:nrow(X), n_subsamp, replace = FALSE)
              subsamp_idx2 <- sample(1:nrow(X), n_subsamp, replace = FALSE)
              clusters1 <- rep(NA, nrow(X))
              clusters2 <- rep(NA, nrow(X))
              if (input$cluster_mode == "K-means") {
                kmeans_out1 <- stats::kmeans(X[subsamp_idx1, ], centers = k)
                kmeans_out2 <- stats::kmeans(X[subsamp_idx2, ], centers = k)
                clusters1[subsamp_idx1] <- kmeans_out1$cluster
                clusters2[subsamp_idx2] <- kmeans_out2$cluster
              } else if (input$cluster_mode == "Hierarchical") {
                hclust_out1 <- hclust(
                  as.dist(as.matrix(D)[subsamp_idx1, subsamp_idx1]),
                  method = input$linkage
                )
                hclust_out2 <- hclust(
                  as.dist(as.matrix(D)[subsamp_idx2, subsamp_idx2]),
                  method = input$linkage
                )
                clusters1[subsamp_idx1] <- cutree(hclust_out1, k = k)
                clusters2[subsamp_idx2] <- cutree(hclust_out2, k = k)
              }
              keep_samples <- intersect(subsamp_idx1, subsamp_idx2)
              if (input$stability_metric == "ARI") {
                js <- mclust::adjustedRandIndex(
                  clusters1[keep_samples], clusters2[keep_samples]
                )
              } else if (input$stability_metric == "Jaccard") {
                js <- jaccard(
                  clusters1[keep_samples], clusters2[keep_samples]
                )
              }
            }
          )
          data.frame(k = k, jaccard = js)
        }
      ) |>
        dplyr::bind_rows()

      plt1 <- stability_out |>
        dplyr::group_by(k) |>
        dplyr::summarize(jaccard = mean(jaccard)) |>
        ggplot2::ggplot() +
        ggplot2::aes(x = k, y = jaccard) +
        ggplot2::geom_point() +
        ggplot2::geom_line() +
        ggplot2::scale_x_continuous(breaks = k_values) +
        ggplot2::labs(
          x = "Number of Clusters",
          y = sprintf("Average %s", input$stability_metric)
        ) +
        ggplot2::theme_minimal()
      plt2 <- stability_out |>
        ggplot2::ggplot() +
        ggplot2::aes(x = k, y = jaccard, group = k) +
        ggplot2::geom_violin(
          fill = "grey86", color = "transparent", scale = "width"
        ) +
        ggplot2::geom_boxplot(width = 0.2, fill = NA) +
        ggplot2::scale_x_continuous(breaks = k_values) +
        ggplot2::labs(
          x = "Number of Clusters",
          y = input$stability_metric
        ) +
        ggplot2::theme_minimal()
      plt <- patchwork::wrap_plots(plt1, plt2, nrow = 1)
      return(plt)
    })
    shinyWrappers::plotServer(
      id = "stability_plot",
      plot_fun = plot_stability,
      plot_options = FALSE,
      modes = "ggplot"
    )
  })
}
