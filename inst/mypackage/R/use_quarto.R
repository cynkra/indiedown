# indiedown: do not customize this file!
# It mirrors the use_cynkradown_quarto() helper from cynkradown.

#' Install the mypackage Quarto extension into a project
#'
#' Copies the bundled Quarto extension into
#' `_extensions/mypackage/mypackage/` inside `path`, alongside the fonts and
#' image resources used by the extension's LaTeX preamble. After running
#' this, a `.qmd` document with `format: mypackage-pdf` in the YAML header
#' can be rendered with `quarto render`.
#'
#' @param path Directory to install the extension into. Defaults to the
#'   current working directory.
#' @param overwrite If `TRUE`, replace any existing
#'   `_extensions/mypackage/mypackage/` directory at `path`.
#' @param examples If `TRUE`, also copy the bundled example `.qmd`
#'   documents next to the extension.
#'
#' @return The path to the installed extension, invisibly.
#' @export
use_mypackage_quarto <- function(path = ".",
                                 overwrite = FALSE,
                                 examples = FALSE) {
  pkg <- "mypackage"

  src_ext <- system.file(
    "quarto", "_extensions", pkg, pkg,
    package = pkg
  )
  if (!nzchar(src_ext)) {
    stop(
      "Quarto extension assets not found in the installed ", pkg, " package.",
      call. = FALSE
    )
  }

  dest_root <- normalizePath(path, mustWork = TRUE)
  dest_ext <- file.path(dest_root, "_extensions", pkg, pkg)

  if (file.exists(dest_ext)) {
    if (!overwrite) {
      stop(
        "'", dest_ext, "' already exists. Use `overwrite = TRUE` to replace.",
        call. = FALSE
      )
    }
    unlink(dest_ext, recursive = TRUE)
  }

  dir.create(dirname(dest_ext), recursive = TRUE, showWarnings = FALSE)
  file.copy(src_ext, dirname(dest_ext), recursive = TRUE)

  # Pull fonts and image resources from the rmarkdown asset directory so the
  # two surfaces share a single source of truth.
  for (sub in c("fonts", "res")) {
    src <- system.file("indiedown", sub, package = pkg)
    if (nzchar(src)) {
      file.copy(src, dest_ext, recursive = TRUE)
    }
  }

  if (examples) {
    src_examples <- system.file("quarto", "examples", package = pkg)
    if (nzchar(src_examples)) {
      for (f in list.files(src_examples, full.names = TRUE)) {
        file.copy(f, dest_root, overwrite = overwrite)
      }
    }
  }

  message(
    "Installed ", pkg, " Quarto extension at ",
    file.path("_extensions", pkg, pkg),
    ".\nUse 'format: ", pkg, "-pdf' in the YAML header of a .qmd document."
  )

  invisible(dest_ext)
}
