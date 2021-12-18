pkgname <- "mypackage"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
base::assign(".ExTimings", "mypackage-Ex.timings", pos = 'CheckExEnv')
base::cat("name\tuser\tsystem\telapsed\n", file=base::get(".ExTimings", pos = 'CheckExEnv'))
base::assign(".format_ptime",
function(x) {
  if(!is.na(x[4L])) x[1L] <- x[1L] + x[4L]
  if(!is.na(x[5L])) x[2L] <- x[2L] + x[5L]
  options(OutDec = '.')
  format(x[1L:3L], digits = 7L)
},
pos = 'CheckExEnv')

### * </HEADER>
library('mypackage')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("cd_format_date")
### * cd_format_date

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: cd_format_date
### Title: Corporate Design: Format Date
### Aliases: cd_format_date

### ** Examples

cd_format_date("2012-01-01", "de-DE")
cd_format_date("2012-01-01", "en-US")



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("cd_format_date", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("cd_knit_chunk_opts")
### * cd_knit_chunk_opts

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: cd_knit_chunk_opts
### Title: Corporate Design: knitr Chunk Options
### Aliases: cd_knit_chunk_opts

### ** Examples

cd_knit_chunk_opts()




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("cd_knit_chunk_opts", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("cd_page_title")
### * cd_page_title

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: cd_page_title
### Title: Corporate Design: Title Page
### Aliases: cd_page_title

### ** Examples

cd_page_title(
  title = "My Title",
  subtitle = "My Subtitle"
)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("cd_page_title", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("default")
### * default

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: default
### Title: Set Default Value
### Aliases: default

### ** Examples

default(NULL)
default(NULL, "my default")
default("a string", "my default")



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("default", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("indiedown_glue")
### * indiedown_glue

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: indiedown_glue
### Title: Glue LaTeX Code for Use in R Markdown
### Aliases: indiedown_glue

### ** Examples

x <- "something"
indiedown_glue(r"(\LaTeX\ code with <<x>> substituted )")




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("indiedown_glue", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("indiedown_path")
### * indiedown_path

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: indiedown_path
### Title: Path helpers
### Aliases: indiedown_path indiedown_path_tex

### ** Examples

indiedown_path()



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("indiedown_path", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
