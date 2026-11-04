# Copies font files of the skeleton to `dir`, renamed to `names`
copy_fonts <- function(dir, files, names = files) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(
    file.path(
      system.file("mypackage/inst/indiedown/fonts", package = "indiedown"),
      files
    ),
    file.path(dir, names)
  ))
  normalizePath(dir, "/")
}
