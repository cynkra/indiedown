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
  # no folder of fonts that fc-list does not see, unlike on Windows
  skeleton$Sys.info <- function() c(sysname = "Linux")
  if (!lookup) {
    # fail if the system is searched for a font
    skeleton$installed_font_names <- function() {
      stop("unexpected system font lookup")
    }
  }
  skeleton
}

# A default.yaml with `lines` for the `skeleton`
local_default_yaml <- function(skeleton, lines, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(lines, file.path(dir, "default.yaml"))
  skeleton$indiedown_path <- function(...) file.path(dir, ...)
}

defaults <- list(
  mainfont = "regular.ttf",
  mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf")
)

test_that("the configured font is used without a system font lookup", {
  skeleton <- local_skeleton()

  expect_identical(skeleton$resolve_fonts(list(), defaults), defaults)
})

test_that("the document's mainfontoptions are appended to the configured ones", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(mainfontoptions = "Scale=0.9"), defaults),
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf", "Scale=0.9")
    )
  )
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

test_that("a font named in the document is used as named, without a lookup", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Some Sans", mainfontoptions = "Scale=0.9"),
      preferred
    ),
    list(mainfont = "Some Sans", mainfontoptions = "Scale=0.9")
  )
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "missing.otf"), preferred),
    list(mainfont = "missing.otf")
  )
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Some Sans"), list()),
    list(mainfont = "Some Sans")
  )
})

test_that("the option names a font if the document does not", {
  skeleton <- local_skeleton()
  # a sourced file is not part of a package
  withr::local_options(indiedown.mainfont = "Some Sans")

  expect_identical(
    skeleton$resolve_fonts(list(), preferred),
    list(mainfont = "Some Sans")
  )
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Other Sans"), preferred),
    list(mainfont = "Other Sans")
  )
  # the argument takes the place of the option
  expect_identical(
    skeleton$resolve_fonts(list(), preferred, mainfont = "Third Sans"),
    list(mainfont = "Third Sans")
  )
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

  args <- skeleton$apply_default_yaml(list(mainfont = "Some Sans"))
  expect_true("mainfont:Some Sans" %in% args)
  expect_false(any(grepl("^mainfontoptions:", args)))
})

test_that("the preferred font is used if it is installed", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() {
    c("Licensed Sans Medium", "Licensed Sans Heavy", "Some Sans")
  }

  expect_silent(fonts <- skeleton$resolve_fonts(list(), preferred))
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
      preferred
    )$mainfontoptions,
    c("BoldFont=Licensed Sans Heavy", "ItalicFont=*", "Scale=0.9")
  )
})

test_that("a missing preferred font falls back, with one message per session", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfontoptions = "Scale=0.9"),
      preferred
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

  expect_silent(fonts <- skeleton$resolve_fonts(list(), preferred))
  expect_identical(fonts, defaults)

  # again if the advice changes
  expect_message(
    skeleton$resolve_fonts(list(), preferred, font_path = "/no/such/folder"),
    "/no/such/folder"
  )
})

test_that("the preferred font needs all fonts that its options name", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Licensed Sans Medium"

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred),
    "Licensed Sans Medium"
  )
  expect_identical(fonts, defaults)

  expect_identical(
    skeleton$font_faces("A", c("Scale=0.9", "BoldFont=*-Bold", "ItalicFont=*")),
    c("A", "A-Bold")
  )
})

test_that("without fc-list, the fallback replaces the preferred font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() NULL

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred),
    "was not found"
  )
  expect_identical(fonts, defaults)
})

test_that("the message explains how to make the font available", {
  skeleton <- local_skeleton()

  expect_match(
    skeleton$font_install_hint("A", sysname = "Windows"),
    "for the current user"
  )
  expect_match(skeleton$font_install_hint("A", sysname = "Darwin"), "Font Book")
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Linux"),
    paste0(
      "copy its font files to ~/.local/share/fonts,\n",
      'or set `options(indiedown.font_path = "<folder>")` to a folder ',
      'with its font files, named like "A.otf" or ".ttf"'
    )
  )
  expect_identical(
    skeleton$font_install_hint("A", "/no/such/folder"),
    paste0(
      'check that the folder "/no/such/folder" from the option ',
      "`indiedown.font_path` holds its font files, ",
      'named like "A.otf" or ".ttf"'
    )
  )
})

test_that("the format repeats the font message after the output is written", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  local_default_yaml(
    skeleton,
    c("preferredmainfont: Licensed Sans Medium", "mainfont: regular.ttf")
  )

  input <- file.path(withr::local_tempdir(), "doc.Rmd")
  writeLines(c("---", "title: Doc", "---", "", "Text."), input)
  render <- function() {
    utils::capture.output(
      messages <- capture_messages(rmarkdown::render(
        input,
        skeleton$indiedown_pdf_document_with_asset(),
        # pandoc only, without LaTeX
        output_file = "doc.tex",
        envir = new.env()
      ))
    )
    messages
  }

  messages <- render()
  font <- grep('"Licensed Sans Medium"', messages, fixed = TRUE)
  expect_length(font, 2)
  expect_identical(messages[[font[[1]]]], messages[[font[[2]]]])
  # the last message, after the "Output created" line
  expect_identical(font[[2]], length(messages))
  expect_match(messages[[font[[2]] - 1]], "Output created")

  # a render without the message does not repeat it
  messages <- render()
  expect_false(any(grepl("Licensed Sans", messages, fixed = TRUE)))
})

test_that("the font message is not repeated if the output is not written", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  local_default_yaml(
    skeleton,
    c("preferredmainfont: Licensed Sans Medium", "mainfont: regular.ttf")
  )
  format <- skeleton$indiedown_pdf_document_with_asset()

  expect_message(
    format$pre_processor(
      list(),
      "doc.knit.md",
      "static",
      list(),
      "doc_files",
      "."
    ),
    "not found"
  )
  expect_silent(format$on_exit())
})

test_that("apply_default_yaml() passes the preferred font to pandoc", {
  skeleton <- local_skeleton()
  local_default_yaml(
    skeleton,
    c(
      "fontsize: 11pt",
      "preferredmainfont: Licensed Sans Medium",
      "preferredmainfontoptions:",
      "- BoldFont=Licensed Sans Heavy",
      "mainfont: regular.ttf",
      "mainfontoptions:",
      "- Path=<<indiedown_path>>/fonts/"
    )
  )
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

  dir <- copy_fonts(withr::local_tempdir(), "regular.ttf")
  local_fonts(dir)
  expect_true(
    all(c("Roboto", "Roboto-Regular") %in% skeleton$installed_font_names())
  )
})

roboto <- c(
  defaults,
  list(
    preferredmainfont = "Roboto-Regular",
    preferredmainfontoptions = c(
      "BoldFont=Roboto-Bold",
      "ItalicFont=*",
      "BoldItalicFont=Roboto-Bold",
      "Scale=0.9"
    )
  )
)

test_that("the preferred font is loaded from the folder of the option", {
  skeleton <- local_skeleton()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)

  expect_silent(
    fonts <- skeleton$resolve_fonts(
      list(mainfontoptions = "Numbers=Lining"),
      roboto
    )
  )
  expect_identical(
    fonts,
    list(
      mainfont = "Roboto-Regular.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=Roboto-Bold.ttf",
        "ItalicFont=Roboto-Regular.ttf",
        "BoldItalicFont=Roboto-Bold.ttf",
        "Scale=0.9",
        "Numbers=Lining"
      )
    )
  )

  # the argument takes the place of the option
  expect_identical(
    formals(skeleton$resolve_fonts)$font_path,
    quote(get_indiedown_option("font_path"))
  )
  other <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.otf", "Roboto-Bold.otf")
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto, font_path = other)$mainfont,
    "Roboto-Regular.otf"
  )
})

test_that("fonts installed for the current user on Windows are found", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata)
  # by file name, ignoring case, next to an unrelated font
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("regular.ttf", "bold.ttf", "italic.ttf"),
    c("roboto-regular.TTF", "Roboto-Bold.ttf", "other.ttf")
  )

  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfontoptions[1:2],
    c(paste0("Path=", user, "/"), "BoldFont=Roboto-Bold.ttf")
  )

  # but not if the option `<package>.system_fonts` is FALSE
  withr::local_options(indiedown.system_fonts = FALSE)
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto),
    "for the current user"
  )
  expect_identical(fonts$mainfont, "regular.ttf")
})

test_that("only Windows has a folder of fonts that fc-list does not see", {
  skeleton <- local_skeleton()
  withr::local_envvar(LOCALAPPDATA = "C:/Users/me/AppData/Local")

  expect_identical(
    skeleton$font_dirs("Windows"),
    "C:/Users/me/AppData/Local/Microsoft/Windows/Fonts"
  )
  expect_null(skeleton$font_dirs("Linux"))
  expect_null(skeleton$font_dirs("Darwin"))
  expect_null(skeleton$font_dirs("Windows", system_fonts = FALSE))
})

test_that("font files are found in one folder and loaded by path", {
  skeleton <- local_skeleton()
  # LaTeX reads a tilde as a space, as in short names on Windows
  dir <- copy_fonts(
    file.path(withr::local_tempdir(), "JANE~1"),
    c("regular.ttf", "bold.ttf"),
    c("a.otf", "a-bold.otf")
  )
  half <- copy_fonts(withr::local_tempdir(), "regular.ttf", "a.otf")

  files <- skeleton$find_font_files(c("A", "A-Bold"), c(half, dir))
  expect_identical(
    files,
    c(A = file.path(dir, "a.otf"), "A-Bold" = file.path(dir, "a-bold.otf"))
  )
  expect_null(skeleton$find_font_files(c("A", "B"), c(half, dir)))

  expect_identical(
    skeleton$font_from_files(
      list(mainfont = "A", mainfontoptions = c("BoldFont=*-Bold", "Scale=0.9")),
      files
    ),
    list(
      mainfont = "a.otf",
      mainfontoptions = c(
        paste0("Path=", sub("~", "\\string~", dir, fixed = TRUE), "/"),
        "BoldFont=a-bold.otf",
        "Scale=0.9"
      )
    )
  )
})

test_that("get_indiedown_option() reads the option of the package", {
  skeleton <- local_skeleton()
  # a sourced file is not part of a package
  expect_identical(
    skeleton$indiedown_option_name("font_path"),
    "indiedown.font_path"
  )
  expect_null(skeleton$get_indiedown_option("font_path"))
  expect_identical(
    skeleton$get_indiedown_option("font_path", "default"),
    "default"
  )

  withr::local_options(indiedown.font_path = "fonts", mydown.font_path = "x")
  expect_identical(skeleton$get_indiedown_option("font_path"), "fonts")
  expect_identical(
    skeleton$get_indiedown_option("font_path", "default"),
    "fonts"
  )

  # in a package, the name of the package is the prefix
  expect_identical(
    skeleton$indiedown_option_name("font_path", asNamespace("indiedown")),
    "indiedown.font_path"
  )
  expect_identical(
    skeleton$indiedown_option_name("font_path", asNamespace("stats")),
    "stats.font_path"
  )
  expect_identical(
    skeleton$indiedown_option_name("font_path", globalenv()),
    "indiedown.font_path"
  )
})
