moved {
  from = azurerm_role_assignment.log_analytics_reader_management_group[0]
  to   = azurerm_role_assignment.log_analytics_reader_management_group["default"]
}

moved {
  from = azurerm_role_assignment.reader_management_group[0]
  to   = azurerm_role_assignment.reader_management_group["default"]
}

moved {
  from = azurerm_role_assignment.management_group_reader[0]
  to   = azurerm_role_assignment.management_group_reader["default"]
}
