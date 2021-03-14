#' Download and Use Google Fonts
#'
#' Download and use Google fonts, using the *gfonts* package.
#'
#' @inheritParams use_indiedown_skeleton
#' @inheritParams gfonts::download_font
#' @examples
#' \donttest{
#' path <- file.path(tempdir(), "mydown")
#' usethis::create_package(path, open = FALSE)
#' # add indiedown assets
#' use_indiedown_skeleton(path, overwrite = TRUE)
#' # Use Lora, instead of default Roboto
#' use_indiedown_gfonts(
#'   path = path,
#'   id = "lora",
#'   variants = c("regular", "italic", "700", "700italic")
#' )
#' }
#' @export
use_indiedown_gfonts <- function(path = ".",
                                 id = "roboto",
                                 variants = c("regular", "300italic", "700", "700italic")
                                 ) {

  path_fonts <- fs::path_norm(fs::path(path, "inst", "indiedown", "fonts"))

  fs::dir_create(path_fonts)

  # FIXME can we avoid downloading the non ttfs?
  gfonts::download_font(id = id, output_dir = path_fonts, variants = variants)
  file.remove(file.path(path_fonts, grep("\\.ttf", list.files(path_fonts), value = TRUE, invert = TRUE)))

  font_path <- function(var) {
    grep(paste0("-", var, ".ttf$"), list.files(path_fonts), value = TRUE)
  }

  file_variants <- vapply(variants, font_path, "")

  default_names <- c("regular", "italic", "bold", "bolditalic")

  fs::file_move(
    file.path(path_fonts, file_variants),
    file.path(path_fonts, paste0(default_names, ".ttf"))
  )

  usethis::ui_done("add fonts")

}



