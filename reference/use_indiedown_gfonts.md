# Download and Use Google Fonts

Download and use Google fonts, using the *gfonts* package.

## Usage

``` r
use_indiedown_gfonts(
  path = ".",
  id = "roboto",
  variants = c("regular", "300italic", "700", "700italic")
)
```

## Arguments

- path:

  Package path

- id:

  Id of the font, correspond to column `id` from
  [`get_all_fonts`](https://dreamrs.github.io/gfonts/reference/get_all_fonts.html).

- variants:

  Variant(s) to download, default is to includes all available ones.

## Value

This function is called for its side effects and returns `NULL`,
invisibly.

## Examples

``` r
# \donttest{
path <- file.path(tempdir(), "mydown")
create_indiedown_package(path, overwrite = TRUE)
#> ✔ indiedown skeleton set up at /tmp/RtmpHV8zJ6/mydown
#> ℹ See `vignette("indiedown")` for how to customize the mydown package
# Use Lora, instead of default Roboto
use_indiedown_gfonts(
  path = path,
  id = "lora",
  variants = c("regular", "italic", "700", "700italic")
)
#> ✔ Added lora fonts
# }
```
