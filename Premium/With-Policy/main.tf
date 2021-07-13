terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.63.0"
    }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg01" {
  name     = "azfw-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet01" {
  name                = "vnet-azfw"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
}

resource "azurerm_subnet" "sn01vn01" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg01.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip01" {
  name                = "pip-azfw"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azfw" {
  name                = "testfirewall"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.sn01vn01.id
    public_ip_address_id = azurerm_public_ip.pip01.id
  }
}

resource "azurerm_firewall_policy" "azfwpolicy01" {
  name                = "sample-fwpolicy"
  resource_group_name = azurerm_resource_group.rg01.name
  location            = azurerm_resource_group.rg01.location
}

resource "azurerm_firewall_policy_rule_collection_group" "azfwprcg01" {
  name               = "sample-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.azfwpolicy01.id
  priority           = 500
  application_rule_collection {
    name     = "app_rule_collection01"
    priority = 500
    action   = "Deny"
    rule {
      name = "app_rule_collection01_rule01"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.0.10.0/24"]
      destination_fqdns = [".xbox.com"]
    }
  }

  network_rule_collection {
    name     = "network_rule_collection01"
    priority = 400
    action   = "Deny"
    rule {
      name                  = "network_rule_collection1_rule01"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.0.10.0/24"]
      destination_addresses = ["10.0.20.10", "10.0.20.11"]
      destination_ports     = ["80", "1000-2000"]
    }
  }

  nat_rule_collection {
    name     = "nat_rule_collection1"
    priority = 300
    action   = "Dnat"
    rule {
      name                = "nat_rule_collection01_rule01"
      protocols           = ["TCP", "UDP"]
      source_addresses    = ["10.0.10.10", "10.0.10.11"]
      destination_address = "10.0.20.20"
      destination_ports   = ["80", "1000-2000"]
      translated_address  = "10.0.21.20"
      translated_port     = "8080"
    }
  }
}