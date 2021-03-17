# create_indiedown_package() works

    Code
      create_indiedown_package("mydown")
    Message <cliMessage>
      v indiedown skeleton set up at mydown
      i See `vignette("indiedown")` for how to customize the mydown package
    Code
      withr::with_collate("C", fs::dir_tree("mydown"))
    Output
      mydown
      +-- DESCRIPTION
      +-- LICENSE
      +-- NAMESPACE
      +-- R
      |   +-- cd_format_date.R
      |   +-- cd_knit_chunk_opts.R
      |   +-- cd_page_title.R
      |   +-- indiedown.R
      |   \-- indiedown_pdf_document.R
      +-- inst
      |   +-- indiedown
      |   |   +-- default.yaml
      |   |   +-- fonts
      |   |   |   +-- bold.ttf
      |   |   |   +-- bolditalic.ttf
      |   |   |   +-- italic.ttf
      |   |   |   \-- regular.ttf
      |   |   +-- pre_processor.R
      |   |   +-- preamble.tex
      |   |   \-- res
      |   |       \-- logo.png
      |   \-- rmarkdown
      |       \-- templates
      |           \-- report
      |               +-- skeleton
      |               |   \-- skeleton.Rmd
      |               \-- template.yaml
      \-- man
          +-- cd_format_date.Rd
          +-- cd_knit_chunk_opts.Rd
          +-- cd_page_title.Rd
          +-- default.Rd
          +-- indiedown_glue.Rd
          +-- indiedown_path.Rd
          +-- indiedown_pdf_document_with_asset.Rd
          \-- mydown.Rd
    Code
      unlink("mydown/R/cd_page_title.R")
      create_indiedown_package("mydown", overwrite = TRUE)
    Message <cliMessage>
      v indiedown skeleton set up at mydown
      i See `vignette("indiedown")` for how to customize the mydown package

