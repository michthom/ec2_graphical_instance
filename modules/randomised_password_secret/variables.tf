variable "secret_name" {
  type        = string
  description = "Location of secret e.g. `prod/webserver/private_key`"
  validation {
    condition     = can(regex("^[0-9a-zA-Z/_+=.@-]+$", var.secret_name))
    error_message = "Secret name can only contain 0-9 a-z A-Z or special characters `/_+=.@-`"
  }
}

variable "secret_description" {
  type        = string
  description = "Description of secret"
  default = ""
  validation {
    condition     = (length(var.secret_description) <= 250)
    error_message = "Secret description must be 250 characters or less."
  }
}

variable "password_length" {
  type        = string
  description = "Length of password in characters"
  default     = 12
  validation {
    condition     = (8 <= var.password_length) && (var.password_length <= 20)
    error_message = "Password must be longer than 8 and less than 20 characters"
  }
}