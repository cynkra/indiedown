#' @export
pdf_document_with_asset = function(path, includes = NULL, ...) {

  # or find a better way to do this
  .path_asset <<- path

  # file preamble
  if (file.exists(file.path(.path_asset, "preamble.tex"))) {
    # replace <path_asset>
    file_preamble <- tempfile(fileext = ".txt")
    txt <- readLines(file.path(.path_asset, "preamble.tex"), encoding = "UTF-8")
    txt <- gsub("<path_asset>", .path_asset, txt, fixed = TRUE)
    writeLines(txt, file_preamble)

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
  file_pre_processor <- file.path(.path_asset, "pre_processor.R")
  if (file.exists(file_pre_processor)) {
    env <- environment()
    source(file.path(file_pre_processor), env)
    stopifnot(exists("pre_processor", envir = env))
  } else {
    pre_processor <- pre_processor_basic
  }

  ans$pre_processor <- pre_processor
  ans

}

pre_processor_basic <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
  args <- apply_default_yaml(metadata = metadata)
}

apply_default_yaml <- function(metadata) {

  defaults_txt <- readLines(file.path(.path_asset, "default.yaml"), encoding = "UTF-8")

  # replace <path_assets> by package path
  defaults_txt <- gsub("<path_asset>", .path_asset, defaults_txt, fixed = TRUE)

  defaults <- yaml::yaml.load(defaults_txt)

  # do not apply asset defaults if variable set in document
  defaults_applied <- defaults[setdiff(names(defaults), names(metadata))]

  args <- list_to_pandoc_args(defaults_applied)

  # pandoc ignores 'header-includes' if includes$in_header is specified
  # https://github.com/jgm/pandoc/issues/3139
  # we can still use `header-includes` by passing it as a command line option to pandoc
  if(!is.null(metadata$`header-includes`)) {
    args <- c(args, "--variable", paste0("header-includes:", paste(metadata$`header-includes`, collapse = "\n")))
  }

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

  # zip in '--variable' before each element, use unlikely temp separator string
  unlist(strsplit(paste("--variable", vars, sep = "Fwh0VauLpwa7"), split = "Fwh0VauLpwa7",  fixed = TRUE))
}
