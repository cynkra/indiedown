test_that("create_indiedown_package() works", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  create_indiedown_package("mydown")
  expect_true(dir.exists("mydown/R"))
  expect_true(file.exists("mydown/R/cd_page_title.R"))

  expect_error(create_indiedown_package("mydown"))

  unlink("mydown/R/cd_page_title.R")
  expect_false(file.exists("mydown/R/cd_page_title.R"))
  expect_error(create_indiedown_package("mydown", overwrite = TRUE), NA)
  expect_true(file.exists("mydown/R/cd_page_title.R"))
})
