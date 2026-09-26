# indiedown

Individual R Markdown PDF Templates.

indiedown allows you to generate a customized R Markdown PDF template in
a few basic steps.

Start by installing indiedown:

``` r

install.packages("indiedown")
```

You can also install the development version from GitHub:

``` r

# install.packages("devtools")
devtools::install_github("cynkra/indiedown")
```

To create your own customized R Markdown template, start by creating an
indiedown template package, called `mydown` in this example. Navigate to
the directory where you want to create the package, then:

``` r

indiedown::create_indiedown_package("mydown")
```

This creates a package skeleton in the new `mydown` directory in the
current working directory. You can build *mydown*, using “Build and
Reload” in the RStudio or via the command line, as follows:

``` r

devtools::install("mydown")
```

With *mydown* built and installed, our new template is available in
RStudio (after a restart).

- Read more at
  [`vignette("indiedown")`](https://indiedown.cynkra.com/articles/indiedown.md).
- See
  [`vignette("walkthrough")`](https://indiedown.cynkra.com/articles/walkthrough.md)
  for a step by step guide to customization.
- See
  [`vignette("customize")`](https://indiedown.cynkra.com/articles/customize.md)
  for advanced customization.
