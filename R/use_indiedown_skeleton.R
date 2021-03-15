#' Skeleton for a Customized RMarkdown Template
#'
#' Set up the packages structure for an indiedown-based customized RMarkdown
#' template. See `vignette("intro")` for a more detailed usage example.
#'
#' @param path Package path
#' @param overwrite Should existing assets be overwritten?
#'
#' @export
#' @examples
#' path <- file.path(tempdir(), "mydown")
#'
#' # set up empty R Package 'mydown'
#' create_indiedown_package(path, overwrite = TRUE)
#'
#' @importFrom fs dir_copy file_move
create_indiedown_package <- function(path, overwrite = FALSE) {


  path_skeleton <- system.file("mypackage", package = "indiedown")

  fs::dir_copy(
    path_skeleton,
    path,
    overwrite = TRUE
  )

  pkg_name <- basename(path)

  withr::local_dir(path)

  files <- c(
    "inst/rmarkdown/templates/report/skeleton/skeleton.Rmd",
    "R/indiedown_pdf_document.R",
    "man/mypackage.Rd",
    "DESCRIPTION",
    "NAMESPACE"
  )

  gsub_in_file(
    pattern = "mypackage",
    replacement = pkg_name,
    file = files
  )

  file.rename(
    "man/mypackage.Rd",
    file.path("man", paste0(pkg_name, ".Rd"))
  )

  # Can't use .here as part of the template due to the leading dot
  writeLines(character(), ".here")

  usethis::ui_done("set up indiedown skeleton")
  usethis::ui_info(paste('see `vignette("intro")` for how to customize', pkg_name))

}
