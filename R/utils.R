gsub_in_file <- function(pattern, replacement, file, fixed = TRUE) {

  con <- file(file)
  on.exit(close(con))
  txt <- readLines(con = con)
  txt <- gsub(pattern, replacement, txt, fixed = fixed)
  writeLines(txt, con = con)

}
