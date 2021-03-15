test_that("create_indiedown_package() works", {
  path <- file.path(tempdir(), "mydown")
  create_indiedown_package(path, overwrite = TRUE)
  expect_true(file.exists(file.path(path, "R")))
})
