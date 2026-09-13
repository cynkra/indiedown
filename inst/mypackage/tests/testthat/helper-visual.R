# Pixel-exact visual snapshot testing.
#
# `expect_pdf_snapshot()` renders an R Markdown document to PDF, rasterises
# every page to PNG with poppler (pdftools), and compares the PNGs
# byte-for-byte against committed reference images via
# `testthat::expect_snapshot_file()`.
#
# Pixel-exact rendering is only stable on a fixed toolchain, so these tests
# run on Linux only and record the toolchain (LaTeX / package versions) next
# to the snapshots in an `*-environment.txt` file. That record is refreshed
# only when the snapshots are (re)generated: to refresh, delete the relevant
# `tests/testthat/_snaps/<test>` directory and re-run the tests -- both the
# images and the environment record are then written fresh.
#
# Why not vdiffr? vdiffr snapshots the SVG of an R graphics object (ggplot2 /
# grid / base). The regression surface here is the *rendered PDF page* --
# fonts, geometry, margins, logos, title pages, two-column and float layout --
# which is produced by pandoc + LaTeX and which vdiffr never sees (it does not
# run LaTeX). vdiffr would only cover the plot layer, and blindly to how a plot
# is placed on the page. It is a good complement for the graphics helpers
# (e.g. a ggplot theme) but cannot replace rasterised-PDF comparison for what
# these packages are for.

skip_if_no_visual_snapshots <- function() {
  testthat::skip_on_cran()
  if (tolower(Sys.info()[["sysname"]]) != "linux") {
    testthat::skip("pixel-exact visual snapshots run on Linux only")
  }
  testthat::skip_if_not_installed("pdftools")
  testthat::skip_if_not(
    (requireNamespace("tinytex", quietly = TRUE) && tinytex::is_tinytex()) ||
      nzchar(Sys.which("lualatex")),
    "no LaTeX engine (TinyTeX / lualatex) available"
  )
}

visual_snapshot_environment <- function() {
  latex <- tryCatch(
    system2("lualatex", "--version", stdout = TRUE, stderr = FALSE)[[1]],
    error = function(e) NA_character_
  )
  pkg_version <- function(pkg) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      as.character(utils::packageVersion(pkg))
    } else {
      NA_character_
    }
  }
  c(
    "# Toolchain used to generate the visual snapshots in this directory.",
    "# Pixel-exact comparisons are only stable on this toolchain; refreshed",
    "# only when the snapshots themselves are regenerated.",
    paste0("os: ", Sys.info()[["sysname"]], " ", Sys.info()[["release"]]),
    paste0("r: ", as.character(getRversion())),
    paste0("pandoc: ", as.character(rmarkdown::pandoc_version())),
    paste0("latex: ", latex),
    paste0("poppler: ", pdftools::poppler_config()$version),
    paste0("pdftools: ", pkg_version("pdftools")),
    paste0("rmarkdown: ", pkg_version("rmarkdown")),
    paste0("knitr: ", pkg_version("knitr")),
    paste0("tinytex: ", pkg_version("tinytex"))
  )
}

# The environment record lives beside the snapshots but must never *fail* a
# test on its own -- only the rendered images decide pass/fail. An
# always-equal comparator keeps testthat from flagging it as orphaned while
# never producing a spurious diff.
compare_snapshot_environment <- function(old, new) {
  TRUE
}

# Render `rmd` (a character vector of R Markdown lines) to PDF, rasterise each
# page, and snapshot the images. `name` prefixes the snapshot files.
expect_pdf_snapshot <- function(name, rmd, dpi = 100) {
  skip_if_no_visual_snapshots()

  dir <- withr::local_tempdir()
  input <- file.path(dir, paste0(name, ".Rmd"))
  writeLines(rmd, input)

  pdf <- rmarkdown::render(
    input,
    output_dir = dir,
    quiet = TRUE,
    envir = new.env()
  )

  # Rasterise into the temp dir (auto-named), then give each page a stable
  # snapshot name so the committed references are named predictably.
  pngs <- withr::with_dir(
    dir,
    pdftools::pdf_convert(pdf, format = "png", dpi = dpi, verbose = FALSE)
  )

  for (i in seq_along(pngs)) {
    testthat::expect_snapshot_file(
      file.path(dir, pngs[[i]]),
      name = sprintf("%s-page-%02d.png", name, i),
      compare = testthat::compare_file_binary
    )
  }

  env_file <- file.path(dir, paste0(name, "-environment.txt"))
  writeLines(visual_snapshot_environment(), env_file)
  testthat::expect_snapshot_file(
    env_file,
    name = basename(env_file),
    compare = compare_snapshot_environment
  )
}
