#' Corporate Design: Format Date
#'
#' Format date in local language format
#'
#' @param date Current date
#' @param lang Language, either `"de-DE"`, `"de-CH"` or `"en_US"`
#' @return Character string, date in local format
#' @examples
#' cd_format_date("2012-01-01", "de-CH")
#' cd_format_date("2012-01-01", "en_US")
#' @export
cd_format_date <- function(date, lang = rmarkdown::metadata$lang) {

  date <- as.Date(date)

  if (is.null(lang)) {
    lang = "en-US"
  }

  if (lang %in% c("ngerman", "de-DE", "de-CH")) {
    withr::with_locale(c("LC_TIME" = find_locale("de_CH")), format(date, "%e. %B %Y"))
  } else {
    withr::with_locale(c("LC_TIME" = find_locale("en_US")), format(date, "%B %e, %Y"))
  }
}

available_locales <- (function() {
  locales <- NULL
  function() {
    if (is.null(locales)) {
      locales <- system2("locale", "-a", stdout = TRUE)
    }
    locales
  }
})()

find_locale <- function(main) {
  locales <- available_locales()
  utf8 <- grep(paste0(main, ".*utf"), locales, ignore.case = TRUE, value = TRUE)
  if (length(utf8) > 0) {
    return(utf8)
  }

  if (main %in% locales) {
    warning("Using locale ", main, ", because UTF-8 variant not found.", call. = FALSE)
    return(main)
  }

  stop("Can't find locale ", main, call. = FALSE)
}
