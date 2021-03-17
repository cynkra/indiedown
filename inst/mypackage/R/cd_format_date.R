#' Corporate Design: Format Date
#'
#' Format date in local language format
#'
#' @param date Current date
#' @param lang Language, either `"de-DE"`, `"de-CH"` or `"en_US"`
#'
#' @export
cd_format_date <- function(date, lang = default(rmarkdown::metadata$lang, "de_CH")) {
  if (lang %in% c("german", "de-DE", "de-CH")) {
    withr::with_locale(c("LC_TIME" = "de_CH"), format(date, "%e. %B %Y"))
  } else {
    withr::with_locale(c("LC_TIME" = "en_US"), format(date, "%B %e, %Y"))
  }
}
