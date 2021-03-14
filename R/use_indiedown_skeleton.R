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


  path_seleton <- system.file("mypackage", package = "indiedown")

  fs::dir_copy(
    path_seleton,
    path,
    overwrite = TRUE
  )

  pkg_name <- basename(path)

  files <- c(
    file.path(path, "inst", "rmarkdown", "templates", "report", "skeleton", "skeleton.Rmd"),
    file.path(path, "R", "indiedown_pdf_document.R"),
    file.path(path, "man", "mypackage.Rd"),
    file.path(path, "DESCRIPTION"),
    file.path(path, "NAMESPACE")
  )

  gsub_in_file(
    pattern = "mypackage",
    replacement = pkg_name,
    file = files
  )

  file.rename(
    file.path(path, "man", "mypackage.Rd"),
    file.path(path, "man", paste0(pkg_name, ".Rd"))
  )

  usethis::ui_done("set up indiedown skeleton")
  usethis::ui_info(paste('see `vignette("intro")` for how to customize', pkg_name))

}

