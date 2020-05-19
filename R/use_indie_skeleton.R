#' @export
use_indie_skeleton <- function(path = ".", overwrite = FALSE) {
  path_skeleton <- system.file("skeleton", package = "indiedown")

  # path_indiedown <- fs::path(path, "inst", "indiedown")
  # path_rmarkdown <- fs::path(path, "inst", "rmarkdown")

  # usethis::use_directory(path_indiedown)
  # usethis::use_directory(path_rmarkdown)

  fs::dir_copy(
    path = fs::path(path_skeleton, "indiedown"),
    new_path = fs::path(path, "inst"),
    overwrite = overwrite
  )
  fs::dir_copy(
    path = fs::path(path_skeleton, "rmarkdown"),
    new_path = fs::path(path, "inst"),
    overwrite = overwrite
  )

}

