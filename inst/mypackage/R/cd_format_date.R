#' Corporate Design: Format Date
#'
#' Format date in local language format
#'
#' @param date Current date
#' @param lang Language, either `"de-DE"`, `"de-CH"` or `"en_US"`
#' @return Character string, date in local format
#' @examples
#' cd_format_date("2012-01-01", "de-DE")
#' cd_format_date("2012-01-01", "en-US")
#' @export
cd_format_date <- function(date, lang = default(rmarkdown::metadata$lang, "en-US")) {
  date <- as.Date(date)
  if (lang %in% c("german", "de-DE", "de-CH")) {
    withr::with_locale(c("LC_TIME" = "de_DE"), format(date, "%e. %B %Y"))
  } else {
    withr::with_locale(c("LC_TIME" = "en_US"), format(date, "%B %e, %Y"))
  }
}
