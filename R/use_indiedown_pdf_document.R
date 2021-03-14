# create main function <<pkg_name>>::<<pkg_name>>()
use_indiedown_pdf_doucument <- function(path, overwrite = FALSE) {
  pkg_name <- basename(path)

  file_dest <- file.path(path, "R", paste0(pkg_name, ".R"))
  if (!overwrite && file.exists(file_dest)) {
    stop(basename(file_dest), " already exits. ")
  }

  gsub_in_file(
    pattern = "<<pkg_name>>",
    replacement = pkg_name,
    origin = path_indiedown("template/<<pkg_name>>.R"),
    dest = file_dest
  )

  usethis::ui_done(paste0("created ./R/", basename(file_dest)))
}





