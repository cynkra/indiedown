#' @export
cd_knit_chunk_opts <- function(metadata = rmarkdown::metadata,
                               fig.width = NULL,
                               fig.height = NULL,
                               fig.pos = "h",
                               cache = FALSE,
                               message = FALSE,
                               echo = FALSE,
                               tidy = FALSE
                               ) {

  if (metadata$twocolumn) {
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
    fig.pos = "h",
    cache = FALSE,
    message = FALSE,
    echo = FALSE,
    tidy = FALSE
  )

  options(knitr.table.format = "latex")
}
