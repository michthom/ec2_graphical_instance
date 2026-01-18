locals {
  # If an explicit list is provided, use it.
  # Otherwise, fall back to fileset() using the glob.
  selected_files = length(var.file_list) > 0 ? var.file_list : (
    var.glob_filter != null ? fileset(var.source_directory, var.glob_filter) : []
  )

  # Render files in order
  rendered_files = [
    for f in local.selected_files :
    templatefile("${var.source_directory}/${f}", var.template_vars)
  ]

  concatenated = join("\n", local.rendered_files)
}