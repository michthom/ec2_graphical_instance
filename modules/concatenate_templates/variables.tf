variable "source_directory" {
  type        = string
  description = "Path to the directory holding the files to concatenate."
}

variable "glob_filter" {
  type        = string
  default     = null
  description = "Glob filter with which to select files lexically from the source directory."
}

variable "file_list" {
  type        = list(string)
  default     = []
  description = "Ordered list of files to explicitly select from the source directory."
  validation {
    condition = (
      (length(var.file_list) > 0 && var.glob_filter == null) ||
      (length(var.file_list) == 0 && var.glob_filter != null)
    )
    error_message = "You must provide either 'file_list' or 'glob_filter', but not both."
  }
}

variable "template_vars" {
  type        = map(any)
  default     = {}
  description = "Map of template keys to values that should be interpolated into the files before concatenation."
}
