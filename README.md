<!-- README.md is generated from README.Rmd on GitHub Actions: do not edit by hand -->

# indiedown

Individual RMarkdown PDF Templates.

<!-- badges: start -->

[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.cynkra.org/articles/stages.html#stable) [![R build status](https://github.com/cynkra/indiedown/workflows/R-CMD-check/badge.svg)](https://github.com/cynkra/indiedown/actions) [![Coverage status](https://codecov.io/gh/cynkra/indiedown/branch/master/graph/badge.svg)](https://codecov.io/github/cynkra/indiedown?branch=master) [![CRAN status](https://www.r-pkg.org/badges/version/indiedown)](https://cran.r-project.org/package=indiedown)

<!-- badges: end -->

indiedown allows you to generate a customized RMarkdown PDF template in a few basic steps.

Start by installing indiedown:

<pre class='chroma'>
<span class='c'># install.packages("remotes")</span>
<span class='nf'>remotes</span><span class='nf'>::</span><span class='nf'><a href='https://remotes.r-lib.org/reference/install_github.html'>install_github</a></span><span class='o'>(</span><span class='s'>"cynkra/indiedown"</span><span class='o'>)</span></pre>

To create your own, customized RMarkdown template, start by creating an indiedown template package, called `mydown`:

<pre class='chroma'>
<span class='nf'>indiedown</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/indiedown/man/create_indiedown_package.html'>create_indiedown_package</a></span><span class='o'>(</span><span class='s'>"mydown"</span><span class='o'>)</span></pre>

This creates a package skeleton at `./mydown`. You can build build *mydown*, using ‘build and reload’ in the RStudio or via the command line, as follows:

<pre class='chroma'>
<span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://devtools.r-lib.org//reference/install.html'>install</a></span><span class='o'>(</span><span class='s'>"mydown"</span><span class='o'>)</span></pre>

With *mydown* built and installed, our new template is available in RStudio (after a restart).

See `vignette("indiedown")` for a more detailed tutorial.

See `vignette("customize")` for how to customize your template.
