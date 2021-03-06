% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cd_knit_chunk_opts.R
\name{cd_knit_chunk_opts}
\alias{cd_knit_chunk_opts}
\title{Corporate Design: knitr Chunk Options}
\usage{
cd_knit_chunk_opts(
  twocolumn = default(rmarkdown::metadata$twocolumn, FALSE),
  fig.width = NULL,
  fig.height = NULL,
  fig.pos = "h",
  message = FALSE,
  echo = FALSE
)
}
\arguments{
\item{twocolumn}{Use two-column mode? This will affect \code{fig.width} and \code{fig.height}}

\item{fig.width}{Figure width. If \code{NULL}, automatically chosen based on \code{twocolumn}.}

\item{fig.height}{Figure height If \code{NULL}, automatically chosen based on \code{twocolumn}.}

\item{fig.pos}{Floating modifier for figures.}

\item{message}{Should messages be shown?}

\item{echo}{Should echo be shown?}
}
\description{
Set knitr chunk options in accordance with corporate design.
}
