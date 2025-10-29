# Azure-Specific Security Configuration
# This Terraform configuration adds WAF and DDoS protection

# Azure Application Gateway with WAF (Alternative to NGINX Ingress)
resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.cluster_name}-appgw-pip"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  allocation_method  = "Static"
  sku               = "Standard"
  
  # DDoS Protection
  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.main.id
    enable = true
  }

  tags = var.tags
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "${var.cluster_name}-ddos-plan"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location

  tags = var.tags
}

# Application Gateway with WAF v2
resource "azurerm_application_gateway" "main" {
  name                = "${var.cluster_name}-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # WAF Configuration
  waf_configuration {
    enabled                  = true
    firewall_mode           = "Prevention"  # Detection or Prevention
    rule_set_type           = "OWASP"
    rule_set_version        = "3.2"
    file_upload_limit_mb    = 100
    request_body_check      = true
    max_request_body_size_kb = 128

    # Disabled rules (customize as needed)
    disabled_rule_group {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      rules          = ["920230", "920300"]
    }
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name = "appGwBackendPool"
  }

  backend_http_settings {
    name                  = "appGwBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol             = "Http"
    request_timeout      = 60
    
    # Health probe
    probe_name = "health-probe"
  }

  # Health Probe
  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "myapp.yourdomain.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "appGwHttpListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name            = "port_80"
    protocol                      = "Http"
  }

  # HTTPS Listener
  http_listener {
    name                           = "appGwHttpsListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name            = "port_443"
    protocol                      = "Https"
    ssl_certificate_name          = "appGwSslCert"
  }

  # SSL Certificate
  ssl_certificate {
    name     = "appGwSslCert"
    data     = filebase64("path/to/your/certificate.pfx")
    password = var.ssl_certificate_password
  }

  request_routing_rule {
    name                       = "appGwRoutingRule"
    rule_type                 = "Basic"
    http_listener_name        = "appGwHttpListener"
    backend_address_pool_name  = "appGwBackendPool"
    backend_http_settings_name = "appGwBackendHttpSettings"
    priority                  = 100
  }

  # HTTPS Routing Rule
  request_routing_rule {
    name                       = "appGwHttpsRoutingRule"
    rule_type                 = "Basic"
    http_listener_name        = "appGwHttpsListener"
    backend_address_pool_name  = "appGwBackendPool"
    backend_http_settings_name = "appGwBackendHttpSettings"
    priority                  = 200
  }

  tags = var.tags
}

# Subnet for Application Gateway
resource "azurerm_subnet" "app_gateway" {
  name                 = "${var.cluster_name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.100.0/24"]
}

# Azure Monitor for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name               = "${var.cluster_name}-appgw-diagnostics"
  target_resource_id = azurerm_application_gateway.main.id
  storage_account_id = azurerm_storage_account.logs.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Storage Account for Logs
resource "azurerm_storage_account" "logs" {
  name                     = "${var.cluster_name}logs"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  
  tags = var.tags
}