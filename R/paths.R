template_resources = function(package, name, ...) {
  system.file("rmarkdown", "templates", name, "resources", ..., package = package)
}

# report_resources <- function(dir_names) {
#   resources <- lapply(
#     system.file(dir_names, package = getPackageName()),
#     list.files,
#     full.names = TRUE
#   )
#   unlist(resources)
# }
