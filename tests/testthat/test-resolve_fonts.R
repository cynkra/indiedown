# resolve_fonts() and apply_default_yaml() live in the skeleton
# and are copied into each template package,
# so they are tested from a fresh copy of the skeleton's code.
local_skeleton <- function() {
  skeleton <- new.env(parent = globalenv())
  sys.source(
    system.file("mypackage", "R", "indiedown.R", package = "indiedown"),
    envir = skeleton
  )
  skeleton$indiedown_path <- function(...) {
    system.file("mypackage", "inst", "indiedown", ..., package = "indiedown")
  }
  # fail if the system is searched for a font
  skeleton$installed_font_names <- function() {
    stop("unexpected system font lookup")
  }
  skeleton
}

defaults <- list(
  mainfont = "regular.ttf",
  mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf")
)

test_that("the configured font is used without a system font lookup", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(), defaults, option = "mydown.mainfont"),
    defaults
  )
})

test_that("the document's mainfontoptions are appended to the configured ones", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfontoptions = "Scale=0.9"),
      defaults,
      option = "mydown.mainfont"
    ),
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf", "Scale=0.9")
    )
  )
})

test_that("an installed font named in the document is used", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() c("Some Sans", "SomeSans")

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "some sans", mainfontoptions = "Scale=0.9"),
      defaults,
      option = "mydown.mainfont"
    ),
    list(mainfont = "some sans", mainfontoptions = "Scale=0.9")
  )
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Some Sans"),
      defaults,
      option = "mydown.mainfont"
    ),
    list(mainfont = "Some Sans")
  )
})

test_that("a missing font named in the document falls back with a message", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Other Sans", mainfontoptions = "BoldFont=Other Bold"),
      defaults,
      option = "mydown.mainfont"
    ),
    '"Other Sans" from the `mainfont` field of the document is not installed, using "regular.ttf" instead'
  )
  expect_identical(fonts, defaults)
})

test_that("the option names a font if the document does not", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() c("Some Sans", "Other Sans")
  withr::local_options(mydown.mainfont = "Some Sans")

  expect_identical(
    skeleton$resolve_fonts(list(), defaults, option = "mydown.mainfont"),
    list(mainfont = "Some Sans")
  )
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Other Sans"),
      defaults,
      option = "mydown.mainfont"
    ),
    list(mainfont = "Other Sans")
  )

  withr::local_options(mydown.mainfont = "Missing Sans")
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(),
      defaults,
      option = "mydown.mainfont"
    ),
    "from the `mydown.mainfont` option is not installed"
  )
  expect_identical(fonts, defaults)
})

test_that("a font file is looked up as a file", {
  skeleton <- local_skeleton()
  dir <- withr::local_tempdir()
  font <- file.path(dir, "my-font.otf")
  file.create(font)

  expect_identical(
    skeleton$resolve_fonts(list(mainfont = font), defaults, option = "x"),
    list(mainfont = font)
  )

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = file.path(dir, "missing.otf")),
      defaults,
      option = "x"
    ),
    "check the path"
  )
  expect_identical(fonts, defaults)
})

test_that("a font file name is looked up in the TeX tree", {
  skeleton <- local_skeleton()
  skeleton$Sys.which <- function(names) ""

  # without kpsewhich, LaTeX has to find it
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "some.otf"), defaults, option = "x"),
    list(mainfont = "some.otf")
  )

  skip_if(!nzchar(Sys.which("kpsewhich")), "kpsewhich not available")
  skeleton <- local_skeleton()
  expect_message(
    skeleton$resolve_fonts(
      list(mainfont = "no-such-font-file.otf"),
      defaults,
      option = "x"
    ),
    "not installed"
  )
})

test_that("without a configured font, the named font is used as is", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Some Sans"), list(), option = "x"),
    list(mainfont = "Some Sans")
  )
})

test_that("the message explains how to install fonts on each system", {
  skeleton <- local_skeleton()

  expect_match(
    skeleton$font_install_hint("A", "Windows"),
    "Install for all users"
  )
  expect_match(skeleton$font_install_hint("A", "Darwin"), "Font Book")
  expect_match(skeleton$font_install_hint("A", "Linux"), "fc-cache")
})

test_that("apply_default_yaml() passes the resolved font to pandoc", {
  skeleton <- local_skeleton()

  args <- skeleton$apply_default_yaml(list())
  expect_true("mainfont:regular.ttf" %in% args)
  expect_match(
    args,
    "^mainfontoptions:Path=.*/fonts/,BoldFont=bold.ttf,.*,Scale=0.92$",
    all = FALSE
  )

  skeleton$installed_font_names <- function() "Some Sans"
  args <- skeleton$apply_default_yaml(list(mainfont = "Some Sans"))
  expect_true("mainfont:Some Sans" %in% args)
  expect_false(any(grepl("^mainfontoptions:", args)))

  expect_message(
    args <- skeleton$apply_default_yaml(list(mainfont = "Missing Sans")),
    "not installed"
  )
  expect_true("mainfont:regular.ttf" %in% args)
  expect_match(args, "^mainfontoptions:Path=", all = FALSE)
})
