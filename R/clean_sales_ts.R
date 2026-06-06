#' Czyszczenie szeregów czasowych sprzedaży
#'
#' Funkcja przetwarza dane sprzedażowe: usuwa braki danych, obsługuje
#' duplikaty, umożliwia sortowanie oraz opcjonalną agregację czasową.
#'
#' @param df Obiekt tibble (wynik działania funkcji load_sales_data).
#' @param fill_na_method Metoda uzupełniania braków w sprzedaży: "zero" (domyślnie), "mean" lub "locf" (last observation carried forward).
#' @param time_aggregation Opcjonalna agregacja dat: NULL (brak, dane dzienne), "week", "month".
#' @param sort_data Wartość logiczna (TRUE/FALSE) - czy posortować dane chronologicznie.
#' @return Oczyszczony obiekt tibble.
#' @export
#' @import dplyr
#' @import tidyr
#' @import lubridate
clean_sales_ts <- function(df, fill_na_method = "zero", time_aggregation = NULL, sort_data = TRUE) {

  # 1. Opcjonalne sortowanie danych
  if (sort_data) {
    df <- df %>% dplyr::arrange(date, store_nbr, family)
  }

  # 2. Agregacja czasowa (jeśli podana)
  if (!is.null(time_aggregation)) {
    df <- df %>%
      dplyr::mutate(date = lubridate::floor_date(date, unit = time_aggregation))
  }

  # 3. Obsługa duplikatów na poziomie daty, sklepu i kategorii
  # Zamiast usuwać duplikaty, agregujemy je sumując sprzedaż i uśredniając stan promocji
  df <- df %>%
    dplyr::group_by(date, store_nbr, family) %>%
    dplyr::summarise(
      sales = sum(sales, na.rm = TRUE),
      onpromotion = mean(onpromotion, na.rm = TRUE),
      .groups = "drop"
    )

  # 4. Obsługa braków danych (NA) w kolumnie 'sales'
  if (fill_na_method == "zero") {
    df <- df %>% tidyr::replace_na(list(sales = 0))
  } else if (fill_na_method == "mean") {
    mean_sales <- mean(df$sales, na.rm = TRUE)
    df <- df %>% tidyr::replace_na(list(sales = mean_sales))
  } else if (fill_na_method == "locf") {
    # Sortowanie jest krytyczne dla metody locf (wypełnianie w dół)
    df <- df %>%
      dplyr::arrange(store_nbr, family, date) %>%
      tidyr::fill(sales, .direction = "down") %>%
      tidyr::replace_na(list(sales = 0)) # Zabezpieczenie dla początkowych NA
  } else {
    warning("Nieznana metoda fill_na_method. Zastosowano uzupełnianie zerami.")
    df <- df %>% tidyr::replace_na(list(sales = 0))
  }

  # 5. Wyzerowanie ujemnej sprzedaży, którą mogła wykryć funkcja validate_sales_ts
  df <- df %>%
    dplyr::mutate(sales = ifelse(sales < 0, 0, sales))

  message("Czyszczenie danych zakończone pomyślnie.")
  return(df)
}
