output "selected_files" {
  value = local.selected_files
}

output "rendered_files" {
  value = local.rendered_files
}

output "concatenated_content_cleartext" {
  value = local.concatenated
}

output "concatenated_content_base64" {
  value = base64encode(local.concatenated)
}
