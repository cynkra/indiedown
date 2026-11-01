#' Snapshot the pages of a rendered PDF document
#'
#' @description
#' `expect_pdf_snapshot()` renders an R Markdown document to PDF,
#' rasterizes each page to PNG with poppler via the \pkg{pdftools} package,
#' and compares each page with its snapshot
#' using [testthat::expect_snapshot_file()].
#' Use it in the tests of a template package
#' to catch unintended changes to the rendered pages,
#' such as fonts, margins, title pages, or the placement of floats.
#'
#' `skip_if_no_pdf_snapshot()` skips the current test
#' where PDF snapshots cannot be taken:
#' on CRAN, on systems other than Linux,
#' and without \pkg{rmarkdown}, \pkg{pdftools}, pandoc, or LaTeX.
#' `expect_pdf_snapshot()` calls it before rendering.
#'
#' @section Snapshot files:
#' For `name = "report"`, the snapshot directory of the test file holds
#' `report-page-01.png`, `report-page-02.png`, and so on, one for each page,
#' and `report-environment.txt`, a record of the toolchain.
#' The record lists the versions of the operating system, R, pandoc, LaTeX,
#' poppler, fontconfig, FreeType, and the R packages involved,
#' the font that fontconfig offers for Helvetica,
#' and a hash of each font file that the template bundles,
#' or of the fallback fonts.
#' The record never fails a test:
#' it is written when the snapshot is created and kept as is afterwards.
#' To refresh the snapshots and the record,
#' delete the snapshot files of `name` and run the tests again.
#'
#' Pixel-exact comparisons are only stable on a fixed toolchain,
#' so `skip_if_no_pdf_snapshot()` skips on systems other than Linux.
#' A positive `tolerance` accepts small differences.
#'
#' testthat deletes the snapshot files that a complete test run does not use.
#' When it skips or when rendering fails,
#' `expect_pdf_snapshot()` declares the existing snapshot files of `name`
#' with [testthat::announce_snapshot_file()],
#' so that a test run on a system without LaTeX keeps them.
#'
#' @section Fonts:
#' R's [grDevices::pdf()] device does not embed the fonts of a plot,
#' it refers to Helvetica by name.
#' poppler substitutes the font that fontconfig offers for Helvetica,
#' so the rasterized plot text depends on the fonts installed on the system.
#' Unless `system_fonts = TRUE`,
#' `expect_pdf_snapshot()` therefore lets fontconfig see
#' only the fonts that the template bundles in `fonts`
#' while the document is rendered and rasterized.
#' If the template bundles no fonts,
#' Latin Modern Sans from the LaTeX installation is the fixed fallback.
#' The pages are rasterized in a separate R process,
#' because fontconfig reads its configuration only once per process.
#'
#' @param name Prefix of the snapshot file names, unique within a test file.
#' @param rmd The lines of the R Markdown document, a character vector.
#'   It is rendered in a temporary directory,
#'   in a new environment whose parent is the global environment.
#' @param ... These dots are for future extensions and must be empty.
#' @param tolerance The share of pixels, between 0 and 1,
#'   that may differ between a page and its snapshot.
#'   The default, 0, requires the PNG files to be byte-identical.
#'   A positive value needs the \pkg{png} package.
#' @param dpi Resolution of the rasterized pages, in dots per inch.
#' @param system_fonts If `FALSE`, the default,
#'   fontconfig sees only the fonts in `fonts`, or the fallback.
#'   If `TRUE`, it sees the fonts installed on the system.
#' @param fonts Directory with the fonts that the template bundles.
#'   The default, `NULL`, uses `inst/indiedown/fonts`
#'   of the package being tested.
#' @return `expect_pdf_snapshot()` is called for its side effects
#'   and returns `NULL`, invisibly.
#'   `skip_if_no_pdf_snapshot()` returns `TRUE`, invisibly,
#'   if it does not skip.
#'
#' @export
#' @examples
#' # In tests/testthat/test-visual.R of a template package called mydown:
#' \dontrun{
#' test_that("the report looks right", {
#'   indiedown::expect_pdf_snapshot(
#'     "report",
#'     c(
#'       "---",
#'       "title: Report",
#'       "date: January 1, 2026",
#'       "output: mydown::mydown",
#'       "---",
#'       "",
#'       "Some text."
#'     )
#'   )
#' })
#' }
expect_pdf_snapshot <- function(
  name,
  rmd,
  ...,
  tolerance = 0,
  dpi = 100,
  system_fonts = FALSE,
  fonts = NULL
) {
  rlang::check_installed("testthat", "to take PDF snapshots.")
  rlang::check_dots_empty()
  check_pdf_snapshot_args(name, rmd, tolerance, dpi, system_fonts, fonts)

  # Unless the snapshots are taken, declare the existing ones,
  # so that a complete test run does not delete them as unused.
  taken <- FALSE
  withr::defer(if (!taken) announce_pdf_snapshot(name))

  skip_if_no_pdf_snapshot()
  rlang::check_installed("callr", "to rasterize PDF snapshots.")
  if (tolerance > 0) {
    rlang::check_installed("png", "to compare PDF snapshots with a tolerance.")
  }

  dir <- withr::local_tempdir()
  fonts <- fonts %||% template_fonts()
  if (!system_fonts) {
    fonts <- visible_fonts(fonts, dir)
    withr::local_envvar(FONTCONFIG_FILE = write_fonts_conf(fonts, dir))
  }

  input <- file.path(dir, paste0(name, ".Rmd"))
  writeLines(rmd, input)
  pdf <- rmarkdown::render(
    input,
    output_dir = dir,
    quiet = TRUE,
    envir = new.env(parent = globalenv())
  )

  pages <- rasterize_pdf(pdf, name, dpi)
  record <- paste0(name, "-environment.txt")
  writeLines(
    pdf_snapshot_environment(pdf, fonts, system_fonts),
    file.path(dir, record)
  )

  # Injecting the file name gives a readable label in failure messages
  compare <- compare_png(tolerance)
  for (page in pages) {
    rlang::inject(testthat::expect_snapshot_file(
      file.path(dir, !!page),
      compare = compare
    ))
  }
  rlang::inject(testthat::expect_snapshot_file(
    file.path(dir, !!record),
    compare = compare_true
  ))

  taken <- TRUE
  invisible()
}

#' @rdname expect_pdf_snapshot
#' @export
skip_if_no_pdf_snapshot <- function() {
  rlang::check_installed("testthat", "to skip PDF snapshots.")
  testthat::skip_on_cran()
  if (!identical(tolower(Sys.info()[["sysname"]]), "linux")) {
    testthat::skip("PDF snapshots are pixel-exact on Linux only")
  }
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not_installed("pdftools")
  testthat::skip_if_not(
    rmarkdown::pandoc_available(),
    "pandoc is not available"
  )
  testthat::skip_if_not(has_latex(), "LaTeX is not available")
  invisible(TRUE)
}

check_pdf_snapshot_args <- function(
  name,
  rmd,
  tolerance,
  dpi,
  system_fonts,
  fonts,
  call = rlang::caller_env()
) {
  if (!rlang::is_string(name) || !nzchar(name)) {
    cli_abort("{.arg name} must be a non-empty string.", call = call)
  }
  if (!is.character(rmd)) {
    cli_abort("{.arg rmd} must be a character vector.", call = call)
  }
  if (!is_number(tolerance) || tolerance < 0 || tolerance > 1) {
    cli_abort("{.arg tolerance} must be a number between 0 and 1.", call = call)
  }
  if (!is_number(dpi) || dpi <= 0) {
    cli_abort("{.arg dpi} must be a positive number.", call = call)
  }
  if (!rlang::is_bool(system_fonts)) {
    cli_abort("{.arg system_fonts} must be `TRUE` or `FALSE`.", call = call)
  }
  if (!is.null(fonts) && !(rlang::is_string(fonts) && dir.exists(fonts))) {
    cli_abort(
      "{.arg fonts} must be the path to a directory or `NULL`.",
      call = call
    )
  }
}

is_number <- function(x) {
  is.numeric(x) && length(x) == 1 && !is.na(x)
}

has_latex <- function() {
  (rlang::is_installed("tinytex") && tinytex::is_tinytex()) ||
    any(nzchar(Sys.which(c("pdflatex", "xelatex", "lualatex"))))
}

announce_pdf_snapshot <- function(name) {
  if (!testthat::is_testing()) {
    return(invisible())
  }
  files <- unique(basename(list.files(
    testthat::test_path("_snaps"),
    recursive = TRUE
  )))
  prefix <- paste0(name, "-")
  rest <- substring(files, nchar(prefix) + 1)
  ours <- startsWith(files, prefix) &
    grepl("^(page-[0-9]+[.]png|environment[.]txt)$", rest)
  for (file in files[ours]) {
    testthat::announce_snapshot_file(file)
  }
  invisible()
}

# The fonts of the package being tested, by the indiedown convention
template_fonts <- function() {
  package <- testthat::testing_package()
  if (!nzchar(package)) {
    return(NULL)
  }
  tryCatch(
    as.character(fs::path_package(package, "indiedown", "fonts")),
    error = function(e) NULL
  )
}

font_files <- function(dir) {
  if (is.null(dir) || !dir.exists(dir)) {
    return(character())
  }
  files <- list.files(
    dir,
    pattern = "[.](otf|ttf|ttc|pfa|pfb)$",
    ignore.case = TRUE,
    recursive = TRUE
  )
  sort(files, method = "radix")
}

# The fallback is only added if the template bundles no fonts:
# next to the bundled fonts, fontconfig would offer it for some styles
# and mix two families in one plot.
visible_fonts <- function(fonts, dir) {
  if (length(font_files(fonts)) > 0) {
    return(fonts)
  }

  files <- paste0(
    "lmsans10-",
    c("regular", "bold", "oblique", "boldoblique"),
    ".otf"
  )
  paths <- run_command("kpsewhich", files)
  if (length(paths) != length(files)) {
    cli_abort(c(
      "Can't find the fallback font Latin Modern Sans with {.code kpsewhich}.",
      i = paste(
        "Bundle fonts with the template in {.path inst/indiedown/fonts},",
        "or set {.code system_fonts = TRUE}."
      )
    ))
  }

  fallback <- file.path(dir, "fonts-fallback")
  dir.create(fallback)
  file.copy(paths, fallback)
  fallback
}

write_fonts_conf <- function(fonts, dir) {
  conf <- file.path(dir, "fonts.conf")
  writeLines(
    c(
      "<?xml version=\"1.0\"?>",
      "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">",
      "<fontconfig>",
      paste0("  <dir>", xml_escape(fonts), "</dir>"),
      paste0(
        "  <cachedir>",
        xml_escape(file.path(dir, "fontconfig-cache")),
        "</cachedir>"
      ),
      "</fontconfig>"
    ),
    conf
  )
  conf
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# Returns the file names of the pages, in the directory of `pdf`.
rasterize_pdf <- function(pdf, name, dpi) {
  # `filenames` is a format for sprintf(): page number and file extension
  prefix <- gsub("%", "%%", file.path(dirname(pdf), name), fixed = TRUE)
  pages <- callr::r(
    function(pdf, filenames, dpi) {
      pdftools::pdf_convert(
        pdf,
        format = "png",
        filenames = filenames,
        dpi = dpi,
        verbose = FALSE
      )
    },
    args = list(pdf, paste0(prefix, "-page-%02d.%s"), dpi)
  )
  basename(pages)
}

compare_png <- function(tolerance) {
  force(tolerance)
  function(old, new) {
    if (testthat::compare_file_binary(old, new)) {
      return(TRUE)
    }
    if (tolerance == 0) {
      return(FALSE)
    }
    old <- png::readPNG(old)
    new <- png::readPNG(new)
    if (!identical(dim(old), dim(new))) {
      return(FALSE)
    }
    differs <- old != new
    if (length(dim(differs)) == 3) {
      differs <- rowSums(differs, dims = 2) > 0
    }
    mean(differs) <= tolerance
  }
}

# The environment record is never compared
compare_true <- function(old, new) {
  TRUE
}

pdf_snapshot_environment <- function(pdf, fonts = NULL, system_fonts = FALSE) {
  info <- Sys.info()
  pandoc <- if (rmarkdown::pandoc_available()) {
    as.character(rmarkdown::pandoc_version())
  } else {
    NA_character_
  }
  packages <- c("pdftools", "rmarkdown", "knitr", "tinytex")
  files <- font_files(fonts)

  c(
    "# Toolchain used to generate the visual snapshots in this directory.",
    "# Pixel-exact comparisons are only stable on this toolchain; refreshed",
    "# only when the snapshots themselves are regenerated.",
    paste0("os: ", info[["sysname"]], " ", info[["release"]]),
    paste0("r: ", getRversion()),
    paste0("pandoc: ", pandoc),
    paste0("latex: ", latex_version(pdf)),
    paste0("poppler: ", pdftools::poppler_config()$version),
    paste0("fontconfig: ", fontconfig_version()),
    paste0("freetype: ", loaded_library("libfreetype")),
    paste0(packages, ": ", vapply(packages, package_version_or_na, "")),
    paste0("system fonts: ", if (system_fonts) "visible" else "hidden"),
    paste0("fc-match Helvetica: ", run_command("fc-match", "Helvetica")[1]),
    if (length(files) > 0) {
      paste0("font: ", files, " ", rlang::hash_file(file.path(fonts, files)))
    }
  )
}

# The engine is inferred from the PDF producer that it writes
latex_version <- function(pdf) {
  producer <- pdftools::pdf_info(pdf)$keys$Producer %||% NA_character_
  engine <- if (grepl("xdvipdfmx", producer, ignore.case = TRUE)) {
    "xelatex"
  } else if (grepl("LuaTeX|LuaHBTeX", producer, ignore.case = TRUE)) {
    "lualatex"
  } else if (grepl("pdfTeX", producer, ignore.case = TRUE)) {
    "pdflatex"
  }
  if (is.null(engine)) {
    return(paste0("unknown, PDF producer: ", producer))
  }
  run_command(engine, "--version", stderr = TRUE)[1]
}

fontconfig_version <- function() {
  version <- run_command("fc-match", "--version", stderr = TRUE)[1]
  version <- sub("^fontconfig version ", "", version)
  paste0(version, " (", loaded_library("libfontconfig"), ")")
}

# The file name of a shared library loaded into this R process,
# with the full version number of the library
loaded_library <- function(lib) {
  maps <- tryCatch(readLines("/proc/self/maps"), error = function(e) {
    character()
  })
  paths <- grep(paste0("/", lib, "[.]so"), maps, value = TRUE)
  if (length(paths) == 0) {
    return(NA_character_)
  }
  basename(sub("^.* ", "", paths[[1]]))
}

package_version_or_na <- function(package) {
  if (rlang::is_installed(package)) {
    as.character(utils::packageVersion(package))
  } else {
    NA_character_
  }
}

# The lines of the output of a command, or NA if it fails
run_command <- function(command, args, stderr = FALSE) {
  if (!nzchar(Sys.which(command))) {
    return(NA_character_)
  }
  out <- tryCatch(
    suppressWarnings(system2(command, args, stdout = TRUE, stderr = stderr)),
    error = function(e) NA_character_
  )
  if (length(out) == 0 || !is.null(attr(out, "status"))) {
    return(NA_character_)
  }
  out
}
