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
#' # with open = TRUE (default), it switches to the new project
#' usethis::create_package(path, open = FALSE)
#'
#' # add indiedown assets
#' use_indiedown_skeleton(path, overwrite = TRUE)
#'
#' @importFrom fs dir_copy file_move
use_indiedown_skeleton <- function(path = ".", overwrite = FALSE) {

  pkg_name <- basename(path)

  fs::dir_copy(
    path = system.file("skeleton", package = "indiedown"),
    new_path = path,
    overwrite = overwrite
  )

  gsub_in_file(
    pattern = "<<pkg_name>>",
    replacement = pkg_name,
    file = file.path(path, "inst", "rmarkdown", "templates", "report", "skeleton", "skeleton.Rmd")
  )

  gsub_in_file(
    pattern = "<<pkg_name>>",
    replacement = pkg_name,
    file = file.path(path, "R", "indiedown_pdf_document.R")
  )

  usethis::ui_done("set up indiedown skeleton")
  usethis::ui_info(paste('see `vignette("intro")` for how to customize', pkg_name))

}

