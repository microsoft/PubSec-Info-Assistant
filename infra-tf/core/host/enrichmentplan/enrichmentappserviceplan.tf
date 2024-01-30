

// Create an App Service Plan to group applications under the same payment plan and SKU, specifically for containers
resource "azurerm_service_plan" "appServicePlan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku_name = "P1v3"
  os_type = "Linux"

  tags = var.tags
}

# resource "azurerm_monitor_autoscale_setting" "scaleOutRule" {
#   name                = azurerm_app_service_plan.appServicePlan.name
#   resource_group_name = var.resourceGroupName
#   location            = var.location
#   target_resource_id  = azurerm_app_service_plan.appServicePlan.id

#   profile {
#     name = "Scale out condition"
#     capacity {
#       default = 1
#       minimum = 1
#       maximum = 3
#     }

#     rule {
#       metric_trigger {
#         metric_name         = "ApproximateMessageCount"
#         metric_resource_id  = var.storageAccountId
#         operator            = "GreaterThan"
#         statistic           = "Average"
#         threshold           = 10
#         time_grain          = "PT1M"
#         time_window         = "PT10M"
#         time_aggregation    = "Average"
#         divide_by_instance_count = true
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }
#   }
# }

output "id" {
  value = azurerm_service_plan.appServicePlan.id
}

output "name" {
  value = azurerm_service_plan.appServicePlan.name
}
