#' Wizualizacja trendów sprzedaży
#'
#' Funkcja tworzy wykres liniowy przedstawiający trendy sprzedaży w czasie przy użyciu pakietu ggplot2.
#' Pozwala na opcjonalne grupowanie danych (np. po kategoriach produktów lub sklepach).
#'
#' @param df Obiekt tibble (oczyszczone dane sprzedażowe).
#' @param group_var Opcjonalna nazwa zmiennej jako ciąg znaków (np. "family" lub "store_nbr"), według której dane mają zostać pogrupowane na wykresie.
#' @return Obiekt ggplot przedstawiający trendy sprzedaży.
#' @export
#' @import dplyr
#' @import ggplot2
plot_sales_trends <- function(df, group_var = NULL) {

  # Zabezpieczenie przed brakiem danych
  if (nrow(df) == 0) {
    stop("Przekazany zbiór danych jest pusty.")
  }

  # Przygotowanie danych do wykresu w zależności od grupowania
  if (is.null(group_var)) {
    plot_data <- df %>%
      dplyr::group_by(date) %>%
      dplyr::summarise(total_sales = sum(sales, na.rm = TRUE), .groups = "drop")

    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = date, y = total_sales)) +
      ggplot2::geom_line(color = "#2c3e50", size = 1) +
      ggplot2::labs(title = "Ogólny trend sprzedaży w czasie", y = "Całkowita sprzedaż")
  } else {
    # Dynamiczne mapowanie zmiennej grupującej
    plot_data <- df %>%
      dplyr::group_by(date, !!rlang::sym(group_var)) %>%
      dplyr::summarise(total_sales = sum(sales, na.rm = TRUE), .groups = "drop")

    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = date, y = total_sales, color = as.factor(!!rlang::sym(group_var)))) +
      ggplot2::geom_line(size = 0.8) +
      ggplot2::labs(title = paste("Trend sprzedaży w rozbiciu na:", group_var),
                    y = "Całkowita sprzedaż",
                    color = group_var)
  }

  # Wspólne elementy stylistyczne wykresu
  p <- p +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Data") +
    ggplot2::theme(
      plot_title = ggplot2::element_text(face = "bold", size = 14, margin = ggplot2::margin(b = 10)),
      axis.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )

  return(p)
}
