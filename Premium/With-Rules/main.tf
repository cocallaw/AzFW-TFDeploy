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

resource "azurerm_firewall_application_rule_collection" "apprulecollection01" {
  name                = "apprulecollection"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg01.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "sampleapprule01"

    source_addresses = [
      "10.0.0.0/16",
    ]

    target_fqdns = [
      "*.bing.com",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_nat_rule_collection" "natrulecollection01" {
  name                = "natrulecollection"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg01.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "samplenatrule01"

    source_addresses = [
      "10.0.10.0/24",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "10.0.1.10",
      "10.0.1.11"
    ]

    translated_port = 53

    translated_address = "8.8.8.8"

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

resource "azurerm_firewall_network_rule_collection" "netrulecollection01" {
  name                = "netrulecollection"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg01.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "samplenetrule01"

    source_addresses = [
      "10.0.0.0/16",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "8.8.8.8",
      "8.8.4.4",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}