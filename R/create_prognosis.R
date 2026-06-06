#' Prognozowanie sprzedaży przy użyciu modeli ARIMA i Prophet
#'
#' Funkcja agreguje dane do całkowitej sprzedaży dziennej, a następnie tworzy prognozę
#' na określoną liczbę dni w przód za pomocą automatycznego modelu ARIMA oraz modelu Prophet.
#'
#' @param df Obiekt tibble (oczyszczone dane sprzedażowe).
#' @param h Liczba dni do przodu, dla których ma zostać wykonana prognoza (domyślnie 30).
#' @return Lista zawierająca: 'arima_forecast' (obiekt prognozy ARIMA), 'prophet_forecast' (ramka danych z wynikami Prophet) oraz 'comparison_df' (tabela porównawcza prognoz).
#' @export
#' @import dplyr
#' @import forecast
#' @import prophet
create_prognosis <- function(df, h = 30) {

  # 1. Przygotowanie danych - agregacja do sumy dziennej
  daily_series <- df %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(y = sum(sales, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(date)

  if (nrow(daily_series) < 2 * h) {
    stop("Zbyt krótki szereg czasowy, aby zbudować rzetelną prognozę.")
  }

  # --- MODEL 1: ARIMA ---
  message("Trenowanie modelu auto.ARIMA...")
  # Tworzenie obiektu ts (szereg czasowy) - zakładamy częstotliwość 7 dla danych dziennych (sezonowość tygodniowa)
  ts_data <- ts(daily_series$y, frequency = 7)
  arima_model <- forecast::auto.arima(ts_data)
  arima_fc <- forecast::forecast(arima_model, h = h)

  # --- MODEL 2: PROPHET ---
  message("Trenowanie modelu Prophet...")
  # Prophet wymaga konkretnych nazw kolumn: ds (data) i y (wartość)
  prophet_df <- daily_series %>% dplyr::rename(ds = date)
  prophet_model <- prophet::prophet(prophet_df, yearly.seasonality = TRUE, weekly.seasonality = TRUE, daily.seasonality = FALSE)

  future_dates <- prophet::make_future_dataframe(prophet_model, periods = h)
  prophet_fc <- predict(prophet_model, future_dates)

  # 2. Wyciągnięcie wyników do wspólnej tabeli porównawczej na przyszłe dni
  future_start_date <- max(daily_series$date) + 1
  forecast_dates <- seq(future_start_date, by = "day", length.out = h)

  comparison_df <- tibble::tibble(
    date = forecast_dates,
    arima_forecast = as.numeric(arima_fc$mean),
    prophet_forecast = tail(prophet_fc$yhat, h)
  )

  message("Generowanie prognoz zakończone sukcesem.")

  return(list(
    arima_forecast = arima_fc,
    prophet_forecast = prophet_fc,
    comparison_df = comparison_df
  ))
}
