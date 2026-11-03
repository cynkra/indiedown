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
  skeleton$Sys.info <- function() c(sysname = "Linux")
  # no folders of installed fonts to search, not even those of Linux,
  # unless a test asks for the folders of a system
  skeleton$dirs_of <- skeleton$font_dirs
  skeleton$font_dirs <- function(sysname = Sys.info()[["sysname"]]) {
    if (missing(sysname) && sysname == "Linux") list() else dirs_of(sysname)
  }
  environment(skeleton$font_dirs) <- skeleton
  if (!lookup) {
    # fail if the system is searched for a font name,
    # and find no installed font files
    skeleton$installed_font_names <- function(...) {
      stop("unexpected system font lookup")
    }
    skeleton$installed_fonts <- no_fonts
  }
  skeleton
}

# No installed fonts, as fc-list lists them on a system without fonts
no_fonts <- function(...) {
  list(path = character(), name = character(), family = character())
}

# systemfonts as if it were missing, or installed in an `old` version
local_systemfonts <- function(old = NULL, .env = parent.frame()) {
  local_mocked_bindings(
    is_installed = function(pkg, ..., version = NULL) {
      !is.null(old) && is.null(version)
    },
    .package = "rlang",
    .env = .env
  )
  if (!is.null(old)) {
    local_mocked_bindings(
      packageVersion = function(...) package_version(old),
      .package = "utils",
      .env = .env
    )
  }
}

defaults <- list(
  mainfont = "regular.ttf",
  mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf")
)

test_that("the configured font is used without a system font lookup", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(), defaults),
    defaults
  )
})

test_that("the document's mainfontoptions are appended to the configured ones", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfontoptions = "Scale=0.9"),
      defaults
    ),
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf", "Scale=0.9")
    )
  )
})

test_that("an installed font named in the document is used", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) c("Some Sans", "SomeSans")

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "some sans", mainfontoptions = "Scale=0.9"),
      defaults
    ),
    list(mainfont = "some sans", mainfontoptions = "Scale=0.9")
  )
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Some Sans"),
      defaults
    ),
    list(mainfont = "Some Sans")
  )
})

test_that("a missing font named in the document falls back with a message", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Some Sans"

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Other Sans", mainfontoptions = "BoldFont=Other Bold"),
      defaults
    ),
    '"Other Sans" from the `mainfont` field of the document was not found, using "regular.ttf" instead'
  )
  expect_identical(fonts, defaults)
})

test_that("the option names a font if the document does not", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) c("Some Sans", "Other Sans")
  withr::local_options(indiedown.mainfont = "Some Sans")

  expect_identical(
    skeleton$resolve_fonts(list(), defaults),
    list(mainfont = "Some Sans")
  )
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Other Sans"),
      defaults
    ),
    list(mainfont = "Other Sans")
  )

  withr::local_options(indiedown.mainfont = "Missing Sans")
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(),
      defaults
    ),
    "from the `indiedown.mainfont` option was not found"
  )
  expect_identical(fonts, defaults)
})

test_that("a font file is looked up as a file", {
  skeleton <- local_skeleton()
  dir <- withr::local_tempdir()
  font <- file.path(dir, "my-font.otf")
  file.create(font)

  expect_identical(
    skeleton$resolve_fonts(list(mainfont = font), defaults),
    list(mainfont = font)
  )

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = file.path(dir, "missing.otf")),
      defaults
    ),
    "check the path"
  )
  expect_identical(fonts, defaults)
})

test_that("a font file in the Path= of the document is left as named", {
  skeleton <- local_skeleton()
  skeleton$has_systemfonts <- function() FALSE
  document <- copy_fonts(
    withr::local_tempdir(),
    c("bolditalic.ttf", "bold.ttf"),
    c("my-font.otf", "my-bold.otf")
  )
  other <- copy_fonts(
    withr::local_tempdir(),
    c("bolditalic.ttf", "bold.ttf"),
    c("my-font.otf", "my-bold.otf")
  )
  named <- list(
    mainfont = "my-font.otf",
    mainfontoptions = c(
      paste0("Path=", document, "/"),
      "BoldFont=my-bold.otf",
      "ItalicFont=my-font.otf",
      "BoldItalicFont=my-bold.otf"
    )
  )

  # the file is in the folder of the document, which is also in the option
  expect_silent(
    fonts <- skeleton$resolve_fonts(named, defaults, font_path = other)
  )
  expect_identical(fonts, named)

  # otherwise it is loaded from the folder of the option, with one Path= only
  named$mainfontoptions[[1]] <- paste0("Path=", withr::local_tempdir(), "/")
  expect_silent(
    fonts <- skeleton$resolve_fonts(named, defaults, font_path = other)
  )
  expect_identical(fonts$mainfont, "my-font.otf")
  expect_identical(sum(grepl("^Path=", fonts$mainfontoptions)), 1L)
  expect_identical(fonts$mainfontoptions[[1]], paste0("Path=", other, "/"))
})

test_that("a font file name is looked up in the TeX tree", {
  skeleton <- local_skeleton()
  skeleton$Sys.which <- function(names) ""

  # without kpsewhich, LaTeX has to find it
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "some.otf"), defaults),
    list(mainfont = "some.otf")
  )

  skip_if(!nzchar(Sys.which("kpsewhich")), "kpsewhich not available")
  skeleton <- local_skeleton()
  expect_message(
    skeleton$resolve_fonts(
      list(mainfont = "no-such-font-file.otf"),
      defaults
    ),
    "not found"
  )
})

test_that("without a configured font, the named font is used as is", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Some Sans"), list()),
    list(mainfont = "Some Sans")
  )
})

test_that("the hints ask to restart R, which systemfonts needs to see new fonts", {
  skeleton <- local_skeleton()
  for (sysname in c("Windows", "Darwin", "Linux")) {
    expect_match(skeleton$font_install_hint("Arial", sysname), "and restart R$")
  }
})

test_that("the message explains how to install fonts on each system", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()

  expect_match(
    skeleton$font_install_hint("A", "Windows"),
    "for the current user"
  )
  expect_no_match(skeleton$font_install_hint("A", "Windows"), "all users")
  expect_match(skeleton$font_install_hint("A", "Darwin"), "Font Book")
  expect_identical(
    skeleton$font_install_hint("A", "Linux"),
    "copy its font files to ~/.local/share/fonts, and restart R"
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

  skeleton$installed_font_names <- function(...) "Some Sans"
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
  skeleton$installed_font_names <- function(...) {
    c("Licensed Sans Medium", "Licensed Sans Heavy", "Some Sans")
  }

  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), preferred)
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
      preferred
    )$mainfontoptions,
    c("BoldFont=Licensed Sans Heavy", "ItalicFont=*", "Scale=0.9")
  )

  # a named font takes precedence
  withr::local_options(indiedown.mainfont = "Some Sans")
  expect_identical(
    skeleton$resolve_fonts(list(), preferred),
    list(mainfont = "Some Sans")
  )
})

test_that("a missing preferred font falls back, with one message per session", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Some Sans"

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

  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), preferred)
  )
  expect_identical(fonts, defaults)
})

test_that("the preferred font needs all fonts that its options name", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Licensed Sans Medium"

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

test_that("a missing named font falls back to the preferred font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) {
    c("Licensed Sans Medium", "Licensed Sans Heavy")
  }

  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Other Sans", mainfontoptions = "Scale=0.9"),
      preferred
    ),
    '^Font "Other Sans" from the `mainfont` field of the document was not found, using "Licensed Sans Medium" instead'
  )
  expect_identical(fonts$mainfont, "Licensed Sans Medium")
  expect_identical(
    fonts$mainfontoptions,
    c("BoldFont=Licensed Sans Heavy", "ItalicFont=*")
  )
})

test_that("the format repeats the font message after the output is written", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Some Sans"

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
  skeleton$installed_font_names <- function(...) "Some Sans"
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
  skeleton$installed_font_names <- function(...) {
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
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton(lookup = TRUE)
  skeleton$Sys.which <- function(names) ""

  system <- systemfonts::system_fonts()
  fonts <- skeleton$installed_fonts()
  expect_identical(
    fonts[c("path", "name", "family")],
    list(
      path = ifelse(system$index == 0, system$path, NA),
      name = system$name,
      family = system$family
    )
  )
  expect_identical(fonts$styles$path, system$path[system$index == 0])
  expect_identical(
    fonts$styles$italic,
    as.logical(system$italic[system$index == 0])
  )
  expect_identical(
    skeleton$installed_font_names(),
    c(system$family, system$name)
  )
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

# A preferred font named by PostScript name, with all its faces
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

# A preferred font that names only its bold face
roboto_bold <- c(
  defaults,
  list(
    preferredmainfont = "Roboto-Regular",
    preferredmainfontoptions = "BoldFont=Roboto-Bold"
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
    skeleton$resolve_fonts(list(), roboto),
    list(
      mainfont = "regular.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=bold.ttf",
        "ItalicFont=regular.ttf",
        "BoldItalicFont=bold.ttf",
        "Scale=0.9"
      )
    )
  )
})

test_that("fonts installed for the current user on Windows are found", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  appdata <- withr::local_tempdir()
  windir <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = windir)
  # the original file names, found by PostScript name
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("regular.ttf", "bold.ttf")
  )

  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfontoptions[1:2],
    c(paste0("Path=", user, "/"), "BoldFont=bold.ttf")
  )

  # file names come first, also those of the fonts for all users
  system <- copy_fonts(
    file.path(windir, "Fonts"),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfontoptions[1:2],
    c(paste0("Path=", system, "/"), "BoldFont=Roboto-Bold.ttf")
  )
})

test_that("fonts installed for all users are found by file name only", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  windir <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = withr::local_tempdir(), WINDIR = windir)
  system <- copy_fonts(file.path(windir, "Fonts"), c("regular.ttf", "bold.ttf"))

  # not by PostScript name, the lookup of the installed fonts provides these
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto),
    'Preferred font "Roboto-Regular" was not found'
  )
  expect_identical(fonts, defaults)

  file.rename(
    file.path(system, c("regular.ttf", "bold.ttf")),
    file.path(system, c("Roboto-Regular.ttf", "Roboto-Bold.ttf"))
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfont,
    "Roboto-Regular.ttf"
  )
})

test_that("a named font that is only found as files is loaded from them", {
  # to tell apart the faces that its options do not name
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Some Sans"
  dir <- copy_fonts(withr::local_tempdir(), "regular.ttf", "Roboto-Regular.ttf")
  withr::local_options(indiedown.font_path = dir)

  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Roboto-Regular", mainfontoptions = "Scale=0.9"),
      defaults
    ),
    list(
      mainfont = "Roboto-Regular.ttf",
      mainfontoptions = c(paste0("Path=", dir, "/"), "Scale=0.9")
    )
  )
})

test_that("a font named as a font file is found by its file name", {
  skeleton <- local_skeleton()
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = withr::local_tempdir())
  roboto_files <- c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    roboto_files
  )
  faces <- c(
    "BoldFont=Roboto-Bold.ttf",
    "ItalicFont=*",
    "BoldItalicFont=Roboto-Bold.ttf"
  )
  loaded <- function(dir) {
    list(
      mainfont = "Roboto-Regular.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=Roboto-Bold.ttf",
        "ItalicFont=Roboto-Regular.ttf",
        "BoldItalicFont=Roboto-Bold.ttf"
      )
    )
  }

  # the preferred font, in the folder of the option
  preferred <- c(
    defaults,
    list(
      preferredmainfont = "Roboto-Regular.ttf",
      preferredmainfontoptions = faces
    )
  )
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), preferred, font_path = dir)
  )
  expect_identical(fonts, loaded(dir))

  # a named font, in the folder of the option
  named <- list(mainfont = "Roboto-Regular.ttf", mainfontoptions = faces)
  expect_silent(
    fonts <- skeleton$resolve_fonts(named, defaults, font_path = dir)
  )
  expect_identical(fonts, loaded(dir))

  # and among the fonts installed for the current user on Windows
  skeleton$Sys.info <- function() c(sysname = "Windows")
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("regular.ttf", "bold.ttf"),
    roboto_files
  )
  expect_identical(skeleton$resolve_fonts(named, defaults), loaded(user))

  # but not with a folder
  named$mainfont <- file.path("fonts", "Roboto-Regular.ttf")
  expect_message(
    fonts <- skeleton$resolve_fonts(named, defaults, font_path = dir),
    "check the path",
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the message about unidentified files keeps the extension of a file", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  local_systemfonts()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("a.ttf", "b.ttf")
  )
  preferred <- c(
    defaults,
    list(
      preferredmainfont = "Roboto-Regular.ttf",
      preferredmainfontoptions = "BoldFont=Roboto-Bold"
    )
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred, font_path = dir),
    'such as "Roboto-Regular.ttf",\n',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the message about the preferred font explains the option", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()

  expect_message(
    skeleton$resolve_fonts(
      list(),
      preferred
    ),
    paste0(
      "Preferred font \"Licensed Sans Medium\" was not found, ",
      "using \"regular.ttf\" instead.\n",
      "To use it, copy its font files to ~/.local/share/fonts, and restart R,\n",
      "or set `options(indiedown.font_path = \"<folder>\")` to a folder with its font files.\n"
    ),
    fixed = TRUE
  )

  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  withr::local_options(indiedown.font_path = "/no/such/folder")
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(),
      preferred
    ),
    paste0(
      "To use it, check that the folder \"/no/such/folder\" ",
      "from the option `indiedown.font_path` holds its font files.\n"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the folders of installed fonts depend on the system", {
  skeleton <- local_skeleton()
  withr::local_envvar(
    LOCALAPPDATA = "C:/Users/me/AppData/Local",
    WINDIR = "C:/Windows",
    XDG_DATA_HOME = NA
  )

  expect_identical(
    skeleton$font_dirs("Windows"),
    list(
      user = "C:/Users/me/AppData/Local/Microsoft/Windows/Fonts",
      system = "C:/Windows/Fonts",
      unseen = "C:/Users/me/AppData/Local/Microsoft/Windows/Fonts"
    )
  )
  expect_identical(
    skeleton$font_dirs("Darwin"),
    list(user = "~/Library/Fonts", system = "/Library/Fonts")
  )
  expect_identical(
    skeleton$font_dirs("Linux"),
    list(
      user = c("~/.local/share/fonts", "~/.fonts"),
      system = c("/usr/local/share/fonts", "/usr/share/fonts")
    )
  )
  withr::local_envvar(XDG_DATA_HOME = "/xdg")
  expect_identical(
    skeleton$font_dirs("Linux")$user[[3]],
    "/xdg/fonts"
  )
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
  # aliases can share a file
  expect_identical(
    skeleton$match_font_files(
      c("X", "Y"),
      c("/a/xy.ttf", "/a/xy.ttf"),
      c("X", "Y")
    ),
    c(X = "/a/xy.ttf", Y = "/a/xy.ttf")
  )
  # not from the named instances of a variable font
  expect_null(skeleton$match_font_files("X", NA_character_, "X"))
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

test_that("font names are read from font files with systemfonts", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  dir <- copy_fonts(withr::local_tempdir(), c("bold.ttf", "regular.ttf"))
  writeLines("not a font", file.path(dir, "broken.ttf"))
  files <- file.path(dir, c("bold.ttf", "broken.ttf", "regular.ttf"))

  # with the family name for the regular face
  expect_identical(
    skeleton$font_file_names(files),
    list(
      path = files[c(1:3, 3)],
      name = c("Roboto-Bold", NA, "Roboto-Regular", "Roboto")
    )
  )

  local_systemfonts()
  expect_null(skeleton$font_file_names(files))
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

test_that("the options are the defaults of the arguments", {
  skeleton <- local_skeleton()
  expect_identical(
    formals(skeleton$resolve_fonts)$font_path,
    quote(get_indiedown_option("font_path"))
  )
  expect_identical(
    formals(skeleton$find_font_files)$font_path,
    quote(get_indiedown_option("font_path"))
  )
  expect_identical(
    formals(skeleton$resolve_fonts)$mainfont,
    quote(get_indiedown_option("mainfont"))
  )
})

test_that("the arguments take the place of the options", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) c("Some Sans", "Other Sans")
  withr::local_options(indiedown.mainfont = "Some Sans")
  expect_identical(
    skeleton$resolve_fonts(list(), defaults, mainfont = "Other Sans"),
    list(mainfont = "Other Sans")
  )
})

# Licensed Sans in the files of Roboto, in the Linux folders of the home folder,
# with XDG_DATA_HOME unset, so that fontconfig reads ~/.local/share/fonts
local_linux_fonts <- function(skeleton, subdir, env = parent.frame()) {
  home <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(HOME = home, XDG_DATA_HOME = NA, .local_envir = env)
  linux <- skeleton$dirs_of("Linux")
  skeleton$font_dirs <- function(...) linux
  copy_fonts(
    file.path(home, subdir),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  home
}

test_that("fonts in subfolders of a font folder are found", {
  withr::local_envvar(PATH = R.home("bin"))
  for (subdir in c(".local/share/fonts", ".fonts", "x/y/z")) {
    skeleton <- local_skeleton()
    dir <- file.path(withr::local_tempdir(), "fonts")
    skeleton$font_dirs <- function(...) list(user = dir)
    copy_fonts(
      file.path(dir, subdir),
      c("regular.ttf", "bold.ttf"),
      c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
    )
    expect_silent(fonts <- skeleton$resolve_fonts(list(), roboto))
    # as normalized on the system, such as /private/var on macOS
    # and without short names on Windows
    expect_identical(
      fonts$mainfontoptions[[1]],
      paste0("Path=", normalizePath(file.path(dir, subdir), "/"), "/")
    )
  }
})

test_that("fonts in ~/.local/share/fonts are found with fc-list", {
  skip_on_os(c("windows", "mac"))
  skip_if_not(nzchar(Sys.which("fc-list")), "fc-list not available")
  skeleton <- local_skeleton(lookup = TRUE)
  home <- local_linux_fonts(skeleton, ".local/share/fonts")
  copy_fonts(file.path(home, ".local/share/fonts"), "bolditalic.ttf", "x.ttf")
  # without systemfonts, only fc-list tells the faces apart
  # that the options do not name
  local_systemfonts()
  expect_silent(fonts <- skeleton$resolve_fonts(list(), roboto_bold))
  expect_identical(
    fonts$mainfontoptions,
    c(
      paste0("Path=", normalizePath(home, "/"), "/.local/share/fonts/"),
      "BoldFont=Roboto-Bold.ttf",
      "ItalicFont=x.ttf",
      "BoldItalicFont=x.ttf"
    )
  )
})

test_that("fonts in ~/.fonts are found without fc-list", {
  skip_on_os(c("windows", "mac"))
  skeleton <- local_skeleton()
  home <- local_linux_fonts(skeleton, ".fonts/vendor")
  withr::local_envvar(PATH = R.home("bin"))
  expect_silent(fonts <- skeleton$resolve_fonts(list(), roboto))
  expect_identical(
    fonts$mainfontoptions[[1]],
    paste0("Path=", normalizePath(home, "/"), "/.fonts/vendor/")
  )
})

test_that("the option is enough on Linux", {
  skeleton <- local_skeleton()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  withr::local_envvar(PATH = R.home("bin"))
  withr::local_options(indiedown.font_path = dir)
  expect_silent(fonts <- skeleton$resolve_fonts(list(), roboto))
  expect_identical(fonts$mainfontoptions[[1]], paste0("Path=", dir, "/"))
})

test_that("the search of the font folders is bounded", {
  skeleton <- local_skeleton()
  dir <- withr::local_tempdir()
  deep <- file.path(dir, "a", "b", "c", "d")
  dir.create(deep, recursive = TRUE)
  file.create(file.path(c(dir, deep), "x.ttf"))
  expect_length(skeleton$list_font_files(dir), 1)
  expect_length(skeleton$list_font_files(dir, depth = 4), 2)
  file.create(file.path(dir, c("a/1.otf", "a/b/2.OTF", "e.txt")))
  expect_length(skeleton$list_font_files(dir, limit = 2), 2)
  expect_length(skeleton$list_font_files(dir, limit = 1), 1)
})

test_that("without fc-list and systemfonts, the fallback font is used", {
  skeleton <- local_skeleton(lookup = TRUE)
  skeleton$Sys.which <- function(names) ""
  local_systemfonts()

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred),
    paste0(
      'Preferred font "Licensed Sans Medium" was not found, ',
      'using "regular.ttf" instead.\n',
      "The systemfonts package could not be loaded, ",
      "which may be why the font lookup failed.\n",
      "To use it, install systemfonts 1.3.0 or later ",
      'with `install.packages("systemfonts")`,\n',
      "or copy its font files to ~/.local/share/fonts, and restart R,\n"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
  expect_null(skeleton$installed_fonts())

  # a named font is left to LaTeX
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Some Sans"), preferred)
  )
  expect_identical(fonts, list(mainfont = "Some Sans"))
})

test_that("an old systemfonts gives a warning and the fallback font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  local_systemfonts("1.2.3")
  # the files of the preferred font, but not by name, and an unrelated font
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("italic.ttf", "regular.ttf", "bold.ttf"),
    c("other.ttf", "a.ttf", "b.ttf")
  )
  withr::local_options(indiedown.font_path = dir)

  expect_warning(
    expect_message(
      fonts <- skeleton$resolve_fonts(list(), roboto),
      "The systemfonts package could not be loaded",
      fixed = TRUE
    ),
    paste0(
      "The font lookup needs systemfonts 1.3.0 or later, ",
      "but version 1.2.3 is installed.\n"
    ),
    fixed = TRUE
  )
  expect_identical(fonts$mainfont, "regular.ttf")

  # once per session
  expect_silent(skeleton$resolve_fonts(list(), roboto))
  expect_null(skeleton$font_file_names(file.path(dir, "a.ttf")))
})

test_that("font files are recognised by PostScript name with systemfonts", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("italic.ttf", "regular.ttf", "bold.ttf", "bolditalic.ttf"),
    c("other.ttf", "a.ttf", "b.ttf", "c.ttf")
  )

  expect_identical(
    skeleton$resolve_fonts(list(), roboto, font_path = dir),
    list(
      mainfont = "a.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=b.ttf",
        "ItalicFont=a.ttf",
        "BoldItalicFont=b.ttf",
        "Scale=0.9"
      )
    )
  )
  # also a named font
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Roboto-BoldItalic", mainfontoptions = "Scale=0.9"),
      roboto,
      font_path = dir
    ),
    list(
      mainfont = "c.ttf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "Scale=0.9",
        "ItalicFont=c.ttf"
      )
    )
  )

  # without systemfonts, the message explains how to do without it
  local_systemfonts()
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto, font_path = dir),
    paste0(
      'Preferred font "Roboto-Regular" was not found, ',
      'using "regular.ttf" instead.\n',
      "The systemfonts package could not be loaded, ",
      "which may be why the font lookup failed:\n",
      'without it, the font files in "',
      dir,
      '" cannot be identified.\n',
      "To use it, install systemfonts 1.3.0 or later ",
      'with `install.packages("systemfonts")`,\n',
      'or check that the folder "',
      dir,
      '" from the option `indiedown.font_path` holds its font files.\n',
      "If its font files are among those that cannot be identified, ",
      "copy them to a folder,\n",
      "rename them to the font names that are looked up, ",
      'such as "Roboto-Regular.otf",\n',
      'and set `options(indiedown.font_path = "<folder>")`.\n'
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)

  # a named font is left to LaTeX when the installed fonts cannot be listed,
  # because LaTeX finds the fonts that are installed by name,
  # but not those among the unidentified files in the folder of the option
  skeleton$installed_fonts <- function(...) NULL
  skeleton$installed_font_names <- function(...) NULL
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Roboto-BoldItalic"),
      roboto,
      font_path = dir
    ),
    paste0(
      'Font "Roboto-BoldItalic" from the `mainfont` field of the document ',
      "is left to LaTeX, which may not find it.\n",
      "The systemfonts package could not be loaded, ",
      "which may be why the font lookup failed:\n",
      'without it, the font files in "',
      dir,
      '" cannot be identified.\n',
      "If LaTeX does not find it, install systemfonts 1.3.0 or later ",
      'with `install.packages("systemfonts")`,\n',
      "or ",
      skeleton$font_install_hint("Roboto-BoldItalic"),
      ".\n",
      "If its font files are among those that cannot be identified, ",
      "copy them to a folder,\n",
      "rename them to the font names that are looked up, ",
      'such as "Roboto-BoldItalic.otf",\n',
      'and set `options(indiedown.font_path = "<folder>")`.\n'
    ),
    fixed = TRUE
  )
  expect_identical(fonts, list(mainfont = "Roboto-BoldItalic"))
})

test_that("a family name is loaded from the files of its regular face", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = withr::local_tempdir())
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("bolditalic.ttf", "bold.ttf", "italic.ttf", "regular.ttf"),
    c("a.ttf", "b.ttf", "c.ttf", "d.ttf")
  )
  # systemfonts lists the fonts installed for the current user,
  # which LaTeX does not find by name
  skeleton$installed_fonts <- function(...) {
    list(
      path = file.path(user, "d.ttf"),
      name = "Roboto-Regular",
      family = "Roboto"
    )
  }
  skeleton$installed_font_names <- function(...) "Roboto"

  # with the other faces of the family Roboto:
  # the skeleton's italic is of the family Roboto Light,
  # so the italic is the bold italic, as fontconfig would choose it
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Roboto"), roboto),
    list(
      mainfont = "d.ttf",
      mainfontoptions = c(
        paste0("Path=", user, "/"),
        "BoldFont=b.ttf",
        "ItalicFont=a.ttf",
        "BoldItalicFont=a.ttf"
      )
    )
  )

  # without systemfonts, the message names the folder,
  # and explains how to do without it next to the usual advice,
  # as with TeX Live's fc-list on Windows, which does not see the folder
  local_systemfonts()
  skeleton$installed_fonts <- no_fonts
  skeleton$installed_font_names <- function(...) character()
  unidentified <- paste0(
    "The systemfonts package could not be loaded, ",
    "which may be why the font lookup failed:\n",
    'without it, the font files in "',
    user,
    '" cannot be identified.\n'
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Roboto"), roboto),
    unidentified,
    fixed = TRUE
  )
  expect_identical(fonts$mainfont, "regular.ttf")
  expect_message(
    skeleton$resolve_fonts(list(), roboto),
    paste0(
      'Preferred font "Roboto-Regular" was not found, ',
      'using "regular.ttf" instead.\n',
      unidentified,
      "To use it, install systemfonts 1.3.0 or later ",
      'with `install.packages("systemfonts")`,\n',
      "or install its font files for the current user ",
      "(Settings > Personalization > Fonts, or right-click > Install), and restart R,\n",
      'or set `options(indiedown.font_path = "<folder>")` ',
      "to a folder with its font files.\n",
      "If its font files are among those that cannot be identified, ",
      "copy them to a folder,\n",
      "rename them to the font names that are looked up, ",
      'such as "Roboto-Regular.otf",\n',
      'and set `options(indiedown.font_path = "<folder>")`.\n'
    ),
    fixed = TRUE
  )
})

test_that("unidentified font files count against a named font only on Windows", {
  # no list of the installed fonts, and no systemfonts to identify font files
  skeleton <- local_skeleton()
  skeleton$installed_fonts <- function(...) NULL
  skeleton$installed_font_names <- function(...) NULL
  local_systemfonts()
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = withr::local_tempdir())

  # on Windows, a font installed for the current user may be among
  # the unidentified font files, and LaTeX does not find it by name
  skeleton$Sys.info <- function() c(sysname = "Windows")
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    "regular.ttf",
    "SomeOtherFont.ttf"
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Arial"), roboto),
    paste0(
      'Font "Arial" from the `mainfont` field of the document ',
      'could not be verified, ',
      'using "regular.ttf" instead.\n',
      "The systemfonts package could not be loaded, ",
      "which may be why the font lookup failed:\n",
      'without it, the font files in "',
      user,
      '" cannot be identified.\n',
      "To use it, install systemfonts 1.3.0 or later ",
      'with `install.packages("systemfonts")`,\n',
      "or install its font files for the current user ",
      "(Settings > Personalization > Fonts, or right-click > Install), and restart R.\n",
      "If its font files are among those that cannot be identified, ",
      "copy them to a folder,\n",
      "rename them to the font names that are looked up, ",
      'such as "Arial.otf",\n',
      'and set `options(indiedown.font_path = "<folder>")`.\n'
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
  # without font files there, it is left to LaTeX
  unlink(file.path(user, "SomeOtherFont.ttf"))
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Arial"), roboto)
  )
  expect_identical(fonts, list(mainfont = "Arial"))

  # elsewhere, LaTeX finds an installed font by name
  skeleton$Sys.info <- function() c(sysname = "Darwin")
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Arial"), roboto)
  )
  expect_identical(fonts, list(mainfont = "Arial"))
  # also next to unidentified font files in the folder of the option,
  # which may hold the font under other names, as the message explains
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Corporate Sans Medium.ttf", "Corporate Sans Heavy.ttf")
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Arial"),
      roboto,
      font_path = dir
    ),
    paste0(
      "is left to LaTeX, which may not find it.\n",
      "The systemfonts package could not be loaded"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, list(mainfont = "Arial"))
})

test_that("systemfonts is not needed for fonts found otherwise", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  local_systemfonts("1.2.3")
  # an unrelated font in a user folder, the preferred font in a system folder
  user <- copy_fonts(
    file.path(withr::local_tempdir(), "fonts"),
    "regular.ttf",
    "other.ttf"
  )
  system <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  skeleton$font_dirs <- function(...) list(user = user, system = system)
  # with all faces named
  expect_silent(fonts <- skeleton$resolve_fonts(list(), roboto))
  expect_identical(fonts$mainfontoptions[[1]], paste0("Path=", system, "/"))

  # a missing font, with a list of the installed fonts
  unlink(system, recursive = TRUE)
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto),
    "To use it, copy its font files to ~/.local/share/fonts, and restart R,",
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("an installed named font is loaded by name, also with its files", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Roboto-Regular"
  # LaTeX finds fonts in the folders of the user by name on Linux,
  # with the bold and italic faces
  local_linux_fonts(skeleton, ".local/share/fonts")
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Roboto-Regular"), roboto),
    list(mainfont = "Roboto-Regular")
  )
})

test_that("a named font installed for the current user on Windows is loaded by path", {
  # to tell apart the faces that its options do not name
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) "Roboto-Regular"
  skeleton$Sys.info <- function() c(sysname = "Windows")
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = withr::local_tempdir())
  user <- copy_fonts(
    file.path(appdata, "Microsoft", "Windows", "Fonts"),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  expect_identical(
    skeleton$resolve_fonts(
      list(
        mainfont = "Roboto-Regular",
        mainfontoptions = "BoldFont=Roboto-Bold"
      ),
      roboto
    ),
    list(
      mainfont = "Roboto-Regular.ttf",
      mainfontoptions = c(
        paste0("Path=", user, "/"),
        "BoldFont=Roboto-Bold.ttf"
      )
    )
  )
})

test_that("the message is shown again if its advice changes", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  expect_message(skeleton$resolve_fonts(list(), preferred), "was not found")
  expect_silent(skeleton$resolve_fonts(list(), preferred))
  expect_message(
    skeleton$resolve_fonts(list(), preferred, font_path = "/no/fonts/a"),
    "/no/fonts/a",
    fixed = TRUE
  )
  expect_message(
    skeleton$resolve_fonts(list(), preferred, font_path = "/no/fonts/b"),
    "/no/fonts/b",
    fixed = TRUE
  )
})

test_that("the option system_fonts hides the installed fonts", {
  # on Windows, ~ is not HOME
  skip_on_os("windows")
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton(lookup = TRUE)
  home <- withr::local_tempdir()
  withr::local_envvar(HOME = home, XDG_DATA_HOME = "", PATH = R.home("bin"))
  skeleton$font_dirs <- skeleton$dirs_of
  dir <- copy_fonts(
    file.path(home, ".local", "share", "fonts"),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfontoptions[[1]],
    paste0("Path=", dir, "/")
  )

  local_mocked_bindings(
    system_fonts = function(...) stop("systemfonts is not used"),
    .package = "systemfonts"
  )
  withr::local_options(indiedown.system_fonts = FALSE)
  expect_identical(skeleton$font_dirs("Linux"), list())
  expect_identical(
    skeleton$installed_fonts()[c("path", "name", "family")],
    no_fonts()
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto),
    "was not found"
  )
  expect_identical(fonts, defaults)
})

test_that("the lookup lists the installed fonts once and each folder once per font", {
  # on Windows, ~ is not HOME
  skip_on_os("windows")
  skeleton <- local_skeleton(lookup = TRUE)
  # XDG_DATA_HOME is ~/.local/share, as by default
  home <- withr::local_tempdir()
  withr::local_envvar(
    HOME = home,
    XDG_DATA_HOME = file.path(home, ".local/share")
  )
  linux <- skeleton$dirs_of("Linux")
  skeleton$font_dirs <- function(...) linux
  calls <- new.env()
  calls$fonts <- 0
  calls$dirs <- character()
  skeleton$installed_fonts <- function(...) {
    calls$fonts <- calls$fonts + 1
    no_fonts()
  }
  skeleton$list_font_files <- function(dir, ...) {
    calls$dirs <- c(calls$dirs, dir)
    character()
  }

  expect_message(
    skeleton$resolve_fonts(list(mainfont = "Missing"), preferred),
    "not found"
  )
  expect_identical(calls$fonts, 1)
  expect_identical(
    calls$dirs,
    normalizePath(
      c(
        file.path(home, ".local", "share", "fonts"),
        file.path(home, ".fonts"),
        "/usr/local/share/fonts",
        "/usr/share/fonts"
      ),
      "/",
      FALSE
    )
  )
})

test_that("PostScript names are read once per file and session", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  dir <- copy_fonts(withr::local_tempdir(), c("regular.ttf", "bold.ttf"))
  files <- file.path(dir, c("regular.ttf", "bold.ttf"))
  read <- 0
  font_info <- systemfonts::font_info
  local_mocked_bindings(
    font_info = function(...) {
      read <<- read + 1
      font_info(...)
    },
    .package = "systemfonts"
  )

  names <- list(
    path = files[c(1, 2, 1)],
    name = c("Roboto-Regular", "Roboto-Bold", "Roboto")
  )
  expect_identical(skeleton$font_file_names(files), names)
  expect_identical(read, 2)
  expect_identical(skeleton$font_file_names(files), names)
  expect_identical(read, 2)

  # again after a change
  Sys.setFileTime(files[[1]], Sys.time() + 60)
  expect_identical(skeleton$font_file_names(files), names)
  expect_identical(read, 3)
})

# The fonts that XeLaTeX embeds for the pandoc variables `fonts`,
# with text in each face
xelatex_fonts <- function(fonts) {
  dir <- withr::local_tempdir()
  writeLines(
    c(
      "\\documentclass{article}",
      "\\usepackage{fontspec}",
      sprintf(
        "\\setmainfont[%s]{%s}",
        paste(fonts$mainfontoptions, collapse = ","),
        fonts$mainfont
      ),
      "\\begin{document}",
      "Regular \\textbf{bold} \\textit{italic} \\textbf{\\textit{bold italic}}",
      "\\end{document}"
    ),
    file.path(dir, "fonts.tex")
  )
  withr::with_dir(
    dir,
    system2(
      "xelatex",
      c("-interaction=nonstopmode", "fonts.tex"),
      stdout = FALSE,
      stderr = FALSE
    )
  )
  fonts <- pdftools::pdf_fonts(file.path(dir, "fonts.pdf"))
  # without the subset prefix and the encoding
  sort(sub(
    "^[A-Z]{6}[+](.*?)(-Identity-H)?$",
    "\\1",
    fonts$name[fonts$embedded]
  ))
}

test_that("the faces that the options do not name are loaded from the family", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skip_if(!nzchar(Sys.which("kpsewhich")), "kpsewhich not available")
  # Latin Modern Sans from the TeX tree, a family with four faces
  files <- paste0(
    "lmsans10-",
    c("regular", "bold", "oblique", "boldoblique"),
    ".otf"
  )
  lm <- suppressWarnings(system2("kpsewhich", files, stdout = TRUE))
  skip_if(length(lm) != 4, "Latin Modern Sans not available")
  skeleton <- local_skeleton()
  dir <- normalizePath(withr::local_tempdir(), "/")
  file.copy(lm, dir)

  # a preferred font that names only its bold face, found by file name
  lm_sans <- c(
    defaults,
    list(
      preferredmainfont = "LMSans10-Regular",
      preferredmainfontoptions = "BoldFont=LMSans10-Bold"
    )
  )
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(), lm_sans, font_path = dir)
  )
  expect_identical(
    fonts,
    list(
      mainfont = "lmsans10-regular.otf",
      mainfontoptions = c(
        paste0("Path=", dir, "/"),
        "BoldFont=lmsans10-bold.otf",
        "ItalicFont=lmsans10-oblique.otf",
        "BoldItalicFont=lmsans10-boldoblique.otf"
      )
    )
  )

  # a family name, from files whose names differ from the font names
  named <- normalizePath(withr::local_tempdir(), "/")
  file.copy(lm, file.path(named, c("a.otf", "b.otf", "c.otf", "d.otf")))
  expect_silent(
    named_fonts <- skeleton$resolve_fonts(
      list(mainfont = "Latin Modern Sans"),
      lm_sans,
      font_path = named
    )
  )
  expect_identical(
    named_fonts,
    list(
      mainfont = "a.otf",
      mainfontoptions = c(
        paste0("Path=", named, "/"),
        "BoldFont=b.otf",
        "ItalicFont=c.otf",
        "BoldItalicFont=d.otf"
      )
    )
  )

  skip_on_cran()
  skip_if_not_installed("pdftools")
  skip_if(!nzchar(Sys.which("xelatex")), "xelatex not available")
  lm_faces <- c(
    "LMSans10-Bold",
    "LMSans10-BoldOblique",
    "LMSans10-Oblique",
    "LMSans10-Regular"
  )
  expect_identical(xelatex_fonts(fonts), lm_faces)
  expect_identical(xelatex_fonts(named_fonts), lm_faces)
})

test_that("the faces are chosen by family, slant and weight", {
  skeleton <- local_skeleton()
  styles <- list(
    path = paste0(
      "/f/",
      c("r", "m", "mi", "i", "b", "bi", "k", "ki", "o"),
      ".otf"
    ),
    family = c(rep("Sans", 8), "Other Sans"),
    weight = c(80, 100, 100, 80, 200, 200, 210, 210, 200),
    italic = c(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)
  )
  faces <- c("BoldFont", "ItalicFont", "BoldItalicFont")

  # the bold closest to bold, the italic closest to the weight of the font
  expect_identical(
    skeleton$other_faces(styles, "/f/m.otf", character(), faces),
    c(
      BoldFont = "/f/b.otf",
      ItalicFont = "/f/mi.otf",
      BoldItalicFont = "/f/bi.otf"
    )
  )
  # the bold italic closest to a named bold face
  expect_identical(
    skeleton$other_faces(styles, "/f/r.otf", "/f/k.otf", faces[-1]),
    c(ItalicFont = "/f/i.otf", BoldItalicFont = "/f/ki.otf")
  )
  # no bold face heavier than the heaviest
  expect_identical(
    skeleton$other_faces(styles, "/f/k.otf", character(), faces),
    c(ItalicFont = "/f/ki.otf")
  )
  # a family without italics or bold faces
  expect_identical(
    skeleton$other_faces(styles, "/f/o.otf", character(), faces),
    character()
  )
  # without the weight of the font
  styles$weight[[1]] <- NA
  expect_null(skeleton$other_faces(styles, "/f/r.otf", character(), faces))
})

test_that("the faces are told apart by the installed fonts without systemfonts", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  local_systemfonts()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  # as fc-list lists them, with the weight and slant of fontconfig
  listed <- skeleton$installed_font_list(
    path = file.path(dir, c("Roboto-Regular.ttf", "Roboto-Bold.ttf")),
    index = c(0, 0),
    names = list("Roboto-Regular", "Roboto-Bold"),
    families = list("Roboto", "Roboto"),
    weight = c(80, 200),
    italic = c(FALSE, FALSE)
  )
  skeleton$installed_fonts <- function(...) listed
  regular <- c(defaults, list(preferredmainfont = "Roboto-Regular"))
  expect_identical(
    skeleton$resolve_fonts(list(), regular, font_path = dir)$mainfontoptions,
    c(paste0("Path=", dir, "/"), "BoldFont=Roboto-Bold.ttf")
  )

  # all faces named, loaded from the files
  skeleton$installed_fonts <- no_fonts
  expect_identical(
    skeleton$resolve_fonts(list(), roboto, font_path = dir)$mainfont,
    "Roboto-Regular.ttf"
  )

  # otherwise, the faces cannot be told apart
  hint <- paste0(
    "The systemfonts package could not be loaded, ",
    "which may be why the font lookup failed:\n",
    'without it, the bold and italic faces of the font files in "',
    dir,
    '" cannot be identified.\n',
    "To use it, install systemfonts 1.3.0 or later ",
    'with `install.packages("systemfonts")`,\n',
    "or name all faces of the font in its options, ",
    "with `BoldFont=`, `ItalicFont=` and `BoldItalicFont=`.\n"
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto_bold, font_path = dir),
    paste0(
      'Preferred font "Roboto-Regular" was not found, ',
      'using "regular.ttf" instead.\n',
      hint
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)

  # a named font is not left to LaTeX without a list of the installed fonts
  skeleton$installed_fonts <- function(...) NULL
  skeleton$installed_font_names <- function(...) NULL
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Roboto-Regular"),
      defaults,
      font_path = dir
    ),
    hint,
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the named instances of variable fonts are not loaded from files", {
  skip_on_os("windows")
  skeleton <- local_skeleton(lookup = TRUE)
  # fc-list as it lists a variable font with its named instances
  fc_list <- file.path(withr::local_tempdir(), "fc-list")
  writeLines(
    c(
      "#!/bin/sh",
      "cat <<'EOF'",
      "/f/Var.ttf\t0\tVar-Regular\tVar Regular\tVar\t[0 210]\t0",
      "/f/Var.ttf\t65536\tVar-Regular\tVar Regular\tVar\t80\t0",
      "/f/Var.ttf\t131072\tVar-Bold\tVar Bold\tVar,Var Bold\t200\t0",
      "/f/Sans.ttf\t0\tSans-Regular\tSans Regular,Sans Normal\tSans\t80\t0",
      "EOF"
    ),
    fc_list
  )
  Sys.chmod(fc_list, "755")
  skeleton$Sys.which <- function(names) fc_list

  installed <- skeleton$installed_fonts()
  expect_identical(
    installed$path,
    c(rep("/f/Var.ttf", 2), rep(NA, 4), rep("/f/Sans.ttf", 3))
  )
  expect_true("Var-Bold" %in% skeleton$installed_font_names(installed))
  expect_identical(
    installed$styles,
    list(
      path = c("/f/Var.ttf", "/f/Sans.ttf"),
      family = c("Var", "Sans"),
      weight = c(NA, 80),
      italic = c(FALSE, FALSE)
    )
  )

  find <- function(faces) {
    skeleton$find_font_files(faces, NULL, installed, list())
  }
  expect_null(find("Var-Bold"))
  expect_identical(find("Var-Regular"), c(`Var-Regular` = "/f/Var.ttf"))
  # several names of one font
  expect_identical(
    find(c("Sans-Regular", "Sans Normal")),
    c(`Sans-Regular` = "/f/Sans.ttf", `Sans Normal` = "/f/Sans.ttf")
  )
})

test_that("on Windows, systemfonts lists no fonts of the current user", {
  skip_if_not_installed("systemfonts")
  skeleton <- local_skeleton(lookup = TRUE)
  skeleton$Sys.info <- function() c(sysname = "Windows")
  skeleton$Sys.which <- function(names) ""
  skeleton$has_systemfonts <- function() TRUE
  appdata <- withr::local_tempdir()
  withr::local_envvar(LOCALAPPDATA = appdata, WINDIR = "C:/Windows")
  user <- gsub(
    "/",
    "\\",
    file.path(skeleton$font_dirs()$user, "sub"),
    fixed = TRUE
  )
  local_mocked_bindings(
    system_fonts = function(...) {
      data.frame(
        path = c(paste0(user, "\\Corp.ttc"), "C:\\Windows\\Fonts\\arial.ttf"),
        index = c(0L, 0L),
        name = c("CorporateSans-Medium", "ArialMT"),
        family = c("Corporate Sans", "Arial"),
        weight = factor(c("medium", "normal")),
        italic = c(FALSE, FALSE)
      )
    },
    .package = "systemfonts"
  )

  installed <- skeleton$installed_fonts()
  expect_identical(installed$name, "ArialMT")
  expect_identical(installed$styles$weight, 80)
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "CorporateSans-Medium"),
      defaults
    ),
    'Font "CorporateSans-Medium" from the `mainfont` field of the document was not found',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Arial"), defaults),
    list(mainfont = "Arial")
  )
})

test_that("the folder of the option comes before the installed fonts", {
  skip_if_not_installed("systemfonts", "1.3.0")
  skeleton <- local_skeleton()
  installed <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("a.ttf", "b.ttf")
  )
  skeleton$installed_fonts <- function(...) {
    list(
      path = file.path(installed, c("Roboto-Regular.ttf", "Roboto-Bold.ttf")),
      name = c("Roboto-Regular", "Roboto-Bold")
    )
  }
  expect_identical(
    skeleton$resolve_fonts(list(), roboto, font_path = dir)$mainfontoptions[[
      1
    ]],
    paste0("Path=", dir, "/")
  )
  expect_identical(
    skeleton$resolve_fonts(list(), roboto)$mainfontoptions[[1]],
    paste0("Path=", installed, "/")
  )
})

test_that("the message names the preferred font that is used instead", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function(...) character()
  local_systemfonts()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Roboto-Regular.ttf", "Roboto-Bold.ttf")
  )
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Missing Sans"),
      roboto,
      font_path = dir
    ),
    paste0(
      'Font "Missing Sans" from the `mainfont` field of the document was not found, ',
      'using "Roboto-Regular" instead.\n'
    ),
    fixed = TRUE
  )
  expect_identical(fonts$mainfont, "Roboto-Regular.ttf")
})

test_that("paths are compared as on the system", {
  skeleton <- local_skeleton()
  expect_identical(
    skeleton$path_key("C:\\Users\\Me/Fonts\\A.otf", windows = TRUE),
    "c:/users/me/fonts/a.otf"
  )
  expect_identical(
    skeleton$path_key("/home/Me\\A.otf", windows = FALSE),
    "/home/Me/A.otf"
  )
  expect_identical(
    skeleton$in_dirs(
      c("/f/a.otf", "/f/sub/b.otf", "/fonts/c.otf", "/g/d.otf"),
      c("/f", "/g/")
    ),
    c(TRUE, TRUE, FALSE, TRUE)
  )
  expect_identical(skeleton$in_dirs("/f/a.otf", NULL), FALSE)
})
