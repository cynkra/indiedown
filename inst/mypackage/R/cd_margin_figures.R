#' Enable tufte-style margin and full-width figures
#'
#' Optional module. Call it on the format returned by
#' `indiedown_pdf_document_with_asset()` to map two chunk options onto
#' dedicated float environments:
#'
#' * `fig.margin = TRUE` places the figure in the margin (`marginfigure`),
#' * `fig.fullwidth = TRUE` spans the full text width (`figure*`).
#'
#' It also registers a `marginfigure` knitr engine so that ```` ```{marginfigure} ````
#' blocks (margin text, not figures) are wrapped in the same environment.
#'
#' The LaTeX side needs the `marginfigure` environment. The skeleton
#' `preamble.tex` ships a commented-out `\\usepackage{sidenotes}` line that
#' provides it (and makes `figure*` behave); uncomment it when you opt in.
#'
#' @param format A `rmarkdown` output format, typically the result of the
#'   package's own format wrapper.
#' @param width Console width passed to `knitr` (`opts_knit$width`); narrower
#'   values wrap printed output to fit margin notes. Defaults to `45`.
#' @return The modified `format`, invisibly friendly for piping.
#' @export
#' @examples
#' \dontrun{
#' mypackage <- function(...) {
#'   format <- indiedown_pdf_document_with_asset(...)
#'   cd_margin_figures(format)
#' }
#' }
cd_margin_figures <- function(format, width = 45) {
  # a `marginfigure` block engine, so margin *text* can be written as a chunk
  knitr::knit_engines$set(marginfigure = function(options) {
    options$type <- "marginfigure"
    eng_block <- knitr::knit_engines$get("block")
    eng_block(options)
  })

  if (is.null(format$knitr)) {
    format$knitr <- list()
  }
  if (is.null(format$knitr$opts_knit)) {
    format$knitr$opts_knit <- list()
  }
  if (is.null(format$knitr$knit_hooks)) {
    format$knitr$knit_hooks <- list()
  }

  format$knitr$opts_knit$width <- width

  # map fig.margin / fig.fullwidth onto the right float environment
  format$knitr$knit_hooks$plot <- function(x, options) {
    if (isTRUE(options$fig.margin)) {
      options$fig.env <- "marginfigure"
      if (is.null(options$fig.cap)) {
        options$fig.cap <- ""
      }
    } else if (isTRUE(options$fig.fullwidth)) {
      options$fig.env <- "figure*"
      if (is.null(options$fig.cap)) {
        options$fig.cap <- ""
      }
    }

    knitr::hook_plot_tex(x, options)
  }

  format
}
