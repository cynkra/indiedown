#' Corporate Design: Title Page
#'
#' Example function to generate a title page
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
cd_page_title <- function(title = default(rmarkdown::metadata$title, "Title"),
                          subtitle = default(rmarkdown::metadata$subtitle, "Subtitle"),
                          date = default(rmarkdown::metadata$date, cd_format_date(Sys.Date()))) {

  logo_path <- indiedown_path_tex("res/logo.png")

  indiedown_glue(
    # R >=4, raw strings allow to write LaTeX without escaping \ etc
    r"(
\vspace*{-1cm}
\begin{center}
  \makebox[\textwidth]{\includegraphics[width=0.1\paperwidth]{<<logo_path>>}}
\end{center}


\vspace*{2cm}

\noindent \Huge <<title>>

\noindent \huge <<subtitle>>

\vspace*{2cm}


\normalsize

\noindent <<date>>

\clearpage
    )"
  )
}
