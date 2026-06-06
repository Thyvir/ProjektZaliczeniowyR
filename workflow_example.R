# Ładujemy cały pakiet do pamięci
devtools::load_all()

# 1. Wczytanie danych z folderu "dane"
dane_sprzedazowe <- load_sales_data("dane")

# 2. Wywołanie walidacji
raport_jakosci <- validate_sales_ts(dane_sprzedazowe)

# Wyświetlenie raportu w konsoli
print(raport_jakosci)

#3. Czyszczenie danych
#Uzupełniamy braki zerami i upewniamy się, że nie ma duplikatów

dane_czyste <- clean_sales_ts(
  df = dane_sprzedazowe,
  fill_na_method = "zero",
  time_aggregation = NULL,
  sort_data = TRUE
)

#4. Obliczenie metryk biznesowych
#Wyliczamy 7-dniową średnią kroczącą oraz metryki, definiując szczyty jako top 5% sprzedaży

metryki <- compute_sales_metrics(
  df = dane_czyste,
  window_size = 7,
  peak_threshold_percentile = 0.95
)

#Wyświetlenie podsumowania metryk dla poszczególnych sklepów i produktów

print(head(metryki$metrics_summary))

# 5. Wizualizacja trendów sprzedaży
# Generujemy ogólny wykres trendu na oczyszczonych danych
wykres_ogolny <- plot_sales_trends(df = dane_czyste)

# Wyświetlamy wykres w oknie "Plots"
print(wykres_ogolny)

# 6. Analiza wybranego segmentu (funkcja wyższego rzędu)
# Sprawdzamy pełną logikę (filtrowanie, metryki, wykres) dla wybranego miasta i okna czasowego
analiza_segmentu <- sales_ts_logic(
  df = dane_czyste,
  cities = c("Quito"),             # Filtrujemy tylko sklepy w Quito
  types = c("A", "D"),             # Wybrane typy sklepów
  start_date = "2016-01-01",       # Analiza od 2016 roku
  group_by_var = "family"          # Kolory na wykresie odpowiadają kategoriom produktów
)

# Podglądamy automatycznie wygenerowany wykres dla tego konkretnego segmentu
print(analiza_segmentu$plot)

# 7. Generowanie podsumowania biznesowego (Management Summary)
# Wyciągamy wnioski KPI porównując ostatnie 30 dni z poprzednimi 30 dniami
podsumowanie_biznesowe <- create_management_summary(
  df = dane_czyste,
  period_days = 30
)

# Wyświetlamy najważniejsze wyniki (np. najlepszy sklep i rosnącą kategorię)
cat("\nNajlepszy sklep (całkowita sprzedaż):\n")
print(podsumowanie_biznesowe$best_store)

cat("\nNajszybciej rosnąca kategoria (ostatnie 30 dni):\n")
print(podsumowanie_biznesowe$fastest_growing_category)

# 8. Prognozowanie przyszłej sprzedaży (ARIMA & Prophet)
# Generujemy prognozę sprzedaży dla całego agregatu na najbliższe 14 dni
# (Zapewniamy dostępność pakietów używanych wewnątrz funkcji)
library(forecast)
library(prophet)

prognozy <- create_prognosis(
  df = dane_czyste,
  h = 14
)

# Wyświetlamy bezpośrednie porównanie wyników z obu algorytmów
cat("\nPorównanie prognoz (ARIMA vs Prophet) na najbliższe dni:\n")
print(head(prognozy$comparison_df))
