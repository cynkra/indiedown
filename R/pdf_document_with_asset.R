#' @export
pdf_document_with_asset = function(asset, ...) {

  ans <- rmarkdown::pdf_document(...)

  # or find a better way to do this
  .path_assets <<- system.file("assets", package = asset)

  # browser()

  # use pre_processor from asset package or pre_processor_basic, if not present
  if (.path_assets != "") {
    env <- environment()
    source(file.path(.path_assets, "pre_processor.R"), env)
    stopifnot(exists("pre_processor", envir = env))
  } else {
    pre_processor <- pre_processor_basic
  }

  ans$pre_processor <- pre_processor
  ans

}


pre_processor_basic <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
  args <- apply_default_yaml()
}

apply_default_yaml <- function() {
  path_assets <- .path_assets
  defaults <- yaml::read_yaml(file.path(path_assets, "default.yaml"))

  # do not apply asset defaults if variable set in document
  defaults_applied <- defaults[setdiff(names(defaults), names(metadata))]

  args <- list_to_pandoc_args(defaults_applied)
  args
}


# list <- list(
#   indent = TRUE,
#   `compact-title` = TRUE,
#   classoption = c("twocolumn", "landscape")
# )
# list_to_pandoc_args(list)
list_to_pandoc_args <- function(list) {

  is_logical <- vapply(list, is.logical, TRUE)
  is_character <- vapply(list, is.character, TRUE)

  # prepare logicals (TRUE FALSE to yes no)
  list[is_logical] <- lapply(list[is_logical], function(x) ifelse(x, "yes", "no"))
  # prepare character (comma separate multiple values)
  list[is_character] <- lapply(list[is_character], paste, collapse = ",")

  vars <- paste0(names(list),":",unlist(list))

  # zip in '--variable' before each element
  unlist(strsplit(paste("--variable", vars, sep = "$$TEMPSEP$$"), split = "$$TEMPSEP$$",  fixed = TRUE))

}
