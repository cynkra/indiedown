# indiedown: customize conditional settings here

pre_processor <- function(metadata, input_file, runtime, knit_meta, files_dir, output_dir) {

  # apply default.yaml (do not remove)
  args <- apply_default_yaml(metadata = metadata)

  # set the margin based on twocolumn and wide
  if (is.null(metadata$geometry)) {
    if (isTRUE(metadata$twocolumn) || isTRUE(metadata$wide)) {
      args <- c(args, "--variable", "geometry:top=1cm,bottom=1.75cm,left=2cm,right=2cm,includehead,includefoot")
    } else {
      args <- c(args, "--variable", "geometry:top=1cm,bottom=1.75cm,left=2.5cm,right=2.5cm,includehead,includefoot")
    }
  }

  args
}
