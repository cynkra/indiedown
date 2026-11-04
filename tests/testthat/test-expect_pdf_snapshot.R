# Runs `code` as the only test file of a temporary test directory,
# as a complete local run that cleans up unused snapshots.
# The code sees the internal functions of indiedown.
run_snapshot_tests <- function(dir, code) {
  writeLines(
    c("testthat::local_edition(3)", code),
    file.path(dir, "test-pdf.R")
  )
  withr::local_envvar(CI = "false", NOT_CRAN = "true")
  # knitr reports a failed rendering with a message
  results <- suppressMessages(testthat::test_dir(
    dir,
    env = new.env(parent = asNamespace("indiedown")),
    reporter = "silent",
    stop_on_failure = FALSE,
    stop_on_warning = FALSE
  ))
  # The messages of the failed expectations of each test
  failures <- vapply(
    results,
    function(test) {
      failed <- Filter(
        function(x) inherits(x, "expectation_failure"),
        test$results
      )
      paste(vapply(failed, conditionMessage, character(1)), collapse = "\n")
    },
    character(1)
  )
  cbind(as.data.frame(results), failures = failures)
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

# Pages without text, so that no font is needed to rasterize them
write_test_pdf <- function(path, pages = 1) {
  grDevices::pdf(path, width = 3, height = 3)
  for (i in seq_len(pages)) {
    graphics::plot.new()
    graphics::rect(0.1, 0.1, 0.9, 0.9, col = "grey")
  }
  grDevices::dev.off()
  path
}

# Stands in for the LaTeX step of the rendering,
# `pages()` gives the number of pages
local_mocked_render <- function(pages = function() 1, .env = parent.frame()) {
  local_mocked_bindings(
    render = function(input, output_dir, ...) {
      write_test_pdf(
        file.path(output_dir, sub("[.]Rmd$", ".pdf", basename(input))),
        pages()
      )
    },
    .package = "rmarkdown",
    .env = .env
  )
}

# The message of the skip, or `NA` if the code does not skip
skip_message <- function(code) {
  tryCatch(
    {
      code
      NA_character_
    },
    skip = function(cnd) conditionMessage(cnd)
  )
}

skeleton_fonts <- function() {
  system.file("mypackage", "inst", "indiedown", "fonts", package = "indiedown")
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

test_that("a tolerance needs the png package", {
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  local_mocked_bindings(
    check_installed = function(pkg, reason = NULL, ...) {
      rlang::abort(paste("Package", pkg, "is missing."))
    },
    .package = "rlang"
  )

  expect_error(
    expect_pdf_snapshot("doc", "Text", tolerance = 0.1),
    "Package png is missing."
  )
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

test_that("the PNG comparison handles grayscale images", {
  skip_if_not_installed("png")

  dir <- withr::local_tempdir()
  pixels <- matrix(0.5, 10, 10)
  old <- write_test_png(pixels, file.path(dir, "old.png"))
  pixels[1, 1:2] <- 0
  new <- write_test_png(pixels, file.path(dir, "new.png"))

  expect_false(compare_png(0.019)(old, new))
  expect_true(compare_png(0.02)(old, new))
})

test_that("the environment record is never compared", {
  expect_true(compare_true("old", "new"))
})

test_that("skip_if_no_pdf_snapshot() skips unless the toolchain is complete", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  skip_if_not_installed("showtext")
  skip_if_not_installed("sysfonts")

  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(is_linux = function() TRUE, has_latex = function() TRUE)
  local_mocked_bindings(
    pandoc_available = function(...) TRUE,
    .package = "rmarkdown"
  )
  expect_true(skip_if_no_pdf_snapshot())

  local_mocked_bindings(is_linux = function() FALSE)
  expect_match(
    skip_message(skip_if_no_pdf_snapshot()),
    "Linux only"
  )

  local_mocked_bindings(is_linux = function() TRUE, has_latex = function() {
    FALSE
  })
  expect_match(
    skip_message(skip_if_no_pdf_snapshot()),
    "LaTeX is not available"
  )

  local_mocked_bindings(has_latex = function() TRUE)
  local_mocked_bindings(
    pandoc_available = function(...) FALSE,
    .package = "rmarkdown"
  )
  expect_match(
    skip_message(skip_if_no_pdf_snapshot()),
    "pandoc is not available"
  )
})

test_that("skip_if_no_pdf_snapshot() skips without showtext or sysfonts", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")

  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(is_linux = function() TRUE, has_latex = function() TRUE)
  local_mocked_bindings(
    pandoc_available = function(...) TRUE,
    .package = "rmarkdown"
  )
  missing <- NULL
  local_mocked_bindings(
    skip_if_not_installed = function(package, ...) {
      if (package %in% missing) {
        testthat::skip(paste0("Package ", package, " is not installed"))
      }
    },
    .package = "testthat"
  )

  for (package in c("showtext", "sysfonts")) {
    missing <- package
    expect_match(
      skip_message(skip_if_no_pdf_snapshot()),
      paste0(package, " is not installed")
    )
  }
  missing <- NULL
  expect_true(skip_if_no_pdf_snapshot())
})

test_that("is_linux() reports the operating system", {
  expect_equal(is_linux(), Sys.info()[["sysname"]] == "Linux")
})

test_that("has_latex() finds TinyTeX and the LaTeX engines on the path", {
  skip_if_not_installed("tinytex")
  # Linux is the only system with snapshots, the path is searched differently
  skip_on_os("windows")

  local_mocked_bindings(is_tinytex = function() TRUE, .package = "tinytex")
  expect_true(has_latex())

  local_mocked_bindings(is_tinytex = function() FALSE, .package = "tinytex")
  bin <- withr::local_tempdir()
  withr::local_envvar(PATH = bin)
  expect_false(has_latex())

  for (engine in c("lualatex", "lualatex.exe")) {
    file.create(file.path(bin, engine))
    Sys.chmod(file.path(bin, engine), "755")
  }
  expect_true(has_latex())
})

test_that("a skipped PDF snapshot keeps its snapshot files", {
  local_mocked_bindings(
    skip_if_no_pdf_snapshot = function() testthat::skip("no PDF snapshots")
  )
  kept <- c("doc-page-01.png", "doc-page-02.png", "doc-environment.txt")
  dir <- local_snaps(c(kept, "unused-page-01.png"))

  results <- run_snapshot_tests(
    dir,
    'test_that("doc", expect_pdf_snapshot("doc", "Text"))'
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
      "  expect_pdf_snapshot('doc', rmd, system_fonts = TRUE)",
      "})"
    )
  )

  expect_equal(results$error, TRUE)
  snaps <- dir(file.path(dir, "_snaps", "pdf"))
  expect_setequal(snaps, kept)
})

test_that("only the snapshot files of the name are announced", {
  withr::local_envvar(TESTTHAT = "false")
  expect_null(announce_pdf_snapshot("doc"))
})

test_that("font_files() lists the font files in a directory", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "sub"))
  file.create(file.path(
    dir,
    c("b.ttf", "A.OTF", "c.ttc", "d.pfb", "e.pfa", "README.md", "f.ttf.txt")
  ))
  file.create(file.path(dir, "sub", "g.ttf"))

  expect_equal(
    font_files(dir),
    c("A.OTF", "b.ttf", "c.ttc", "d.pfb", "e.pfa", "sub/g.ttf")
  )
  expect_equal(font_files(file.path(dir, "sub")), "g.ttf")
  expect_equal(font_files(file.path(dir, "missing")), character())
  expect_equal(font_files(NULL), character())
})

test_that("visible_fonts() keeps the bundled fonts", {
  dir <- withr::local_tempdir()
  fonts <- file.path(dir, "fonts")
  dir.create(fonts)
  file.create(file.path(fonts, "regular.ttf"))
  local_mocked_bindings(
    run_command = function(...) stop("The fallback is not needed.")
  )

  expect_equal(visible_fonts(fonts, dir), fonts)
})

test_that("visible_fonts() falls back to Latin Modern Sans", {
  dir <- withr::local_tempdir()
  source <- file.path(dir, "source")
  dir.create(source)
  commands <- list()
  local_mocked_bindings(
    run_command = function(command, args, ...) {
      commands[[length(commands) + 1]] <<- list(command, args)
      file.create(file.path(source, args))
      file.path(source, args)
    }
  )

  fallback <- visible_fonts(file.path(dir, "no-fonts"), dir)

  expect_equal(basename(fallback), "fonts-fallback")
  expect_equal(
    sort(dir(fallback)),
    c(
      "lmsans10-bold.otf",
      "lmsans10-boldoblique.otf",
      "lmsans10-oblique.otf",
      "lmsans10-regular.otf"
    )
  )
  expect_equal(commands[[1]][[1]], "kpsewhich")
})

test_that("visible_fonts() fails without a fallback font", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(run_command = function(...) NA_character_)

  expect_error(visible_fonts(NULL, dir), "kpsewhich")
  expect_error(visible_fonts(NULL, dir), "system_fonts = TRUE")
})

test_that("plot_font_files() matches the font files to the four faces", {
  dir <- withr::local_tempdir()
  file.create(file.path(
    dir,
    c(
      "Font-Regular.otf",
      "Font-Bold.otf",
      "Font-Italic.otf",
      "Font-BoldItalic.otf",
      "README.md"
    )
  ))

  expect_equal(
    plot_font_files(dir),
    list(
      regular = file.path(dir, "Font-Regular.otf"),
      bold = file.path(dir, "Font-Bold.otf"),
      italic = file.path(dir, "Font-Italic.otf"),
      bolditalic = file.path(dir, "Font-BoldItalic.otf")
    )
  )
})

test_that("plot_font_files() takes oblique as italic and ignores the case", {
  dir <- withr::local_tempdir()
  file.create(file.path(
    dir,
    c("sans10-regular.otf", "SANS10-OBLIQUE.OTF", "sans10-boldoblique.otf")
  ))

  files <- plot_font_files(dir)

  expect_equal(basename(files$italic), "SANS10-OBLIQUE.OTF")
  expect_equal(basename(files$bolditalic), "sans10-boldoblique.otf")
})

test_that("plot_font_files() leaves out the missing faces", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "sub"))
  file.create(file.path(dir, "sub", c("regular.ttf", "bold.ttf")))

  files <- plot_font_files(dir)

  expect_named(files, c("regular", "bold", "italic", "bolditalic"))
  expect_equal(files$regular, file.path(dir, "sub", "regular.ttf"))
  expect_equal(files$bold, file.path(dir, "sub", "bold.ttf"))
  expect_null(files$italic)
  expect_null(files$bolditalic)
})

test_that("plot_font_files() takes the first font file as the regular face", {
  dir <- withr::local_tempdir()
  file.create(file.path(dir, c("b-bold.ttf", "a-italic.ttf")))

  files <- plot_font_files(dir)

  expect_equal(files$regular, file.path(dir, "a-italic.ttf"))
  expect_equal(files$italic, file.path(dir, "a-italic.ttf"))
  expect_equal(files$bold, file.path(dir, "b-bold.ttf"))
})

test_that("plot_font_files() is NULL without font files", {
  dir <- withr::local_tempdir()
  file.create(file.path(dir, "README.md"))

  expect_null(plot_font_files(dir))
  expect_null(plot_font_files(file.path(dir, "missing")))
  expect_null(plot_font_files(NULL))
})

test_that("local_showtext() registers the fonts as the default family", {
  skip_if_not_installed("sysfonts")
  dir <- withr::local_tempdir()
  file.create(file.path(dir, c("regular.ttf", "bold.ttf")))
  calls <- list()
  local_mocked_bindings(
    font_add = function(...) calls[[length(calls) + 1]] <<- list(...),
    .package = "sysfonts"
  )

  local_showtext(dir)

  expect_length(calls, 1)
  expect_equal(
    unname(calls[[1]]),
    list(
      "",
      file.path(dir, "regular.ttf"),
      file.path(dir, "bold.ttf"),
      NULL,
      NULL
    )
  )
})

test_that("local_showtext() registers the skeleton fonts with sysfonts", {
  skip_if_not_installed("sysfonts")
  fonts <- skeleton_fonts()
  skip_if(length(font_files(fonts)) == 0, "the skeleton fonts are missing")

  local_showtext(fonts)

  expect_true("" %in% sysfonts::font_families())
})

test_that("local_showtext() sets `fig.showtext` until the function ends", {
  skip_if_not_installed("sysfonts")
  options <- knitr::opts_chunk$get()
  withr::defer(knitr::opts_chunk$restore(options))
  knitr::opts_chunk$set(echo = FALSE)
  expect_null(knitr::opts_chunk$get("fig.showtext"))

  during <- function() {
    local_showtext(NULL)
    knitr::opts_chunk$get("fig.showtext")
  }

  expect_true(during())
  expect_null(knitr::opts_chunk$get("fig.showtext"))
  expect_false(knitr::opts_chunk$get("echo"))
})

test_that("local_showtext() does not register fonts without font files", {
  skip_if_not_installed("sysfonts")
  local_mocked_bindings(
    font_add = function(...) stop("No fonts to register."),
    .package = "sysfonts"
  )

  expect_no_error(local_showtext(withr::local_tempdir()))
})

test_that("write_fonts_conf() lets fontconfig see only the fonts", {
  dir <- withr::local_tempdir()

  conf <- write_fonts_conf("fonts & <more>", dir)

  expect_equal(conf, file.path(dir, "fonts.conf"))
  lines <- readLines(conf)
  expect_equal(lines[[1]], "<?xml version=\"1.0\"?>")
  expect_equal(sum(grepl("<dir>", lines, fixed = TRUE)), 1)
  expect_true("  <dir>fonts &amp; &lt;more&gt;</dir>" %in% lines)
  expect_true(
    paste0("  <cachedir>", dir, "/fontconfig-cache</cachedir>") %in% lines
  )
})

test_that("fontconfig offers only the fonts of the configuration", {
  skip_if(is.na(run_command("fc-match", "Helvetica")[1]), "fc-match is missing")
  fonts <- skeleton_fonts()
  skip_if(length(font_files(fonts)) == 0, "the skeleton fonts are missing")

  dir <- withr::local_tempdir()
  withr::local_envvar(FONTCONFIG_FILE = write_fonts_conf(fonts, dir))

  file <- run_command("fc-match", c("-f", "%{file}", "Helvetica"))
  expect_true(basename(file) %in% font_files(fonts))
})

test_that("convert_pdf() writes a PNG file for each page", {
  skip_if_not_installed("pdftools")

  dir <- withr::local_tempdir()
  pdf <- write_test_pdf(file.path(dir, "doc.pdf"))

  files <- convert_pdf(pdf, file.path(dir, "page-%02d.%s"), 20)

  expect_equal(basename(files), "page-01.png")
  expect_true(file.exists(files))
})

test_that("rasterize_pdf() converts each page to a PNG file", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  skip_if_not_installed("png")

  dir <- withr::local_tempdir()
  pdf <- write_test_pdf(file.path(dir, "doc.pdf"))

  # The name goes into a format, `%` must not be taken as a placeholder
  pages <- rasterize_pdf(pdf, "100%", 20)

  expect_equal(pages, "100%-page-01.png")
  expect_equal(dim(png::readPNG(file.path(dir, pages)))[1:2], c(60, 60))
})

test_that("the environment record lists the toolchain and the fonts", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("rmarkdown")

  dir <- withr::local_tempdir()
  pdf <- write_test_pdf(file.path(dir, "plot.pdf"))

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
      "showtext",
      "sysfonts",
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

test_that("the environment record notes a missing pandoc", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("rmarkdown")
  local_mocked_bindings(
    pandoc_available = function(...) FALSE,
    .package = "rmarkdown"
  )

  pdf <- write_test_pdf(withr::local_tempfile(fileext = ".pdf"))

  expect_true("pandoc: NA" %in% pdf_snapshot_environment(pdf))
})

test_that("latex_engine() infers the engine from the PDF producer", {
  expect_equal(latex_engine("xdvipdfmx (0.7.9)"), "xelatex")
  expect_equal(latex_engine("LuaTeX-1.18.0"), "lualatex")
  expect_equal(latex_engine("LuaHBTeX, Version 1.24.0"), "lualatex")
  expect_equal(latex_engine("pdfTeX-1.40.26"), "pdflatex")
  expect_null(latex_engine("R 4.5.3"))
  expect_null(latex_engine(NA_character_))
})

test_that("latex_version() asks the engine for its version", {
  local_mocked_bindings(
    pdf_producer = function(pdf) "LuaHBTeX, Version 1.24.0",
    run_command = function(command, args, stderr = FALSE) {
      c(paste(command, args, stderr), "second line")
    }
  )
  expect_equal(latex_version("doc.pdf"), "lualatex --version TRUE")

  local_mocked_bindings(pdf_producer = function(pdf) "R 4.5.3")
  expect_equal(latex_version("doc.pdf"), "unknown, PDF producer: R 4.5.3")

  local_mocked_bindings(pdf_producer = function(pdf) NA_character_)
  expect_equal(latex_version("doc.pdf"), "unknown, PDF producer: NA")
})

test_that("pdf_producer() reads the producer of the PDF", {
  skip_if_not_installed("pdftools")

  pdf <- write_test_pdf(withr::local_tempfile(fileext = ".pdf"))

  expect_match(pdf_producer(pdf), "^R ")
})

test_that("fontconfig_version() combines the version and the library", {
  local_mocked_bindings(
    run_command = function(command, args, stderr = FALSE) {
      "fontconfig version 2.15.0"
    },
    loaded_library = function(lib) paste0(lib, ".so.1.14.0")
  )

  expect_equal(fontconfig_version(), "2.15.0 (libfontconfig.so.1.14.0)")
})

test_that("loaded_library() finds the file name of a loaded library", {
  maps <- withr::local_tempfile()
  writeLines(
    c(
      "7f00-7f01 r--p 00000000 08:01 1 /usr/lib/libfoobar.so.2",
      "7f02-7f03 r-xp 00001000 08:01 2 /usr/lib/x86_64/libfoo.so.1.2.3",
      "7f04-7f05 r--p 00002000 08:01 2 /usr/lib/x86_64/libfoo.so.1.2.3"
    ),
    maps
  )

  expect_equal(loaded_library("libfoo", maps), "libfoo.so.1.2.3")
  expect_equal(loaded_library("libbar", maps), NA_character_)
  expect_equal(loaded_library("libfoo", tempfile()), NA_character_)
})

test_that("package_version_or_na() reports installed packages only", {
  expect_equal(
    package_version_or_na("stats"),
    as.character(packageVersion("stats"))
  )
  expect_equal(package_version_or_na("no.such.package"), NA_character_)
})

test_that("run_command() returns the output of a command, or NA", {
  rscript <- file.path(R.home("bin"), "Rscript")

  expect_match(run_command(rscript, "--version", stderr = TRUE)[1], "^R")
  expect_match(run_command(rscript, "--help")[1], "^Usage: Rscript")
  # The command fails with a status
  expect_equal(run_command(rscript, "no-such-file.R"), NA_character_)
  expect_equal(run_command("no-such-command", "--help"), NA_character_)
})

test_that("run_command() returns NA if system2() fails", {
  # system2() fails if `stderr` is neither a flag nor a file
  rscript <- file.path(R.home("bin"), "Rscript")

  expect_equal(
    run_command(rscript, "--version", stderr = character()),
    NA_character_
  )
})

test_that("expect_pdf_snapshot() rasterizes, compares and tolerates", {
  skip_if_not(is_linux(), "PDF snapshots are tested on Linux only")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  skip_if_not_installed("png")
  skip_if_not_installed("sysfonts")
  fonts <- skeleton_fonts()
  skip_if(length(font_files(fonts)) == 0, "the skeleton fonts are missing")

  # Only the LaTeX step is replaced
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  local_mocked_render()

  dir <- local_snaps(character())
  test <- function(tolerance) {
    c(
      'test_that("doc", {',
      "  expect_pdf_snapshot(",
      '    "doc", "Some text.",',
      paste0("    tolerance = ", tolerance, ","),
      "    dpi = 20,",
      paste0("    fonts = ", deparse(fonts)),
      "  )",
      "})"
    )
  }
  snaps <- file.path(dir, "_snaps", "pdf")

  # The first run creates the snapshot and the environment record
  results <- run_snapshot_tests(dir, test(0))
  expect_equal(results$failed, 0)
  expect_equal(results$error, FALSE)
  expect_setequal(dir(snaps), c("doc-page-01.png", "doc-environment.txt"))
  record <- readLines(file.path(snaps, "doc-environment.txt"))
  expect_true("system fonts: hidden" %in% record)
  expect_true(any(startsWith(record, "font: regular.ttf ")))

  # Change one pixel of the snapshot
  page <- file.path(snaps, "doc-page-01.png")
  pixels <- png::readPNG(page)
  pixels[1, 1, ] <- 1 - pixels[1, 1, ]
  png::writePNG(pixels, page)

  results <- run_snapshot_tests(dir, test(0))
  expect_equal(results$failed, 1)
  expect_true(file.exists(file.path(snaps, "doc-page-01.new.png")))

  results <- run_snapshot_tests(dir, test(0.01))
  expect_equal(results$failed, 0)
  expect_false(file.exists(file.path(snaps, "doc-page-01.new.png")))
})

test_that("expect_pdf_snapshot() can use the fonts of the system", {
  skip_if_not(is_linux(), "PDF snapshots are tested on Linux only")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  local_mocked_render()

  dir <- local_snaps(character())
  results <- run_snapshot_tests(
    dir,
    c(
      'test_that("doc", {',
      '  expect_pdf_snapshot("doc", "Some text.", dpi = 20, system_fonts = TRUE)',
      "})"
    )
  )

  expect_equal(results$failed, 0)
  expect_equal(results$error, FALSE)
  record <- readLines(file.path(dir, "_snaps", "pdf", "doc-environment.txt"))
  expect_true("system fonts: visible" %in% record)
})

test_that("expect_pdf_snapshot() fails if the document has fewer pages", {
  skip_if_not(is_linux(), "PDF snapshots are tested on Linux only")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  pages <- 2
  local_mocked_render(function() pages)

  dir <- local_snaps(character())
  snaps <- file.path(dir, "_snaps", "pdf")
  test <- c(
    'test_that("doc", {',
    '  expect_pdf_snapshot("doc", "Text", dpi = 20, system_fonts = TRUE)',
    "})"
  )
  all <- c("doc-page-01.png", "doc-page-02.png", "doc-environment.txt")

  results <- run_snapshot_tests(dir, test)
  expect_equal(results$failed, 0)
  expect_setequal(dir(snaps), all)

  # The surplus page snapshot is kept, so that the test keeps failing
  pages <- 1
  for (i in 1:2) {
    results <- run_snapshot_tests(dir, test)
    expect_equal(results$failed, 1)
    expect_match(
      results$failures,
      "page count of `doc` changed: 1 rendered, 2 in the snapshot",
      fixed = TRUE
    )
    expect_setequal(dir(snaps), all)
  }

  # Deleting the snapshot files accepts the change
  unlink(file.path(snaps, all))
  results <- run_snapshot_tests(dir, test)
  expect_equal(results$failed, 0)
  expect_setequal(dir(snaps), c("doc-page-01.png", "doc-environment.txt"))
})

test_that("expect_pdf_snapshot() fails if the document has more pages", {
  skip_if_not(is_linux(), "PDF snapshots are tested on Linux only")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  pages <- 1
  local_mocked_render(function() pages)

  dir <- local_snaps(character())
  snaps <- file.path(dir, "_snaps", "pdf")
  test <- c(
    'test_that("doc", {',
    '  expect_pdf_snapshot("doc", "Text", dpi = 20, system_fonts = TRUE)',
    "})"
  )
  kept <- c("doc-page-01.png", "doc-environment.txt")

  results <- run_snapshot_tests(dir, test)
  expect_equal(results$failed, 0)
  expect_setequal(dir(snaps), kept)

  # The additional page is not added to the snapshot
  pages <- 2
  for (i in 1:2) {
    results <- run_snapshot_tests(dir, test)
    expect_equal(results$failed, 1)
    expect_match(
      results$failures,
      "page count of `doc` changed: 2 rendered, 1 in the snapshot",
      fixed = TRUE
    )
    expect_setequal(dir(snaps), kept)
  }
})

test_that("pdf_snapshot_pages() lists the page snapshots of a name", {
  dir <- local_snaps(c(
    "doc-page-01.png",
    "doc-page-02.png",
    "doc-page-01.new.png",
    "doc-environment.txt",
    "doc-x-page-01.png"
  ))
  withr::local_options(
    testthat.snapshotter = list(
      snap_dir = file.path(dir, "_snaps"),
      file = "pdf"
    )
  )
  expect_setequal(
    pdf_snapshot_pages("doc"),
    c("doc-page-01.png", "doc-page-02.png")
  )
})

test_that("pdf_snapshot_pages() fails if the snapshot directory is unknown", {
  withr::local_options(testthat.snapshotter = NULL)
  expect_error(pdf_snapshot_pages("doc"), "snapshot directory")

  withr::local_options(testthat.snapshotter = list(snap_dir = "_snaps"))
  expect_error(pdf_snapshot_pages("doc"), "internals of testthat")

  # Outside of a test run, there is nothing to check
  withr::local_envvar(TESTTHAT = "false")
  expect_null(pdf_snapshot_pages("doc"))
})

test_that("expect_pdf_snapshot() sets `fig.showtext` for the rendering only", {
  skip_if_not(is_linux(), "PDF snapshots are tested on Linux only")
  skip_if_not_installed("pdftools")
  skip_if_not_installed("callr")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  seen <- NULL
  local_mocked_bindings(
    render = function(input, output_dir, ...) {
      seen <<- knitr::opts_chunk$get("fig.showtext")
      write_test_pdf(file.path(
        output_dir,
        sub("[.]Rmd$", ".pdf", basename(input))
      ))
    },
    .package = "rmarkdown"
  )

  dir <- local_snaps(character())
  results <- run_snapshot_tests(
    dir,
    c(
      'test_that("doc", {',
      '  expect_pdf_snapshot("doc", "Some text.", dpi = 20, system_fonts = TRUE)',
      "})"
    )
  )

  expect_equal(results$failed, 0)
  expect_equal(results$error, FALSE)
  expect_true(seen)
  expect_null(knitr::opts_chunk$get("fig.showtext"))
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
      "  expect_pdf_snapshot(",
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

test_that("the text of plots is embedded with showtext, not referred to", {
  skip_if_no_pdf_snapshot()
  fonts <- skeleton_fonts()
  skip_if(length(font_files(fonts)) == 0, "the skeleton fonts are missing")

  dir <- withr::local_tempdir()
  input <- file.path(dir, "plot.Rmd")
  writeLines(
    c(
      "---",
      "output: pdf_document",
      "---",
      "",
      "```{r, echo = FALSE}",
      "plot(1:3)",
      "```"
    ),
    input
  )
  render <- function() {
    rmarkdown::render(
      input,
      output_dir = dir,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )
  }
  embedded <- function(pdf) all(pdftools::pdf_fonts(pdf)$embedded)
  render_with_showtext <- function() {
    local_showtext(fonts)
    render()
  }

  # R's pdf() device refers to a standard font without embedding it
  expect_false(embedded(render()))
  expect_true(embedded(render_with_showtext()))
})

test_that("expect_pdf_snapshot() hides the fonts of the system from the font lookup", {
  skip_if_not_installed("rmarkdown")
  local_mocked_bindings(skip_if_no_pdf_snapshot = function() invisible(TRUE))
  names <- c(
    "indiedown.system_fonts",
    "indiedown.font_path",
    "indiedown.mainfont"
  )
  seen <- NULL
  local_mocked_bindings(
    render = function(...) {
      seen <<- lapply(names, getOption)
      stop("the rendering stops here")
    },
    .package = "rmarkdown"
  )
  withr::local_options(
    indiedown.font_path = "fonts",
    indiedown.mainfont = "Some Sans"
  )

  expect_error(
    expect_pdf_snapshot("doc", "Text", fonts = skeleton_fonts()),
    "the rendering stops here"
  )
  expect_identical(seen, list(FALSE, NULL, NULL))
  expect_identical(lapply(names, getOption), list(NULL, "fonts", "Some Sans"))

  expect_error(
    expect_pdf_snapshot("doc", "Text", system_fonts = TRUE),
    "the rendering stops here"
  )
  expect_identical(seen, list(NULL, "fonts", "Some Sans"))
})
