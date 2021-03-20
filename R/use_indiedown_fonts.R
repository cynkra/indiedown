#' Download and Use Google Fonts
#'
#' Download and use Google fonts, using the *gfonts* package.
#'
#' @inheritParams create_indiedown_package
#' @inheritParams gfonts::download_font
#' @return This function is called for its side effects and returns `NULL`, invisibly.
#' @export
#' @examples
#' \donttest{
#' path <- file.path(tempdir(), "mydown")
#' create_indiedown_package(path, overwrite = TRUE)
#' # Use Lora, instead of default Roboto
#' use_indiedown_gfonts(
#'   path = path,
#'   id = "lora",
#'   variants = c("regular", "italic", "700", "700italic")
#' )
#' }
use_indiedown_gfonts <- function(path = ".",
                                 id = "roboto",
                                 variants = c("regular", "300italic", "700", "700italic")) {
  path_fonts <- fs::path_norm(fs::path(path, "inst", "indiedown", "fonts"))

  fs::dir_create(path_fonts)

  # FIXME can we avoid downloading the non ttfs?
  gfonts::download_font(id = id, output_dir = path_fonts, variants = variants)
  file.remove(file.path(
    path_fonts,
    grep("\\.ttf", list.files(path_fonts), value = TRUE, invert = TRUE)
  ))

  font_path <- function(var) {
    grep(paste0("-", var, ".ttf$"), list.files(path_fonts), value = TRUE)
  }

  file_variants <- vapply(variants, font_path, "")

  default_names <- c("regular", "italic", "bold", "bolditalic")

  fs::file_move(
    file.path(path_fonts, file_variants),
    file.path(path_fonts, paste0(default_names, ".ttf"))
  )

  cli_alert_success("Added {id} fonts")

  invisible()
}
