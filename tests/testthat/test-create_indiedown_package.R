test_that("create_indiedown_package() works", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  expect_snapshot({
    create_indiedown_package("mydown")
    withr::with_collate("C", fs::dir_tree("mydown"))

    unlink("mydown/R/cd_page_title.R")
    create_indiedown_package("mydown", overwrite = TRUE)
  })

  expect_true(file.exists("mydown/R/cd_page_title.R"))
})

test_that("create_indiedown_package() fails with meaningful error message", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  fs::dir_create("mydown")
  fs::file_create("mydown2")
  fs::link_create("mydown", "mydown3")
  fs::link_create("mydown-bogus", "mydown4")

  expect_error(create_indiedown_package("mydown"), "overwrite")
  expect_error(create_indiedown_package("mydown2"), "file")
  expect_error(create_indiedown_package("mydown3"), "overwrite")
  expect_error(create_indiedown_package("mydown4"), "link")

  fs::link_delete("mydown3")
  fs::file_delete("mydown2")
  fs::dir_delete("mydown")
})
