# Skeleton for a Customized R Markdown Template

Set up the packages structure for an indiedown-based customized R
Markdown template. See
[`vignette("indiedown")`](https://indiedown.cynkra.com/articles/indiedown.md)
for a more detailed usage example.

## Usage

``` r
create_indiedown_package(path, overwrite = FALSE)
```

## Arguments

- path:

  Package path

- overwrite:

  Should existing assets be overwritten?

## Value

This function is called for its side effects and returns `NULL`,
invisibly.

## Examples

``` r
path <- file.path(tempdir(), "mydown")

# set up empty R Package 'mydown'
create_indiedown_package(path, overwrite = TRUE)
#> ✔ indiedown skeleton set up at /tmp/RtmpIbooYs/mydown
#> ℹ See `vignette("indiedown")` for how to customize the mydown package
```
