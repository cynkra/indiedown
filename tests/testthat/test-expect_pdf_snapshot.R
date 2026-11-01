# Runs `code` as the only test file of a temporary test directory,
# as a complete local run that cleans up unused snapshots.
run_snapshot_tests <- function(dir, code) {
  writeLines(
    c("testthat::local_edition(3)", code),
    file.path(dir, "test-pdf.R")
  )
  withr::local_envvar(CI = "false", NOT_CRAN = "true")
  # knitr reports a failed rendering with a message
  results <- suppressMessages(testthat::test_dir(
    dir,
    reporter = "silent",
    stop_on_failure = FALSE,
    stop_on_warning = FALSE
  ))
  as.data.frame(results)
}

local_snaps <- function(files, .local_envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = .local_envir)
  snaps <- file.path(dir, "_snaps", "pdf")
  dir.create(snaps, recursive = TRUE)
  file.create(file.path(snaps, files))
  dir
}

write_test_png <- function(pixels, path) {
  png::writePNG(pixels, path)
  path
}

test_that("expect_pdf_snapshot() validates its arguments", {
  expect_snapshot(error = TRUE, {
    expect_pdf_snapshot("", "")
    expect_pdf_snapshot("doc", 1)
    expect_pdf_snapshot("doc", "", 0)
    expect_pdf_snapshot("doc", "", tolerance = 2)
    expect_pdf_snapshot("doc", "", dpi = 0)
    expect_pdf_snapshot("doc", "", system_fonts = NA)
    expect_pdf_snapshot("doc", "", fonts = tempfile())
  })
})

test_that("the PNG comparison honours `tolerance`", {
  skip_if_not_installed("png")

  dir <- withr::local_tempdir()
  pixels <- array(0.5, c(10, 10, 3))
  old <- write_test_png(pixels, file.path(dir, "old.png"))
  same <- write_test_png(pixels, file.path(dir, "same.png"))
  pixels[1, 1:2, 1] <- 0
  new <- write_test_png(pixels, file.path(dir, "new.png"))
  other <- write_test_png(pixels[1:5, , ], file.path(dir, "other.png"))

  # 2 of 100 pixels differ
  expect_true(compare_png(0)(old, same))
  expect_false(compare_png(0)(old, new))
  expect_false(compare_png(0.019)(old, new))
  expect_true(compare_png(0.02)(old, new))
  expect_false(compare_png(1)(old, other))
})

test_that("a skipped PDF snapshot keeps its snapshot files", {
  local_mocked_bindings(
    skip_if_no_pdf_snapshot = function() testthat::skip("no PDF snapshots")
  )
  kept <- c("doc-page-01.png", "doc-page-02.png", "doc-environment.txt")
  dir <- local_snaps(c(kept, "unused-page-01.png"))

  results <- run_snapshot_tests(
    dir,
    'test_that("doc", indiedown::expect_pdf_snapshot("doc", "Text"))'
  )

  expect_equal(results$skipped, TRUE)
  snaps <- dir(file.path(dir, "_snaps", "pdf"))
  expect_setequal(snaps, kept)
})

test_that("a failed rendering keeps the snapshot files", {
  skip_if_not_installed("rmarkdown")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  kept <- c("doc-page-01.png", "doc-environment.txt")
  dir <- local_snaps(c(kept, "unused-page-01.png"))

  results <- run_snapshot_tests(
    dir,
    c(
      'test_that("doc", {',
      '  rmd <- c("```{r}", "stop(\\"rendering fails\\")", "```")',
      "  indiedown::expect_pdf_snapshot('doc', rmd, system_fonts = TRUE)",
      "})"
    )
  )

  expect_equal(results$error, TRUE)
  snaps <- dir(file.path(dir, "_snaps", "pdf"))
  expect_setequal(snaps, kept)
})

test_that("the environment record lists the toolchain and the fonts", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("rmarkdown")

  dir <- withr::local_tempdir()
  pdf <- file.path(dir, "plot.pdf")
  grDevices::pdf(pdf)
  plot(1)
  grDevices::dev.off()

  fonts <- file.path(dir, "fonts")
  dir.create(fonts)
  writeLines("regular", file.path(fonts, "regular.ttf"))
  writeLines("bold", file.path(fonts, "bold.otf"))
  writeLines("not a font", file.path(fonts, "LICENSE.txt"))

  record <- pdf_snapshot_environment(pdf, fonts, system_fonts = FALSE)

  entries <- grep("^#", record, value = TRUE, invert = TRUE)
  expect_equal(
    sub(": .*", "", entries),
    c(
      "os",
      "r",
      "pandoc",
      "latex",
      "poppler",
      "fontconfig",
      "freetype",
      "pdftools",
      "rmarkdown",
      "knitr",
      "tinytex",
      "system fonts",
      "fc-match Helvetica",
      "font",
      "font"
    )
  )
  expect_true("system fonts: hidden" %in% record)
  expect_match(record, "^latex: unknown, PDF producer: R ", all = FALSE)
  expect_true(
    paste("font: bold.otf", rlang::hash_file(file.path(fonts, "bold.otf"))) %in%
      record
  )
  expect_true(
    paste(
      "font: regular.ttf",
      rlang::hash_file(file.path(fonts, "regular.ttf"))
    ) %in%
      record
  )

  record <- pdf_snapshot_environment(pdf, NULL, system_fonts = TRUE)
  expect_true("system fonts: visible" %in% record)
  expect_false(any(startsWith(record, "font: ")))
})

test_that("expect_pdf_snapshot() renders, compares and tolerates", {
  skip_if_no_pdf_snapshot()
  skip_if_not_installed("png")
  skip_if(
    is.na(run_command("kpsewhich", "lmsans10-regular.otf")),
    "the fallback font Latin Modern Sans is not available"
  )

  dir <- local_snaps(character())
  test <- function(tolerance) {
    c(
      'test_that("doc", {',
      "  indiedown::expect_pdf_snapshot(",
      '    "doc",',
      '    c("---", "output: pdf_document", "---", "", "Some text."),',
      paste0("    tolerance = ", tolerance, ","),
      "    dpi = 20",
      "  )",
      "})"
    )
  }
  snaps <- file.path(dir, "_snaps", "pdf")

  # The first run creates the snapshot and the environment record
  results <- run_snapshot_tests(dir, test(0))
  expect_equal(results$failed, 0)
  expect_setequal(dir(snaps), c("doc-page-01.png", "doc-environment.txt"))
  record <- readLines(file.path(snaps, "doc-environment.txt"))
  expect_true("system fonts: hidden" %in% record)
  expect_match(record, "^fc-match Helvetica: lmsans10-regular.otf", all = FALSE)

  # Change one pixel of the snapshot
  page <- file.path(snaps, "doc-page-01.png")
  pixels <- png::readPNG(page)
  pixels[1, 1, ] <- 1 - pixels[1, 1, ]
  png::writePNG(pixels, page)

  results <- run_snapshot_tests(dir, test(0))
  expect_equal(results$failed, 1)
  expect_true(file.exists(file.path(snaps, "doc-page-01.new.png")))

  results <- run_snapshot_tests(dir, test(0.001))
  expect_equal(results$failed, 0)
  expect_false(file.exists(file.path(snaps, "doc-page-01.new.png")))
})
