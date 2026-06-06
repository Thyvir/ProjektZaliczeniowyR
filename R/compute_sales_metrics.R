#' Obliczanie metryk biznesowych dla sprzedaży
#'
#' Funkcja wylicza kluczowe wskaźniki takie jak: sprzedaż całkowita,
#' przeciętna sprzedaż, zmienność (odchylenie standardowe), udział promocji,
#' średnia krocząca oraz szacuje średni odstęp pomiędzy szczytami sprzedaży.
#'
#' @param df Oczyszczony obiekt tibble (najlepiej wynik clean_sales_ts).
#' @param window_size Rozmiar okna dla średniej kroczącej (domyślnie 7 dni).
#' @param peak_threshold_percentile Percentyl określający "szczyt" sprzedaży dla danego produktu (domyślnie 0.90, czyli górne 10%).
#' @return Lista zawierająca: 'enriched_ts' (dane ze średnią kroczącą) oraz 'metrics_summary' (tabela zagregowanych metryk per sklep i kategoria).
#' @export
#' @import dplyr
#' @import zoo
compute_sales_metrics <- function(df, window_size = 7, peak_threshold_percentile = 0.90) {

  # 1. Dodanie metryk kroczących do szeregu czasowego
  # Wykonujemy to wewnątrz grup (per sklep i produkt)
  df_enriched <- df %>%
    dplyr::group_by(store_nbr, family) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(
      moving_avg_sales = zoo::rollmean(sales, k = window_size, fill = NA, align = "right")
    ) %>%
    dplyr::ungroup()

  # 2. Obliczanie metryk zagregowanych
  metrics_summary <- df %>%
    dplyr::group_by(store_nbr, family) %>%
    dplyr::summarise(
      total_sales = sum(sales, na.rm = TRUE),
      average_sales = mean(sales, na.rm = TRUE),
      sales_volatility_sd = sd(sales, na.rm = TRUE),
      # Zakładając, że > 0 oznacza obecność promocji w danym dniu/tygodniu
      promo_share_pct = mean(onpromotion > 0, na.rm = TRUE) * 100,

      # Wyznaczenie progu dla szczytu sprzedaży na potrzeby kolejnego kroku
      peak_threshold = quantile(sales, probs = peak_threshold_percentile, na.rm = TRUE),
      .groups = "drop"
    )

  # 3. Zaawansowana metryka: Średnia odległość między szczytami (w dniach)
  peaks_data <- df %>%
    dplyr::left_join(
      metrics_summary %>% dplyr::select(store_nbr, family, peak_threshold),
      by = c("store_nbr", "family")
    ) %>%
    dplyr::filter(sales > peak_threshold) %>%
    dplyr::group_by(store_nbr, family) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(
      days_between_peaks = as.numeric(difftime(date, dplyr::lag(date), units = "days"))
    ) %>%
    dplyr::summarise(
      avg_days_between_peaks = mean(days_between_peaks, na.rm = TRUE),
      .groups = "drop"
    )

  # 4. Połączenie wyników i porządkowanie tabeli
  metrics_summary <- metrics_summary %>%
    dplyr::left_join(peaks_data, by = c("store_nbr", "family")) %>%
    dplyr::select(-peak_threshold) %>%
    # Zamiana wartości NaN (w przypadku braku wystarczającej liczby szczytów) na NA
    dplyr::mutate(
      avg_days_between_peaks = ifelse(is.nan(avg_days_between_peaks), NA, avg_days_between_peaks)
    )

  message("Metryki biznesowe zostały obliczone pomyślnie.")

  return(list(
    enriched_ts = df_enriched,
    metrics_summary = metrics_summary
  ))
}
