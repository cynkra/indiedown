#' Corporate Design Element for Title Page
#'
#' Example function to generate a title page
#'
#' @param title Document title.
#' @param subtitle Document subtitle.
#' @param date Document creation date.
#' @export
#'
cd_page_title <- function(title = default(rmarkdown::metadata$title, "Title"),
                          subtitle = default(rmarkdown::metadata$subtitle, "Subtitle"),
                          date = default(rmarkdown::metadata$date, cd_format_date(Sys.Date()))
                          ) {

  logo_path <- indiedown_path_tex("res/logo.png")

  indiedown_glue(
    # R >=4, raw strings allow to write LaTeX without escaping \ etc
    r"(
\vspace*{-1.8cm}
\begin{center}
  \vspace*{-3.65cm}\makebox[\textwidth]{\includegraphics[width=\paperwidth]{<<logo_path>>}}
\end{center}

\noindent \Huge <<title>>
\noindent \huge <<subtitle>>

\normalsize

\noindent <<date>>

\clearpage
    )"
  )
}

