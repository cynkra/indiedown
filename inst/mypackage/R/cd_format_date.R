#' cd_format_date
#'
#' FIXME
#'
#' @param date ...
#' @param lang ...
#'
#' @export
cd_format_date <- function(date, lang = default(rmarkdown::metadata$lang, "de_CH")) {
  if (lang %in% c("german", "de-DE", "de-CH")) {
    withr::with_locale(c("LC_TIME" = "de_CH"), format(date, "%e. %B %Y"))
  } else {
    withr::with_locale(c("LC_TIME" = "en_US"), format(date, "%B %e, %Y"))
  }
}
