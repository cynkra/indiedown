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
#' It is looked up like the preferred font,
#' and replaced by the format's fonts, with a message, if it is not found.
#' With LuaLaTeX, a font that `fc-list` does not list is looked up with `luaotfload-tool`,
#' which also finds the fonts of the TeX installation.
#' It is used as named if the lookup cannot tell,
#' e.g. without `fc-list` (with LuaLaTeX: without `luaotfload-tool`),
#' for a font file, or with a `Path=` option.
#' Give a font file by its name only, and put it in the folder of the document
#' or in the TeX installation, or give its folder as `Path=` in `mainfontoptions`:
#' it is not looked up in the folder of the option `mypackage.font_path`.
#' Otherwise, the format's preferred font
#' is used if it is set in `default.yaml` and found,
#' and the font that ships with the package if not.
#' The preferred font can also be loaded from its font files,
#' named after its fonts, in a folder named by the option `mypackage.font_path`.
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
