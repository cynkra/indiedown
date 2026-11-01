# Indiedown functionality, copied from indiedown
#
# do not customize this file!

indiedown_pdf_document_with_asset <- function(includes = NULL, ...) {
  # file preamble
  if (file.exists(file.path(indiedown_path(), "preamble.tex"))) {
    file_preamble <- tempfile(fileext = ".tex")
    txt <- readLines(
      file.path(indiedown_path(), "preamble.tex"),
      encoding = "UTF-8"
    )
    txt <- gsub("<<indiedown_path>>", indiedown_path_tex(), txt, fixed = TRUE)
    writeLines(txt, file_preamble)

    if (is.null(includes)) {
      includes <- rmarkdown::includes(in_header = file_preamble)
    } else {
      if ("in_header" %in% names(includes)) {
        warning(
          "The use of 'includes, in_header' overwrites preamble.tex from asset and may mess up the layout."
        )
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

pre_processor_basic <- function(
  metadata,
  input_file,
  runtime,
  knit_meta,
  files_dir,
  output_dir
) {
  args <- apply_default_yaml(metadata = metadata)
}

apply_default_yaml <- function(metadata) {
  defaults_txt <- readLines(
    file.path(indiedown_path(), "default.yaml"),
    encoding = "UTF-8"
  )

  # replace <<indiedown_path>> by package path
  defaults_txt <- gsub(
    "<<indiedown_path>>",
    indiedown_path_tex(),
    defaults_txt,
    fixed = TRUE
  )

  defaults <- yaml::yaml.load(defaults_txt)

  # the main font is resolved separately, also if set in the document
  fonts <- resolve_fonts(metadata, defaults)
  defaults[c("mainfont", "mainfontoptions")] <- NULL

  # do not apply asset defaults if variable set in document
  defaults_applied <- defaults[setdiff(names(defaults), names(metadata))]

  # pandoc variables take precedence over the document's metadata
  args <- list_to_pandoc_args(c(defaults_applied, fonts))

  # pandoc ignores 'header-includes' if includes$in_header is specified
  # https://github.com/jgm/pandoc/issues/3139
  # we can still use `header-includes` by passing it as a command line option to pandoc
  if (!is.null(rmarkdown::metadata$`header-includes`)) {
    args <- c(
      args,
      "--variable",
      paste0(
        "header-includes:",
        paste(rmarkdown::metadata$`header-includes`, collapse = "\n")
      )
    )
  }

  args
}

# The main font is, in this order:
#
# 1. the font named in the `mainfont` field of the document,
#    or else in the option `<package>.mainfont`,
#    if it is installed;
#    it can be a font file, as a path or as a file name in the TeX tree,
#    or the family name of a system font;
# 2. the font configured with `mainfont` and `mainfontoptions`
#    in default.yaml, typically font files shipped with the package
#    in inst/indiedown/fonts and loaded by path.
#
# Only a font that is named explicitly is looked up on the system,
# so that the output does not depend on the fonts installed by default.
# A message explains how to install a named font that is missing.
# The `mainfontoptions` of the document are used with a named font
# and appended to those of default.yaml otherwise.
#
# Returns a list with the pandoc variables `mainfont` and `mainfontoptions`,
# omitting unset ones.
resolve_fonts <- function(
  metadata,
  defaults,
  option = paste0(utils::packageName(), ".mainfont")
) {
  fallback <- list(
    mainfont = defaults[["mainfont"]],
    mainfontoptions = unlist(defaults[["mainfontoptions"]])
  )
  options <- unlist(metadata[["mainfontoptions"]])

  font <- metadata[["mainfont"]]
  origin <- "the `mainfont` field of the document"
  if (is.null(font)) {
    font <- getOption(option)
    origin <- paste0("the `", option, "` option")
  }

  if (is.null(font)) {
    fonts <- fallback
    fonts$mainfontoptions <- c(fallback$mainfontoptions, options)
  } else if (is.null(fallback$mainfont) || font_is_installed(font)) {
    fonts <- list(mainfont = font, mainfontoptions = options)
  } else {
    message(
      "Font \"",
      font,
      "\" from ",
      origin,
      " is not installed, using \"",
      fallback$mainfont,
      "\" instead.\n",
      "To use \"",
      font,
      "\", ",
      font_install_hint(font),
      "."
    )
    fonts <- fallback
  }

  Filter(Negate(is.null), fonts)
}

font_is_installed <- function(font) {
  if (is_font_file(font)) {
    if (file.exists(font)) {
      return(TRUE)
    }
    if (basename(font) != font) {
      return(FALSE)
    }
    # a file name: look it up in the TeX tree
    kpsewhich <- Sys.which("kpsewhich")
    if (!nzchar(kpsewhich)) {
      # cannot check, leave it to LaTeX
      return(TRUE)
    }
    found <- suppressWarnings(
      system2(kpsewhich, shQuote(font), stdout = TRUE, stderr = FALSE)
    )
    return(length(found) > 0)
  }

  names <- installed_font_names()
  if (is.null(names)) {
    # cannot check, leave it to LaTeX
    return(TRUE)
  }
  tolower(font) %in% tolower(names)
}

is_font_file <- function(font) {
  grepl("[.](otf|ttf|otc|ttc)$", font, ignore.case = TRUE)
}

# Family and PostScript names of the installed system fonts,
# or NULL if they cannot be determined
installed_font_names <- function() {
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    fonts <- systemfonts::system_fonts()
    return(c(fonts$family, fonts$name))
  }

  fc_list <- Sys.which("fc-list")
  if (nzchar(fc_list)) {
    out <- suppressWarnings(system2(
      fc_list,
      c("--format", shQuote("%{family}\\n%{postscriptname}\\n")),
      stdout = TRUE,
      stderr = FALSE
    ))
    return(trimws(unlist(strsplit(out, ",", fixed = TRUE))))
  }

  NULL
}

font_install_hint <- function(font, sysname = Sys.info()[["sysname"]]) {
  if (is_font_file(font)) {
    return(
      "check the path, relative paths start at the directory of the document"
    )
  }
  switch(
    sysname,
    Windows = paste(
      "right-click the font files, choose \"Install for all users\",",
      "and restart R"
    ),
    Darwin = paste(
      "open the font files, click \"Install\" in Font Book,",
      "and restart R"
    ),
    paste(
      "copy the font files to ~/.local/share/fonts, run `fc-cache -f`,",
      "and restart R"
    )
  )
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
  list[is_logical] <- lapply(list[is_logical], function(x) {
    ifelse(x, "yes", "no")
  })
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
  paste(
    readLines(indiedown_path("tex", file), encoding = "UTF-8"),
    collapse = "\n"
  )
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
