## CRAN comments after intitial submission

> Please rather write "R Markdown" instead of "RMarkdown" in title and description.

Done.

> Please add more details about the package functionality and implemented methods in your Description text.

Done.

> Please add \value to .Rd files regarding exported methods and explain the functions results in the documentation. Please write about the structure of the output (class) and also what the output means. (If a function does not return a value, please document that too, e.g. \value{No return value, called for side effects} or similar)
Missing Rd-tags:
     cd_format_date.Rd: \value
     cd_knit_chunk_opts.Rd: \value
     cd_page_title.Rd: \value
     default.Rd: \value
     indiedown_glue.Rd: \value
     indiedown_path.Rd: \value
     mypackage.Rd: \value

Done.

> \dontrun{} should only be used if the example really cannot be executed (e.g. because of missing additional software, missing API keys, ...) by the user. That's why wrapping examples in \dontrun{} adds the comment ('# Not run:') as a warning for the user.
Is this necessary?

> If not, please unwrap the examples if they are executable in < 5 sec, or replace \dontrun{} with \donttest{}.

\dontrun{} -> \donttest{}

> If possible: Please add some more small executable examples in your Rd-files to illustrate the use of the exported function but also enable automatic testing.

Done. Added examples to all functions
