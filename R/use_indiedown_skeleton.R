#' Skeleton for a Customized RMarkdown Template
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
#'
use_indiedown_skeleton <- function(path = ".", overwrite = FALSE) {

  pkg_name <- basename(path)

  path_skeleton <- system.file("skeleton", package = "indiedown")

  fs::dir_copy(
    path = fs::path(path_skeleton),
    new_path = fs::path(path),
    overwrite = overwrite
  )

  usethis::ui_done("set up indiedown skeleton")

  use_indiedown_pdf_document(path, overwrite = overwrite)

  usethis::ui_info(paste("see ... for how to customize", pkg_name))

}

