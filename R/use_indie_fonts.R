# regular, italic, bold, italic
# use_indie_fonts(id = "lora", variants = c("regular", "italic", "700", "700italic"))
#' @export
use_indie_fonts <- function(path = ".",
  id = "roboto",
  variants = c("regular", "300italic", "700", "700italic")) {

  path_fonts <- fs::path_norm(fs::path(path, "inst", "indiedown", "fonts"))

  fs::dir_create(path_fonts)

  # FIXME can we avoid downloading the non ttfs?
  gfonts::download_font(id = id, output_dir = path_fonts, variants = variants)
  fs::file_delete(fs::path(path_fonts, grep("\\.ttf", list.files(path_fonts), value = TRUE, invert = TRUE)))

  font_path <- function(var) {
    grep(paste0("-", var, ".ttf$"), list.files(path_fonts), value = TRUE)
  }


  file_variants <- vapply(variants, font_path, "")

  default_names <- c("regular", "italic", "bold", "bolditalic")

  fs::file_move(
    fs::path(path_fonts, file_variants),
    fs::path(path_fonts, paste0(default_names, ".ttf"))
  )

  usethis::ui_done("fonts installed")

}



