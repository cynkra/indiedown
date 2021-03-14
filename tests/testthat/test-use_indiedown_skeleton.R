test_that("use_indiedown_skeleton works", {
  path <- file.path(tempdir(), "mydown")
  use_indiedown_skeleton(path, overwrite = TRUE)
  expect_true(file.exists(file.path(path, "R")))
})
