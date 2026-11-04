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
#' Otherwise, or if that font is not found, the format's preferred font
#' is used if it is set in `default.yaml` and found,
#' and the font that ships with the package if not.
#' The preferred font is loaded from its font files,
#' which can also be in a folder named by the option `mypackage.font_path`.
#' A message explains how to make a missing font available.
#' It is shown at the start and at the end of the render,
#' and again in the same R session only if its advice changes.
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
