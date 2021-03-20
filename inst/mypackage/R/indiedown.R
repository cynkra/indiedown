# Indiedown functionality, copied from indiedown
#
# do not customize this file!

indiedown_pdf_document_with_asset <- function(includes = NULL, ...) {

  # file preamble
  if (file.exists(file.path(indiedown_path(), "preamble.tex"))) {

    file_preamble <- tempfile(fileext = ".tex")
    txt <- readLines(file.path(indiedown_path(), "preamble.tex"), encoding = "UTF-8")
    txt <- gsub("<<indiedown_path>>", indiedown_path_tex(), txt, fixed = TRUE)
    writeLines(txt, file_preamble)

    if (is.null(includes)) {
      includes <- rmarkdown::includes(in_header = file_preamble)
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
  file_pre_processor <- file.path(indiedown_path(), "pre_processor.R")
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
  defaults_txt <- readLines(file.path(indiedown_path(), "default.yaml"), encoding = "UTF-8")

  # replace <<indiedown_path>> by package path
  defaults_txt <- gsub("<<indiedown_path>>", indiedown_path_tex(), defaults_txt, fixed = TRUE)

  defaults <- yaml::yaml.load(defaults_txt)

  # do not apply asset defaults if variable set in document
  defaults_applied <- defaults[setdiff(names(defaults), names(metadata))]

  args <- list_to_pandoc_args(defaults_applied)

  # pandoc ignores 'header-includes' if includes$in_header is specified
  # https://github.com/jgm/pandoc/issues/3139
  # we can still use `header-includes` by passing it as a command line option to pandoc
  if (!is.null(rmarkdown::metadata$`header-includes`)) {
    args <- c(args, "--variable", paste0("header-includes:", paste(rmarkdown::metadata$`header-includes`, collapse = "\n")))
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

  vars <- paste0(names(list), ":", unlist(list))

  zip <- function(x, y) {
    x <- rep_len(x, length(y))
    m <- matrix(c(x, y), nrow = 2, byrow = TRUE)
    as.vector(m)
  }
  zip("--variable", vars)
}

#' Path helpers
#'
#' `indiedown_path()` creates a path to this package's indiedown assets,
#' located at `inst/indiedown`.
#'
#' @param ... Path components, passed on to `system.file()`.
#' @return Character string, path to this package's indiedown assets
#' @examples
#' indiedown_path()
#' @export
indiedown_path <- function(...) {
  system.file("indiedown", ..., package = utils::packageName())
}

#' Path to indiedown assets, usable in LaTeX
#'
#' `indiedown_path_tex()` creates a path that is usable in LaTeX,
#' with all special characters escaped.
#'
#' @rdname indiedown_path
#' @export
indiedown_path_tex <- function(...) {
  sanitize_tex(indiedown_path(...))
}


sanitize_tex <- function(path) {
  # on win, tex does not like \\
  path <- gsub("\\", "/", fixed = TRUE, path)
  path <- gsub("~", "\\string~", path, fixed = TRUE)
  path
}

#' Glue LaTeX Code for Use in R Markdown
#'
#' Use the function to wrap literal LaTeX code in R. Use a raw string input
#' (`r"()"`) to automatically escape quotes and backslashes, as they are common
#' in LaTeX. Expressions enclosed by `<<` and `>>` will be evaluated as R code.
#'
#' `indiedown_glue()` uses a different default than the underlying
#' `glue::glue()` (`<<` and `>>`), because braces are so common in LaTeX.
#' Doubling the full delimiter (`<<<<` and `>>>>`) escapes it.
#'
#' @param x Character, often as a raw string (`r"()"`)
#' @param .open,.close The opening and closing delimiter.
#' @return Object of class `"knit_asis"` (so that knitr will treat it as is). Usually LaTeX code.
#' @export
#' @examples
#' x <- "something"
#' indiedown_glue(r"(\LaTeX\ code with <<x>> substituted )")
#'
indiedown_glue <- function(x, .open = "<<", .close = ">>") {
  ans <- glue::glue(x, .envir = sys.frame(-1), .open = .open, .close = .close)
  knitr::asis_output(ans)
}


# compatible with older versions. We can use raw strings from 4.0 on.
read_tex <- function(file) {
  paste(readLines(indiedown_path("tex", file), encoding = "UTF-8"), collapse = "\n")
}

#' Set Default Value
#'
#' Set default value of an argument. If `x` is `NULL`, `default` is used.
#'
#' @param x Character string, or `NULL`
#' @param default If `x` is `NULL`, `default` is used.
#'
#' @return Character string
#' @examples
#' default(NULL)
#' default(NULL, "my default")
#' default("a string", "my default")
#' @export
default <- function(x, default = "") {
  ans <- if (is.null(x)) default else x
  force(ans)
}
