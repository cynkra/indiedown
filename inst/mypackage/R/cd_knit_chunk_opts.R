#' Corporate Design: knitr Chunk Options
#'
#' Set knitr chunk options in accordance with corporate design.
#'
#' @param twocolumn Use two-column mode? This will affect `fig.width` and `fig.height`.
#' @param fig.width Figure width. If `NULL`, automatically chosen based on `twocolumn`.
#' @param fig.height Figure height If `NULL`, automatically chosen based on `twocolumn`.
#' @param fig.pos Floating modifier for figures
#' @param message Should messages be shown?
#' @param echo Should echo be shown?
#' @return This function is called for its side effects and returns `NULL`, invisibly.
#' @examples
#' cd_knit_chunk_opts()
#'
#' @export
cd_knit_chunk_opts <- function(twocolumn = default(rmarkdown::metadata$twocolumn, FALSE),
                               fig.width = NULL,
                               fig.height = NULL,
                               fig.pos = "h",
                               message = FALSE,
                               echo = FALSE) {

  if (twocolumn) {
    fig.width <- default(fig.width, 4)
    fig.height <- default(fig.height, 3.5)
  } else {
    if (isTRUE(rmarkdown::metadata$wide)) {
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
    message = message,
    echo = echo
  )

  options(knitr.table.format = "latex")
  invisible()
}
