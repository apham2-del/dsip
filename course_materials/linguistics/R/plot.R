#' Plot linguistic survey results on US map
#'
#' @param ling_data the linguistic survey data
#' @param qa_key the question and answer key
#' @param qid the question ID
#' @param point_size the size of the points on the map
#' @param map_type the type of map to plot
#' @param show_contiguous_us whether to show only the contiguous US
#'
#' @returns a ggplot object
plot_ling_map <- function(ling_data, qa_key, qid, point_size = 0.5,
                          map_type = c("state", "county"),
                          viridis_option = "A",
                          show_contiguous_us = TRUE) {
  map_type <- match.arg(map_type)

  # get question ID
  qcol <- dplyr::case_when(
    qid < 100 ~ paste0("Q0", qid),
    TRUE ~ paste0("Q", qid)
  )
  merge_by <- "answer_num"
  names(merge_by) <- qcol

  # get responses for the question of interest
  qid_key <- qa_key |>
    dplyr::filter(qid == !!qid)

  # merge text responses with the survey data
  plt_df <- ling_data |>
    dplyr::left_join(qid_key, by = merge_by)

  if (show_contiguous_us) {
    # remove Hawaii and Alaska for plotting purposes
    plt_df <- plt_df |>
      dplyr::filter(!(state_abb %in% c("HI", "AK")))
  }

  # get state/county boundaries data
  map_df <- ggplot2::map_data(map_type)

  # make map plot
  plt <- plt_df |>
    ggplot2::ggplot() +
    ggplot2::geom_polygon(
      ggplot2::aes(x = long, y = lat, group = group),
      data = map_df, color = "black", fill = NA
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = long, y = lat, color = answer),
      size = point_size
    ) +
    ggplot2::labs(
      title = sprintf("%s: %s", qcol, qid_key$question[[1]]),
      color = "Answer"
    ) +
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank()
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(override.aes = list(size = 3))
    ) +
    # scale it to make it look more like a map
    ggplot2::coord_fixed(1.5)

  return(plt)
}


#' Plot linguistic survey results, aggregated by county
#'
#' @param ling_data the linguistic survey data
#' @param qa_key the question and answer key
#' @param qid the question ID
#' @param linewidth the width of the county borders
#' @param show_contiguous_us whether to show only the contiguous US
#'
#' @returns a ggplot object
plot_ling_map_by_county <- function(ling_data, qa_key, qid, linewidth = 0.1,
                                    show_contiguous_us = TRUE) {

  # get county boundaries data
  map_df <- ggplot2::map_data("county")

  # get question ID
  qcol <- dplyr::case_when(
    qid < 100 ~ paste0("Q0", qid),
    TRUE ~ paste0("Q", qid)
  )
  merge_by <- "answer_num"
  names(merge_by) <- qcol

  if (show_contiguous_us) {
    # remove Hawaii and Alaska for plotting purposes
    ling_data <- ling_data |>
      dplyr::filter(!(state_abb %in% c("HI", "AK")))
  }

  # get responses for the question of interest
  qid_key <- qa_key |>
    dplyr::filter(qid == !!qid)

  # prepare data for plotting
  plt_df <- ling_data |>
    dplyr::left_join(qid_key, by = merge_by) |>
    # do some cleaning of the counties to match the built-in ggplot map data
    dplyr::mutate(
      county = dplyr::case_when(
        state == "louisiana" ~ stringr::str_remove(county, " parish"),
        county == "dekalb" ~ "de kalb",
        county == "desoto" ~ "de soto",
        (state == "virginia") & !(county %in% c("james city", "charles city")) ~
          stringr::str_remove(county, " city"),
        county == "dewitt" ~ "de witt",
        county == "dupage" ~ "du page",
        county == "lamoure" ~ "la moure",
        county == "laporte" ~ "la porte",
        county == "lasalle" ~ "la salle",
        county == "district of columbia" ~ "washington",
        TRUE ~ stringr::str_remove_all(county, "'")
      ),
      state = dplyr::case_when(
        state == "dc" ~ "district of columbia",
        TRUE ~ state
      )
    ) |>
    dplyr::filter(!is.na(answer)) |>
    # aggregate response by county
    dplyr::group_by(county, state) |>
    dplyr::summarise(
      answer = names(which.max(table(answer))[1]),
      .groups = "drop"
    ) |>
    # merge with county boundaries data
    dplyr::left_join(
      map_df, by = c("county" = "subregion", "state" = "region")
    )

  # look at county mismatches in merge
  # plt_df |>
  #   dplyr::filter(is.na(long)) |>
  #   dplyr::distinct(county, state)

  # make map plot
  plt <- plt_df |>
    ggplot2::ggplot() +
    ggplot2::geom_polygon(
      ggplot2::aes(x = long, y = lat, group = group, fill = answer),
      data = plt_df, color = "black", linewidth = linewidth
    ) +
    ggplot2::geom_polygon(
      ggplot2::aes(x = long, y = lat, group = group),
      data = map_df, color = "black", linewidth = linewidth, fill = NA
    ) +
    ggplot2::labs(
      title = sprintf("%s: %s", qcol, qid_key$question[[1]]),
      color = "Answer"
    ) +
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank()
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(override.aes = list(size = 3))
    ) +
    # scale it to make it look more like a map
    ggplot2::coord_fixed(1.5)
  return(plt)
}


#' Plot dimension reduction results as scatter plot
#'
#' @param X the data matrix with scores to plot
#' @param components vector of components to plot
#' @param color a vector to use for coloring data points
#' @param point_size the size of the points
#' @param point_alpha the transparency of the points
#' @param viridis_option the viridis color option ("A" through "H")
#' @param ... additional arguments to pass to ggplot2::theme()
#'
#' @returns a ggplot object
plot_dr_scatter <- function(X, components = 1:2, color = NULL,
                            point_size = 0.5, point_alpha = 1,
                            viridis_option = "A", ...) {
  if (length(components) == 2) {
    # plot 2d scatter plot
    x_var <- names(X)[components[1]]
    y_var <- names(X)[components[2]]
    if (is.null(color)) {
      plt <- X |>
        ggplot2::ggplot() +
        ggplot2::aes(
          x = .data[[x_var]], y = .data[[y_var]]
        )
    } else {
      plt <- X |>
        dplyr::bind_cols(.color = color) |>
        ggplot2::ggplot() +
        ggplot2::aes(
          x = .data[[x_var]], y = .data[[y_var]], color = .color
        )
      if (is.numeric(color)) {
        plt <- plt +
          ggplot2::scale_color_viridis_c(option = viridis_option)
      }
    }
    plt <- plt +
      ggplot2::geom_point(size = point_size)
  } else {
    # plot pair plot
    plt <- ggwrappers::plot_pairs(
      X,
      columns = components,
      color_lower = color,
      point_size = point_size,
      point_alpha = point_alpha
    )
    if (is.numeric(color)) {
      plt <- plt +
        ggplot2::scale_color_viridis_c(option = viridis_option)
    }
  }
  plt <- plt +
    ggplot2::theme_minimal(...)
  return(plt)
}


#' Plot dimension reduction results on a map
#'
#' @param X the data matrix
#' @param ling_data the linguistic data
#' @param ndim the number of top components to plot
#' @param point_size the size of the points
#' @param point_alpha the transparency of the points
#' @param linewidth the width of the county borders
#' @param viridis_option the viridis color option ("A" through "H")
#' @param by_county whether to plot by county
#' @param show_contiguous_us whether to show only the contiguous US
#'
#' @returns a ggplot object
plot_dr_map <- function(X, ling_data, components = 1:2,
                        point_size = 0.5, point_alpha = 0.5, linewidth = 0.1,
                        viridis_option = "A",
                        by_county = FALSE, show_contiguous_us = TRUE) {
  # get state/county boundaries data
  map_type <- ifelse(by_county ,"county", "state")
  map_df <- ggplot2::map_data(map_type)
  state_map_df <- ggplot2::map_data("state")

  # get the data to plot
  X_df <- as.data.frame(X)
  plt_df <- ling_data |>
    dplyr::select(
      tidyselect::any_of(
        c("ZIP", "state_abb", "state", "city", "lat", "long", "county")
      )
    ) |>
    dplyr::bind_cols(X_df)
  if (show_contiguous_us) {
    # remove Hawaii and Alaska for plotting purposes
    plt_df <- plt_df |>
      dplyr::filter(!(state_abb %in% c("HI", "AK")))
  }
  if (by_county) {
    plt_df <- plt_df |>
      # do some cleaning of the counties to match the map data
      dplyr::mutate(
        county = dplyr::case_when(
          state == "louisiana" ~ stringr::str_remove(county, " parish"),
          county == "dekalb" ~ "de kalb",
          county == "desoto" ~ "de soto",
          (state == "virginia") & !(county %in% c("james city", "charles city")) ~
            stringr::str_remove(county, " city"),
          county == "dewitt" ~ "de witt",
          county == "dupage" ~ "du page",
          county == "lamoure" ~ "la moure",
          county == "laporte" ~ "la porte",
          county == "lasalle" ~ "la salle",
          county == "district of columbia" ~ "washington",
          TRUE ~ stringr::str_remove_all(county, "'")
        ),
        state = dplyr::case_when(
          state == "dc" ~ "district of columbia",
          TRUE ~ state
        )
      ) |>
      # aggregate results per county
      dplyr::group_by(county, state) |>
      dplyr::summarise(
        dplyr::across(
          tidyselect::all_of(colnames(X_df)), mean
        ),
        .groups = "drop"
      ) |>
      # merge with county boundaries data
      dplyr::left_join(
        map_df, by = c("county" = "subregion", "state" = "region")
      )
  }

  plt_ls <- list()
  for (i in components) {
    # make map plot
    if (by_county) {
      plt_ls[[i]] <- plt_df |>
        ggplot2::ggplot() +
        ggplot2::geom_polygon(
          ggplot2::aes(
            x = long, y = lat, group = group,
            fill = .data[[colnames(X_df)[i]]],
            color = .data[[colnames(X_df)[i]]]
          ),
          data = plt_df, linewidth = linewidth
        ) +
        ggplot2::geom_polygon(
          ggplot2::aes(x = long, y = lat, group = group),
          data = state_map_df,
          color = "black", linewidth = linewidth * 2, fill = NA
        )
    } else {
      plt_ls[[i]] <- plt_df |>
        ggplot2::ggplot() +
        ggplot2::geom_polygon(
          ggplot2::aes(x = long, y = lat, group = group),
          data = map_df, color = "black", fill = NA
        ) +
        ggplot2::geom_point(
          ggplot2::aes(
            x = long, y = lat, color = .data[[colnames(X_df)[i]]]
          ),
          size = point_size
        )
    }
    plt_ls[[i]] <- plt_ls[[i]] +
      ggplot2::scale_color_viridis_c(option = viridis_option) +
      ggplot2::scale_fill_viridis_c(option = viridis_option) +
      ggplot2::labs(
        title = sprintf("Component %s", i),
        color = "Value", fill = "Value"
      ) +
      ggplot2::theme(
        axis.title = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        panel.grid = ggplot2::element_blank(),
        panel.background = ggplot2::element_blank()
      ) +
      # scale it to make it look more like a map
      ggplot2::coord_fixed(1.5)
  }
  plt <- patchwork::wrap_plots(plt_ls)
  return(plt)
}
