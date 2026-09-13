#' Corporate Design: Format Date
#'
#' Format date in local language format.
#'
#' @param date Current date.
#' @param lang Language, e.g. `"de-DE"`, `"de-CH"` or `"en-US"`. Defaults to
#'   the document's `lang` metadata field, or `"en-US"`.
#' @return Character string, date in local format.
#' @examples
#' cd_format_date("2012-01-01", "de-DE")
#' cd_format_date("2012-01-01", "en-US")
#' @export
cd_format_date <- function(
  date,
  lang = default(rmarkdown::metadata$lang, "en-US")
) {
  date <- as.Date(date)
  if (lang %in% c("german", "ngerman", "de-DE", "de-CH")) {
    withr::with_locale(
      c("LC_TIME" = find_locale("de_DE")),
      format(date, "%e. %B %Y")
    )
  } else {
    withr::with_locale(
      c("LC_TIME" = find_locale("en_US")),
      format(date, "%B %e, %Y")
    )
  }
}

# Cache the list of installed locales; `locale -a` is slow to call repeatedly.
available_locales <- (function() {
  locales <- NULL
  function() {
    if (is.null(locales)) {
      locales <<- system2("locale", "-a", stdout = TRUE)
    }
    locales
  }
})()

# Resolve a locale name to an installed variant, preferring UTF-8. Errors with
# a helpful message when the locale is missing, instead of silently
# misformatting the date.
find_locale <- function(main) {
  locales <- available_locales()
  utf8 <- grep(paste0(main, ".*utf"), locales, ignore.case = TRUE, value = TRUE)
  if (length(utf8) > 0) {
    return(utf8[[1]])
  }

  if (main %in% locales) {
    warning(
      "Using locale ",
      main,
      ", because UTF-8 variant not found.",
      call. = FALSE
    )
    return(main)
  }

  stop("Can't find locale ", main, call. = FALSE)
}
