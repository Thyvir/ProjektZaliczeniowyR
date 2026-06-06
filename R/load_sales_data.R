#' Wczytywanie danych sprzedażowych
#'
#' Funkcja wczytuje surowe pliki CSV pobrane ze strony Kaggle
#' łączy je w jeden obiekt typu tibble, korzystając z pakietu tidyverse.
#'
#' @param path_to_dir Ścieżka do folderu, w którym znajdują się pobrane pliki CSV.
#' @return Obiekt tibble zawierający połączone dane z train.csv, stores.csv i holidays_events.csv.
#' @export
#' @import readr
#' @import dplyr
load_sales_data <- function(path_to_dir) {
  # Sprawdzenie czy folder istnieje
  if (!dir.exists(path_to_dir)) {
    stop("Podany folder nie istnieje. Sprawdź ścieżkę.")
  }

  # Wczytanie danych z użyciem readr (tidyverse)
  train <- readr::read_csv(file.path(path_to_dir, "train.csv"), show_col_types = FALSE)
  stores <- readr::read_csv(file.path(path_to_dir, "stores.csv"), show_col_types = FALSE)
  holidays <- readr::read_csv(file.path(path_to_dir, "holidays_events.csv"), show_col_types = FALSE)

  # Łączenie danych
  #left_join, aby zachować wszystkie rekordy sprzedażowe z pliku train
  merged_data <- train %>%
    dplyr::left_join(stores, by = "store_nbr") %>%
    # W dni bez świąt pojawią się wartości NA w kolumnach ze świąt
    dplyr::left_join(holidays, by = "date", relationship = "many-to-many")

  return(merged_data)
}
