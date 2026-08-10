#' Corporate Design: knitr Chunk Options
#'
#' Set knitr chunk options in accordance with corporate design. Figure
#' dimensions default to sensible values chosen from the `twocolumn` and
#' `wide` metadata fields; all other arguments are passed through to
#' [knitr::opts_chunk].
#'
#' @param metadata Document metadata (YAML header); `twocolumn` and `wide`
#'   determine the default figure dimensions.
#' @param fig.width,fig.height Figure width/height in inches. If `NULL` (the
#'   default), chosen automatically from `twocolumn`/`wide`.
#' @param fig.pos Floating modifier for figures.
#' @param cache Should chunk output be cached?
#' @param message Should messages be shown?
#' @param echo Should source code be echoed?
#' @param tidy Should source code be reformatted?
#' @return This function is called for its side effects and returns `NULL`,
#'   invisibly.
#' @examples
#' cd_knit_chunk_opts()
#'
#' @export
cd_knit_chunk_opts <- function(
  metadata = rmarkdown::metadata,
  fig.width = NULL,
  fig.height = NULL,
  fig.pos = "h",
  cache = FALSE,
  message = FALSE,
  echo = FALSE,
  tidy = FALSE
) {
  if (isTRUE(metadata$twocolumn)) {
    fig.width <- default(fig.width, 4)
    fig.height <- default(fig.height, 3.5)
  } else {
    if (isTRUE(metadata$wide)) {
      fig.width <- default(fig.width, 8.5)
      fig.height <- default(fig.height, 3.38)
    } else {
      fig.width <- default(fig.width, 7.25)
      fig.height <- default(fig.height, 3.5)
    }
  }
  knitr::opts_chunk$set(
    fig.width = fig.width,
    fig.height = fig.height,
    fig.pos = fig.pos,
    cache = cache,
    message = message,
    echo = echo,
    tidy = tidy
  )

  options(knitr.table.format = "latex")
  invisible()
}
