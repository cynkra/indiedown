test_that("create_indiedown_package() passes R CMD check", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  create_indiedown_package("mydown")

  expect_error(rcmdcheck::rcmdcheck("mydown", error_on = "error"), NA)
})
