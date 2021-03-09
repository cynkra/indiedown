# indiedown: Individual RMarkdown PDF Templates

indiedown allows you to generate a customized RMarkdown PDF template in 10 minutes.
Start by installing indiedown:

```r
# install.packages("remotes")
remotes::install_github("cynkra/indiedown")
```

### Minute 1: Create an individual RMarkdown template

```r
library(indiedown)
usethis::create_package("mydown")
use_indiedown_skeleton()
```

### Minute 2: Add a custom font:

```r
use_indiedown_fonts(
  id = "open-sans",
  variants = c("regular", "300italic", "700", "700italic")
)
```

### Minute 3: Apply aritrary modification at three entry points:

- Set defaults (such as fonts or geometry) in the YAML header at `inst/indedown/default.ymal`
- Tweak LaTeX settings at `inst/indedown/pramble.tex`
- Apply dynamic adjustments in `pre_processor.R` (advanced)

See the vignette for details.

### Minute 10: Create a new RMarkdown from your template in RStudio.






