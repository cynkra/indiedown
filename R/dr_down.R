#' Hardware report (experimental)
#'
#' `dr_down` analyzes the R markdown capabilities of the hardware.
#'
#' @export
#' @examples
#' \dontrun{
#'   indiedown::dr_down()
#' }
dr_down <- function() {

  # Check the version
  pandoc_v <- as.character(rmarkdown::pandoc_version())
  r_v <- paste(version$major, version$minor, sep = ".")

  if (Sys.getenv("RSTUDIO") == "1" && requireNamespace("rstudioapi", quietly = TRUE)) {
    rstudio_v <- as.character(rstudioapi::versionInfo()$version)
  } else {
    rstudio_v <- NA_character_
  }

  if(requireNamespace("tinytex", quietly = TRUE)){
    tinytex_v <- as.character(packageVersion("tinytex"))
    is_tinytex <- tinytex::is_tinytex()
  } else{
    tinytex_v <- NA_character_
    is_tinytex <- FALSE
  }

  version_info <- c(
    r = r_v,
    rstudio = rstudio_v,
    tinytex = tinytex_v,
    pandoc = pandoc_v
  )

  # test different latex engine to compile a basic document
  latex_engines <- c(
    "lualatex",
    "xelatex",
    "pdflatex"
  )

  tdir <- tempfile("dr_down")
  fs::dir_create(tdir)
  a <- fs::file_copy(
    fs::path_package("indiedown", "dr_down", "test.Rmd"),
    tdir
  )

  try_with_engine <- function(latex_engines) {
    tryCatch(
      suppressWarnings(
        rmarkdown::render(
          fs::path(tdir, "test.Rmd"),
          rmarkdown::pdf_document(latex_engine = latex_engines),
          quiet = TRUE
        )
      ),
      error = identity
    )
  }

  ans <- lapply(latex_engines, try_with_engine)
  success <- setNames(!sapply(ans, inherits, "error"), latex_engines)

  # clean up
  fs::dir_delete(tdir)


  cli_h1("System Information")

  cli_alert_info("R-Version: {version_info['r']}")

  cli_alert_info("Operating System: {R.Version()$os}")

  if (is_tinytex) {
    cli_alert_success("tinytex Version: {version_info['tinytex']}")
  } else {
    cli_alert_warning("tinytex not installed")
  }

  if (rmarkdown::pandoc_available()) {
    cli_alert_success("pandoc Version: {version_info['pandoc']}")
  } else {
    cli_alert_warning("pandoc not available")
  }

  cli_alert_info("indiedown Version: {packageVersion('indiedown')}")

  if (!is.na(version_info['rstudio'])) {
    cli_alert_success("RStudio: {version_info['rstudio']}")
  } else {
    cli_alert_info("Running outside of RStudio")
  }


  cli_h1("Test Runs")
  text <- paste("Running", names(success), ifelse(success, "successfully", "unsuccessfully"))
  for (i in seq(text)) {
    if (success[i]) {
      cli_alert_success(text[i])
    } else {
      cli_alert_danger(text[i])
    }
  }

  ans <- list(
    version_info = version_info,
    success = success,
    is_tinytex = is_tinytex
  )
  invisible(ans)
}
