test_that("the report skeleton renders to PDF", {
  skip_on_cran()
  skip_if_not(
    tinytex::is_tinytex() || nzchar(Sys.which("lualatex")),
    "No TinyTeX / lualatex available"
  )
  skip_if_not_installed("kableExtra")

  skeleton <- system.file(
    "rmarkdown",
    "templates",
    "report",
    "skeleton",
    "skeleton.Rmd",
    package = "mypackage"
  )
  skip_if(skeleton == "", "skeleton.Rmd not found")

  dir <- withr::local_tempdir()
  input <- file.path(dir, "skeleton.Rmd")
  file.copy(skeleton, input)

  output <- rmarkdown::render(
    input,
    output_dir = dir,
    quiet = TRUE,
    envir = new.env()
  )

  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 0)
  expect_identical(tolower(tools::file_ext(output)), "pdf")
})
