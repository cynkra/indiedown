skip_on_cran()
test_that("dr_down speaks about System Information", {
  expect_message(indiedown::dr_down(), "System Information")
})
