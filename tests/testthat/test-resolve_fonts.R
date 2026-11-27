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

test_that("a named font is used as named without a fallback font", {
  skeleton <- local_skeleton()

  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "Some Sans"), list()),
    list(mainfont = "Some Sans")
  )
})

test_that("a named font takes precedence if fc-list lists all its fonts", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() {
    c("Some Sans", "Some Sans Bold", "Licensed Sans Medium")
  }

  options <- c("BoldFont=* Bold", "Scale=0.9")
  expect_silent(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Some Sans", mainfontoptions = options),
      preferred
    )
  )
  expect_identical(
    fonts,
    list(mainfont = "Some Sans", mainfontoptions = options)
  )

  # ignoring case
  expect_identical(
    skeleton$resolve_fonts(list(mainfont = "some sans"), preferred),
    list(mainfont = "some sans")
  )
})

test_that("the option names a font if the document does not", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() {
    c("Some Sans", "Other Sans", "Third Sans")
  }
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

test_that("a named font is loaded from its files", {
  skeleton <- local_skeleton()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Some-Regular.ttf", "Some-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)

  expect_silent(
    args <- skeleton$apply_default_yaml(list(
      mainfont = "Some-Regular",
      mainfontoptions = c("BoldFont=Some-Bold", "Scale=0.9")
    ))
  )
  expect_true("mainfont:Some-Regular.ttf" %in% args)
  expect_true(
    paste0(
      "mainfontoptions:Path=",
      dir,
      "/,BoldFont=Some-Bold.ttf,Scale=0.9"
    ) %in%
      args
  )

  # from the option, in the folder of the fonts installed for the current user
  skeleton$font_dirs <- function(...) dir
  withr::local_options(
    indiedown.font_path = NULL,
    indiedown.mainfont = "Some-Regular"
  )
  expect_identical(
    skeleton$resolve_fonts(list(), defaults),
    list(
      mainfont = "Some-Regular.ttf",
      mainfontoptions = paste0("Path=", dir, "/")
    )
  )
})

test_that("a missing named font falls back with a message", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()

  messages <- capture_messages(
    args <- skeleton$apply_default_yaml(list(
      mainfont = "Missing Sans",
      mainfontoptions = "Scale=0.9"
    ))
  )
  expect_identical(
    messages,
    paste0(
      'Font "Missing Sans" from the `mainfont` field of the document ',
      'was not found, using "regular.ttf" instead.\n',
      "To use it, copy its font files to ~/.local/share/fonts,\n",
      'or set `options(indiedown.font_path = "<folder>")` to a folder ',
      'with its font files, named like "Missing Sans.otf" or ".ttf".\n'
    )
  )
  expect_true("mainfont:regular.ttf" %in% args)
  # without the options of the missing font
  expect_false(any(grepl("Scale=0.9(,|$)", args)))

  # one message, although the preferred font is missing too
  messages <- capture_messages(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Other Sans"), preferred)
  )
  expect_length(messages, 1)
  expect_match(
    messages,
    'Font "Other Sans" from the `mainfont` field',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)

  # from the option, with the preferred font installed
  skeleton$installed_font_names <- function() {
    c("Licensed Sans Medium", "Licensed Sans Heavy")
  }
  withr::local_options(indiedown.mainfont = "Missing Sans")
  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred),
    paste0(
      'Font "Missing Sans" from the option `indiedown.mainfont` ',
      'was not found, using "Licensed Sans Medium" instead.'
    ),
    fixed = TRUE
  )
  expect_identical(fonts$mainfont, "Licensed Sans Medium")
})

test_that("a named font is used as named if the lookup cannot tell", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() NULL

  # without fc-list
  expect_silent(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Some Sans"), preferred)
  )
  expect_identical(fonts, list(mainfont = "Some Sans"))

  # a font file, which fc-list does not list
  skeleton$installed_font_names <- function() character()
  named <- list(
    mainfont = "some.otf",
    mainfontoptions = "BoldFont=some-bold.ttf"
  )
  expect_identical(skeleton$resolve_fonts(named, defaults), named)

  # with `Path=`, also next to files of the same name in the option's folder
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Some-Regular.ttf", "Some-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)
  named <- list(
    mainfont = "Some-Regular",
    mainfontoptions = c("Path=fonts/", "Extension=.ttf", "BoldFont=Some-Bold")
  )
  expect_identical(skeleton$resolve_fonts(named, defaults), named)
  named$mainfontoptions[[1]] <- "Path = fonts/"
  expect_identical(skeleton$resolve_fonts(named, defaults), named)
})

test_that("with LuaLaTeX, a font that fc-list does not list is looked up with luaotfload", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  skeleton$luaotfload_finds <- function(fonts) all(fonts == "TeX Serif")
  named <- list(mainfont = "TeX Serif")

  expect_silent(
    fonts <- skeleton$resolve_fonts(named, preferred, engine = "lualatex")
  )
  expect_identical(fonts, named)

  # not found by luaotfload either
  expect_message(
    fonts <- skeleton$resolve_fonts(
      list(mainfont = "Missing Serif"),
      defaults,
      engine = "lualatex"
    ),
    'Font "Missing Serif"',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)

  # listed by fc-list, luaotfload is not asked
  skeleton$luaotfload_finds <- function(fonts) stop("unexpected")
  expect_identical(
    skeleton$resolve_fonts(
      list(mainfont = "Some Sans"),
      defaults,
      engine = "lualatex"
    ),
    list(mainfont = "Some Sans")
  )

  # without luaotfload-tool, the named font is used as named
  skeleton$luaotfload_finds <- function(fonts) NULL
  expect_identical(
    skeleton$resolve_fonts(named, defaults, engine = "lualatex"),
    named
  )

  # not with XeLaTeX
  expect_message(
    fonts <- skeleton$resolve_fonts(named, defaults, engine = "xelatex"),
    'Font "TeX Serif"',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("luaotfload_finds() reads the output of luaotfload-tool", {
  skeleton <- local_skeleton(lookup = TRUE)
  skeleton$Sys.which <- function(names) c("luaotfload-tool" = "")
  expect_null(skeleton$luaotfload_finds("Some Sans"))

  skeleton$Sys.which <- function(names) {
    c("luaotfload-tool" = "/luaotfload-tool")
  }
  skeleton$system2 <- function(command, args, ...) {
    font <- sub("^--find=.(.*).$", "\\1", args)
    if (font %in% c("Some Sans", "Some Sans Bold")) {
      paste0('luaotfload | resolve : Font "', font, '" found!')
    } else {
      paste0('luaotfload | resolve : Cannot find "', font, '" in index.')
    }
  }
  expect_true(skeleton$luaotfload_finds(c("Some Sans", "Some Sans Bold")))
  expect_false(skeleton$luaotfload_finds(c("Some Sans", "Other Sans")))
})

test_that("LuaLaTeX finds a font of the TeX installation that fc-list does not list", {
  skip_on_cran()
  skip_if(!nzchar(Sys.which("lualatex")), "lualatex not available")
  skip_if(
    !nzchar(Sys.which("luaotfload-tool")),
    "luaotfload-tool not available"
  )
  skeleton <- local_skeleton(lookup = TRUE)
  # fontconfig sees no fonts
  dir <- withr::local_tempdir()
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
  withr::local_envvar(FONTCONFIG_FILE = conf)
  named <- list(mainfont = "Latin Modern Roman")

  expect_silent(
    fonts <- skeleton$resolve_fonts(named, defaults, engine = "lualatex")
  )
  expect_identical(fonts, named)

  # with XeLaTeX, fc-list decides
  skip_if(!nzchar(Sys.which("fc-list")), "fc-list not available")
  expect_message(
    fonts <- skeleton$resolve_fonts(named, defaults, engine = "xelatex"),
    'Font "Latin Modern Roman"',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("the output format passes its LaTeX engine to the font lookup", {
  skeleton <- local_skeleton()
  skeleton$apply_default_yaml <- function(metadata) {
    skeleton$font_lookup$engine
  }

  format <- skeleton$indiedown_pdf_document_with_asset(
    latex_engine = "lualatex"
  )
  args <- format$pre_processor(list(), "in.md", "static", list(), NULL, ".")
  expect_identical(args[[1]], "lualatex")
  expect_null(skeleton$font_lookup$engine)
})

test_that("a named font file is not found if named with its folder", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  # fontspec fails on a folder in the name, also if the file exists
  dir <- withr::local_tempdir()
  copy_fonts(file.path(dir, "fonts"), "regular.ttf", "Some-Regular.ttf")
  withr::local_dir(dir)

  expect_message(
    expect_identical(
      skeleton$resolve_fonts(
        list(mainfont = "fonts/Some-Regular.ttf"),
        defaults
      ),
      defaults
    ),
    paste0(
      'Font "fonts/Some-Regular.ttf" from the `mainfont` field of the document ',
      'was not found, using "regular.ttf" instead.\n',
      "To use it, check the path, and give only the file name, ",
      "with its folder as `Path=` in `mainfontoptions`, ",
      "relative to the folder of the document.\n"
    ),
    fixed = TRUE
  )
  # also for another face
  named <- list(mainfont = "some.otf", mainfontoptions = "BoldFont=C:/b.otf")
  expect_message(
    expect_identical(skeleton$resolve_fonts(named, defaults), defaults),
    'Font "some.otf"',
    fixed = TRUE
  )

  # the folder as `Path=`
  named <- list(mainfont = "Some-Regular.ttf", mainfontoptions = "Path=fonts/")
  expect_silent(
    expect_identical(skeleton$resolve_fonts(named, defaults), named)
  )
})

test_that("apply_default_yaml() passes the resolved font to pandoc", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"

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

test_that("apply_default_yaml() passes header-includes to pandoc", {
  skeleton <- local_skeleton()

  args <- skeleton$apply_default_yaml(list())
  expect_false(any(grepl("^header-includes:", args)))

  # outside rmarkdown::render(), as the metadata argument is all there is
  args <- skeleton$apply_default_yaml(list(
    `header-includes` = c("\\usepackage{a}", "\\usepackage{b}")
  ))
  expect_identical(
    utils::tail(args, 2),
    c("--variable", "header-includes:\\usepackage{a}\n\\usepackage{b}")
  )
})

test_that("header-includes are taken from the knitted document", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  skeleton <- local_skeleton()

  # inline R code in the YAML header is evaluated by knitr
  dir <- withr::local_tempdir()
  input <- file.path(dir, "doc.Rmd")
  writeLines(
    c(
      "---",
      "header-includes:",
      "- '\\newcommand{\\knitted}{`r 1 + 1`}'",
      "---",
      "",
      "Text."
    ),
    input
  )
  # LaTeX output without running LaTeX.
  # As in the template's format, the pre-processor replaces rmarkdown's,
  # which would add `header-includes` itself,
  # and an `in_header` file makes pandoc ignore `header-includes`
  # (https://github.com/jgm/pandoc/issues/3139).
  in_header <- file.path(dir, "in-header.tex")
  writeLines("% in_header", in_header)
  format <- rmarkdown::latex_document(
    includes = rmarkdown::includes(in_header = in_header)
  )
  format$pre_processor <- skeleton$pre_processor_basic
  output <- rmarkdown::render(
    input,
    output_format = format,
    quiet = TRUE,
    envir = new.env()
  )

  tex <- readLines(output)
  expect_equal(sum(tex == "\\newcommand{\\knitted}{2}"), 1)
  expect_false(any(grepl("`r ", tex, fixed = TRUE)))
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
  option <- paste0(
    ',\nor set `options(indiedown.font_path = "<folder>")` to a folder ',
    'with its font files, named like "A.otf" or ".ttf"'
  )

  windows <- paste0(
    "install its font files for the current user ",
    "(Settings > Personalization > Fonts, or right-click > Install)",
    option
  )
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Windows"),
    windows
  )
  darwin <- paste0(
    'open its font files and click "Install" in Font Book',
    option
  )
  expect_identical(skeleton$font_install_hint("A", sysname = "Darwin"), darwin)
  linux <- paste0("copy its font files to ~/.local/share/fonts", option)
  expect_identical(skeleton$font_install_hint("A", sysname = "Linux"), linux)

  # a named font on Windows, which may be named other than its files
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Windows", named = TRUE),
    paste0(
      "install its font files for all users ",
      "(right-click > Install for all users)",
      option
    )
  )
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Darwin", named = TRUE),
    darwin
  )
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Linux", named = TRUE),
    linux
  )

  expect_identical(
    skeleton$font_install_hint("A", "/no/such/folder"),
    paste0(
      'check that the folder "/no/such/folder" from the option ',
      "`indiedown.font_path` holds its font files, ",
      'named like "A.otf" or ".ttf"'
    )
  )
  # a font file
  expect_identical(
    skeleton$font_install_hint("a.otf", "/no/such/folder", named = TRUE),
    paste(
      "check the path, and give only the file name, with its folder",
      "as `Path=` in `mainfontoptions`, relative to the folder of the document"
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

test_that("the message names the missing faces of the preferred font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  # Roboto-Bold is missing
  dir <- copy_fonts(withr::local_tempdir(), "regular.ttf", "Roboto-Regular.ttf")

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), roboto, font_path = dir),
    paste0(
      'using "regular.ttf" instead.\n',
      'Missing: "Roboto-Bold", as "Roboto-Bold.otf" or "Roboto-Bold.ttf".\n',
      "To use it, check"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)

  # Roboto-Bold listed by fc-list, Roboto-Regular only as a file:
  # the faces are split
  skeleton$installed_font_names <- function() "Roboto-Bold"
  messages <- capture_messages(
    skeleton$resolve_fonts(list(), roboto, font_path = dir)
  )
  expect_no_match(messages, "Missing:", fixed = TRUE)
  expect_match(
    messages,
    "All its faces must be font files in one folder, or all be installed.\n",
    fixed = TRUE
  )

  # on Windows, fc-list does not list the fonts of the current user
  font <- list(
    mainfont = "Roboto-Regular",
    mainfontoptions = "BoldFont=Roboto-Bold"
  )
  expect_identical(
    skeleton$missing_faces(font, dir, sysname = "Windows"),
    paste0(
      "All its faces must be font files in one folder, ",
      "or all be installed for all users.\n"
    )
  )

  # with LuaLaTeX, a face that luaotfload finds is not missing
  skeleton$installed_font_names <- function() character()
  skeleton$luaotfload_finds <- function(fonts) fonts == "Roboto-Bold"
  expect_match(
    skeleton$missing_faces(font, dir, engine = "lualatex"),
    "All its faces must be",
    fixed = TRUE
  )
  expect_match(
    skeleton$missing_faces(font, dir),
    'Missing: "Roboto-Bold"',
    fixed = TRUE
  )

  # not if all faces are missing, the message then names the font files
  expect_null(skeleton$missing_faces(
    list(mainfont = "A", mainfontoptions = "BoldFont=B"),
    dir
  ))

  # not for a font with a single face
  expect_null(skeleton$missing_faces(list(mainfont = "Some Sans"), dir))
})

test_that("a package path that breaks the YAML fails with an error", {
  skeleton <- local_skeleton()
  real_path <- skeleton$indiedown_path
  # `: ` breaks the YAML too, but is not allowed in folder names on Windows,
  # it is tested below with the path only;
  # the `~` checks that the message shows the path unescaped for LaTeX
  bad <- file.path(withr::local_tempdir(), "lib~ #1")
  dir.create(bad, recursive = TRUE)
  stopifnot(file.copy(
    list.files(real_path(), full.names = TRUE),
    bad,
    recursive = TRUE
  ))
  bad <- normalizePath(bad, "/")
  skeleton$indiedown_path <- function(...) file.path(bad, ...)

  expect_error(
    skeleton$apply_default_yaml(list()),
    paste0('The package path "', bad, '" contains " #", which breaks'),
    fixed = TRUE
  )

  # no error if `default.yaml` does not use the package path
  writeLines("fontsize: 11pt", file.path(bad, "default.yaml"))
  expect_no_error(skeleton$apply_default_yaml(list()))
  expect_error(
    skeleton$check_yaml_path("/a #1/R: x"),
    '"/a #1/R: x" contains " #" and ": ", which breaks',
    fixed = TRUE
  )
  expect_identical(skeleton$check_yaml_path("/lib#1/R:x"), "/lib#1/R:x")
})

test_that("check_tex_path() rejects the characters that break LaTeX", {
  skeleton <- local_skeleton()

  for (path in c(
    "/a,b",
    "/a=b",
    "/a%b",
    "/a#b",
    "/a{b",
    "/a}b",
    "/a[b",
    "/a]b",
    "/a\"b",
    "/a:b",
    "C:/a:b"
  )) {
    expect_error(
      skeleton$check_tex_path(path, "x", "y"),
      "LaTeX does not accept"
    )
  }
  expect_error(
    skeleton$check_tex_path("/a,b{c}", "font folder", "Fix it in a folder"),
    paste0(
      'The font folder "/a,b{c}" contains `,` `{` and `}`, ',
      "which LaTeX does not accept in the path of a font.\n",
      "Fix it in a folder without `,` `=` `%` `#` `{` `}` `[` `]` `\"` or `:`."
    ),
    fixed = TRUE
  )
  expect_identical(
    skeleton$check_tex_path("/a b/~c (d)", "x", "y"),
    "/a b/~c (d)"
  )
  # the `:` of a Windows drive letter
  expect_identical(skeleton$check_tex_path("C:/a/b", "x", "y"), "C:/a/b")
  expect_identical(skeleton$check_tex_path("d:\\a", "x", "y"), "d:\\a")
  expect_error(skeleton$check_tex_path("C:a", "x", "y"), "contains `:`")
})

test_that("a font folder that breaks LaTeX fails with an error", {
  skeleton <- local_skeleton()
  dir <- copy_fonts(
    file.path(withr::local_tempdir(), "OneDrive - Acme, Inc {fonts}"),
    c("regular.ttf", "bold.ttf"),
    c("Some-Regular.ttf", "Some-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)

  expect_error(
    skeleton$apply_default_yaml(list(
      mainfont = "Some-Regular",
      mainfontoptions = "BoldFont=Some-Bold"
    )),
    paste0(
      'The font folder "',
      dir,
      '" contains `,` `{` and `}`, ',
      "which LaTeX does not accept in the path of a font.\n",
      "Copy the font files to another folder, ",
      "set the option `indiedown.font_path` to it,\n",
      "and choose a folder without"
    ),
    fixed = TRUE
  )
})

test_that("a font folder that breaks LaTeX but lacks the font is no error", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  dir <- file.path(withr::local_tempdir(), "OneDrive - Acme, Inc")
  dir.create(dir)
  withr::local_options(indiedown.font_path = dir)

  expect_message(
    args <- skeleton$apply_default_yaml(list(mainfont = "Some-Regular")),
    "was not found"
  )
  expect_true("mainfont:regular.ttf" %in% args)
})

test_that("a package path that breaks LaTeX fails for the fallback font", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  # a copy of the package's files in a folder with `[`, `]` and `%`
  bad <- file.path(withr::local_tempdir(), "R[1]", "50%")
  dir.create(bad, recursive = TRUE)
  stopifnot(file.copy(
    list.files(skeleton$indiedown_path(), full.names = TRUE),
    bad,
    recursive = TRUE
  ))
  bad <- normalizePath(bad, "/")
  skeleton$indiedown_path <- function(...) file.path(bad, ...)

  expect_error(
    skeleton$apply_default_yaml(list()),
    paste0(
      'The package folder "',
      bad,
      '" contains `%` `[` and `]`, ',
      "which LaTeX does not accept in the path of a font.\n",
      "Install the package in a folder without"
    ),
    fixed = TRUE
  )

  # no error if the fallback font is not used
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Some-Regular.ttf", "Some-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)
  expect_silent(
    args <- skeleton$apply_default_yaml(list(
      mainfont = "Some-Regular",
      mainfontoptions = "BoldFont=Some-Bold"
    ))
  )
  expect_true(
    paste0("mainfontoptions:Path=", dir, "/,BoldFont=Some-Bold.ttf") %in% args
  )
})

test_that("fc-list runs at most once", {
  skeleton <- local_skeleton()
  calls <- 0
  skeleton$installed_font_names <- function() {
    calls <<- calls + 1
    character()
  }

  # for the named font, the preferred font, and its missing faces
  expect_message(
    fonts <- skeleton$resolve_fonts(list(mainfont = "Missing Sans"), preferred),
    'Font "Missing Sans"',
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
  expect_identical(calls, 1)

  calls <- 0
  expect_message(
    skeleton$resolve_fonts(list(), preferred),
    'Preferred font "Licensed Sans Medium"',
    fixed = TRUE
  )
  expect_identical(calls, 1)
})

test_that("the message names all folders of the option", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  withr::local_options(indiedown.font_path = c("/no/such/a", "/no/such/b"))

  expect_message(
    fonts <- skeleton$resolve_fonts(list(), preferred),
    paste0(
      'check that one of the folders "/no/such/a", "/no/such/b" ',
      "from the option `indiedown.font_path` holds its font files"
    ),
    fixed = TRUE
  )
  expect_identical(fonts, defaults)
})

test_that("a face named as a font file with a folder asks to check the path", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() "Some Sans"
  named <- list(
    mainfont = "Some Sans",
    mainfontoptions = "BoldFont=fonts/Some-Bold.otf"
  )

  expect_message(
    expect_identical(skeleton$resolve_fonts(named, defaults), defaults),
    paste0(
      'Font "Some Sans" from the `mainfont` field of the document ',
      'was not found, using "regular.ttf" instead.\n',
      "To use it, check the path"
    ),
    fixed = TRUE
  )
})

test_that("the faces next to a font file are looked up by name", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  named <- list(
    mainfont = "Missing Sans",
    mainfontoptions = "BoldFont=missing-bold.otf"
  )

  expect_message(
    expect_identical(skeleton$resolve_fonts(named, defaults), defaults),
    paste0(
      'Font "Missing Sans" from the `mainfont` field of the document ',
      'was not found, using "regular.ttf" instead.\n',
      "To use it, copy its font files"
    ),
    fixed = TRUE
  )

  # an installed family, with a font file that fontspec looks up
  skeleton$installed_font_names <- function() "Some Sans"
  named$mainfont <- "Some Sans"
  expect_silent(
    expect_identical(skeleton$resolve_fonts(named, defaults), named)
  )

  # without fc-list, the lookup cannot tell
  skeleton$installed_font_names <- function() NULL
  named$mainfont <- "Missing Sans"
  expect_silent(
    expect_identical(skeleton$resolve_fonts(named, defaults), named)
  )
})

test_that("on Windows, the message asks to install a named font for all users", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() character()
  skeleton$Sys.info <- function() c(sysname = "Windows")
  withr::local_envvar(LOCALAPPDATA = withr::local_tempdir())

  expect_message(
    skeleton$resolve_fonts(list(mainfont = "Missing Sans"), defaults),
    paste0(
      "To use it, install its font files for all users ",
      "(right-click > Install for all users)"
    ),
    fixed = TRUE
  )
  # the preferred font, which is also found among the fonts of the current user
  expect_message(
    skeleton$resolve_fonts(list(), preferred),
    "To use it, install its font files for the current user",
    fixed = TRUE
  )
})

test_that("on macOS without fc-list, the message asks for fontconfig", {
  skeleton <- local_skeleton()
  skeleton$installed_font_names <- function() NULL
  skeleton$Sys.info <- function() c(sysname = "Darwin")

  expect_message(
    skeleton$resolve_fonts(list(), preferred),
    paste0(
      "To use it, install fontconfig, e.g. with `brew install fontconfig`, ",
      "for `fc-list` to find installed fonts,\n",
      'and open its font files and click "Install" in Font Book'
    ),
    fixed = TRUE
  )
  expect_identical(
    skeleton$font_install_hint("A", sysname = "Darwin"),
    paste0(
      'open its font files and click "Install" in Font Book',
      ',\nor set `options(indiedown.font_path = "<folder>")` to a folder ',
      'with its font files, named like "A.otf" or ".ttf"'
    )
  )
})

test_that("XeLaTeX loads a font from .ttf files by path", {
  skip_on_cran()
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  skip_if(!nzchar(Sys.which("xelatex")), "xelatex not available")
  skip_if_not_installed("pdftools")
  skeleton <- local_skeleton()
  dir <- copy_fonts(
    withr::local_tempdir(),
    c("regular.ttf", "bold.ttf"),
    c("Some-Regular.ttf", "Some-Bold.ttf")
  )
  withr::local_options(indiedown.font_path = dir)

  input <- file.path(withr::local_tempdir(), "doc.Rmd")
  writeLines(
    c(
      "---",
      "title: Doc",
      "mainfont: Some-Regular",
      "mainfontoptions: BoldFont=Some-Bold",
      "---",
      "",
      "Text and **bold text**."
    ),
    input
  )
  utils::capture.output(
    expect_silent(
      output <- rmarkdown::render(
        input,
        skeleton$indiedown_pdf_document_with_asset(latex_engine = "xelatex"),
        envir = new.env(),
        quiet = TRUE
      )
    )
  )

  # the PostScript names of the skeleton's font files
  fonts <- pdftools::pdf_fonts(output)$name
  expect_true(any(grepl("Roboto-Regular$", fonts)))
  expect_true(any(grepl("Roboto-Bold$", fonts)))
})
