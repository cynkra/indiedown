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
  # no folders of installed fonts to search, as on Linux
  skeleton$Sys.info <- function() c(sysname = "Linux")
  if (!lookup) {
    # fail if the system is searched for a font name,
    # and find no installed font files
    skeleton$installed_font_names <- function() {
      stop("unexpected system font lookup")
    }
    skeleton$installed_fonts <- function() NULL
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
    "for the current user"
  )
  expect_no_match(skeleton$font_install_hint("A", "Windows"), "all users")
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
    fonts <- skeleton$resolve_fonts(
      list(),
      preferred,
      option = "x",
      path_option = "x.font_path"
    ),
    paste0(
      "Preferred font \"Licensed Sans Medium\" cannot be looked up ",
      "without fc-list or the systemfonts package, ",
      "using \"regular.ttf\" instead.\n",
      "To use it, install the systemfonts package,\n",
      "or set `options(x.font_path = \"<folder>\")` to a folder with its font files.\n"
    ),
    fixed = TRUE
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

test_that("the format repeats the font message after the output is written", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"

  input <- file.path(withr::local_tempdir(), "doc.Rmd")
  writeLines(c("---", "mainfont: Missing Sans", "---", "", "Text."), input)
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
  font <- grep('"Missing Sans"', messages, fixed = TRUE)
  expect_length(font, 2)
  expect_identical(messages[[font[[1]]]], messages[[font[[2]]]])
  # the last message, after the "Output created" line
  expect_identical(font[[2]], length(messages))
  expect_match(messages[[font[[2]] - 1]], "Output created")

  # a render without the message does not repeat it
  messages <- render()
  expect_false(any(grepl("Missing Sans", messages, fixed = TRUE)))
})

test_that("the font message is not repeated if the output is not written", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  format <- skeleton$indiedown_pdf_document_with_asset()

  expect_message(
    format$pre_processor(
      list(mainfont = "Missing Sans"),
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

  # with the files, by PostScript name and full name
  fonts <- skeleton$installed_fonts()
  expect_identical(
    unique(normalizePath(fonts$path)),
    normalizePath(file.path(dir, "regular.ttf"))
  )
  expect_true(all(c("Roboto", "Roboto-Regular") %in% fonts$name))
  expect_identical(unique(fonts$family), "Roboto")
  files <- skeleton$find_font_files("Roboto-Regular")
  expect_named(files, "Roboto-Regular")
  expect_identical(
    normalizePath(unname(files)),
    normalizePath(file.path(dir, "regular.ttf"))
  )
})

test_that("installed fonts are looked up with systemfonts without fc-list", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton(lookup = TRUE)
  skeleton$Sys.which <- function(names) ""

  system <- systemfonts::system_fonts()
  expect_identical(
    skeleton$installed_fonts(),
    list(path = system$path, name = system$name, family = system$family)
  )
  expect_identical(
    skeleton$installed_font_names(),
    c(system$family, system$name)
  )

  # without systemfonts, installed fonts cannot be looked up
  skeleton$requireNamespace <- function(...) FALSE
  expect_null(skeleton$installed_fonts())
  expect_null(skeleton$installed_font_names())
})

# Copies font files of the skeleton to `dir`, renamed to `names`
copy_fonts <- function(dir, files, names = files) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(
    file.path(
      system.file("mypackage/inst/indiedown/fonts", package = "indiedown"),
      files
    ),
    file.path(dir, names)
  ))
  normalizePath(dir, "/")
}

# A preferred font named by PostScript name
roboto <- c(
  defaults,
  list(
    preferredmainfont = "Roboto-Regular",
    preferredmainfontoptions = c(
      "BoldFont=Roboto-Bold",
      "ItalicFont=*",
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
  withr::local_options(x.font_path = dir)

  expect_silent(
    fonts <- skeleton$resolve_fonts(
      list(mainfontoptions = "Numbers=Lining"),
      roboto,
      option = "x",
      path_option = "x.font_path"
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
        "Scale=0.9",
        "Numbers=Lining"
      )
    )
  )
})

test_that("the preferred font is loaded from the files of the installed fonts", {
  skeleton <- local_skeleton()
  dir <- copy_fonts(withr::local_tempdir(), c("regular.ttf", "bold.ttf"))
  skeleton$installed_fonts <- function() {
    list(
      path = file.path(dir, c("regular.ttf", "regular.ttf", "bold.ttf")),
      name = c("Roboto-Regular", "Roboto", "Roboto-Bold"),
      family = "Roboto"
    )
  }

  expect_identical(
    skeleton$resolve_fonts(list(), roboto, option = "x"),
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=bold.ttf",
        "ItalicFont=regular.ttf",
        "Scale=0.9"
      )
    )
  )
})

test_that("fonts installed for the current user on Windows are found", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  appdata <- withr::local_tempdir()
  windir <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = windir)
  # the original file names, found by PostScript name
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("regular.ttf", "bold.ttf")
  )
  # the fonts for all users come second
  copy_fonts(
    file.path(windir, "Fonts"),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )

  expect_identical(
    skeleton$resolve_fonts(list(), roboto, option = "x")$mainfontoptions[1:2],
    c(paste0("Path=", user, "/"), "BoldFont=bold.ttf")
  )
})

test_that("fonts installed for all users are found by file name only", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  windir <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = withr::local_tempdir(), WINDIR = windir)
  system <- copy_fonts(file.path(windir, "Fonts"), c("regular.ttf", "bold.ttf"))

  # not by PostScript name, the lookup of the installed fonts provides these
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto, option = "x"),
    'Preferred font "Roboto-Regular" was not found'
  )
  expect_identical(fonts, defaults)

  file.rename(
    file.path(system, c("regular.ttf", "bold.ttf")),
    file.path(system, c("Roboto-Regular.ttf", "Roboto-Bold.ttf"))
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto, option = "x")$mainfont,
    "Roboto-Regular.ttf"
  )
})

test_that("a named font that is only found as files is loaded from them", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  dir <- copy_fonts(withr::local_tempdir(), "regular.ttf", "Roboto-Regular.ttf")
  withr::local_options(x.font_path = dir)

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Roboto-Regular", mainfontoptions = "Scale=0.9"),
      defaults,
      option = "x",
      path_option = "x.font_path"
    ),
    list(
      mainfont = "Roboto-Regular.ttf",
      mainfontoptions = c(paste0("Path=", dir, "/"), "Scale=0.9")
    )
  )
})

test_that("the message about the preferred font explains the option", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()

  expect_message(
    skeleton$resolve_fonts(
      list(),
      preferred,
      option = "x",
      path_option = "x.font_path"
    ),
    paste0(
      "Preferred font \"Licensed Sans Medium\" was not found, ",
      "using \"regular.ttf\" instead.\n",
      "To use it, copy its font files to ~/.local/share/fonts ",
      "and run `fc-cache -f`,\n",
      "or set `options(x.font_path = \"<folder>\")` to a folder with its font files.\n"
    ),
    fixed = TRUE
  )

  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  withr::local_options(x.font_path = "/no/such/folder")
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(),
      preferred,
      option = "x",
      path_option = "x.font_path"
    ),
    paste0(
      "To use it, check that the folder \"/no/such/folder\" ",
      "from the option `x.font_path` holds its font files.\n"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the folders of installed fonts depend on the system", {
  skeleton <- local_skeleton()
  withr::local_envvar(
    LOCALAPPDATA = "C:/Users/me/AppData/Local",
    WINDIR = "C:/Windows"
  )

  expect_identical(
    skeleton$font_dirs("Windows"),
    list(
      user = "C:/Users/me/AppData/Local/Microsoft/Windows/Fonts",
      system = "C:/Windows/Fonts"
    )
  )
  expect_identical(
    skeleton$font_dirs("Darwin"),
    list(user = "~/Library/Fonts", system = "/Library/Fonts")
  )
  expect_identical(skeleton$font_dirs("Linux"), list())
})

test_that("font files are matched by name in one folder", {
  skeleton <- local_skeleton()
  paths <- c("/a/x.otf", "/b/x.ttf", "/b/y.ttf", "/c/x.otf", "/c/y.ttc")

  # the first folder with all faces, case-insensitively
  expect_identical(
    skeleton$match_font_files(c("x", "Y"), paths, c("X", "X", "Y", "X", "Y")),
    c(x = "/b/x.ttf", Y = "/b/y.ttf")
  )
  # not from a font collection
  expect_null(skeleton$match_font_files("Y", paths[5], "Y"))
  # one file for each face
  expect_null(
    skeleton$match_font_files(
      c("X", "Y"),
      c("/a/xy.ttf", "/a/xy.ttf"),
      c("X", "Y")
    )
  )
  # without names
  expect_null(skeleton$match_font_files("X", "/a/x.ttf", NULL))
})

test_that("font files are loaded by path", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$font_from_files(list(mainfont = "A"), c(A = "/f/JANE~1/a.otf")),
    list(mainfont = "a.otf", mainfontoptions = "Path=/f/JANE\\string~1/")
  )
  expect_identical(
    skeleton$font_from_files(
      list(mainfont = "A", mainfontoptions = c("BoldFont=*-Bold", "Scale=0.9")),
      c(A = "/f/a.otf", "A-Bold" = "/f/a-bold.otf")
    ),
    list(
      mainfont = "a.otf",
      mainfontoptions = c("Path=/f/", "BoldFont=a-bold.otf", "Scale=0.9")
    )
  )
})

test_that("PostScript names are read from font files with systemfonts", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton()
  dir <- copy_fonts(withr::local_tempdir(), c("regular.ttf", "bold.ttf"))
  writeLines("not a font", file.path(dir, "broken.ttf"))

  expect_identical(
    skeleton$font_postscript_names(
      file.path(dir, c("regular.ttf", "broken.ttf", "bold.ttf"))
    ),
    c("Roboto-Regular", NA, "Roboto-Bold")
  )

  skeleton$requireNamespace <- function(...) FALSE
  expect_null(skeleton$font_postscript_names(file.path(dir, "regular.ttf")))
})
