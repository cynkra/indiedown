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
    "man/mypackage.Rd",
    "DESCRIPTION",
    "NAMESPACE"
  )

  gsub_in_file(
    pattern = "mypackage",
    replacement = pkg_name,
    file = files
  )

  file.rename(
    "man/mypackage.Rd",
    file.path("man", paste0(pkg_name, ".Rd"))
  )

  # Can't use .here as part of the template due to the leading dot
  writeLines(character(), ".here")

  cli_alert_success("indiedown skeleton set up at {.file {path}}")
  cli_alert_info('See {.code vignette("indiedown")} for how to customize the {pkg_name} package')

  if (!rlang::is_installed("rmarkdown")) {
    cli_alert_warning("Install the {.pkg rmarkdown} package to create documents from this template.")
  }

  invisible()
}
