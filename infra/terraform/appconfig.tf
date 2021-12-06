module "appconfig" {
  source  = "modules/appconfig"

  name                                = "${var.env}-${var.app_name}-appconfig"
  description                         = var.appconfig_desc
  environments                        = var.env
  use_hosted_configuration            = var.appconfig_hosted_config
  hosted_config_version_content_type  = var.appconfig_hosted_config_content_type
  hosted_config_version_content       = var.appconfig_hosted_config_content

}