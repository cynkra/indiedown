gsub_in_file <- function(pattern, replacement, file, fixed = TRUE) {
  txt <- readLines(con = file(file))
  txt <- gsub(pattern, replacement, txt, fixed = fixed)
  writeLines(txt, con = file(file))
}
