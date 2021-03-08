#' @export
use_indie_skeleton <- function(path = ".", overwrite = FALSE) {

  # pernaps use this
  # usethis::create_package()

  # and call the function create_indiedown_package()

  path_skeleton <- system.file("skeleton", package = "indiedown")

  fs::dir_copy(
    path = fs::path(path_skeleton),
    new_path = fs::path(path),
    overwrite = overwrite
  )

  con_pkg <- file(file.path(path, "DESCRIPTION"), "r")
  pkgdescription_function <- readLines(con = con_pkg, n = 1)
  pkg_name <- sub("Package: (.+)", "\\1", pkgdescription_function[1])
  print(pkg_name)
  con <- file(file.path(path, "R", "pkg_name.R"), "r")
  pkgname_function <- readLines(con = con, n = -1)
  close(con)
  pkgname_function[4] <- sub("pkg_name", pkg_name, pkgname_function[4])
  cat(pkgname_function, file = file.path(path, "R", paste0(pkg_name, ".R")), sep = "\n")
  fs::file_delete(file.path(path, "R", "pkg_name.R"))

}

