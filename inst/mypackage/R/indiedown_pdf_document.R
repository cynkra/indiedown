# indiedown: customize options to rmarkdown::pdf_document() here

#' Customized R Markdown Document
#'
#' `mypackage()` is the main function of the mypackage package. Use as
#' `output: mypackage::mypackage` in the R Markdown YAML header.
#'
#' @section Main font:
#' The main font ships with the package.
#' A document can use another font by setting `mainfont` in its YAML header,
#' a user by setting the option `mypackage.mainfont`, e.g. in `.Rprofile`.
#' The font can be the family name of an installed font or a font file.
#' If it is not installed, the shipped font is used, and a message explains
#' how to install it.
#'
#' @param ... Passed on to [rmarkdown::pdf_document()].
#' @return R Markdown output format to pass to [rmarkdown::render()].
#' @export
mypackage <- function(...) {
  indiedown_pdf_document_with_asset(
    highlight = "pygments",
    latex_engine = "lualatex",
    ...
  )
}
