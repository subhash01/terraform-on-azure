resource "random_id" "function" {
  keepers = {
    # Generate a new id each time we switch to a new Azure Resource Group
    rg_id = "${azurerm_resource_group.k8s.name}"
  }

  byte_length = 4
}

# Create a new storage account for our function app
resource "azurerm_storage_account" "function" {
  name                     = "ignitek8sdemo${random_id.function.hex}"
  resource_group_name      = "${azurerm_resource_group.k8s.name}"
  location                 = "${azurerm_resource_group.k8s.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    Environment = "${var.environment_tag}"
    build       = "${var.build_tag}"
  }
}

# Create a new service plan for our function app
resource "azurerm_app_service_plan" "function" {
  name                = "ignite-demo-function-service-plan"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags {
    Environment = "${var.environment_tag}"
    build       = "${var.build_tag}"
  }
}

# Create Application Insights for the function app
resource "azurerm_application_insights" "function" {
  name                = "ignite-demo-function-insights"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  application_type    = "Web"

  tags {
    Environment = "${var.environment_tag}"
    build       = "${var.build_tag}"
  }
}

# Create the function app
resource "azurerm_function_app" "function" {
  name                      = "ignitedemo${random_id.function.hex}"
  location                  = "${azurerm_resource_group.k8s.location}"
  resource_group_name       = "${azurerm_resource_group.k8s.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.function.id}"
  storage_connection_string = "${azurerm_storage_account.function.primary_connection_string}"

  # App settings for the function app
  app_settings {
    "AppInsights_InstrumentationKey" = "${azurerm_application_insights.function.instrumentation_key}"
    "WEBSITE_RUN_FROM_PACKAGE"       = "${var.function_app_content_zip_url}"
  }

  tags {
    Environment = "${var.environment_tag}"
    build       = "${var.build_tag}"
  }
}