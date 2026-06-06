#' Tworzenie podsumowania menedżerskiego
#'
#' Funkcja generuje raport biznesowy: identyfikuje najlepszy i najgorszy sklep pod względem sprzedaży,
#' najszybciej rosnącą kategorię produktów, produkt o największym spadku procentowym w ostatnim okresie
#' oraz średnią sprzedaż w ostatnim okresie w porównaniu do historycznej.
#'
#' @param df Obiekt tibble (oczyszczone dane sprzedażowe).
#' @param period_days Liczba dni definiująca "ostatni okres" do analizy dynamiki (domyślnie 30 dni).
#' @return Lista zawierająca zestaw kluczowych wskaźników efektywności (KPI) i wniosków biznesowych.
#' @export
#' @import dplyr
#' @import lubridate
create_management_summary <- function(df, period_days = 30) {

  summary_report <- list()

  # 1. Ogólne statystyki sklepów (całościowo)
  store_performance <- df %>%
    dplyr::group_by(store_nbr) %>%
    dplyr::summarise(total_sales = sum(sales, na.rm = TRUE), .groups = "drop")

  summary_report$best_store <- store_performance %>% dplyr::slice_max(total_sales, n = 1) %>% as.list()
  summary_report$worst_store <- store_performance %>% dplyr::slice_min(total_sales, n = 1) %>% as.list()

  # 2. Definicja okresów czasu do badania dynamiki (Ostatni okres vs Poprzedni okres)
  max_date <- max(df$date, na.rm = TRUE)
  split_date_1 <- max_date - lubridate::days(period_days)
  split_date_2 <- split_date_1 - lubridate::days(period_days)

  recent_period <- df %>% dplyr::filter(date > split_date_1 & date <= max_date)
  previous_period <- df %>% dplyr::filter(date > split_date_2 & date <= split_date_1)

  # Średnia sprzedaż w ostatnim okresie
  summary_report$recent_period_avg_daily_sales <- mean(recent_period$sales, na.rm = TRUE)
  summary_report$global_historical_avg_daily_sales <- mean(df$sales, na.rm = TRUE)

  # 3. Analiza dynamiki kategorii (family) pomiędzy okresami
  recent_cat <- recent_period %>%
    dplyr::group_by(family) %>%
    dplyr::summarise(sales_recent = sum(sales, na.rm = TRUE), .groups = "drop")

  previous_cat <- previous_period %>%
    dplyr::group_by(family) %>%
    dplyr::summarise(sales_prev = sum(sales, na.rm = TRUE), .groups = "drop")

  category_growth <- recent_cat %>%
    dplyr::inner_join(previous_cat, by = "family") %>%
    dplyr::mutate(
      absolute_growth = sales_recent - sales_prev,
      percentage_growth = (sales_recent - sales_prev) / sales_prev * 100
    )

  # Najszybciej rosnąca kategoria (wzrost wartościowy)
  summary_report$fastest_growing_category <- category_growth %>%
    dplyr::slice_max(absolute_growth, n = 1) %>%
    dplyr::select(family, absolute_growth, percentage_growth) %>%
    as.list()

  # Największy spadek procentowy
  summary_report$biggest_percentage_drop_category <- category_growth %>%
    dplyr::slice_min(percentage_growth, n = 1) %>%
    dplyr::select(family, absolute_growth, percentage_growth) %>%
    as.list()

  message("Podsumowanie menedżerskie zostało wygenerowane.")
  return(summary_report)
}
