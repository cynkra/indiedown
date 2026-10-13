#' Two-column layout for kable tables
#'
#' Rewrites the LaTeX produced by [knitr::kable()] so that a table spans both
#' columns in a two-column document, by turning the `table` environment into
#' `table*`.
#'
#' @param kable_input Output of [knitr::kable()] with a LaTeX format specified.
#' @param placement Character, LaTeX float placement specifiers, one or several
#'   of `Hhtbp!`, or `NULL`.
#' @return Character, the rewritten LaTeX.
#' @export
kable_twocolumn <- function(kable_input, placement = NULL) {
  if (!is.null(placement)) {
    placement <- paste0("[", placement, "]")
  }
  x <- gsub(
    "\\begin{table}",
    paste0("\\begin{table*}", placement),
    kable_input,
    fixed = TRUE
  )
  x <- gsub("\\end{table}", "\\end{table*}", x, fixed = TRUE)
  x
}
