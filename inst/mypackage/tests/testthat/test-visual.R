# Pixel-exact visual snapshots of the rendered PDF. See helper-visual.R for
# the mechanism and how to refresh the reference images. All fixtures use a
# fixed date and static content so the output is deterministic.

test_that("the report skeleton looks right", {
  expect_pdf_snapshot(
    "skeleton",
    c(
      "---",
      "title           : \"Report-Title\"",
      "subtitle        : \"Subtitle\"",
      "author          : [\"My-Name\", \"Our-Team\"]",
      "date            : \"January 1, 2026\"",
      "documentclass   : article",
      "fontsize        : 11pt",
      "numbersections  : true",
      "output          : mypackage::mypackage",
      "---",
      "",
      "```{r, include = FALSE}",
      "library(knitr)",
      "library(mypackage)",
      "cd_knit_chunk_opts()",
      "```",
      "",
      "```{r}",
      "cd_page_title()",
      "```",
      "",
      "# Customized R Markdown Template",
      "",
      "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do",
      "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim",
      "ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut",
      "aliquip ex ea commodo consequat."
    )
  )
})

test_that("typography and tables look right (details)", {
  expect_pdf_snapshot(
    "details",
    c(
      "---",
      "title           : \"Details\"",
      "date            : \"January 1, 2026\"",
      "twocolumn       : true",
      "output          : mypackage::mypackage",
      "---",
      "",
      "```{r, include = FALSE}",
      "library(knitr)",
      "library(mypackage)",
      "cd_knit_chunk_opts()",
      "```",
      "",
      "# Typography",
      "",
      "Regular, **bold**, *italic* and `monospace` text, plus inline math",
      "$a^2 + b^2 = c^2$.",
      "",
      "## A table",
      "",
      "```{r, echo = FALSE}",
      "knitr::kable(head(mtcars[, 1:3], 4), format = \"latex\", booktabs = TRUE)",
      "```"
    )
  )
})
