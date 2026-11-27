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

# Restores the fonts registered with sysfonts when the calling test ends,
# sysfonts has no function that removes a registration
local_sysfonts <- function(.local_envir = parent.frame()) {
  env <- asNamespace("sysfonts")$.pkg.env
  old <- mget(c(".font.list", ".font.list.all"), envir = env)
  withr::defer(list2env(old, envir = env), envir = .local_envir)
}
