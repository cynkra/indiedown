test_that("create_indiedown_package() can be installed", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  create_indiedown_package("mydown")

  withr::local_temp_libpaths()

  expect_error(callr::rcmd("INSTALL", "mydown", fail_on_status = TRUE), NA)
})
