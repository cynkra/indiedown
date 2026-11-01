# resolve_fonts() and apply_default_yaml() live in the standalone file
# that each template package carries,
# so they are tested from a fresh copy of the skeleton's version of it.
local_skeleton <- function(lookup = FALSE) {
  skeleton <- new.env(parent = globalenv())
  sys.source(
    system.file(
      "mypackage",
      "R",
      "import-standalone-indiedown.R",
      package = "indiedown"
    ),
    envir = skeleton
  )
  skeleton$indiedown_path <- function(...) {
    system.file("mypackage", "inst", "indiedown", ..., package = "indiedown")
  }
  if (!lookup) {
    # fail if the system is searched for a font
    skeleton$installed_font_names <- function() {
      stop("unexpected system font lookup")
    }
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
    '"Other Sans" from the `mainfont` field of the document was not found, using "regular.ttf" instead'
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
    "from the `mydown.mainfont` option was not found"
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
    "not found"
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
  skeleton$installed_font_names <- function() character()

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
    "not found"
  )
  expect_true("mainfont:regular.ttf" %in% args)
  expect_match(args, "^mainfontoptions:Path=", all = FALSE)
})

preferred <- c(
  defaults,
  list(
    preferredmainfont = "Licensed Sans Medium",
    preferredmainfontoptions = c(
      "BoldFont=Licensed Sans Heavy",
      "ItalicFont=*"
    )
  )
)

test_that("the preferred font is used if it is installed", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() {
    c("Licensed Sans Medium", "Licensed Sans Heavy", "Some Sans")
  }

  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), preferred, option = "x")
  )
  expect_identical(
    fonts,
    list(
      mainfont = "Licensed Sans Medium",
      mainfontoptions = c("BoldFont=Licensed Sans Heavy", "ItalicFont=*")
    )
  )

  # the document's options are appended
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfontoptions = "Scale=0.9"),
      preferred,
      option = "x"
    )$mainfontoptions,
    c("BoldFont=Licensed Sans Heavy", "ItalicFont=*", "Scale=0.9")
  )

  # a named font takes precedence
  withr::local_options(x = "Some Sans")
  expect_identical(
    skeleton$resolve_fonts(list(), preferred, option = "x"),
    list(mainfont = "Some Sans")
  )
})

test_that("a missing preferred font falls back, with one message per session", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfontoptions = "Scale=0.9"),
      preferred,
      option = "x"
    ),
    '^Preferred font "Licensed Sans Medium" was not found, using "regular.ttf" instead[.]\nTo use it, '
  )
  expect_identical(
    fonts,
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf", "Scale=0.9")
    )
  )

  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), preferred, option = "x")
  )
  expect_identical(fonts, defaults)
})

test_that("the preferred font needs all fonts that its options name", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Licensed Sans Medium"

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred, option = "x"),
    "Licensed Sans Medium"
  )
  expect_identical(fonts, defaults)

  expect_identical(
    skeleton$font_faces("A", c("Scale=0.9", "BoldFont=*-Bold", "ItalicFont=*")),
    c("A", "A-Bold")
  )
})

test_that("a missing named font falls back to the preferred font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() {
    c("Licensed Sans Medium", "Licensed Sans Heavy")
  }

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Other Sans", mainfontoptions = "Scale=0.9"),
      preferred,
      option = "x"
    ),
    '^Font "Other Sans" from the `mainfont` field of the document was not found, using "Licensed Sans Medium" instead'
  )
  expect_identical(fonts$mainfont, "Licensed Sans Medium")
  expect_identical(
    fonts$mainfontoptions,
    c("BoldFont=Licensed Sans Heavy", "ItalicFont=*")
  )
})

test_that("without a font lookup, the fallback replaces the preferred font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() NULL

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred, option = "x"),
    "install the systemfonts package"
  )
  expect_identical(fonts, defaults)

  # a named font is left to LaTeX
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Some Sans"),
      preferred,
      option = "x"
    ),
    list(mainfont = "Some Sans")
  )
})

test_that("apply_default_yaml() passes the preferred font to pandoc", {
  skeleton <- local_skeleton()
  dir <- withr::local_tempdir()
  writeLines(
    c(
      "fontsize: 11pt",
      "preferredmainfont: Licensed Sans Medium",
      "preferredmainfontoptions:",
      "- BoldFont=Licensed Sans Heavy",
      "mainfont: regular.ttf",
      "mainfontoptions:",
      "- Path=<<indiedown_path>>/fonts/"
    ),
    file.path(dir, "default.yaml")
  )
  skeleton$indiedown_path <- function(...) file.path(dir, ...)
  skeleton$installed_font_names <- function() {
    c("Licensed Sans Medium", "Licensed Sans Heavy")
  }

  args <- skeleton$apply_default_yaml(list())
  expect_true("mainfont:Licensed Sans Medium" %in% args)
  expect_true("mainfontoptions:BoldFont=Licensed Sans Heavy" %in% args)
  expect_false(any(grepl("^preferred", args)))
})

test_that("installed fonts are looked up with the current fontconfig setup", {
  skip_if(!nzchar(Sys.which("fc-list")), "fc-list not available")
  skeleton <- local_skeleton(lookup = TRUE)

  # fontconfig sees only the fonts in `dir`
  local_fonts <- function(dir, env = parent.frame()) {
    conf <- file.path(dir, "fonts.conf")
    writeLines(
      c(
        "<?xml version=\"1.0\"?>",
        "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">",
        "<fontconfig>",
        paste0("  <dir>", dir, "</dir>"),
        paste0("  <cachedir>", file.path(dir, "cache"), "</cachedir>"),
        "</fontconfig>"
      ),
      conf
    )
    withr::local_envvar(FONTCONFIG_FILE = conf, .local_envir = env)
  }

  empty <- withr::local_tempdir()
  local_fonts(empty)
  expect_length(skeleton$installed_font_names(), 0)

  dir <- withr::local_tempdir()
  file.copy(
    system.file(
      "mypackage/inst/indiedown/fonts/regular.ttf",
      package = "indiedown"
    ),
    dir
  )
  local_fonts(dir)
  expect_true(
    all(c("Roboto", "Roboto-Regular") %in% skeleton$installed_font_names())
  )
})
