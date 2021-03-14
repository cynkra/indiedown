# indiedown: customize options to rmarkdown::pdf_document() here

#' Customized RMarkdown Document
#'
#' `mypackage()` is the main function of the mypackage package. Use as
#' `output: mypackage::mypackage` in the RMarkdown YAML header.
#'
#' @export
mypackage <- function(...) {
  indiedown_pdf_document_with_asset(
    highlight = "pygments",
    latex_engine = "lualatex",
    ...
  )
}
