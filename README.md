# indiedown: Individual RMarkdown PDF Templates

indiedown allows you to generate a customized RMarkdown PDF template in a few basic steps.

Start by installing indiedown:

```r
# install.packages("remotes")
remotes::install_github("cynkra/indiedown")
```

To create your own, customized RMarkdown template, start by creating an indiedown template package, called `mydown`:

```r
indiedown::create_indiedown_package("mydown")
```

This creates a package skeleton at `./mydown`. You can build build *mydown*, using 'build and reload' in the RStudio or via the command line, as folows:

```r
devtools::install("mydown")
```

With *mydown* built and installed, our new template is available in RStudio (after a restart).

See `vignette("intro")` for a more detailed tutorial.

See `vignette("customize")` for how to customize your template.

