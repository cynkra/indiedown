#' @export
pdf_document_with_asset = function(asset, includes = NULL, ...) {

  # or find a better way to do this
  .path_assets <<- system.file("assets", package = asset)

  # file preamble
  file_preamble <- file.path(.path_assets, "preamle.tex")
  if (file.exists(file_preamble)) {
    if (is.null(includes)) {
      includes <- includes(in_header = file_preamble)
    } else {
      if ("in_header" %in% names(includes)) {
        warning("The use of 'includes, in_header' overwrites preamble.tex from asset and may mess up the layout.")
      } else {
        includes$in_header <- file_preamble
      }
    }
  }

  ans <- rmarkdown::pdf_document(includes = includes, ...)

  # use pre_processor from asset package or pre_processor_basic, if not present
  file_pre_processor <- file.path(.path_assets, "pre_processor.R")
  if (file.exists(file_pre_processor)) {
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

  # add default preamble includes
  defaults_txt <- readLines(file.path(path_assets, "default.yaml"), encoding = "UTF-8")

  # replace <path_assets> by package path
  defaults_txt <- gsub("<path_assets>", path_assets, defaults_txt, fixed = TRUE)

  defaults <- yaml::yaml.load(defaults_txt)

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
