#' Convert a kable table to a full-width `tabularx`
#'
#' Rewrites the LaTeX produced by `kableExtra` so that a table created with
#' `full_width = TRUE` uses the `tabularx` environment instead of `tabu`. The
#' `tabu` package has known issues with colours and other features; `tabularx`
#' avoids them.
#'
#' @param x Character. The LaTeX code of a `kableExtra` table (typically the
#'   result of a `kable()` / `kable_styling()` pipeline).
#'
#' @return Called for its side effect: prints the rewritten LaTeX via [cat()]
#'   so it can be used in an `asis` chunk.
#'
#' @export
full_width_tabular <- function(x) {
  x <- gsub("{tabu}", "{tabularx}", x, fixed = TRUE)
  x <- gsub(" to \\linewidth ", "{\\linewidth}", x, fixed = TRUE)
  x <- gsub("raggedleft", "raggedleft\\arraybackslash", x, fixed = TRUE)
  x <- gsub("raggedright", "raggedright\\arraybackslash", x, fixed = TRUE)

  # FIXME: centering
  x <- gsub("centering", "centering\\arraybackslash", x, fixed = TRUE)

  cat(x[1])
}
