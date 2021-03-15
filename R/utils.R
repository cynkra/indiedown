gsub_in_file <- function(pattern, replacement, file, fixed = TRUE) {
  if (length(file) > 1) {
    lapply(file, function(e) gsub_in_file(pattern, replacement, file = e, fixed = fixed))
    return(invisible(TRUE))
  }

  con <- file(file)
  on.exit(close(con))
  txt <- readLines(con = con)
  txt <- gsub(pattern, replacement, txt, fixed = fixed)
  writeLines(txt, con = con)

  invisible(TRUE)
}
