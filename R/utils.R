gsub_in_file <- function(pattern, replacement, origin, dest = origin, fixed = TRUE) {
  txt <- readLines(con = file(origin))
  txt <- gsub(pattern, replacement, txt, fixed = fixed)
  writeLines(txt, con = file(dest))
}
