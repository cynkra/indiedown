test_that("dr_down speaks about System Information", {
  skip_on_cran()
  expect_message(indiedown::dr_down(), "System Information")
})
