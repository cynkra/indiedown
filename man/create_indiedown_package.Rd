% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_indiedown_package.R
\name{create_indiedown_package}
\alias{create_indiedown_package}
\title{Skeleton for a Customized RMarkdown Template}
\usage{
create_indiedown_package(path, overwrite = FALSE)
}
\arguments{
\item{path}{Package path}

\item{overwrite}{Should existing assets be overwritten?}
}
\value{
This function is called for its side effects and returns \code{NULL}, invisibly.
}
\description{
Set up the packages structure for an indiedown-based customized RMarkdown
template. See \code{vignette("indiedown")} for a more detailed usage example.
}
\examples{
path <- file.path(tempdir(), "mydown")

# set up empty R Package 'mydown'
create_indiedown_package(path, overwrite = TRUE)
}
