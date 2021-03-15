test_that("create_indiedown_package() can be installed", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  suppressMessages(create_indiedown_package("mydown"))

  withr::local_temp_libpaths()

  # R CMD check is checked on GitHub Actions
  expect_error(callr::rcmd("INSTALL", "mydown", fail_on_status = TRUE), NA)
})
