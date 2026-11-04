#' Download and Use Google Fonts
#'
#' Download a font from [Google Fonts](https://fonts.google.com)
#' with the *gfonts* package
#' and install it as the main font of an indiedown template package.
#' Documents rendered with the package's output format then use that font.
#' There is nothing to change in the `.Rmd`.
#'
#' @section Where the font files end up:
#' The function works on the template package at `path`,
#' as created by [create_indiedown_package()].
#' It writes to the folder `inst/indiedown/fonts/` of that package,
#' creating it if necessary, and
#'
#' - keeps only `.ttf` files:
#'   everything else in that folder is deleted;
#' - renames the downloaded files to `regular.ttf`, `italic.ttf`,
#'   `bold.ttf` and `bolditalic.ttf`,
#'   overwriting existing files with these names.
#'
#' The new names are assigned by position, not by inspecting the files:
#' the first entry of `variants` becomes `regular.ttf`,
#' the second `italic.ttf`, and so on.
#' `variants` must therefore have exactly four entries,
#' in the order regular, italic, bold, bold italic.
#' The default uses the light italic (`"300italic"`) of Roboto
#' for the italic slot.
#'
#' @section How the template picks up the fonts:
#' Because the file names are always the same,
#' the template does not need to know which font was downloaded.
#' The skeleton's `inst/indiedown/default.yaml` refers to the four files
#' by name:
#'
#' ```yaml
#' mainfont: regular.ttf
#' mainfontoptions:
#' - Path=<<indiedown_path>>/fonts/
#' - BoldFont=bold.ttf
#' - ItalicFont=italic.ttf
#' - BoldItalicFont=bolditalic.ttf
#' - Scale=0.92
#' ```
#'
#' When a document is rendered with the output format of the template package,
#' for example with this YAML header in the `.Rmd` (where `mydown` is the name
#' of your package):
#'
#' ```yaml
#' output: mydown::mydown
#' ```
#'
#' the following happens:
#'
#' 1. The `pre_processor` of the output format
#'    (`inst/indiedown/pre_processor.R`) calls `apply_default_yaml()`,
#'    which reads `default.yaml`,
#'    and then replaces `<<indiedown_path>>` by the location of `inst/indiedown`
#'    in the *installed* template package.
#'    This happens after the YAML is read,
#'    so that the characters of the location do not change how it is read.
#'    In the value of `Path=` the location is written so that LaTeX reads it as is,
#'    and elsewhere `indiedown_path_tex()` of the template package is used.
#'    Options may also be given as one string joined by commas,
#'    which is split at the commas outside braces.
#'    The settings are handed to pandoc as variables,
#'    except for those that are set in the YAML header of the document itself.
#'    The main font is chosen separately by `resolve_fonts()`:
#'    `mainfont` and `mainfontoptions` from `default.yaml` are used
#'    unless the document or the format names another font that is installed,
#'    see "Using a different font" below.
#' 2. The LaTeX template of pandoc turns `mainfont` and `mainfontoptions`
#'    into a call to the fontspec package, which looks like this
#'    (the path is shortened and the line is wrapped here):
#'
#'    ```latex
#'    \setmainfont[Path=.../mydown/indiedown/fonts/,BoldFont=bold.ttf,
#'      ItalicFont=italic.ttf,BoldItalicFont=bolditalic.ttf,Scale=0.92]{regular.ttf}
#'    ```
#'
#' 3. fontspec needs LuaLaTeX or XeLaTeX.
#'    The skeleton's output format uses `latex_engine = "lualatex"`.
#'
#' The font is used for all body text:
#' regular text, `*emphasis*` (italic), `**strong**` (bold),
#' and both combined (bold italic).
#' The skeleton does not set `sansfont` or `monofont`,
#' so code and other text in a sans or monospace family
#' are not affected.
#'
#' The font files are read from the installed template package.
#' After running `use_indiedown_gfonts()`,
#' re-install the package (e.g., with `devtools::install()`)
#' before rendering a document.
#'
#' @section Using a different font:
#' - **Another Google font:**
#'   call `use_indiedown_gfonts()` again with another `id` and `variants`.
#'   No other file needs to change, because the file names stay the same.
#'   The `Scale=0.92` entry in `default.yaml` applies to all fonts;
#'   adjust it if the new font looks too large or too small.
#' - **A font from another source:**
#'   copy four font files to `inst/indiedown/fonts/`
#'   and either name them `regular.ttf`, `italic.ttf`, `bold.ttf`
#'   and `bolditalic.ttf`,
#'   or adapt `mainfont` and the `BoldFont`, `ItalicFont` and
#'   `BoldItalicFont` entries of `mainfontoptions` in `default.yaml`
#'   to the file names.
#' - **A single document:**
#'   set `mainfont` in the YAML header of the `.Rmd`
#'   to the name of an installed font or to the path of a font file.
#'   The `mainfontoptions` of `default.yaml` refer to the downloaded files
#'   and are not applied to that font;
#'   `mainfontoptions` in the YAML header are.
#'   If the font is not found,
#'   the template's font is used instead, with a message.
#'   The option `<package>.mainfont`, e.g., `mydown.mainfont`,
#'   names a font for all documents of a user.
#' - **A font that cannot be shipped:**
#'   a licensed font, for example, can be named in `preferredmainfont`
#'   (and its other faces in `preferredmainfontoptions`) in `default.yaml`.
#'   Name all four faces, with `BoldFont=`, `ItalicFont=` and `BoldItalicFont=`.
#'   It is used where it is found,
#'   and the downloaded font everywhere else.
#'   Its fonts are found by PostScript name or by file name
#'   and loaded from their files,
#'   so it is enough to install the font for the current user.
#'   Users who cannot install fonts can copy the font files to a folder
#'   and name it in the option `<package>.font_path`, e.g., `mydown.font_path`.
#'
#' See `vignette("walkthrough")` for a step-by-step example
#' and `vignette("customize")` for the other customization points.
#'
#' @param path Path to the template package,
#'   as created by [create_indiedown_package()].
#'   The fonts are written to `inst/indiedown/fonts/` below this path.
#' @param variants Variants to download, as named by Google Fonts
#'   (e.g., `"regular"`, `"italic"`, `"700"`, `"700italic"`).
#'   Exactly four, in the order regular, italic, bold, bold italic.
#'   See the section "Where the font files end up".
#' @inheritParams gfonts::download_font
#' @return This function is called for its side effects
#'   and returns `NULL`, invisibly.
#' @seealso
#' - [create_indiedown_package()] to set up the template package.
#' - [gfonts::get_all_fonts()] for the available font IDs,
#'   and [gfonts::download_font()] for the underlying download.
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
#' # The files always have the same names, whatever the font
#' list.files(file.path(path, "inst", "indiedown", "fonts"))
#' }
use_indiedown_gfonts <- function(
  path = ".",
  id = "roboto",
  variants = c("regular", "300italic", "700", "700italic")
) {
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
