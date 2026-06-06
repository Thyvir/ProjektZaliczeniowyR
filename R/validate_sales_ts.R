#' Walidacja jakości szeregów czasowych
#'
#' Funkcja sprawdza jakość przygotowanych danych sprzedażowych. Weryfikuje braki,
#' duplikaty, poprawne daty, zakresy wartości oraz niespójną częstotliwość.
#'
#' @param df Obiekt tibble (najlepiej wynik działania funkcji load_sales_data).
#' @return Lista zawierająca szczegółowy raport z weryfikacji danych.
#' @export
#' @import dplyr
validate_sales_ts <- function(df) {
  # Inicjalizacja pustej listy na wyniki raportu
  report <- list()

  # 1. Braki danych (NA)
  report$missing_values <- colSums(is.na(df))

  # 2. Duplikaty na poziomie dnia, sklepu i produktu (family)
  report$duplicates <- df %>%
    dplyr::group_by(date, store_nbr, family) %>%
    dplyr::tally() %>%
    dplyr::filter(n > 1) %>%
    nrow()

  if (report$duplicates > 0) {
    warning(paste("Uwaga: Wykryto", report$duplicates, "duplikatów (ta sama data, sklep i kategoria)."))
  }

  # 3. Poprawność dat (czy nie ma wartości NA po konwersji; czy są w formacie Date)
  if (!inherits(df$date, "Date")) {
    warning("Uwaga: Kolumna 'date' nie jest w formacie Date!")
    report$dates_valid <- FALSE
  } else {
    report$dates_valid <- TRUE
  }

  # 4. Sprawdzanie zakresu wartości (np. ujemna sprzedaż)
  report$negative_sales <- df %>%
    dplyr::filter(sales < 0) %>%
    nrow()

  if (report$negative_sales > 0) {
    warning(paste("Uwaga: Wykryto", report$negative_sales, "rekordów z ujemną sprzedażą."))
  }

  # 5. Niespójna częstotliwość (sprawdzanie brakujących dni w ciągłości dat)
  all_dates <- seq(min(df$date, na.rm = TRUE), max(df$date, na.rm = TRUE), by = "day")
  missing_dates <- setdiff(as.Date(all_dates), as.Date(unique(df$date)))

  report$missing_dates_count <- length(missing_dates)

  if (report$missing_dates_count > 0) {
    warning(paste("Uwaga: Wykryto niespójną częstotliwość. Brakuje danych dla",
                  report$missing_dates_count, "dni w szeregu czasowym."))
  }

  # Komunikat o pomyślnym zakończeniu sprawdzania
  message("Walidacja zakończona. Sprawdź zwróconą listę, aby zobaczyć pełny raport.")

  return(report)
}
