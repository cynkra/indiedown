#' Skeleton for a Customized R Markdown Template
#'
#' Set up the packages structure for an indiedown-based customized R Markdown
#' template. See `vignette("indiedown")` for a more detailed usage example.
#'
#' @param path Package path
#' @param overwrite Should existing assets be overwritten?
#'
#' @return This function is called for its side effects and returns `NULL`, invisibly.
#'
#' @export
#' @examples
#' path <- file.path(tempdir(), "mydown")
#'
#' # set up empty R Package 'mydown'
#' create_indiedown_package(path, overwrite = TRUE)
create_indiedown_package <- function(path, overwrite = FALSE) {
  if (fs::dir_exists(path)) {
    if (!overwrite) {
      stop("Path exists, use `overwrite = TRUE` to overwrite.", call. = FALSE)
    }
  } else if (fs::file_exists(path)) {
    stop("Path exists and is a file or a link, remove before proceeding.", call. = FALSE)
  }

  path_skeleton <- system.file("mypackage", package = "indiedown")

  fs::dir_copy(
    path_skeleton,
    path,
    overwrite = TRUE
  )

  pkg_name <- basename(path)

  withr::local_dir(path)

  files <- c(
    "inst/rmarkdown/templates/report/skeleton/skeleton.Rmd",
    "R/indiedown_pdf_document.R",
    "R/use_quarto.R",
    "man/mypackage.Rd",
    "man/use_mypackage_quarto.Rd",
    "DESCRIPTION",
    "NAMESPACE",
    "inst/quarto/_extensions/mypackage/mypackage/_extension.yml",
    "inst/quarto/_extensions/mypackage/mypackage/preamble.tex",
    "inst/quarto/examples/example.qmd"
  )

  gsub_in_file(
    pattern = "mypackage",
    replacement = pkg_name,
    file = files
  )

  if (pkg_name != "mypackage") {
    file.rename(
      "man/mypackage.Rd",
      file.path("man", paste0(pkg_name, ".Rd"))
    )
    file.rename(
      "man/use_mypackage_quarto.Rd",
      file.path("man", paste0("use_", pkg_name, "_quarto.Rd"))
    )
  }

  # Rename the Quarto extension directories from mypackage → pkg_name.
  # Order matters: rename the inner directory first, then the outer.
  if (pkg_name != "mypackage") {
    inner_old <- file.path("inst/quarto/_extensions", "mypackage", "mypackage")
    inner_new <- file.path("inst/quarto/_extensions", "mypackage", pkg_name)
    if (fs::dir_exists(inner_old)) {
      fs::file_move(inner_old, inner_new)
    }
    outer_old <- file.path("inst/quarto/_extensions", "mypackage")
    outer_new <- file.path("inst/quarto/_extensions", pkg_name)
    if (fs::dir_exists(outer_old)) {
      fs::file_move(outer_old, outer_new)
    }
  }

  # Can't use .here as part of the template due to the leading dot
  writeLines(character(), ".here")

  cli_alert_success("indiedown skeleton set up at {.file {path}}")
  cli_alert_info('See {.code vignette("indiedown")} for how to customize the {pkg_name} package')

  if (!rlang::is_installed("rmarkdown")) {
    cli_alert_warning("Install the {.pkg rmarkdown} package to create documents from this template.")
  }

  invisible()
}
