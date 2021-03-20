<!-- README.md is generated from README.Rmd on GitHub Actions: do not edit by hand -->

# indiedown

Individual R Markdown PDF Templates.

<!-- badges: start -->

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) [![R build status](https://github.com/cynkra/indiedown/workflows/rcc/badge.svg)](https://github.com/cynkra/indiedown/actions) [![Coverage status](https://codecov.io/gh/cynkra/indiedown/branch/main/graph/badge.svg)](https://codecov.io/github/cynkra/indiedown?branch=master) ![CRAN status](https://www.r-pkg.org/badges/version/indiedown)

<!-- badges: end -->

indiedown allows you to generate a customized R Markdown PDF template in a few basic steps.

Start by installing indiedown:

<pre class='chroma'>
<span class='nf'><a href='https://rdrr.io/r/utils/install.packages.html'>install.packages</a></span><span class='o'>(</span><span class='s'>"indiedown"</span><span class='o'>)</span></pre>

You can also install the development version from GitHub:

<pre class='chroma'>
<span class='c'># install.packages("devtools")</span>
<span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://devtools.r-lib.org//reference/remote-reexports.html'>install_github</a></span><span class='o'>(</span><span class='s'>"cynkra/indiedown"</span><span class='o'>)</span></pre>

To create your own customized R Markdown template, start by creating an indiedown template package, called `mydown` in this example. Navigate to the directory where you want to create the package, then:

<pre class='chroma'>
<span class='nf'>indiedown</span><span class='nf'>::</span><span class='nf'><a href='https://cynkra.github.io/indiedown/reference/create_indiedown_package.html'>create_indiedown_package</a></span><span class='o'>(</span><span class='s'>"mydown"</span><span class='o'>)</span></pre>

This creates a package skeleton in the new `mydown` directory in the current working directory. You can build *mydown*, using “Build and Reload” in the RStudio or via the command line, as follows:

<pre class='chroma'>
<span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://devtools.r-lib.org//reference/install.html'>install</a></span><span class='o'>(</span><span class='s'>"mydown"</span><span class='o'>)</span></pre>

With *mydown* built and installed, our new template is available in RStudio (after a restart).

-   Read more at `vignette("indiedown")`.
-   See `vignette("walkthrough")` for a step by step guide to customization.
-   See `vignette("customize")` for advanced customization.

------------------------------------------------------------------------

## Code of Conduct

Please note that the indiedown project is released with a [Contributor Code of Conduct](https://cynkra.github.io/indiedown/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
