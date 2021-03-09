# indiedown: Individual RMarkdown PDF Templates

indiedown allows you to generate a customized RMarkdown PDF template in 10 minutes.
Start by installing indiedown:

```r
# install.packages("remotes")
remotes::install_github("cynkra/indiedown")
```

### Create an individual RMarkdown template

```r
library(indiedown)
usethis::create_package("mydown")
use_indiedown_skeleton()
```

### Add a custom font (optional)

```r
use_indiedown_fonts(
  id = "open-sans",
  variants = c("regular", "300italic", "700", "700italic")
)
```

### Apply aritrary modification at three entry points (optional)

- Set defaults (such as fonts or geometry) in the YAML header at `inst/indedown/default.ymal`
- Tweak LaTeX settings at `inst/indedown/pramble.tex`
- Apply dynamic adjustments in `pre_processor.R` (advanced)

See the vignette for details.

### Create a new RMarkdown from your template in RStudio.






