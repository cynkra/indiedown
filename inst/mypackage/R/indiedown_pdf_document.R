# indiedown: customize options to rmarkdown::pdf_document() here

#' Customized R Markdown Document
#'
#' `mypackage()` is the main function of the mypackage package. Use as
#' `output: mypackage::mypackage` in the R Markdown YAML header.
#'
#' @section Main font:
#' A document can set the main font in the `mainfont` field of its YAML header,
#' a user in the option `mypackage.mainfont`, e.g. in `.Rprofile`.
#' The font can be the name of an installed font or a font file.
#' Otherwise, or if that font is not installed, the format's preferred font
#' is used if it is set in `default.yaml` and installed,
#' and the font that ships with the package if not.
#' A message explains how to install a missing font, once per session.
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
