# indiedown: customize options to rmarkdown::pdf_document() here

#' Customized RMarkdown Document
#'
#' `<<pkg_name>>()` is the main function of the <<pkg_name>> package. Use as
#' `output: <<pkg_name>>::<<pkg_name>>` in the RMarkdown YAML header.
#'
#' @export
<<pkg_name>> <- function(...) {
  indiedown_pdf_document_with_asset(
    highlight = "pygments",
    latex_engine = "lualatex",
    ...
  )
}
