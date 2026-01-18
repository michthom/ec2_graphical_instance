output "userdata_files" {
  value = module.canary_instance_userdata.selected_files
}

output "policy" {
  value = module.dcv_user_password_access_policy.policy
}