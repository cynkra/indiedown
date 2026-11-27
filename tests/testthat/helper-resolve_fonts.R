# Helpers and fixtures for test-resolve_fonts.R

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

# The fallback font of the formats in the tests
defaults <- list(
  mainfont = "regular.ttf",
  mainfontoptions = c("Path=/fonts/", "BoldFont=bold.ttf")
)

# A format with a preferred font
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

# A format that prefers the font of the skeleton, under the name of its font files
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
