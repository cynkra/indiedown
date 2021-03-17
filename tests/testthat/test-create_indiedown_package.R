test_that("create_indiedown_package() works", {
  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  expect_snapshot({
    create_indiedown_package("mydown")
    withr::with_collate("C", sort(fs::dir_ls("mydown", recurse = TRUE)))

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
  withr::defer(fs::file_delete("mydown2"))
  withr::defer(fs::dir_delete("mydown"))

  expect_error(create_indiedown_package("mydown"), "overwrite")
  expect_error(create_indiedown_package("mydown2"), "file")
})

test_that("create_indiedown_package() fails for links with meaningful error message", {
  skip("Ignore for now")

  root <- tempfile("indiedown")
  dir.create(root)

  withr::local_dir(root)

  skip_on_os("windows")

  fs::dir_create("mydown")
  fs::link_create("mydown", "mydown3")
  fs::link_create("mydown-bogus", "mydown4")
  withr::defer(fs::link_delete("mydown-bogus"))
  withr::defer(fs::link_delete("mydown3"))
  withr::defer(fs::dir_delete("mydown"))

  expect_error(create_indiedown_package("mydown3"), "overwrite")
  expect_error(create_indiedown_package("mydown4"), "link")
})
