module "appconfig" {
  source  = "./modules/appconfig"

  name                                = "${var.app_env}-${var.app_name}-appconfig"
  description                         = "Appconfig hosting service config for S3AV service"
  environments                        = var.app_env
  use_hosted_configuration            = var.appconfig_hosted_config
  hosted_config_version_content_type  = var.appconfig_hosted_config_content_type
  hosted_config_version_content       = file(var.appconfig_hosted_config_content_path)

}