#' Logika analizy szeregów czasowych na podzbiorach danych
#'
#' Funkcja wyższego rzędu, która filtruje dane na podstawie wybranych metadanych sklepów
#' (miasto, stan, typ) oraz zakresu dat, a następnie automatycznie oblicza metryki biznesowe
#' i generuje wykres trendów sprzedaży.
#'
#' @param df Obiekt tibble (połączone dane z load_sales_data, najlepiej już oczyszczone).
#' @param cities Wektor znakowy z nazwami miast (NULL oznacza brak filtrowania).
#' @param states Wektor znakowy z nazwami stanów (NULL oznacza brak filtrowania).
#' @param types Wektor znakowy z typami sklepów (NULL oznacza brak filtrowania).
#' @param start_date Data początkowa analizy (obiekt Date lub ciąg znaków "YYYY-MM-DD").
#' @param end_date Data końcowa analizy (obiekt Date lub ciąg znaków "YYYY-MM-DD").
#' @param group_by_var Zmienna użyta do grupowania na wykresie (domyślnie "family").
#' @return Lista zawierająca trzy elementy: 'filtered_data', 'metrics' (wynik compute_sales_metrics) oraz 'plot' (obiekt ggplot).
#' @export
#' @import dplyr
sales_ts_logic <- function(df, cities = NULL, states = NULL, types = NULL,
                           start_date = NULL, end_date = NULL, group_by_var = "family") {

  filtered_df <- df

  # 1. Filtrowanie po metadanych sklepów (o ile kolumny istnieją w zbiorze)
  if (!is.null(cities) && "city" %in% names(filtered_df)) {
    filtered_df <- filtered_df %>% dplyr::filter(city %in% cities)
  }
  if (!is.null(states) && "state" %in% names(filtered_df)) {
    filtered_df <- filtered_df %>% dplyr::filter(state %in% states)
  }
  if (!is.null(types) && "type" %in% names(filtered_df)) {
    filtered_df <- filtered_df %>% dplyr::filter(type %in% types)
  }

  # 2. Filtrowanie po czasie
  if (!is.null(start_date)) {
    filtered_df <- filtered_df %>% dplyr::filter(date >= as.Date(start_date))
  }
  if (!is.null(end_date)) {
    filtered_df <- filtered_df %>% dplyr::filter(date <= as.Date(end_date))
  }

  # Zabezpieczenie na wypadek zbyt wąskiego filtra
  if (nrow(filtered_df) == 0) {
    stop("Filtrowanie zwróciło 0 rekordów. Zmień kryteria filtrowania.")
  }

  message(paste("Uruchamianie analizy dla", nrow(filtered_df), "rekordów..."))

  # 3. Wywołanie funkcji obliczającej metryki biznesowe
  calculated_metrics <- compute_sales_metrics(filtered_df)

  # 4. Wywołanie funkcji wizualizującej dane
  trend_plot <- plot_sales_trends(filtered_df, group_var = group_by_var)

  # Zbiorczy wynik
  results <- list(
    filtered_data = filtered_df,
    metrics = calculated_metrics,
    plot = trend_plot
  )

  return(results)
}
