#' Hardware report (experimental)
#'
#' `dr_down` analyzes the R markdown capabilities of the hardware.
#'
#' @export
dr_down <- function() {

  # Check the version
  pandoc_v <- as.character(rmarkdown::pandoc_version())
  r_v <- paste(version$major, version$minor, sep = ".")

  if (Sys.getenv("RSTUDIO") == "1") {
    rstudio_v <- as.character(rstudioapi::versionInfo()$version)
  } else {
    rstudio_v <- NA_character_
  }

  if("tinytex" %in% rownames(installed.packages())){
    tinytex_v <- as.character(packageVersion("tinytex"))
    is_tinytex = tinytex::is_tinytex()
  } else{
    tinytex_v <- NA_character_
    is_tinytex = FALSE
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
    system.file(package = "indiedown", "dr_down", "test.Rmd"),
    tdir
  )

  try_with_engine <- function(latex_engines) {
    try(
      suppressWarnings(
        rmarkdown::render(
          fs::path(tdir, "test.Rmd"),
          rmarkdown::pdf_document(latex_engine = latex_engines),
          quiet = TRUE
        )
      )
    )
  }

  ans <- lapply(latex_engines, try_with_engine)
  is_success <- setNames(!sapply(ans, inherits, "try-error"), latex_engines)

  # clean up
  fs::dir_delete(tdir)

  list(
    version_info = version_info,
    is_success = is_success,
    is_tinytex = is_tinytex
  )
}
