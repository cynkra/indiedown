#' Corporate Design: Title Page
#'
#' Example function to generate a title page. The LaTeX lives in a snippet
#' under `inst/indiedown/tex/page_title.tex`; this function reads it with
#' `read_tex()` and interpolates the local variables via [indiedown_glue()].
#'
#' @param title Document title
#' @param subtitle Document subtitle
#' @param date Document creation date
#' @return Object of class `"knit_asis"` (so that knitr will treat it as is). LaTeX code for title page.
#' @export
#' @examples
#' cd_page_title(
#'   title = "My Title",
#'   subtitle = "My Subtitle"
#' )
cd_page_title <- function(
  title = default(rmarkdown::metadata$title, "Title"),
  subtitle = default(rmarkdown::metadata$subtitle, "Subtitle"),
  date = default(rmarkdown::metadata$date, cd_format_date(Sys.Date()))
) {
  logo_path <- indiedown_path_tex("res/logo.png")

  indiedown_glue(read_tex("page_title.tex"))
}
