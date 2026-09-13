#' Spell-check R Markdown files
#'
#' `spell_check_rmd()` spell-checks all `.Rmd` files in a directory, ignoring
#' the words listed in a `WORDLIST` file (if present).
#' `update_wordlist_rmd()` adds the currently flagged words to `WORDLIST`.
#'
#' @param path Directory containing `.Rmd` files (and, optionally, a
#'   `WORDLIST` file).
#'
#' @return `spell_check_rmd()` returns a data frame of misspelled words, as
#'   produced by [spelling::spell_check_files()]. `update_wordlist_rmd()` is
#'   called for its side effect and returns `NULL`, invisibly.
#'
#' @export
spell_check_rmd <- function(path = ".") {
  files <- rmd_files(path = path)
  wordlist <- read_wordlist(path = path)
  spelling::spell_check_files(files, ignore = wordlist, lang = "en_US")
}

#' @export
#' @rdname spell_check_rmd
update_wordlist_rmd <- function(path = ".") {
  errors <- spell_check_rmd(path = path)$word
  wordlist <- read_wordlist(path = path)
  cat("Are you sure you want to update the wordlist?")
  if (utils::menu(c("Yes", "No")) != 1) {
    return(invisible())
  }
  xfun::write_utf8(
    sort(unique(c(errors, wordlist))),
    con = file.path(path, "WORDLIST")
  )
  invisible()
}

read_wordlist <- function(path = ".") {
  # project wordlist
  file.wordlist <- list.files(path, pattern = "^WORDLIST$", full.names = TRUE)
  if (length(file.wordlist) > 0) {
    wordlist <- xfun::read_utf8(file.wordlist)
  } else {
    wordlist <- character(0)
  }
  wordlist
}

rmd_files <- function(path = ".") {
  files <- list.files(path, pattern = "\\.[Rr]md$", full.names = TRUE)
  if (length(files) == 0) {
    stop("No .Rmd files found.")
  }
  files
}
