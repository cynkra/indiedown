#' @export
cynkra_report = function(
  fig_width = 4, fig_height = 2.5, fig_crop = TRUE, dev = "pdf",
  highlight = "default", latex_engine = "lualatex", template = NULL, asset = NULL, ...
) {
  format <- cynkra_pdf("report", fig_width, fig_height, fig_crop, dev, highlight,
                       latex_engine, template = template, ...)

  # disable default paragraph modifcation to enable titlesec
  format$pandoc$args <- c(
    format$pandoc$args,
    "--variable", "subparagraph:yes"
  )

  # for now, needed in modify_yaml()
  .font_path <<- system.file("fonts", package = asset)
  .preamble_path <<- template_resources(package = asset, "cynkra_report", "cynkra-report-preamble.tex")
  .logo_path <<- system.file("res", package = asset)

  pre_processor <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {
    # save files dir (for generating intermediates)
    # saved_files_dir <<- files_dir

    report_pre_processor(metadata, input_file, runtime, knit_meta, files_dir, output_dir)
  }

  format$pre_processor <- pre_processor
  format
}

cynkra_pdf = function(
  documentclass = c("article", "book", "report"), fig_width = 4, fig_height = 2.5,
  fig_crop = TRUE, dev = "pdf", highlight = "default", latex_engine = "lualatex",
  template = NULL, ...
) {

  # resolve default highlight
  if (identical(highlight, "default")) highlight = "pygments"

  # call the base pdf_document format with the appropriate options
  format = rmarkdown::pdf_document(
    fig_width = fig_width, fig_height = fig_height, fig_crop = fig_crop,
    dev = dev, highlight = highlight, latex_engine = latex_engine, template = template, ...
  )

  # LaTeX document class
  message(documentclass)
  documentclass <- match.arg(documentclass)
  format$pandoc$args <- c(
    format$pandoc$args,
    "--variable", paste0("documentclass:", documentclass),
    "--variable", "table: true",
    if (documentclass == "cynkra-book") "--chapters"
  )

  knitr::knit_engines$set(marginfigure = function(options) {
    options$type = "marginfigure"
    eng_block = knitr::knit_engines$get("block")
    eng_block(options)
  })

  # create knitr options (ensure opts and hooks are non-null)
  knitr_options = rmarkdown::knitr_options_pdf(fig_width, fig_height, fig_crop, dev)
  if (is.null(knitr_options$opts_knit))  knitr_options$opts_knit = list()
  if (is.null(knitr_options$knit_hooks)) knitr_options$knit_hooks = list()

  # set options
  knitr_options$opts_chunk$tidy = TRUE
  knitr_options$opts_knit$width = 45

  # set hooks for special plot output
  knitr_options$knit_hooks$plot = function(x, options) {

    # determine figure type
    if (isTRUE(options$fig.margin)) {
      options$fig.env = "marginfigure"
      if (is.null(options$fig.cap)) options$fig.cap = ""
    } else if (isTRUE(options$fig.fullwidth)) {
      options$fig.env = "figure*"
      if (is.null(options$fig.cap)) options$fig.cap = ""
    }

    knitr::hook_plot_tex(x, options)
  }

  # override the knitr settings of the base format and return the format
  format$knitr = knitr_options
  format$inherits = "pdf_document"
  format
}


# Preprocessor functions are adaptations from the RMarkdown package
# (https://github.com/rstudio/rmarkdown/blob/master/R/pdf_document.R)
# to ensure right geometry defaults in the absence of user specified values

report_pre_processor <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {

  # add conditional header includes
  modify_yaml(input_file, metadata)

  # set pandoc args
  args <- character()

  # use specified document class
  if(!is.null(metadata$documentclass)) {
    args <- c(args, "--variable", paste0("documentclass:", metadata$documentclass))
  }

  # use titling package to change title format to be more compact by default
  if (is.null(metadata$`compact-title`)) {
    args <- c(args, "--variable", "compact-title:yes")
  }

  # set default lang
  if (is.null(metadata$lang)) {
    args <- c(args, "--variable", "lang:de-CH")
  }

  # use identation by default
  if (is.null(metadata$indent)) {
    args <- c(args, "--variable", "indent:true")
  }

  # use linestretch:1.15 by default
  if (is.null(metadata$linestretch)) {
    args <- c(args, "--variable", "linestretch:1.15")
  }

  # set the margin based on twocolumn and wide
  if (is.null(metadata$geometry)) {
    if (isTRUE(metadata$twocolumn) || isTRUE(metadata$wide)) {
      args <- c(args, "--variable", "geometry:top=1cm,bottom=1.75cm,left=2cm,right=2cm,includehead,includefoot")
    } else {
      args <- c(args, "--variable", "geometry:top=1cm,bottom=1.75cm,left=2.5cm,right=2.5cm,includehead,includefoot")
    }
  }

  # set custom secnumdepth
  if (isTRUE(metadata$numbersections)) {
    args <- c(args, "--variable", "secnumdepth:2")
  } else {
    args <- c(args, "--variable", "numbersections:true", "--variable", "secnumdepth:-1")
  }

  # pass twocolumn as classoption
  if (isTRUE(metadata$twocolumn)) {
    args <- c(args, "--variable", paste0("classoption:", metadata$classoption, "twocolumn", collapse = ","))
  }

  # Set colored links
  if (isTRUE(metadata$colorlinks)) {
    if (is.null(metadata$citecolor)) args <- c(args, "--variable", "citecolor:cynkrablue")
    if (is.null(metadata$filecolor)) args <- c(args, "--variable", "filecolor:cynkrablue")
    if (is.null(metadata$linkcolor)) args <- c(args, "--variable", "linkcolor:cynkrablue")
    if (is.null(metadata$urlcolor)) args <- c(args, "--variable", "urlcolor:cynkrablue")
  }

  args
}


modify_yaml <- function(input_file, metadata) {

  # read input file
  input_connection <- base::file(input_file, encoding = "UTF-8")
  on.exit(close(input_connection), add = TRUE)
  input_text <- enc2utf8(readLines(input_connection, warn = FALSE))

  yaml_params <- get_yaml_params(input_text)

  # add default preamble includes
  header_includes <- readLines(
    .preamble_path,
    encoding = "UTF-8"
  )

  # # insert path to package-supplied resources
  header_includes <- gsub(
    "\\$fonts-path\\$",
    .font_path,   # global, for now
    header_includes
  )

  # add logo to first chapter pages
  header_includes <- c(
    header_includes,
    paste0("\\fancypagestyle{plain}{\\fancyhf{}\\renewcommand{\\headrulewidth}{0pt}\\fancyfoot[c]{\\small \\textcolor{Gray}{\\thepage}}\\setlength{\\headheight}{2\\baselineskip}\\fancyhead[r]{\\includegraphics[width=1.75cm,keepaspectratio]{", file.path(.logo_path, "logo_small.pdf"), "}}}")
  )

  # add conditional preamble includes

  # balance columns on last page in two col style.
  # The balance package cripples output, use manual solution from https://tex.stackexchange.com/a/130042/8057
  # Usage: Before the last page, issue \manualbalance{10ex} to reduce the size of the page by 10 ex (approx. 5 lines).
  # After the last page, call \restoregeometry (done automatically by \widesection)
  if (isTRUE(metadata$twocolumn) | grepl("twocolumn", paste0("", metadata$classoption))) {
    header_includes <- c(
      header_includes,
      "\\newcommand\\manualbalance[1]{%",
      "  \\savegeometry{balance}%",
      "  \\addtolength{\\textheight}{-#1}%",
      "      \\addtolength{\\footskip}{#1}%",
      "}",
      "% https://tex.stackexchange.com/a/449999/8057",
      "\\NewDocumentCommand{\\widesection}{s m}{",
      "  \\clearpage%",
      "  \\twocolumn[",
      "    \\IfBooleanTF{#1}{\\section*{#2}}{\\section{#2}}",
      "      ~\\vskip-2ex % Necessary to fix vertical spacing in first section title (?)",
      "  ]",
      "}"
    )
  } else {
    # no-op in single-column format
    header_includes <- c(
      header_includes,
      "\\let\\widesection\\section"
      , "\\newcommand\\manualbalance[1]{}"
    )
  }

  # # fix french setup
  # if (grepl("fr-", paste0("", metadata$lang))) {
  #   header_includes <- c(
  #     header_includes,
  #     "\\frenchbsetup{IndentFirst=false}"
  #   )
  # }

  yaml_params$`header-includes` <- c(
    paste0("```{=latex}\n", paste0(header_includes, collapse = "\n"), "\n```\n")
    , yaml_params$`header-includes`
  )

  replace_yaml_front_matter(yaml_params, input_text, input_file)
}

get_yaml_params <- function(x) {
  yaml_delimiters <- grep("^(---|\\.\\.\\.)\\s*$", x)

  if(length(yaml_delimiters) >= 2 &&
     (yaml_delimiters[2] - yaml_delimiters[1] > 1) &&
     grepl("^---\\s*$", x[yaml_delimiters[1]])) {
    yaml_params <- yaml::yaml.load(paste(x[(yaml_delimiters[1] + 1):(yaml_delimiters[2] - 1)], collapse = "\n"))
    yaml_params
  } else NULL
}

replace_yaml_front_matter <- function(x, input_text, input_file) {
  yaml_delimiters <- grep("^(---|\\.\\.\\.)\\s*$", input_text)
  augmented_input_text <- c("---", yaml::as.yaml(x), "---", input_text[(yaml_delimiters[2] + 1):length(input_text)])

  input_file_connection <- file(input_file)
  on.exit(close(input_file_connection))
  writeLines(augmented_input_text, input_file_connection, useBytes = TRUE)
}
