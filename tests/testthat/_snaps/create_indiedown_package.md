# create_indiedown_package() works

    Code
      create_indiedown_package("mydown")
    Message <cliMessage>
      v indiedown skeleton set up at mydown
      i See `vignette("indiedown")` for how to customize the mydown package
    Code
      withr::with_collate("C", sort(fs::dir_ls("mydown", recurse = TRUE)))
    Output
      mydown/DESCRIPTION
      mydown/LICENSE
      mydown/NAMESPACE
      mydown/R
      mydown/R/cd_format_date.R
      mydown/R/cd_knit_chunk_opts.R
      mydown/R/cd_page_title.R
      mydown/R/indiedown.R
      mydown/R/indiedown_pdf_document.R
      mydown/inst
      mydown/inst/indiedown
      mydown/inst/indiedown/default.yaml
      mydown/inst/indiedown/fonts
      mydown/inst/indiedown/fonts/bold.ttf
      mydown/inst/indiedown/fonts/bolditalic.ttf
      mydown/inst/indiedown/fonts/italic.ttf
      mydown/inst/indiedown/fonts/regular.ttf
      mydown/inst/indiedown/pre_processor.R
      mydown/inst/indiedown/preamble.tex
      mydown/inst/indiedown/res
      mydown/inst/indiedown/res/logo.png
      mydown/inst/rmarkdown
      mydown/inst/rmarkdown/templates
      mydown/inst/rmarkdown/templates/report
      mydown/inst/rmarkdown/templates/report/skeleton
      mydown/inst/rmarkdown/templates/report/skeleton/skeleton.Rmd
      mydown/inst/rmarkdown/templates/report/template.yaml
      mydown/man
      mydown/man/cd_format_date.Rd
      mydown/man/cd_knit_chunk_opts.Rd
      mydown/man/cd_page_title.Rd
      mydown/man/default.Rd
      mydown/man/indiedown_glue.Rd
      mydown/man/indiedown_path.Rd
      mydown/man/mydown.Rd
    Code
      unlink("mydown/R/cd_page_title.R")
      create_indiedown_package("mydown", overwrite = TRUE)
    Message <cliMessage>
      v indiedown skeleton set up at mydown
      i See `vignette("indiedown")` for how to customize the mydown package

