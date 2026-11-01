# expect_pdf_snapshot() validates its arguments

    Code
      expect_pdf_snapshot("", "")
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `name` must be a non-empty string.
    Code
      expect_pdf_snapshot("doc", 1)
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `rmd` must be a character vector.
    Code
      expect_pdf_snapshot("doc", "", 0)
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `...` must be empty.
      x Problematic argument:
      * ..1 = 0
      i Did you forget to name an argument?
    Code
      expect_pdf_snapshot("doc", "", tolerance = 2)
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `tolerance` must be a number between 0 and 1.
    Code
      expect_pdf_snapshot("doc", "", dpi = 0)
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `dpi` must be a positive number.
    Code
      expect_pdf_snapshot("doc", "", system_fonts = NA)
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `system_fonts` must be `TRUE` or `FALSE`.
    Code
      expect_pdf_snapshot("doc", "", fonts = tempfile())
    Condition
      Error in `expect_pdf_snapshot()`:
      ! `fonts` must be the path to a directory or `NULL`.

