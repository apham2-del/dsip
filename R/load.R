
#' @param path the path to the dates data files
#'
#' @returns A data frame containing the epoch information with three columns:
#'   epoch number, date, and day
#'   

load_dates_data <- function(path = here::here("data")) {
  epoch_nums <- read.table(
    file.path(path, "sonoma-dates-epochNums.txt"),
    col.names = "number"
  )
  epoch_dates <- read.table(
    file.path(path, "sonoma-dates-epochDates.txt"),
    col.names = "date"
  )
  epoch_days <- read.table(
    file.path(path, "sonoma-dates-epochDays.txt"),
    col.names = "day"
  )

  epoch_data <- cbind(epoch_nums, epoch_dates, epoch_days) |>
    tibble::as_tibble()
  return(epoch_data)
}


#' Load redwood data
#'
#' @param path the path to the redwood data files
#' @param source the source of the data to load: "all", "log", or "net"
#'
#' @returns A data frame containing the specified redwood data
load_redwood_data <- function(path = here::here("data"),
                              source = c("all", "log", "net")) {
  source <- match.arg(source)
  redwood_data <- data.table::fread(
    file.path(path, sprintf("sonoma-data-%s.csv", source))
  ) |>
    tibble::as_tibble()
  return(redwood_data)
}


#' Load mote location data
#'
#' @param path the path to the mote location data file
#'
#' @returns A data frame containing the mote location data
load_mote_location_data <- function(path = here::here("data")) {
  mote_data <- read.table (
    file = file.path(path, "mote-location-data.txt"),
    header = TRUE,
    col.names = c("ID", "Height", "Direc", "Dist", "Tree"),
  ) |> 
    tibble::as_tibble()
  return(mote_data)
}

  # TODO: LOAD MOTE LOCATION DATA


sonoma_all <- load_redwood_data(source = "all")
sonoma_log <- load_redwood_data(source = "log")
sonoma_net <- load_redwood_data(source = "net")
sonoma_combined <- rbind(sonoma_all, sonoma_log, sonoma_net)

mote <- load_mote_location_data()
names(mote)[names(mote)== "ID"] <- "nodeid"

mote$position <- factor(as.character(mote$Tree),levels = c("interior", "edge"))

sonomojoin <- merge(sonoma_combined, mote[, c("nodeid", "position")], by ="nodeid")

no_impute <- c("humidity", "humid_temp", "humid_adj", "hamatop", "hamabot")


for (col in names(sonomojoin)) {
  if (is.numeric(sonomojoin[[col]]) && !(col %in% no_impute)) {
    sonomojoin[[col]][is.na(sonomojoin[[col]])] <- median(sonomojoin[[col]], na.rm = TRUE)
  }
}

sonomojoin_clean <- aggregate(
  . ~ nodeid + epoch + position,
  data = sonomojoin,
  FUN = function(x) {
    if (is.numeric(x)) mean(x, na.rm = TRUE) else x[1]
  }
)

sonomojoin_clean <- sonomojoin_clean[sonomojoin_clean$humidity >= 0 & sonomojoin_clean$humidity <= 100,]


agg_humidity <- aggregate(humidity ~ position + epoch, data = sonomojoin_clean, FUN = function(x) mean(x, na.rm = TRUE))
agg_voltage <- aggregate(voltage ~ position + epoch, data=sonomojoin_clean, FUN = function(x) mean(x, na.rm=TRUE))


library(ggplot2)

ggplot(agg_humidity, aes(x = epoch, y = humidity, color = position)) +
  geom_line(linewidth = 1) + labs(title = "Average Humidity Over Time by Tree Position (%)",
    x = "Epoch", y = "Average Humidity", color = "Tree Position") + theme_minimal()

ggplot(agg_voltage, aes(x = epoch, y = voltage, color = position)) +
  geom_line(linewidth = 1) + coord_cartesian(ylim=c(0,5)) + labs(title = "Average Voltage Over Time by Tree Position",
    x = "Epoch", y = "Average Voltage (V)", color = "Tree Position") + theme_minimal()



boxplot(humidity ~ position, data=sonomojoin_clean, col=c("orchid1", "darksalmon"), xlab="Tree Position", ylab="humidity (%)", main="Humidity Distrib. by Tree Position")


