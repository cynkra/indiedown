template_resources = function(name, ...) {
  system.file("rmarkdown", "templates", name, "resources", ..., package = "cynkradown")
}

report_resources <- function(dir_names) {
  resources <- lapply(
    system.file(dir_names, package = getPackageName()),
    list.files,
    full.names = TRUE
  )
  unlist(resources)
}
