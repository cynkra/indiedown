test_that("create_indiedown_package() can be installed", {
  root <- withr::local_tempdir("indiedown")

  mydown_path <- fs::path(root, "mydown")
  suppressMessages(create_indiedown_package(mydown_path))

  withr::local_temp_libpaths()

  # R CMD check is checked on GitHub Actions
  expect_error(callr::rcmd("INSTALL", mydown_path, fail_on_status = TRUE), NA)

  out_dir <- withr::local_tempdir("output")

  rmarkdown::render(
    rprojroot::find_testthat_root_file("mytest.Rmd"),
    output_dir = out_dir
  )

  # FIXME: Convert pdf to png with magick, use expect_snapshot_file()
})
