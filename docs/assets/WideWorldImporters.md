# WideWorldImporters

| Property | Value |
| --- | --- |
| SQL Server Version | 15.0.2000.5 |
| Compatibility Level | 130 |
| Collation | Latin1_General_100_CI_AS |
----

## Tables

<details><summary>Click to expand</summary>

* [Application.Cities](#applicationcities)
* [Application.Cities_Archive](#applicationcities_archive)
* [Application.Countries](#applicationcountries)
* [Application.Countries_Archive](#applicationcountries_archive)
* [Application.DeliveryMethods](#applicationdeliverymethods)
* [Application.DeliveryMethods_Archive](#applicationdeliverymethods_archive)
* [Application.PaymentMethods](#applicationpaymentmethods)
* [Application.PaymentMethods_Archive](#applicationpaymentmethods_archive)
* [Application.People](#applicationpeople)
* [Application.People_Archive](#applicationpeople_archive)
* [Application.StateProvinces](#applicationstateprovinces)
* [Application.StateProvinces_Archive](#applicationstateprovinces_archive)
* [Application.SystemParameters](#applicationsystemparameters)
* [Application.TransactionTypes](#applicationtransactiontypes)
* [Application.TransactionTypes_Archive](#applicationtransactiontypes_archive)
* [Purchasing.PurchaseOrderLines](#purchasingpurchaseorderlines)
* [Purchasing.PurchaseOrders](#purchasingpurchaseorders)
* [Purchasing.SupplierCategories](#purchasingsuppliercategories)
* [Purchasing.SupplierCategories_Archive](#purchasingsuppliercategories_archive)
* [Purchasing.Suppliers](#purchasingsuppliers)
* [Purchasing.Suppliers_Archive](#purchasingsuppliers_archive)
* [Purchasing.SupplierTransactions](#purchasingsuppliertransactions)
* [Sales.BuyingGroups](#salesbuyinggroups)
* [Sales.BuyingGroups_Archive](#salesbuyinggroups_archive)
* [Sales.CustomerCategories](#salescustomercategories)
* [Sales.CustomerCategories_Archive](#salescustomercategories_archive)
* [Sales.Customers](#salescustomers)
* [Sales.Customers_Archive](#salescustomers_archive)
* [Sales.CustomerTransactions](#salescustomertransactions)
* [Sales.InvoiceLines](#salesinvoicelines)
* [Sales.Invoices](#salesinvoices)
* [Sales.OrderLines](#salesorderlines)
* [Sales.Orders](#salesorders)
* [Sales.SpecialDeals](#salesspecialdeals)
* [Warehouse.ColdRoomTemperatures](#warehousecoldroomtemperatures)
* [Warehouse.ColdRoomTemperatures_Archive](#warehousecoldroomtemperatures_archive)
* [Warehouse.Colors](#warehousecolors)
* [Warehouse.Colors_Archive](#warehousecolors_archive)
* [Warehouse.PackageTypes](#warehousepackagetypes)
* [Warehouse.PackageTypes_Archive](#warehousepackagetypes_archive)
* [Warehouse.StockGroups](#warehousestockgroups)
* [Warehouse.StockGroups_Archive](#warehousestockgroups_archive)
* [Warehouse.StockItemHoldings](#warehousestockitemholdings)
* [Warehouse.StockItems](#warehousestockitems)
* [Warehouse.StockItems_Archive](#warehousestockitems_archive)
* [Warehouse.StockItemStockGroups](#warehousestockitemstockgroups)
* [Warehouse.StockItemTransactions](#warehousestockitemtransactions)
* [Warehouse.VehicleTemperatures](#warehousevehicletemperatures)

### Application.Cities

| Description |
| --- |
| Cities that are part of any address (including geographic location) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **CityID** | INT | no |  | (NEXT VALUE FOR [Sequences].[CityID]) | Numeric ID used for reference to a city within the database |
| CityName | NVARCHAR(50) | no |  |  | Formal name of the city |
| StateProvinceID | INT | no | [[Application].[StateProvinces].[StateProvinceID]](#applicationstateprovinces) |  | State or province for this city |
| Location | GEOGRAPHY | yes |  |  | Geographic location of the city |
| LatestRecordedPopulation | BIGINT | yes |  |  | Latest available population for the City |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_Cities** | clustered | [CityID] |  |  |
| FK_Application_Cities_StateProvinceID | nonclustered | [StateProvinceID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[DetermineCustomerAccess]](#applicationdeterminecustomeraccess) | sql inline table valued function |
| [[Application].[SystemParameters].[FK_Application_SystemParameters_DeliveryCityID_Application_Cities]](#applicationsystemparameters) | foreign key constraint |
| [[Application].[SystemParameters].[FK_Application_SystemParameters_PostalCityID_Application_Cities]](#applicationsystemparameters) | foreign key constraint |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_DeliveryCityID_Application_Cities]](#purchasingsuppliers) | foreign key constraint |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_PostalCityID_Application_Cities]](#purchasingsuppliers) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_DeliveryCityID_Application_Cities]](#salescustomers) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_PostalCityID_Application_Cities]](#salescustomers) | foreign key constraint |
| [[Website].[Customers]](#websitecustomers) | view |
| [[Website].[SearchForCustomers]](#websitesearchforcustomers) | sql stored procedure |
| [[Website].[SearchForSuppliers]](#websitesearchforsuppliers) | sql stored procedure |
| [[Website].[Suppliers]](#websitesuppliers) | view |

[Back to top](#wideworldimporters)

### Application.Cities_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| CityID | INT | no |  |  |  |
| CityName | NVARCHAR(50) | no |  |  |  |
| StateProvinceID | INT | no |  |  |  |
| Location | GEOGRAPHY | yes |  |  |  |
| LatestRecordedPopulation | BIGINT | yes |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_Cities_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Countries

| Description |
| --- |
| Countries that contain the states or provinces (including geographic boundaries) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **CountryID** | INT | no |  | (NEXT VALUE FOR [Sequences].[CountryID]) | Numeric ID used for reference to a country within the database |
| CountryName | NVARCHAR(60) | no |  |  | Name of the country |
| FormalName | NVARCHAR(60) | no |  |  | Full formal name of the country as agreed by United Nations |
| IsoAlpha3Code | NVARCHAR(3) | yes |  |  | 3 letter alphabetic code assigned to the country by ISO |
| IsoNumericCode | INT | yes |  |  | Numeric code assigned to the country by ISO |
| CountryType | NVARCHAR(20) | yes |  |  | Type of country or administrative region |
| LatestRecordedPopulation | BIGINT | yes |  |  | Latest available population for the country |
| Continent | NVARCHAR(30) | no |  |  | Name of the continent |
| Region | NVARCHAR(30) | no |  |  | Name of the region |
| Subregion | NVARCHAR(30) | no |  |  | Name of the subregion |
| Border | GEOGRAPHY | yes |  |  | Geographic border of the country as described by the United Nations |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_Countries** | clustered | [CountryID] |  |  |
| UQ_Application_Countries_FormalName | nonclustered | [FormalName] |  |  |
| UQ_Application_Countries_CountryName | nonclustered | [CountryName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[StateProvinces].[FK_Application_StateProvinces_CountryID_Application_Countries]](#applicationstateprovinces) | foreign key constraint |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Countries_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| CountryID | INT | no |  |  |  |
| CountryName | NVARCHAR(60) | no |  |  |  |
| FormalName | NVARCHAR(60) | no |  |  |  |
| IsoAlpha3Code | NVARCHAR(3) | yes |  |  |  |
| IsoNumericCode | INT | yes |  |  |  |
| CountryType | NVARCHAR(20) | yes |  |  |  |
| LatestRecordedPopulation | BIGINT | yes |  |  |  |
| Continent | NVARCHAR(30) | no |  |  |  |
| Region | NVARCHAR(30) | no |  |  |  |
| Subregion | NVARCHAR(30) | no |  |  |  |
| Border | GEOGRAPHY | yes |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_Countries_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.DeliveryMethods

| Description |
| --- |
| Ways that stock items can be delivered (ie: truck/van, post, pickup, courier, etc. |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **DeliveryMethodID** | INT | no |  | (NEXT VALUE FOR [Sequences].[DeliveryMethodID]) | Numeric ID used for reference to a delivery method within the database |
| DeliveryMethodName | NVARCHAR(50) | no |  |  | Full name of methods that can be used for delivery of customer orders |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_DeliveryMethods** | clustered | [DeliveryMethodID] |  |  |
| UQ_Application_DeliveryMethods_DeliveryMethodName | nonclustered | [DeliveryMethodName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Purchasing].[PurchaseOrders].[FK_Purchasing_PurchaseOrders_DeliveryMethodID_Application_DeliveryMethods]](#purchasingpurchaseorders) | foreign key constraint |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_DeliveryMethodID_Application_DeliveryMethods]](#purchasingsuppliers) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_DeliveryMethodID_Application_DeliveryMethods]](#salescustomers) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_DeliveryMethodID_Application_DeliveryMethods]](#salesinvoices) | foreign key constraint |
| [[Website].[Customers]](#websitecustomers) | view |
| [[Website].[Suppliers]](#websitesuppliers) | view |

[Back to top](#wideworldimporters)

### Application.DeliveryMethods_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| DeliveryMethodID | INT | no |  |  |  |
| DeliveryMethodName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_DeliveryMethods_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

[Back to top](#wideworldimporters)

### Application.PaymentMethods

| Description |
| --- |
| Ways that payments can be made (ie: cash, check, EFT, etc. |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **PaymentMethodID** | INT | no |  | (NEXT VALUE FOR [Sequences].[PaymentMethodID]) | Numeric ID used for reference to a payment type within the database |
| PaymentMethodName | NVARCHAR(50) | no |  |  | Full name of ways that customers can make payments or that suppliers can be paid |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_PaymentMethods** | clustered | [PaymentMethodID] |  |  |
| UQ_Application_PaymentMethods_PaymentMethodName | nonclustered | [PaymentMethodName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetPaymentMethodUpdates]](#integrationgetpaymentmethodupdates) | sql stored procedure |
| [[Purchasing].[SupplierTransactions].[FK_Purchasing_SupplierTransactions_PaymentMethodID_Application_PaymentMethods]](#purchasingsuppliertransactions) | foreign key constraint |
| [[Sales].[CustomerTransactions].[FK_Sales_CustomerTransactions_PaymentMethodID_Application_PaymentMethods]](#salescustomertransactions) | foreign key constraint |

[Back to top](#wideworldimporters)

### Application.PaymentMethods_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| PaymentMethodID | INT | no |  |  |  |
| PaymentMethodName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_PaymentMethods_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetPaymentMethodUpdates]](#integrationgetpaymentmethodupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.People

| Description |
| --- |
| People known to the application (staff, customer contacts, supplier contacts) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **PersonID** | INT | no |  | (NEXT VALUE FOR [Sequences].[PersonID]) | Numeric ID used for reference to a person within the database |
| FullName | NVARCHAR(50) | no |  |  | Full name for this person |
| PreferredName | NVARCHAR(50) | no |  |  | Name that this person prefers to be called |
| SearchName | NVARCHAR(101) | no |  |  | Name to build full text search on (computed column) |
| IsPermittedToLogon | BIT | no |  |  | Is this person permitted to log on? |
| LogonName | NVARCHAR(50) | yes |  |  | Person's system logon name |
| IsExternalLogonProvider | BIT | no |  |  | Is logon token provided by an external system? |
| HashedPassword | VARBINARY(MAX) | yes |  |  | Hash of password for users without external logon tokens |
| IsSystemUser | BIT | no |  |  | Is the currently permitted to make online access? |
| IsEmployee | BIT | no |  |  | Is this person an employee? |
| IsSalesperson | BIT | no |  |  | Is this person a staff salesperson? |
| UserPreferences | NVARCHAR(MAX) | yes |  |  | User preferences related to the website (holds JSON data) |
| PhoneNumber | NVARCHAR(20) | yes |  |  | Phone number |
| FaxNumber | NVARCHAR(20) | yes |  |  | Fax number   |
| EmailAddress | NVARCHAR(256) | yes |  |  | Email address for this person |
| Photo | VARBINARY(MAX) | yes |  |  | Photo of this person |
| CustomFields | NVARCHAR(MAX) | yes |  |  | Custom fields for employees and salespeople |
| OtherLanguages | NVARCHAR(MAX) | yes |  |  | Other languages spoken (computed column from custom fields) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_People** | clustered | [PersonID] |  |  |
| IX_Application_People_Perf_20160301_05 | nonclustered | [IsPermittedToLogon], [PersonID] | [FullName], [EmailAddress] | Improves performance of order picking and invoicing |
| IX_Application_People_IsSalesperson | nonclustered | [IsSalesperson] |  | Allows quickly locating salespeople |
| IX_Application_People_IsEmployee | nonclustered | [IsEmployee] |  | Allows quickly locating employees |
| IX_Application_People_FullName | nonclustered | [FullName] |  | Improves performance of name-related queries |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Cities].[FK_Application_Cities_Application_People]](#applicationcities) | foreign key constraint |
| [[Application].[Countries].[FK_Application_Countries_Application_People]](#applicationcountries) | foreign key constraint |
| [[Application].[DeliveryMethods].[FK_Application_DeliveryMethods_Application_People]](#applicationdeliverymethods) | foreign key constraint |
| [[Application].[PaymentMethods].[FK_Application_PaymentMethods_Application_People]](#applicationpaymentmethods) | foreign key constraint |
| [[Application].[People].[FK_Application_People_Application_People]](#applicationpeople) | foreign key constraint |
| [[Application].[StateProvinces].[FK_Application_StateProvinces_Application_People]](#applicationstateprovinces) | foreign key constraint |
| [[Application].[SystemParameters].[FK_Application_SystemParameters_Application_People]](#applicationsystemparameters) | foreign key constraint |
| [[Application].[TransactionTypes].[FK_Application_TransactionTypes_Application_People]](#applicationtransactiontypes) | foreign key constraint |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |
| [[Integration].[GetEmployeeUpdates]](#integrationgetemployeeupdates) | sql stored procedure |
| [[Integration].[GetSupplierUpdates]](#integrationgetsupplierupdates) | sql stored procedure |
| [[Purchasing].[PurchaseOrderLines].[FK_Purchasing_PurchaseOrderLines_Application_People]](#purchasingpurchaseorderlines) | foreign key constraint |
| [[Purchasing].[PurchaseOrders].[FK_Purchasing_PurchaseOrders_Application_People]](#purchasingpurchaseorders) | foreign key constraint |
| [[Purchasing].[PurchaseOrders].[FK_Purchasing_PurchaseOrders_ContactPersonID_Application_People]](#purchasingpurchaseorders) | foreign key constraint |
| [[Purchasing].[SupplierCategories].[FK_Purchasing_SupplierCategories_Application_People]](#purchasingsuppliercategories) | foreign key constraint |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_AlternateContactPersonID_Application_People]](#purchasingsuppliers) | foreign key constraint |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_Application_People]](#purchasingsuppliers) | foreign key constraint |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_PrimaryContactPersonID_Application_People]](#purchasingsuppliers) | foreign key constraint |
| [[Purchasing].[SupplierTransactions].[FK_Purchasing_SupplierTransactions_Application_People]](#purchasingsuppliertransactions) | foreign key constraint |
| [[Sales].[BuyingGroups].[FK_Sales_BuyingGroups_Application_People]](#salesbuyinggroups) | foreign key constraint |
| [[Sales].[CustomerCategories].[FK_Sales_CustomerCategories_Application_People]](#salescustomercategories) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_AlternateContactPersonID_Application_People]](#salescustomers) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_Application_People]](#salescustomers) | foreign key constraint |
| [[Sales].[Customers].[FK_Sales_Customers_PrimaryContactPersonID_Application_People]](#salescustomers) | foreign key constraint |
| [[Sales].[CustomerTransactions].[FK_Sales_CustomerTransactions_Application_People]](#salescustomertransactions) | foreign key constraint |
| [[Sales].[InvoiceLines].[FK_Sales_InvoiceLines_Application_People]](#salesinvoicelines) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_AccountsPersonID_Application_People]](#salesinvoices) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_Application_People]](#salesinvoices) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_ContactPersonID_Application_People]](#salesinvoices) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_PackedByPersonID_Application_People]](#salesinvoices) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_SalespersonPersonID_Application_People]](#salesinvoices) | foreign key constraint |
| [[Sales].[OrderLines].[FK_Sales_OrderLines_Application_People]](#salesorderlines) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_Application_People]](#salesorders) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_ContactPersonID_Application_People]](#salesorders) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_PickedByPersonID_Application_People]](#salesorders) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_SalespersonPersonID_Application_People]](#salesorders) | foreign key constraint |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_Application_People]](#salesspecialdeals) | foreign key constraint |
| [[Warehouse].[Colors].[FK_Warehouse_Colors_Application_People]](#warehousecolors) | foreign key constraint |
| [[Warehouse].[PackageTypes].[FK_Warehouse_PackageTypes_Application_People]](#warehousepackagetypes) | foreign key constraint |
| [[Warehouse].[StockGroups].[FK_Warehouse_StockGroups_Application_People]](#warehousestockgroups) | foreign key constraint |
| [[Warehouse].[StockItemHoldings].[FK_Warehouse_StockItemHoldings_Application_People]](#warehousestockitemholdings) | foreign key constraint |
| [[Warehouse].[StockItems].[FK_Warehouse_StockItems_Application_People]](#warehousestockitems) | foreign key constraint |
| [[Warehouse].[StockItemStockGroups].[FK_Warehouse_StockItemStockGroups_Application_People]](#warehousestockitemstockgroups) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_Application_People]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[ActivateWebsiteLogon]](#websiteactivatewebsitelogon) | sql stored procedure |
| [[Website].[ChangePassword]](#websitechangepassword) | sql stored procedure |
| [[Website].[Customers]](#websitecustomers) | view |
| [[Website].[SearchForCustomers]](#websitesearchforcustomers) | sql stored procedure |
| [[Website].[SearchForPeople]](#websitesearchforpeople) | sql stored procedure |
| [[Website].[SearchForSuppliers]](#websitesearchforsuppliers) | sql stored procedure |
| [[Website].[Suppliers]](#websitesuppliers) | view |

[Back to top](#wideworldimporters)

### Application.People_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| PersonID | INT | no |  |  |  |
| FullName | NVARCHAR(50) | no |  |  |  |
| PreferredName | NVARCHAR(50) | no |  |  |  |
| SearchName | NVARCHAR(101) | no |  |  |  |
| IsPermittedToLogon | BIT | no |  |  |  |
| LogonName | NVARCHAR(50) | yes |  |  |  |
| IsExternalLogonProvider | BIT | no |  |  |  |
| HashedPassword | VARBINARY(MAX) | yes |  |  |  |
| IsSystemUser | BIT | no |  |  |  |
| IsEmployee | BIT | no |  |  |  |
| IsSalesperson | BIT | no |  |  |  |
| UserPreferences | NVARCHAR(MAX) | yes |  |  |  |
| PhoneNumber | NVARCHAR(20) | yes |  |  |  |
| FaxNumber | NVARCHAR(20) | yes |  |  |  |
| EmailAddress | NVARCHAR(256) | yes |  |  |  |
| Photo | VARBINARY(MAX) | yes |  |  |  |
| CustomFields | NVARCHAR(MAX) | yes |  |  |  |
| OtherLanguages | NVARCHAR(MAX) | yes |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_People_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetEmployeeUpdates]](#integrationgetemployeeupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.StateProvinces

| Description |
| --- |
| States or provinces that contain cities (including geographic location) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StateProvinceID** | INT | no |  | (NEXT VALUE FOR [Sequences].[StateProvinceID]) | Numeric ID used for reference to a state or province within the database |
| StateProvinceCode | NVARCHAR(5) | no |  |  | Common code for this state or province (such as WA - Washington for the USA) |
| StateProvinceName | NVARCHAR(50) | no |  |  | Formal name of the state or province |
| CountryID | INT | no | [[Application].[Countries].[CountryID]](#applicationcountries) |  | Country for this StateProvince |
| SalesTerritory | NVARCHAR(50) | no |  |  | Sales territory for this StateProvince |
| Border | GEOGRAPHY | yes |  |  | Geographic boundary of the state or province |
| LatestRecordedPopulation | BIGINT | yes |  |  | Latest available population for the StateProvince |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_StateProvinces** | clustered | [StateProvinceID] |  |  |
| UQ_Application_StateProvinces_StateProvinceName | nonclustered | [StateProvinceName] |  |  |
| IX_Application_StateProvinces_SalesTerritory | nonclustered | [SalesTerritory] |  | Index used to quickly locate sales territories |
| FK_Application_StateProvinces_CountryID | nonclustered | [CountryID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Cities].[FK_Application_Cities_StateProvinceID_Application_StateProvinces]](#applicationcities) | foreign key constraint |
| [[Application].[DetermineCustomerAccess]](#applicationdeterminecustomeraccess) | sql inline table valued function |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.StateProvinces_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| StateProvinceID | INT | no |  |  |  |
| StateProvinceCode | NVARCHAR(5) | no |  |  |  |
| StateProvinceName | NVARCHAR(50) | no |  |  |  |
| CountryID | INT | no |  |  |  |
| SalesTerritory | NVARCHAR(50) | no |  |  |  |
| Border | GEOGRAPHY | yes |  |  |  |
| LatestRecordedPopulation | BIGINT | yes |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_StateProvinces_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCityUpdates]](#integrationgetcityupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.SystemParameters

| Description |
| --- |
| Any configurable parameters for the whole system |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **SystemParameterID** | INT | no |  | (NEXT VALUE FOR [Sequences].[SystemParameterID]) | Numeric ID used for row holding system parameters |
| DeliveryAddressLine1 | NVARCHAR(60) | no |  |  | First address line for the company |
| DeliveryAddressLine2 | NVARCHAR(60) | yes |  |  | Second address line for the company |
| DeliveryCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the city for this address |
| DeliveryPostalCode | NVARCHAR(10) | no |  |  | Postal code for the company |
| DeliveryLocation | GEOGRAPHY | no |  |  | Geographic location for the company office |
| PostalAddressLine1 | NVARCHAR(60) | no |  |  | First postal address line for the company |
| PostalAddressLine2 | NVARCHAR(60) | yes |  |  | Second postaladdress line for the company |
| PostalCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the city for this postaladdress |
| PostalPostalCode | NVARCHAR(10) | no |  |  | Postal code for the company when sending via mail |
| ApplicationSettings | NVARCHAR(MAX) | no |  |  | JSON-structured application settings |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_SystemParameters** | clustered | [SystemParameterID] |  |  |
| FK_Application_SystemParameters_PostalCityID | nonclustered | [PostalCityID] |  | Auto-created to support a foreign key |
| FK_Application_SystemParameters_DeliveryCityID | nonclustered | [DeliveryCityID] |  | Auto-created to support a foreign key |

[Back to top](#wideworldimporters)

### Application.TransactionTypes

| Description |
| --- |
| Types of customer, supplier, or stock transactions (ie: invoice, credit note, etc.) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **TransactionTypeID** | INT | no |  | (NEXT VALUE FOR [Sequences].[TransactionTypeID]) | Numeric ID used for reference to a transaction type within the database |
| TransactionTypeName | NVARCHAR(50) | no |  |  | Full name of the transaction type |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Application_TransactionTypes** | clustered | [TransactionTypeID] |  |  |
| UQ_Application_TransactionTypes_TransactionTypeName | nonclustered | [TransactionTypeName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetTransactionTypeUpdates]](#integrationgettransactiontypeupdates) | sql stored procedure |
| [[Purchasing].[SupplierTransactions].[FK_Purchasing_SupplierTransactions_TransactionTypeID_Application_TransactionTypes]](#purchasingsuppliertransactions) | foreign key constraint |
| [[Sales].[CustomerTransactions].[FK_Sales_CustomerTransactions_TransactionTypeID_Application_TransactionTypes]](#salescustomertransactions) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_TransactionTypeID_Application_TransactionTypes]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.TransactionTypes_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| TransactionTypeID | INT | no |  |  |  |
| TransactionTypeName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_TransactionTypes_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetTransactionTypeUpdates]](#integrationgettransactiontypeupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Purchasing.PurchaseOrderLines

| Description |
| --- |
| Detail lines from supplier purchase orders |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **PurchaseOrderLineID** | INT | no |  | (NEXT VALUE FOR [Sequences].[PurchaseOrderLineID]) | Numeric ID used for reference to a line on a purchase order within the database |
| PurchaseOrderID | INT | no | [[Purchasing].[PurchaseOrders].[PurchaseOrderID]](#purchasingpurchaseorders) |  | Purchase order that this line is associated with |
| StockItemID | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | Stock item for this purchase order line |
| OrderedOuters | INT | no |  |  | Quantity of the stock item that is ordered |
| Description | NVARCHAR(100) | no |  |  | Description of the item to be supplied (Often the stock item name but could be supplier description) |
| ReceivedOuters | INT | no |  |  | Total quantity of the stock item that has been received so far |
| PackageTypeID | INT | no | [[Warehouse].[PackageTypes].[PackageTypeID]](#warehousepackagetypes) |  | Type of package received |
| ExpectedUnitPricePerOuter | DECIMAL(18,2) | yes |  |  | The unit price that we expect to be charged |
| LastReceiptDate | DATE | yes |  |  | The last date on which this stock item was received for this purchase order |
| IsOrderLineFinalized | BIT | no |  |  | Is this purchase order line now considered finalized? (Receipted quantities and weights are often not precise) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Purchasing_PurchaseOrderLines** | clustered | [PurchaseOrderLineID] |  |  |
| IX_Purchasing_PurchaseOrderLines_Perf_20160301_4 | nonclustered | [IsOrderLineFinalized], [StockItemID] | [OrderedOuters], [ReceivedOuters] | Improves performance of order picking and invoicing |
| FK_Purchasing_PurchaseOrderLines_StockItemID | nonclustered | [StockItemID] |  | Auto-created to support a foreign key |
| FK_Purchasing_PurchaseOrderLines_PurchaseOrderID | nonclustered | [PurchaseOrderID] |  | Auto-created to support a foreign key |
| FK_Purchasing_PurchaseOrderLines_PackageTypeID | nonclustered | [PackageTypeID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetPurchaseUpdates]](#integrationgetpurchaseupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Purchasing.PurchaseOrders

| Description |
| --- |
| Details of supplier purchase orders |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **PurchaseOrderID** | INT | no |  | (NEXT VALUE FOR [Sequences].[PurchaseOrderID]) | Numeric ID used for reference to a purchase order within the database |
| SupplierID | INT | no | [[Purchasing].[Suppliers].[SupplierID]](#purchasingsuppliers) |  | Supplier for this purchase order |
| OrderDate | DATE | no |  |  | Date that this purchase order was raised |
| DeliveryMethodID | INT | no | [[Application].[DeliveryMethods].[DeliveryMethodID]](#applicationdeliverymethods) |  | How this purchase order should be delivered |
| ContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | The person who is the primary contact for this purchase order |
| ExpectedDeliveryDate | DATE | yes |  |  | Expected delivery date for this purchase order |
| SupplierReference | NVARCHAR(20) | yes |  |  | Supplier reference for our organization (might be our account number at the supplier) |
| IsOrderFinalized | BIT | no |  |  | Is this purchase order now considered finalized? |
| Comments | NVARCHAR(MAX) | yes |  |  | Any comments related this purchase order (comments sent to the supplier) |
| InternalComments | NVARCHAR(MAX) | yes |  |  | Any internal comments related this purchase order (comments for internal reference only and not sent to the supplier) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Purchasing_PurchaseOrders** | clustered | [PurchaseOrderID] |  |  |
| FK_Purchasing_PurchaseOrders_SupplierID | nonclustered | [SupplierID] |  | Auto-created to support a foreign key |
| FK_Purchasing_PurchaseOrders_DeliveryMethodID | nonclustered | [DeliveryMethodID] |  | Auto-created to support a foreign key |
| FK_Purchasing_PurchaseOrders_ContactPersonID | nonclustered | [ContactPersonID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetPurchaseUpdates]](#integrationgetpurchaseupdates) | sql stored procedure |
| [[Purchasing].[PurchaseOrderLines].[FK_Purchasing_PurchaseOrderLines_PurchaseOrderID_Purchasing_PurchaseOrders]](#purchasingpurchaseorderlines) | foreign key constraint |
| [[Purchasing].[SupplierTransactions].[FK_Purchasing_SupplierTransactions_PurchaseOrderID_Purchasing_PurchaseOrders]](#purchasingsuppliertransactions) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_PurchaseOrderID_Purchasing_PurchaseOrders]](#warehousestockitemtransactions) | foreign key constraint |

[Back to top](#wideworldimporters)

### Purchasing.SupplierCategories

| Description |
| --- |
| Categories for suppliers (ie novelties, toys, clothing, packaging, etc.) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **SupplierCategoryID** | INT | no |  | (NEXT VALUE FOR [Sequences].[SupplierCategoryID]) | Numeric ID used for reference to a supplier category within the database |
| SupplierCategoryName | NVARCHAR(50) | no |  |  | Full name of the category that suppliers can be assigned to |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Purchasing_SupplierCategories** | clustered | [SupplierCategoryID] |  |  |
| UQ_Purchasing_SupplierCategories_SupplierCategoryName | nonclustered | [SupplierCategoryName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSupplierUpdates]](#integrationgetsupplierupdates) | sql stored procedure |
| [[Purchasing].[Suppliers].[FK_Purchasing_Suppliers_SupplierCategoryID_Purchasing_SupplierCategories]](#purchasingsuppliers) | foreign key constraint |
| [[Website].[Suppliers]](#websitesuppliers) | view |

[Back to top](#wideworldimporters)

### Purchasing.SupplierCategories_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| SupplierCategoryID | INT | no |  |  |  |
| SupplierCategoryName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_SupplierCategories_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSupplierUpdates]](#integrationgetsupplierupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Purchasing.Suppliers

| Description |
| --- |
| Main entity table for suppliers (organizations) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **SupplierID** | INT | no |  | (NEXT VALUE FOR [Sequences].[SupplierID]) | Numeric ID used for reference to a supplier within the database |
| SupplierName | NVARCHAR(100) | no |  |  | Supplier's full name (usually a trading name) |
| SupplierCategoryID | INT | no | [[Purchasing].[SupplierCategories].[SupplierCategoryID]](#purchasingsuppliercategories) |  | Supplier's category |
| PrimaryContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Primary contact |
| AlternateContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Alternate contact |
| DeliveryMethodID | INT | yes | [[Application].[DeliveryMethods].[DeliveryMethodID]](#applicationdeliverymethods) |  | Standard delivery method for stock items received from this supplier |
| DeliveryCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the delivery city for this address |
| PostalCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the mailing city for this address |
| SupplierReference | NVARCHAR(20) | yes |  |  | Supplier reference for our organization (might be our account number at the supplier) |
| BankAccountName | NVARCHAR(50) | yes |  |  | Supplier's bank account name (ie name on the account) |
| BankAccountBranch | NVARCHAR(50) | yes |  |  | Supplier's bank branch |
| BankAccountCode | NVARCHAR(20) | yes |  |  | Supplier's bank account code (usually a numeric reference for the bank branch) |
| BankAccountNumber | NVARCHAR(20) | yes |  |  | Supplier's bank account number |
| BankInternationalCode | NVARCHAR(20) | yes |  |  | Supplier's bank's international code (such as a SWIFT code) |
| PaymentDays | INT | no |  |  | Number of days for payment of an invoice (ie payment terms) |
| InternalComments | NVARCHAR(MAX) | yes |  |  | Internal comments (not exposed outside organization) |
| PhoneNumber | NVARCHAR(20) | no |  |  | Phone number |
| FaxNumber | NVARCHAR(20) | no |  |  | Fax number   |
| WebsiteURL | NVARCHAR(256) | no |  |  | URL for the website for this supplier |
| DeliveryAddressLine1 | NVARCHAR(60) | no |  |  | First delivery address line for the supplier |
| DeliveryAddressLine2 | NVARCHAR(60) | yes |  |  | Second delivery address line for the supplier |
| DeliveryPostalCode | NVARCHAR(10) | no |  |  | Delivery postal code for the supplier |
| DeliveryLocation | GEOGRAPHY | yes |  |  | Geographic location for the supplier's office/warehouse |
| PostalAddressLine1 | NVARCHAR(60) | no |  |  | First postal address line for the supplier |
| PostalAddressLine2 | NVARCHAR(60) | yes |  |  | Second postal address line for the supplier |
| PostalPostalCode | NVARCHAR(10) | no |  |  | Postal code for the supplier when sending by mail |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Purchasing_Suppliers** | clustered | [SupplierID] |  |  |
| UQ_Purchasing_Suppliers_SupplierName | nonclustered | [SupplierName] |  |  |
| FK_Purchasing_Suppliers_SupplierCategoryID | nonclustered | [SupplierCategoryID] |  | Auto-created to support a foreign key |
| FK_Purchasing_Suppliers_PrimaryContactPersonID | nonclustered | [PrimaryContactPersonID] |  | Auto-created to support a foreign key |
| FK_Purchasing_Suppliers_PostalCityID | nonclustered | [PostalCityID] |  | Auto-created to support a foreign key |
| FK_Purchasing_Suppliers_DeliveryMethodID | nonclustered | [DeliveryMethodID] |  | Auto-created to support a foreign key |
| FK_Purchasing_Suppliers_DeliveryCityID | nonclustered | [DeliveryCityID] |  | Auto-created to support a foreign key |
| FK_Purchasing_Suppliers_AlternateContactPersonID | nonclustered | [AlternateContactPersonID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSupplierUpdates]](#integrationgetsupplierupdates) | sql stored procedure |
| [[Purchasing].[PurchaseOrders].[FK_Purchasing_PurchaseOrders_SupplierID_Purchasing_Suppliers]](#purchasingpurchaseorders) | foreign key constraint |
| [[Purchasing].[SupplierTransactions].[FK_Purchasing_SupplierTransactions_SupplierID_Purchasing_Suppliers]](#purchasingsuppliertransactions) | foreign key constraint |
| [[Warehouse].[StockItems].[FK_Warehouse_StockItems_SupplierID_Purchasing_Suppliers]](#warehousestockitems) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_SupplierID_Purchasing_Suppliers]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[SearchForPeople]](#websitesearchforpeople) | sql stored procedure |
| [[Website].[SearchForSuppliers]](#websitesearchforsuppliers) | sql stored procedure |
| [[Website].[Suppliers]](#websitesuppliers) | view |

[Back to top](#wideworldimporters)

### Purchasing.Suppliers_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| SupplierID | INT | no |  |  |  |
| SupplierName | NVARCHAR(100) | no |  |  |  |
| SupplierCategoryID | INT | no |  |  |  |
| PrimaryContactPersonID | INT | no |  |  |  |
| AlternateContactPersonID | INT | no |  |  |  |
| DeliveryMethodID | INT | yes |  |  |  |
| DeliveryCityID | INT | no |  |  |  |
| PostalCityID | INT | no |  |  |  |
| SupplierReference | NVARCHAR(20) | yes |  |  |  |
| BankAccountName | NVARCHAR(50) | yes |  |  |  |
| BankAccountBranch | NVARCHAR(50) | yes |  |  |  |
| BankAccountCode | NVARCHAR(20) | yes |  |  |  |
| BankAccountNumber | NVARCHAR(20) | yes |  |  |  |
| BankInternationalCode | NVARCHAR(20) | yes |  |  |  |
| PaymentDays | INT | no |  |  |  |
| InternalComments | NVARCHAR(MAX) | yes |  |  |  |
| PhoneNumber | NVARCHAR(20) | no |  |  |  |
| FaxNumber | NVARCHAR(20) | no |  |  |  |
| WebsiteURL | NVARCHAR(256) | no |  |  |  |
| DeliveryAddressLine1 | NVARCHAR(60) | no |  |  |  |
| DeliveryAddressLine2 | NVARCHAR(60) | yes |  |  |  |
| DeliveryPostalCode | NVARCHAR(10) | no |  |  |  |
| DeliveryLocation | GEOGRAPHY | yes |  |  |  |
| PostalAddressLine1 | NVARCHAR(60) | no |  |  |  |
| PostalAddressLine2 | NVARCHAR(60) | yes |  |  |  |
| PostalPostalCode | NVARCHAR(10) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_Suppliers_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSupplierUpdates]](#integrationgetsupplierupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Purchasing.SupplierTransactions

| Description |
| --- |
| All financial transactions that are supplier-related |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **SupplierTransactionID** | INT | no |  | (NEXT VALUE FOR [Sequences].[TransactionID]) | Numeric ID used to refer to a supplier transaction within the database |
| SupplierID | INT | no | [[Purchasing].[Suppliers].[SupplierID]](#purchasingsuppliers) |  | Supplier for this transaction |
| TransactionTypeID | INT | no | [[Application].[TransactionTypes].[TransactionTypeID]](#applicationtransactiontypes) |  | Type of transaction |
| PurchaseOrderID | INT | yes | [[Purchasing].[PurchaseOrders].[PurchaseOrderID]](#purchasingpurchaseorders) |  | ID of an purchase order (for transactions associated with a purchase order) |
| PaymentMethodID | INT | yes | [[Application].[PaymentMethods].[PaymentMethodID]](#applicationpaymentmethods) |  | ID of a payment method (for transactions involving payments) |
| SupplierInvoiceNumber | NVARCHAR(20) | yes |  |  | Invoice number for an invoice received from the supplier |
| TransactionDate | DATE | no |  |  | Date for the transaction |
| AmountExcludingTax | DECIMAL(18,2) | no |  |  | Transaction amount (excluding tax) |
| TaxAmount | DECIMAL(18,2) | no |  |  | Tax amount calculated |
| TransactionAmount | DECIMAL(18,2) | no |  |  | Transaction amount (including tax) |
| OutstandingBalance | DECIMAL(18,2) | no |  |  | Amount still outstanding for this transaction |
| FinalizationDate | DATE | yes |  |  | Date that this transaction was finalized (if it has been) |
| IsFinalized | BIT | yes |  |  | Is this transaction finalized (invoices, credits and payments have been matched) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Purchasing_SupplierTransactions** | nonclustered | [SupplierTransactionID] |  |  |
| IX_Purchasing_SupplierTransactions_IsFinalized | nonclustered | [IsFinalized], [TransactionDate] |  | Index used to quickly locate unfinalized transactions |
| FK_Purchasing_SupplierTransactions_TransactionTypeID | nonclustered | [TransactionTypeID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Purchasing_SupplierTransactions_SupplierID | nonclustered | [SupplierID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Purchasing_SupplierTransactions_PurchaseOrderID | nonclustered | [PurchaseOrderID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Purchasing_SupplierTransactions_PaymentMethodID | nonclustered | [PaymentMethodID], [TransactionDate] |  | Auto-created to support a foreign key |
| CX_Purchasing_SupplierTransactions | clustered | [TransactionDate] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetTransactionUpdates]](#integrationgettransactionupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.BuyingGroups

| Description |
| --- |
| Customer organizations can be part of groups that exert greater buying power |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **BuyingGroupID** | INT | no |  | (NEXT VALUE FOR [Sequences].[BuyingGroupID]) | Numeric ID used for reference to a buying group within the database |
| BuyingGroupName | NVARCHAR(50) | no |  |  | Full name of a buying group that customers can be members of |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_BuyingGroups** | clustered | [BuyingGroupID] |  |  |
| UQ_Sales_BuyingGroups_BuyingGroupName | nonclustered | [BuyingGroupName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |
| [[Sales].[Customers].[FK_Sales_Customers_BuyingGroupID_Sales_BuyingGroups]](#salescustomers) | foreign key constraint |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_BuyingGroupID_Sales_BuyingGroups]](#salesspecialdeals) | foreign key constraint |
| [[Website].[Customers]](#websitecustomers) | view |

[Back to top](#wideworldimporters)

### Sales.BuyingGroups_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| BuyingGroupID | INT | no |  |  |  |
| BuyingGroupName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_BuyingGroups_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.CustomerCategories

| Description |
| --- |
| Categories for customers (ie restaurants, cafes, supermarkets, etc.) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **CustomerCategoryID** | INT | no |  | (NEXT VALUE FOR [Sequences].[CustomerCategoryID]) | Numeric ID used for reference to a customer category within the database |
| CustomerCategoryName | NVARCHAR(50) | no |  |  | Full name of the category that customers can be assigned to |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_CustomerCategories** | clustered | [CustomerCategoryID] |  |  |
| UQ_Sales_CustomerCategories_CustomerCategoryName | nonclustered | [CustomerCategoryName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |
| [[Sales].[Customers].[FK_Sales_Customers_CustomerCategoryID_Sales_CustomerCategories]](#salescustomers) | foreign key constraint |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_CustomerCategoryID_Sales_CustomerCategories]](#salesspecialdeals) | foreign key constraint |
| [[Website].[Customers]](#websitecustomers) | view |

[Back to top](#wideworldimporters)

### Sales.CustomerCategories_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| CustomerCategoryID | INT | no |  |  |  |
| CustomerCategoryName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_CustomerCategories_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.Customers

| Description |
| --- |
| Main entity tables for customers (organizations or individuals) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **CustomerID** | INT | no |  | (NEXT VALUE FOR [Sequences].[CustomerID]) | Numeric ID used for reference to a customer within the database |
| CustomerName | NVARCHAR(100) | no |  |  | Customer's full name (usually a trading name) |
| BillToCustomerID | INT | no | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Customer that this is billed to (usually the same customer but can be another parent company) |
| CustomerCategoryID | INT | no | [[Sales].[CustomerCategories].[CustomerCategoryID]](#salescustomercategories) |  | Customer's category |
| BuyingGroupID | INT | yes | [[Sales].[BuyingGroups].[BuyingGroupID]](#salesbuyinggroups) |  | Customer's buying group (optional) |
| PrimaryContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Primary contact |
| AlternateContactPersonID | INT | yes | [[Application].[People].[PersonID]](#applicationpeople) |  | Alternate contact |
| DeliveryMethodID | INT | no | [[Application].[DeliveryMethods].[DeliveryMethodID]](#applicationdeliverymethods) |  | Standard delivery method for stock items sent to this customer |
| DeliveryCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the delivery city for this address |
| PostalCityID | INT | no | [[Application].[Cities].[CityID]](#applicationcities) |  | ID of the postal city for this address |
| CreditLimit | DECIMAL(18,2) | yes |  |  | Credit limit for this customer (NULL if unlimited) |
| AccountOpenedDate | DATE | no |  |  | Date this customer account was opened |
| StandardDiscountPercentage | DECIMAL(18,3) | no |  |  | Standard discount offered to this customer |
| IsStatementSent | BIT | no |  |  | Is a statement sent to this customer? (Or do they just pay on each invoice?) |
| IsOnCreditHold | BIT | no |  |  | Is this customer on credit hold? (Prevents further deliveries to this customer) |
| PaymentDays | INT | no |  |  | Number of days for payment of an invoice (ie payment terms) |
| PhoneNumber | NVARCHAR(20) | no |  |  | Phone number |
| FaxNumber | NVARCHAR(20) | no |  |  | Fax number   |
| DeliveryRun | NVARCHAR(5) | yes |  |  | Normal delivery run for this customer |
| RunPosition | NVARCHAR(5) | yes |  |  | Normal position in the delivery run for this customer |
| WebsiteURL | NVARCHAR(256) | no |  |  | URL for the website for this customer |
| DeliveryAddressLine1 | NVARCHAR(60) | no |  |  | First delivery address line for the customer |
| DeliveryAddressLine2 | NVARCHAR(60) | yes |  |  | Second delivery address line for the customer |
| DeliveryPostalCode | NVARCHAR(10) | no |  |  | Delivery postal code for the customer |
| DeliveryLocation | GEOGRAPHY | yes |  |  | Geographic location for the customer's office/warehouse |
| PostalAddressLine1 | NVARCHAR(60) | no |  |  | First postal address line for the customer |
| PostalAddressLine2 | NVARCHAR(60) | yes |  |  | Second postal address line for the customer |
| PostalPostalCode | NVARCHAR(10) | no |  |  | Postal code for the customer when sending by mail |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_Customers** | clustered | [CustomerID] |  |  |
| UQ_Sales_Customers_CustomerName | nonclustered | [CustomerName] |  |  |
| IX_Sales_Customers_Perf_20160301_06 | nonclustered | [IsOnCreditHold], [CustomerID], [BillToCustomerID] | [PrimaryContactPersonID] | Improves performance of order picking and invoicing |
| FK_Sales_Customers_PrimaryContactPersonID | nonclustered | [PrimaryContactPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_PostalCityID | nonclustered | [PostalCityID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_DeliveryMethodID | nonclustered | [DeliveryMethodID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_DeliveryCityID | nonclustered | [DeliveryCityID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_CustomerCategoryID | nonclustered | [CustomerCategoryID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_BuyingGroupID | nonclustered | [BuyingGroupID] |  | Auto-created to support a foreign key |
| FK_Sales_Customers_AlternateContactPersonID | nonclustered | [AlternateContactPersonID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[FilterCustomersBySalesTerritoryRole]](#applicationfiltercustomersbysalesterritoryrole) | security policy |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |
| [[Integration].[GetOrderUpdates]](#integrationgetorderupdates) | sql stored procedure |
| [[Integration].[GetSaleUpdates]](#integrationgetsaleupdates) | sql stored procedure |
| [[Sales].[Customers].[FK_Sales_Customers_BillToCustomerID_Sales_Customers]](#salescustomers) | foreign key constraint |
| [[Sales].[CustomerTransactions].[FK_Sales_CustomerTransactions_CustomerID_Sales_Customers]](#salescustomertransactions) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_BillToCustomerID_Sales_Customers]](#salesinvoices) | foreign key constraint |
| [[Sales].[Invoices].[FK_Sales_Invoices_CustomerID_Sales_Customers]](#salesinvoices) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_CustomerID_Sales_Customers]](#salesorders) | foreign key constraint |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_CustomerID_Sales_Customers]](#salesspecialdeals) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_CustomerID_Sales_Customers]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[CalculateCustomerPrice]](#websitecalculatecustomerprice) | sql scalar function |
| [[Website].[Customers]](#websitecustomers) | view |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |
| [[Website].[SearchForCustomers]](#websitesearchforcustomers) | sql stored procedure |
| [[Website].[SearchForPeople]](#websitesearchforpeople) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.Customers_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| CustomerID | INT | no |  |  |  |
| CustomerName | NVARCHAR(100) | no |  |  |  |
| BillToCustomerID | INT | no |  |  |  |
| CustomerCategoryID | INT | no |  |  |  |
| BuyingGroupID | INT | yes |  |  |  |
| PrimaryContactPersonID | INT | no |  |  |  |
| AlternateContactPersonID | INT | yes |  |  |  |
| DeliveryMethodID | INT | no |  |  |  |
| DeliveryCityID | INT | no |  |  |  |
| PostalCityID | INT | no |  |  |  |
| CreditLimit | DECIMAL(18,2) | yes |  |  |  |
| AccountOpenedDate | DATE | no |  |  |  |
| StandardDiscountPercentage | DECIMAL(18,3) | no |  |  |  |
| IsStatementSent | BIT | no |  |  |  |
| IsOnCreditHold | BIT | no |  |  |  |
| PaymentDays | INT | no |  |  |  |
| PhoneNumber | NVARCHAR(20) | no |  |  |  |
| FaxNumber | NVARCHAR(20) | no |  |  |  |
| DeliveryRun | NVARCHAR(5) | yes |  |  |  |
| RunPosition | NVARCHAR(5) | yes |  |  |  |
| WebsiteURL | NVARCHAR(256) | no |  |  |  |
| DeliveryAddressLine1 | NVARCHAR(60) | no |  |  |  |
| DeliveryAddressLine2 | NVARCHAR(60) | yes |  |  |  |
| DeliveryPostalCode | NVARCHAR(10) | no |  |  |  |
| DeliveryLocation | GEOGRAPHY | yes |  |  |  |
| PostalAddressLine1 | NVARCHAR(60) | no |  |  |  |
| PostalAddressLine2 | NVARCHAR(60) | yes |  |  |  |
| PostalPostalCode | NVARCHAR(10) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_Customers_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetCustomerUpdates]](#integrationgetcustomerupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.CustomerTransactions

| Description |
| --- |
| All financial transactions that are customer-related |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **CustomerTransactionID** | INT | no |  | (NEXT VALUE FOR [Sequences].[TransactionID]) | Numeric ID used to refer to a customer transaction within the database |
| CustomerID | INT | no | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Customer for this transaction |
| TransactionTypeID | INT | no | [[Application].[TransactionTypes].[TransactionTypeID]](#applicationtransactiontypes) |  | Type of transaction |
| InvoiceID | INT | yes | [[Sales].[Invoices].[InvoiceID]](#salesinvoices) |  | ID of an invoice (for transactions associated with an invoice) |
| PaymentMethodID | INT | yes | [[Application].[PaymentMethods].[PaymentMethodID]](#applicationpaymentmethods) |  | ID of a payment method (for transactions involving payments) |
| TransactionDate | DATE | no |  |  | Date for the transaction |
| AmountExcludingTax | DECIMAL(18,2) | no |  |  | Transaction amount (excluding tax) |
| TaxAmount | DECIMAL(18,2) | no |  |  | Tax amount calculated |
| TransactionAmount | DECIMAL(18,2) | no |  |  | Transaction amount (including tax) |
| OutstandingBalance | DECIMAL(18,2) | no |  |  | Amount still outstanding for this transaction |
| FinalizationDate | DATE | yes |  |  | Date that this transaction was finalized (if it has been) |
| IsFinalized | BIT | yes |  |  | Is this transaction finalized (invoices, credits and payments have been matched) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_CustomerTransactions** | nonclustered | [CustomerTransactionID] |  |  |
| IX_Sales_CustomerTransactions_IsFinalized | nonclustered | [IsFinalized], [TransactionDate] |  | Allows quick location of unfinalized transactions |
| FK_Sales_CustomerTransactions_TransactionTypeID | nonclustered | [TransactionTypeID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Sales_CustomerTransactions_PaymentMethodID | nonclustered | [PaymentMethodID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Sales_CustomerTransactions_InvoiceID | nonclustered | [InvoiceID], [TransactionDate] |  | Auto-created to support a foreign key |
| FK_Sales_CustomerTransactions_CustomerID | nonclustered | [CustomerID], [TransactionDate] |  | Auto-created to support a foreign key |
| CX_Sales_CustomerTransactions | clustered | [TransactionDate] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetTransactionUpdates]](#integrationgettransactionupdates) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.InvoiceLines

| Description |
| --- |
| Detail lines from customer invoices |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **InvoiceLineID** | INT | no |  | (NEXT VALUE FOR [Sequences].[InvoiceLineID]) | Numeric ID used for reference to a line on an invoice within the database |
| InvoiceID | INT | no | [[Sales].[Invoices].[InvoiceID]](#salesinvoices) |  | Invoice that this line is associated with |
| StockItemID | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | Stock item for this invoice line |
| Description | NVARCHAR(100) | no |  |  | Description of the item supplied (Usually the stock item name but can be overridden) |
| PackageTypeID | INT | no | [[Warehouse].[PackageTypes].[PackageTypeID]](#warehousepackagetypes) |  | Type of package supplied |
| Quantity | INT | no |  |  | Quantity supplied |
| UnitPrice | DECIMAL(18,2) | yes |  |  | Unit price charged |
| TaxRate | DECIMAL(18,3) | no |  |  | Tax rate to be applied |
| TaxAmount | DECIMAL(18,2) | no |  |  | Tax amount calculated |
| LineProfit | DECIMAL(18,2) | no |  |  | Profit made on this line item at current cost price |
| ExtendedPrice | DECIMAL(18,2) | no |  |  | Extended line price charged |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_InvoiceLines** | clustered | [InvoiceLineID] |  |  |
| NCCX_Sales_InvoiceLines | nonclustered columnstore |  | [InvoiceID], [StockItemID], [Quantity], [UnitPrice], [LineProfit], [LastEditedWhen] |  |
| FK_Sales_InvoiceLines_StockItemID | nonclustered | [StockItemID] |  | Auto-created to support a foreign key |
| FK_Sales_InvoiceLines_PackageTypeID | nonclustered | [PackageTypeID] |  | Auto-created to support a foreign key |
| FK_Sales_InvoiceLines_InvoiceID | nonclustered | [InvoiceID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSaleUpdates]](#integrationgetsaleupdates) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.Invoices

| Description |
| --- |
| Details of customer invoices |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **InvoiceID** | INT | no |  | (NEXT VALUE FOR [Sequences].[InvoiceID]) | Numeric ID used for reference to an invoice within the database |
| CustomerID | INT | no | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Customer for this invoice |
| BillToCustomerID | INT | no | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Bill to customer for this invoice (invoices might be billed to a head office) |
| OrderID | INT | yes | [[Sales].[Orders].[OrderID]](#salesorders) |  | Sales order (if any) for this invoice |
| DeliveryMethodID | INT | no | [[Application].[DeliveryMethods].[DeliveryMethodID]](#applicationdeliverymethods) |  | How these stock items are beign delivered |
| ContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Customer contact for this invoice |
| AccountsPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Customer accounts contact for this invoice |
| SalespersonPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Salesperson for this invoice |
| PackedByPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Person who packed this shipment (or checked the packing) |
| InvoiceDate | DATE | no |  |  | Date that this invoice was raised |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | yes |  |  | Purchase Order Number received from customer |
| IsCreditNote | BIT | no |  |  | Is this a credit note (rather than an invoice) |
| CreditNoteReason | NVARCHAR(MAX) | yes |  |  | Reason that this credit note needed to be generated (if applicable) |
| Comments | NVARCHAR(MAX) | yes |  |  | Any comments related to this invoice (sent to customer) |
| DeliveryInstructions | NVARCHAR(MAX) | yes |  |  | Any comments related to delivery (sent to customer) |
| InternalComments | NVARCHAR(MAX) | yes |  |  | Any internal comments related to this invoice (not sent to the customer) |
| TotalDryItems | INT | no |  |  | Total number of dry packages (information for the delivery driver) |
| TotalChillerItems | INT | no |  |  | Total number of chiller packages (information for the delivery driver) |
| DeliveryRun | NVARCHAR(5) | yes |  |  | Delivery run for this shipment |
| RunPosition | NVARCHAR(5) | yes |  |  | Position in the delivery run for this shipment |
| ReturnedDeliveryData | NVARCHAR(MAX) | yes |  |  | JSON-structured data returned from delivery devices for deliveries made directly by the organization |
| ConfirmedDeliveryTime | DATETIME2(7) | yes |  |  | Confirmed delivery date and time promoted from JSON delivery data |
| ConfirmedReceivedBy | NVARCHAR(4000) | yes |  |  | Confirmed receiver promoted from JSON delivery data |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_Invoices** | clustered | [InvoiceID] |  |  |
| IX_Sales_Invoices_ConfirmedDeliveryTime | nonclustered | [ConfirmedDeliveryTime] | [ConfirmedReceivedBy] | Allows quick retrieval of invoices confirmed to have been delivered in a given time period |
| FK_Sales_Invoices_SalespersonPersonID | nonclustered | [SalespersonPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_PackedByPersonID | nonclustered | [PackedByPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_OrderID | nonclustered | [OrderID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_DeliveryMethodID | nonclustered | [DeliveryMethodID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_CustomerID | nonclustered | [CustomerID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_ContactPersonID | nonclustered | [ContactPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_BillToCustomerID | nonclustered | [BillToCustomerID] |  | Auto-created to support a foreign key |
| FK_Sales_Invoices_AccountsPersonID | nonclustered | [AccountsPersonID] |  | Auto-created to support a foreign key |

#### Check Constraints

##### Sales.CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON

###### Definition

<details><summary>Click to expand</summary>

```sql
([ReturnedDeliveryData] IS NULL OR isjson([ReturnedDeliveryData])<>(0))
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetSaleUpdates]](#integrationgetsaleupdates) | sql stored procedure |
| [[Integration].[GetTransactionUpdates]](#integrationgettransactionupdates) | sql stored procedure |
| [[Sales].[CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON]](#salesck_sales_invoices_returneddeliverydata_must_be_valid_json) | check constraint |
| [[Sales].[CustomerTransactions].[FK_Sales_CustomerTransactions_InvoiceID_Sales_Invoices]](#salescustomertransactions) | foreign key constraint |
| [[Sales].[InvoiceLines].[FK_Sales_InvoiceLines_InvoiceID_Sales_Invoices]](#salesinvoicelines) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_InvoiceID_Sales_Invoices]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.OrderLines

| Description |
| --- |
| Detail lines from customer orders |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **OrderLineID** | INT | no |  | (NEXT VALUE FOR [Sequences].[OrderLineID]) | Numeric ID used for reference to a line on an Order within the database |
| OrderID | INT | no | [[Sales].[Orders].[OrderID]](#salesorders) |  | Order that this line is associated with |
| StockItemID | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | Stock item for this order line (FK not indexed as separate index exists) |
| Description | NVARCHAR(100) | no |  |  | Description of the item supplied (Usually the stock item name but can be overridden) |
| PackageTypeID | INT | no | [[Warehouse].[PackageTypes].[PackageTypeID]](#warehousepackagetypes) |  | Type of package to be supplied |
| Quantity | INT | no |  |  | Quantity to be supplied |
| UnitPrice | DECIMAL(18,2) | yes |  |  | Unit price to be charged |
| TaxRate | DECIMAL(18,3) | no |  |  | Tax rate to be applied |
| PickedQuantity | INT | no |  |  | Quantity picked from stock |
| PickingCompletedWhen | DATETIME2(7) | yes |  |  | When was picking of this line completed? |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_OrderLines** | clustered | [OrderLineID] |  |  |
| NCCX_Sales_OrderLines | nonclustered columnstore |  | [OrderID], [StockItemID], [Description], [Quantity], [UnitPrice], [PickedQuantity] |  |
| IX_Sales_OrderLines_Perf_20160301_02 | nonclustered | [StockItemID], [PickingCompletedWhen] | [OrderID], [PickedQuantity] | Improves performance of order picking and invoicing |
| IX_Sales_OrderLines_Perf_20160301_01 | nonclustered | [PickingCompletedWhen], [OrderID], [OrderLineID] | [Quantity], [StockItemID] | Improves performance of order picking and invoicing |
| IX_Sales_OrderLines_AllocatedStockItems | nonclustered | [StockItemID] | [PickedQuantity] | Allows quick summation of stock item quantites already allocated to uninvoiced orders |
| FK_Sales_OrderLines_PackageTypeID | nonclustered | [PackageTypeID] |  | Auto-created to support a foreign key |
| FK_Sales_OrderLines_OrderID | nonclustered | [OrderID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetOrderUpdates]](#integrationgetorderupdates) | sql stored procedure |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.Orders

| Description |
| --- |
| Detail of customer orders |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **OrderID** | INT | no |  | (NEXT VALUE FOR [Sequences].[OrderID]) | Numeric ID used for reference to an order within the database |
| CustomerID | INT | no | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Customer for this order |
| SalespersonPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Salesperson for this order |
| PickedByPersonID | INT | yes | [[Application].[People].[PersonID]](#applicationpeople) |  | Person who picked this shipment |
| ContactPersonID | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  | Customer contact for this order |
| BackorderOrderID | INT | yes | [[Sales].[Orders].[OrderID]](#salesorders) |  | If this order is a backorder, this column holds the original order number |
| OrderDate | DATE | no |  |  | Date that this order was raised |
| ExpectedDeliveryDate | DATE | no |  |  | Expected delivery date |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | yes |  |  | Purchase Order Number received from customer |
| IsUndersupplyBackordered | BIT | no |  |  | If items cannot be supplied are they backordered? |
| Comments | NVARCHAR(MAX) | yes |  |  | Any comments related to this order (sent to customer) |
| DeliveryInstructions | NVARCHAR(MAX) | yes |  |  | Any comments related to order delivery (sent to customer) |
| InternalComments | NVARCHAR(MAX) | yes |  |  | Any internal comments related to this order (not sent to the customer) |
| PickingCompletedWhen | DATETIME2(7) | yes |  |  | When was picking of the entire order completed? |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_Orders** | clustered | [OrderID] |  |  |
| FK_Sales_Orders_SalespersonPersonID | nonclustered | [SalespersonPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Orders_PickedByPersonID | nonclustered | [PickedByPersonID] |  | Auto-created to support a foreign key |
| FK_Sales_Orders_CustomerID | nonclustered | [CustomerID] |  | Auto-created to support a foreign key |
| FK_Sales_Orders_ContactPersonID | nonclustered | [ContactPersonID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[PopulateDataToCurrentDate]](#dataloadsimulationpopulatedatatocurrentdate) | sql stored procedure |
| [[Integration].[GetOrderUpdates]](#integrationgetorderupdates) | sql stored procedure |
| [[Sales].[Invoices].[FK_Sales_Invoices_OrderID_Sales_Orders]](#salesinvoices) | foreign key constraint |
| [[Sales].[OrderLines].[FK_Sales_OrderLines_OrderID_Sales_Orders]](#salesorderlines) | foreign key constraint |
| [[Sales].[Orders].[FK_Sales_Orders_BackorderOrderID_Sales_Orders]](#salesorders) | foreign key constraint |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Sales.SpecialDeals

| Description |
| --- |
| Special pricing (can include fixed prices, discount $ or discount %) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **SpecialDealID** | INT | no |  | (NEXT VALUE FOR [Sequences].[SpecialDealID]) | ID (sequence based) for a special deal |
| StockItemID | INT | yes | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | Stock item that the deal applies to (if NULL, then only discounts are permitted not unit prices) |
| CustomerID | INT | yes | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | ID of the customer that the special pricing applies to (if NULL then all customers) |
| BuyingGroupID | INT | yes | [[Sales].[BuyingGroups].[BuyingGroupID]](#salesbuyinggroups) |  | ID of the buying group that the special pricing applies to (optional) |
| CustomerCategoryID | INT | yes | [[Sales].[CustomerCategories].[CustomerCategoryID]](#salescustomercategories) |  | ID of the customer category that the special pricing applies to (optional) |
| StockGroupID | INT | yes | [[Warehouse].[StockGroups].[StockGroupID]](#warehousestockgroups) |  | ID of the stock group that the special pricing applies to (optional) |
| DealDescription | NVARCHAR(30) | no |  |  | Description of the special deal |
| StartDate | DATE | no |  |  | Date that the special pricing starts from |
| EndDate | DATE | no |  |  | Date that the special pricing ends on |
| DiscountAmount | DECIMAL(18,2) | yes |  |  | Discount per unit to be applied to sale price (optional) |
| DiscountPercentage | DECIMAL(18,3) | yes |  |  | Discount percentage per unit to be applied to sale price (optional) |
| UnitPrice | DECIMAL(18,2) | yes |  |  | Special price per unit to be applied instead of sale price (optional) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Sales_SpecialDeals** | clustered | [SpecialDealID] |  |  |
| FK_Sales_SpecialDeals_StockItemID | nonclustered | [StockItemID] |  | Auto-created to support a foreign key |
| FK_Sales_SpecialDeals_StockGroupID | nonclustered | [StockGroupID] |  | Auto-created to support a foreign key |
| FK_Sales_SpecialDeals_CustomerID | nonclustered | [CustomerID] |  | Auto-created to support a foreign key |
| FK_Sales_SpecialDeals_CustomerCategoryID | nonclustered | [CustomerCategoryID] |  | Auto-created to support a foreign key |
| FK_Sales_SpecialDeals_BuyingGroupID | nonclustered | [BuyingGroupID] |  | Auto-created to support a foreign key |

#### Check Constraints

##### Sales.CK_Sales_SpecialDeals_Exactly_One_NOT_NULL_Pricing_Option_Is_Required

###### Definition

<details><summary>Click to expand</summary>

```sql
(((case when [DiscountAmount] IS NULL then (0) else (1) end+case when [DiscountPercentage] IS NULL then (0) else (1) end)+case when [UnitPrice] IS NULL then (0) else (1) end)=(1))
```

</details>

##### Sales.CK_Sales_SpecialDeals_Unit_Price_Deal_Requires_Special_StockItem

###### Definition

<details><summary>Click to expand</summary>

```sql
([StockItemID] IS NOT NULL AND [UnitPrice] IS NOT NULL OR [UnitPrice] IS NULL)
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Sales].[CK_Sales_SpecialDeals_Exactly_One_NOT_NULL_Pricing_Option_Is_Required]](#salesck_sales_specialdeals_exactly_one_not_null_pricing_option_is_required) | check constraint |
| [[Sales].[CK_Sales_SpecialDeals_Unit_Price_Deal_Requires_Special_StockItem]](#salesck_sales_specialdeals_unit_price_deal_requires_special_stockitem) | check constraint |
| [[Website].[CalculateCustomerPrice]](#websitecalculatecustomerprice) | sql scalar function |

[Back to top](#wideworldimporters)

### Warehouse.ColdRoomTemperatures

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **ColdRoomTemperatureID** | BIGINT | no |  |  |  |
| ColdRoomSensorNumber | INT | no |  |  |  |
| RecordedWhen | DATETIME2(7) | no |  |  |  |
| Temperature | DECIMAL(10,2) | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_ColdRoomTemperatures** | nonclustered | [ColdRoomTemperatureID] |  |  |
| IX_Warehouse_ColdRoomTemperatures_ColdRoomSensorNumber | nonclustered | [ColdRoomSensorNumber] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[RecordColdRoomTemperatures]](#websiterecordcoldroomtemperatures) | sql stored procedure |

[Back to top](#wideworldimporters)

### Warehouse.ColdRoomTemperatures_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| ColdRoomTemperatureID | BIGINT | no |  |  |  |
| ColdRoomSensorNumber | INT | no |  |  |  |
| RecordedWhen | DATETIME2(7) | no |  |  |  |
| Temperature | DECIMAL(10,2) | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_ColdRoomTemperatures_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

[Back to top](#wideworldimporters)

### Warehouse.Colors

| Description |
| --- |
| Stock items can (optionally) have colors |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **ColorID** | INT | no |  | (NEXT VALUE FOR [Sequences].[ColorID]) | Numeric ID used for reference to a color within the database |
| ColorName | NVARCHAR(20) | no |  |  | Full name of a color that can be used to describe stock items |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_Colors** | clustered | [ColorID] |  |  |
| UQ_Warehouse_Colors_ColorName | nonclustered | [ColorName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetStockItemUpdates]](#integrationgetstockitemupdates) | sql stored procedure |
| [[Warehouse].[StockItems].[FK_Warehouse_StockItems_ColorID_Warehouse_Colors]](#warehousestockitems) | foreign key constraint |

[Back to top](#wideworldimporters)

### Warehouse.Colors_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| ColorID | INT | no |  |  |  |
| ColorName | NVARCHAR(20) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_Colors_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

[Back to top](#wideworldimporters)

### Warehouse.PackageTypes

| Description |
| --- |
| Ways that stock items can be packaged (ie: each, box, carton, pallet, kg, etc. |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **PackageTypeID** | INT | no |  | (NEXT VALUE FOR [Sequences].[PackageTypeID]) | Numeric ID used for reference to a package type within the database |
| PackageTypeName | NVARCHAR(50) | no |  |  | Full name of package types that stock items can be purchased in or sold in |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_PackageTypes** | clustered | [PackageTypeID] |  |  |
| UQ_Warehouse_PackageTypes_PackageTypeName | nonclustered | [PackageTypeName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetOrderUpdates]](#integrationgetorderupdates) | sql stored procedure |
| [[Integration].[GetPurchaseUpdates]](#integrationgetpurchaseupdates) | sql stored procedure |
| [[Integration].[GetSaleUpdates]](#integrationgetsaleupdates) | sql stored procedure |
| [[Integration].[GetStockItemUpdates]](#integrationgetstockitemupdates) | sql stored procedure |
| [[Purchasing].[PurchaseOrderLines].[FK_Purchasing_PurchaseOrderLines_PackageTypeID_Warehouse_PackageTypes]](#purchasingpurchaseorderlines) | foreign key constraint |
| [[Sales].[InvoiceLines].[FK_Sales_InvoiceLines_PackageTypeID_Warehouse_PackageTypes]](#salesinvoicelines) | foreign key constraint |
| [[Sales].[OrderLines].[FK_Sales_OrderLines_PackageTypeID_Warehouse_PackageTypes]](#salesorderlines) | foreign key constraint |
| [[Warehouse].[StockItems].[FK_Warehouse_StockItems_OuterPackageID_Warehouse_PackageTypes]](#warehousestockitems) | foreign key constraint |
| [[Warehouse].[StockItems].[FK_Warehouse_StockItems_UnitPackageID_Warehouse_PackageTypes]](#warehousestockitems) | foreign key constraint |

[Back to top](#wideworldimporters)

### Warehouse.PackageTypes_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| PackageTypeID | INT | no |  |  |  |
| PackageTypeName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_PackageTypes_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

[Back to top](#wideworldimporters)

### Warehouse.StockGroups

| Description |
| --- |
| Groups for categorizing stock items (ie: novelties, toys, edible novelties, etc.) |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StockGroupID** | INT | no |  | (NEXT VALUE FOR [Sequences].[StockGroupID]) | Numeric ID used for reference to a stock group within the database |
| StockGroupName | NVARCHAR(50) | no |  |  | Full name of groups used to categorize stock items |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_StockGroups** | clustered | [StockGroupID] |  |  |
| UQ_Warehouse_StockGroups_StockGroupName | nonclustered | [StockGroupName] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_StockGroupID_Warehouse_StockGroups]](#salesspecialdeals) | foreign key constraint |
| [[Warehouse].[StockItemStockGroups].[FK_Warehouse_StockItemStockGroups_StockGroupID_Warehouse_StockGroups]](#warehousestockitemstockgroups) | foreign key constraint |

[Back to top](#wideworldimporters)

### Warehouse.StockGroups_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| StockGroupID | INT | no |  |  |  |
| StockGroupName | NVARCHAR(50) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_StockGroups_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

[Back to top](#wideworldimporters)

### Warehouse.StockItemHoldings

| Description |
| --- |
| Non-temporal attributes for stock items |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StockItemID** | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | ID of the stock item that this holding relates to (this table holds non-temporal columns for stock) |
| QuantityOnHand | INT | no |  |  | Quantity currently on hand (if tracked) |
| BinLocation | NVARCHAR(20) | no |  |  | Bin location (ie location of this stock item within the depot) |
| LastStocktakeQuantity | INT | no |  |  | Quantity at last stocktake (if tracked) |
| LastCostPrice | DECIMAL(18,2) | no |  |  | Unit cost price the last time this stock item was purchased |
| ReorderLevel | INT | no |  |  | Quantity below which reordering should take place |
| TargetStockLevel | INT | no |  |  | Typical quantity ordered |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_StockItemHoldings** | clustered | [StockItemID] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetStockHoldingUpdates]](#integrationgetstockholdingupdates) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Warehouse.StockItems

| Description |
| --- |
| Main entity table for stock items |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StockItemID** | INT | no |  | (NEXT VALUE FOR [Sequences].[StockItemID]) | Numeric ID used for reference to a stock item within the database |
| StockItemName | NVARCHAR(100) | no |  |  | Full name of a stock item (but not a full description) |
| SupplierID | INT | no | [[Purchasing].[Suppliers].[SupplierID]](#purchasingsuppliers) |  | Usual supplier for this stock item |
| ColorID | INT | yes | [[Warehouse].[Colors].[ColorID]](#warehousecolors) |  | Color (optional) for this stock item |
| UnitPackageID | INT | no | [[Warehouse].[PackageTypes].[PackageTypeID]](#warehousepackagetypes) |  | Usual package for selling units of this stock item |
| OuterPackageID | INT | no | [[Warehouse].[PackageTypes].[PackageTypeID]](#warehousepackagetypes) |  | Usual package for selling outers of this stock item (ie cartons, boxes, etc.) |
| Brand | NVARCHAR(50) | yes |  |  | Brand for the stock item (if the item is branded) |
| Size | NVARCHAR(20) | yes |  |  | Size of this item (eg: 100mm) |
| LeadTimeDays | INT | no |  |  | Number of days typically taken from order to receipt of this stock item |
| QuantityPerOuter | INT | no |  |  | Quantity of the stock item in an outer package |
| IsChillerStock | BIT | no |  |  | Does this stock item need to be in a chiller? |
| Barcode | NVARCHAR(50) | yes |  |  | Barcode for this stock item |
| TaxRate | DECIMAL(18,3) | no |  |  | Tax rate to be applied |
| UnitPrice | DECIMAL(18,2) | no |  |  | Selling price (ex-tax) for one unit of this product |
| RecommendedRetailPrice | DECIMAL(18,2) | yes |  |  | Recommended retail price for this stock item |
| TypicalWeightPerUnit | DECIMAL(18,3) | no |  |  | Typical weight for one unit of this product (packaged) |
| MarketingComments | NVARCHAR(MAX) | yes |  |  | Marketing comments for this stock item (shared outside the organization) |
| InternalComments | NVARCHAR(MAX) | yes |  |  | Internal comments (not exposed outside organization) |
| Photo | VARBINARY(MAX) | yes |  |  | Photo of the product |
| CustomFields | NVARCHAR(MAX) | yes |  |  | Custom fields added by system users |
| Tags | NVARCHAR(MAX) | yes |  |  | Advertising tags associated with this stock item (JSON array retrieved from CustomFields) |
| SearchDetails | NVARCHAR(MAX) | no |  |  | Combination of columns used by full text search |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_StockItems** | clustered | [StockItemID] |  |  |
| UQ_Warehouse_StockItems_StockItemName | nonclustered | [StockItemName] |  |  |
| FK_Warehouse_StockItems_UnitPackageID | nonclustered | [UnitPackageID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItems_SupplierID | nonclustered | [SupplierID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItems_OuterPackageID | nonclustered | [OuterPackageID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItems_ColorID | nonclustered | [ColorID] |  | Auto-created to support a foreign key |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetPurchaseUpdates]](#integrationgetpurchaseupdates) | sql stored procedure |
| [[Integration].[GetSaleUpdates]](#integrationgetsaleupdates) | sql stored procedure |
| [[Integration].[GetStockItemUpdates]](#integrationgetstockitemupdates) | sql stored procedure |
| [[Purchasing].[PurchaseOrderLines].[FK_Purchasing_PurchaseOrderLines_StockItemID_Warehouse_StockItems]](#purchasingpurchaseorderlines) | foreign key constraint |
| [[Sales].[InvoiceLines].[FK_Sales_InvoiceLines_StockItemID_Warehouse_StockItems]](#salesinvoicelines) | foreign key constraint |
| [[Sales].[OrderLines].[FK_Sales_OrderLines_StockItemID_Warehouse_StockItems]](#salesorderlines) | foreign key constraint |
| [[Sales].[SpecialDeals].[FK_Sales_SpecialDeals_StockItemID_Warehouse_StockItems]](#salesspecialdeals) | foreign key constraint |
| [[Warehouse].[StockItemHoldings].[PKFK_Warehouse_StockItemHoldings_StockItemID_Warehouse_StockItems]](#warehousestockitemholdings) | foreign key constraint |
| [[Warehouse].[StockItemStockGroups].[FK_Warehouse_StockItemStockGroups_StockItemID_Warehouse_StockItems]](#warehousestockitemstockgroups) | foreign key constraint |
| [[Warehouse].[StockItemTransactions].[FK_Warehouse_StockItemTransactions_StockItemID_Warehouse_StockItems]](#warehousestockitemtransactions) | foreign key constraint |
| [[Website].[CalculateCustomerPrice]](#websitecalculatecustomerprice) | sql scalar function |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |
| [[Website].[SearchForStockItems]](#websitesearchforstockitems) | sql stored procedure |
| [[Website].[SearchForStockItemsByTags]](#websitesearchforstockitemsbytags) | sql stored procedure |

[Back to top](#wideworldimporters)

### Warehouse.StockItems_Archive

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| StockItemID | INT | no |  |  |  |
| StockItemName | NVARCHAR(100) | no |  |  |  |
| SupplierID | INT | no |  |  |  |
| ColorID | INT | yes |  |  |  |
| UnitPackageID | INT | no |  |  |  |
| OuterPackageID | INT | no |  |  |  |
| Brand | NVARCHAR(50) | yes |  |  |  |
| Size | NVARCHAR(20) | yes |  |  |  |
| LeadTimeDays | INT | no |  |  |  |
| QuantityPerOuter | INT | no |  |  |  |
| IsChillerStock | BIT | no |  |  |  |
| Barcode | NVARCHAR(50) | yes |  |  |  |
| TaxRate | DECIMAL(18,3) | no |  |  |  |
| UnitPrice | DECIMAL(18,2) | no |  |  |  |
| RecommendedRetailPrice | DECIMAL(18,2) | yes |  |  |  |
| TypicalWeightPerUnit | DECIMAL(18,3) | no |  |  |  |
| MarketingComments | NVARCHAR(MAX) | yes |  |  |  |
| InternalComments | NVARCHAR(MAX) | yes |  |  |  |
| Photo | VARBINARY(MAX) | yes |  |  |  |
| CustomFields | NVARCHAR(MAX) | yes |  |  |  |
| Tags | NVARCHAR(MAX) | yes |  |  |  |
| SearchDetails | NVARCHAR(MAX) | no |  |  |  |
| LastEditedBy | INT | no |  |  |  |
| ValidFrom | DATETIME2(7) | no |  |  |  |
| ValidTo | DATETIME2(7) | no |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| ix_StockItems_Archive | clustered | [ValidFrom], [ValidTo] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetStockItemUpdates]](#integrationgetstockitemupdates) | sql stored procedure |

[Back to top](#wideworldimporters)

### Warehouse.StockItemStockGroups

| Description |
| --- |
| Which stock items are in which stock groups |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StockItemStockGroupID** | INT | no |  | (NEXT VALUE FOR [Sequences].[StockItemStockGroupID]) | Internal reference for this linking row |
| StockItemID | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | Stock item assigned to this stock group (FK indexed via unique constraint) |
| StockGroupID | INT | no | [[Warehouse].[StockGroups].[StockGroupID]](#warehousestockgroups) |  | StockGroup assigned to this stock item (FK indexed via unique constraint) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_StockItemStockGroups** | clustered | [StockItemStockGroupID] |  |  |
| UQ_StockItemStockGroups_StockItemID_Lookup | nonclustered | [StockItemID], [StockGroupID] |  |  |
| UQ_StockItemStockGroups_StockGroupID_Lookup | nonclustered | [StockGroupID], [StockItemID] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[CalculateCustomerPrice]](#websitecalculatecustomerprice) | sql scalar function |

[Back to top](#wideworldimporters)

### Warehouse.StockItemTransactions

| Description |
| --- |
| Transactions covering all movements of all stock items |

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **StockItemTransactionID** | INT | no |  | (NEXT VALUE FOR [Sequences].[TransactionID]) | Numeric ID used to refer to a stock item transaction within the database |
| StockItemID | INT | no | [[Warehouse].[StockItems].[StockItemID]](#warehousestockitems) |  | StockItem for this transaction |
| TransactionTypeID | INT | no | [[Application].[TransactionTypes].[TransactionTypeID]](#applicationtransactiontypes) |  | Type of transaction |
| CustomerID | INT | yes | [[Sales].[Customers].[CustomerID]](#salescustomers) |  | Customer for this transaction (if applicable) |
| InvoiceID | INT | yes | [[Sales].[Invoices].[InvoiceID]](#salesinvoices) |  | ID of an invoice (for transactions associated with an invoice) |
| SupplierID | INT | yes | [[Purchasing].[Suppliers].[SupplierID]](#purchasingsuppliers) |  | Supplier for this stock transaction (if applicable) |
| PurchaseOrderID | INT | yes | [[Purchasing].[PurchaseOrders].[PurchaseOrderID]](#purchasingpurchaseorders) |  | ID of an purchase order (for transactions associated with a purchase order) |
| TransactionOccurredWhen | DATETIME2(7) | no |  |  | Date and time when the transaction occurred |
| Quantity | DECIMAL(18,3) | no |  |  | Quantity of stock movement (positive is incoming stock, negative is outgoing) |
| LastEditedBy | INT | no | [[Application].[People].[PersonID]](#applicationpeople) |  |  |
| LastEditedWhen | DATETIME2(7) | no |  | (sysdatetime()) |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_StockItemTransactions** | nonclustered | [StockItemTransactionID] |  |  |
| FK_Warehouse_StockItemTransactions_TransactionTypeID | nonclustered | [TransactionTypeID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItemTransactions_SupplierID | nonclustered | [SupplierID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItemTransactions_StockItemID | nonclustered | [StockItemID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItemTransactions_PurchaseOrderID | nonclustered | [PurchaseOrderID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItemTransactions_InvoiceID | nonclustered | [InvoiceID] |  | Auto-created to support a foreign key |
| FK_Warehouse_StockItemTransactions_CustomerID | nonclustered | [CustomerID] |  | Auto-created to support a foreign key |
| CCX_Warehouse_StockItemTransactions | clustered columnstore |  | [StockItemTransactionID], [StockItemID], [TransactionTypeID], [CustomerID], [InvoiceID], [SupplierID], [PurchaseOrderID], [TransactionOccurredWhen], [Quantity], [LastEditedBy], [LastEditedWhen] |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Integration].[GetMovementUpdates]](#integrationgetmovementupdates) | sql stored procedure |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Warehouse.VehicleTemperatures

| Column | Type | Null | Foreign Key | Default | Description |
| --- | --- | --- | --- | --- | --- |
| **VehicleTemperatureID** | BIGINT | no |  |  |  |
| VehicleRegistration | NVARCHAR(20) | no |  |  |  |
| ChillerSensorNumber | INT | no |  |  |  |
| RecordedWhen | DATETIME2(7) | no |  |  |  |
| Temperature | DECIMAL(10,2) | no |  |  |  |
| FullSensorData | NVARCHAR(1000) | yes |  |  |  |
| IsCompressed | BIT | no |  |  |  |
| CompressedSensorData | VARBINARY(MAX) | yes |  |  |  |

#### Indexes

| Name | Type | Key Columns | Include Columns | Description |
| --- | --- | --- | --- | --- |
| **PK_Warehouse_VehicleTemperatures** | nonclustered | [VehicleTemperatureID] |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[RecordVehicleTemperature]](#websiterecordvehicletemperature) | sql stored procedure |
| [[Website].[VehicleTemperatures]](#websitevehicletemperatures) | view |

[Back to top](#wideworldimporters)

</details>

## Views

<details><summary>Click to expand</summary>

* [Website.Customers](#websitecustomers)
* [Website.Suppliers](#websitesuppliers)
* [Website.VehicleTemperatures](#websitevehicletemperatures)

### Website.Customers

| Column | Type | Null | Description |
| --- | ---| --- | --- |
| CustomerID | INT | no |  |
| CustomerName | NVARCHAR(100) | no |  |
| CustomerCategoryName | NVARCHAR(50) | yes |  |
| PrimaryContact | NVARCHAR(50) | yes |  |
| AlternateContact | NVARCHAR(50) | yes |  |
| PhoneNumber | NVARCHAR(20) | no |  |
| FaxNumber | NVARCHAR(20) | no |  |
| BuyingGroupName | NVARCHAR(50) | yes |  |
| WebsiteURL | NVARCHAR(256) | no |  |
| DeliveryMethod | NVARCHAR(50) | yes |  |
| CityName | NVARCHAR(50) | yes |  |
| DeliveryLocation | GEOGRAPHY | yes |  |
| DeliveryRun | NVARCHAR(5) | yes |  |
| RunPosition | NVARCHAR(5) | yes |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE VIEW Website.Customers
AS
SELECT s.CustomerID,
       s.CustomerName,
       sc.CustomerCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       s.PhoneNumber,
       s.FaxNumber,
       bg.BuyingGroupName,
       s.WebsiteURL,
       dm.DeliveryMethodName AS DeliveryMethod,
       c.CityName AS CityName,
       s.DeliveryLocation AS DeliveryLocation,
       s.DeliveryRun,
       s.RunPosition
FROM Sales.Customers AS s
LEFT OUTER JOIN Sales.CustomerCategories AS sc
ON s.CustomerCategoryID = sc.CustomerCategoryID
LEFT OUTER JOIN [Application].People AS pp
ON s.PrimaryContactPersonID = pp.PersonID
LEFT OUTER JOIN [Application].People AS ap
ON s.AlternateContactPersonID = ap.PersonID
LEFT OUTER JOIN Sales.BuyingGroups AS bg
ON s.BuyingGroupID = bg.BuyingGroupID
LEFT OUTER JOIN [Application].DeliveryMethods AS dm
ON s.DeliveryMethodID = dm.DeliveryMethodID
LEFT OUTER JOIN [Application].Cities AS c
ON s.DeliveryCityID = c.CityID

```

</details>

[Back to top](#wideworldimporters)

### Website.Suppliers

| Column | Type | Null | Description |
| --- | ---| --- | --- |
| SupplierID | INT | no |  |
| SupplierName | NVARCHAR(100) | no |  |
| SupplierCategoryName | NVARCHAR(50) | yes |  |
| PrimaryContact | NVARCHAR(50) | yes |  |
| AlternateContact | NVARCHAR(50) | yes |  |
| PhoneNumber | NVARCHAR(20) | no |  |
| FaxNumber | NVARCHAR(20) | no |  |
| WebsiteURL | NVARCHAR(256) | no |  |
| DeliveryMethod | NVARCHAR(50) | yes |  |
| CityName | NVARCHAR(50) | yes |  |
| DeliveryLocation | GEOGRAPHY | yes |  |
| SupplierReference | NVARCHAR(20) | yes |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE VIEW Website.Suppliers
AS
SELECT s.SupplierID,
       s.SupplierName,
       sc.SupplierCategoryName,
       pp.FullName AS PrimaryContact,
       ap.FullName AS AlternateContact,
       s.PhoneNumber,
       s.FaxNumber,
       s.WebsiteURL,
       dm.DeliveryMethodName AS DeliveryMethod,
       c.CityName AS CityName,
       s.DeliveryLocation AS DeliveryLocation,
       s.SupplierReference
FROM Purchasing.Suppliers AS s
LEFT OUTER JOIN Purchasing.SupplierCategories AS sc
ON s.SupplierCategoryID = sc.SupplierCategoryID
LEFT OUTER JOIN [Application].People AS pp
ON s.PrimaryContactPersonID = pp.PersonID
LEFT OUTER JOIN [Application].People AS ap
ON s.AlternateContactPersonID = ap.PersonID
LEFT OUTER JOIN [Application].DeliveryMethods AS dm
ON s.DeliveryMethodID = dm.DeliveryMethodID
LEFT OUTER JOIN [Application].Cities AS c
ON s.DeliveryCityID = c.CityID

```

</details>

[Back to top](#wideworldimporters)

### Website.VehicleTemperatures

| Column | Type | Null | Description |
| --- | ---| --- | --- |
| VehicleTemperatureID | BIGINT | no |  |
| VehicleRegistration | NVARCHAR(20) | no |  |
| ChillerSensorNumber | INT | no |  |
| RecordedWhen | DATETIME2(7) | no |  |
| Temperature | DECIMAL(10,2) | no |  |
| FullSensorData | NVARCHAR(1000) | yes |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE VIEW Website.VehicleTemperatures
AS
SELECT vt.VehicleTemperatureID,
       vt.VehicleRegistration,
       vt.ChillerSensorNumber,
       vt.RecordedWhen,
       vt.Temperature,
       CASE WHEN vt.IsCompressed <> 0
            THEN CAST(DECOMPRESS(vt.CompressedSensorData) AS nvarchar(1000))
            ELSE vt.FullSensorData
       END AS FullSensorData
FROM Warehouse.VehicleTemperatures AS vt;

```

</details>

[Back to top](#wideworldimporters)

</details>

## Stored Procedures

<details><summary>Click to expand</summary>

* [Application.AddRoleMemberIfNonexistent](#applicationaddrolememberifnonexistent)
* [Application.Configuration_ApplyAuditing](#applicationconfiguration_applyauditing)
* [Application.Configuration_ApplyColumnstoreIndexing](#applicationconfiguration_applycolumnstoreindexing)
* [Application.Configuration_ApplyFullTextIndexing](#applicationconfiguration_applyfulltextindexing)
* [Application.Configuration_ApplyPartitioning](#applicationconfiguration_applypartitioning)
* [Application.Configuration_ApplyRowLevelSecurity](#applicationconfiguration_applyrowlevelsecurity)
* [Application.Configuration_ConfigureForEnterpriseEdition](#applicationconfiguration_configureforenterpriseedition)
* [Application.Configuration_EnableInMemory](#applicationconfiguration_enableinmemory)
* [Application.Configuration_RemoveAuditing](#applicationconfiguration_removeauditing)
* [Application.Configuration_RemoveRowLevelSecurity](#applicationconfiguration_removerowlevelsecurity)
* [Application.CreateRoleIfNonexistent](#applicationcreateroleifnonexistent)
* [DataLoadSimulation.Configuration_ApplyDataLoadSimulationProcedures](#dataloadsimulationconfiguration_applydataloadsimulationprocedures)
* [DataLoadSimulation.Configuration_RemoveDataLoadSimulationProcedures](#dataloadsimulationconfiguration_removedataloadsimulationprocedures)
* [DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad](#dataloadsimulationdeactivatetemporaltablesbeforedataload)
* [DataLoadSimulation.PopulateDataToCurrentDate](#dataloadsimulationpopulatedatatocurrentdate)
* [DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad](#dataloadsimulationreactivatetemporaltablesafterdataload)
* [Integration.GetCityUpdates](#integrationgetcityupdates)
* [Integration.GetCustomerUpdates](#integrationgetcustomerupdates)
* [Integration.GetEmployeeUpdates](#integrationgetemployeeupdates)
* [Integration.GetMovementUpdates](#integrationgetmovementupdates)
* [Integration.GetOrderUpdates](#integrationgetorderupdates)
* [Integration.GetPaymentMethodUpdates](#integrationgetpaymentmethodupdates)
* [Integration.GetPurchaseUpdates](#integrationgetpurchaseupdates)
* [Integration.GetSaleUpdates](#integrationgetsaleupdates)
* [Integration.GetStockHoldingUpdates](#integrationgetstockholdingupdates)
* [Integration.GetStockItemUpdates](#integrationgetstockitemupdates)
* [Integration.GetSupplierUpdates](#integrationgetsupplierupdates)
* [Integration.GetTransactionTypeUpdates](#integrationgettransactiontypeupdates)
* [Integration.GetTransactionUpdates](#integrationgettransactionupdates)
* [Sequences.ReseedAllSequences](#sequencesreseedallsequences)
* [Sequences.ReseedSequenceBeyondTableValues](#sequencesreseedsequencebeyondtablevalues)
* [Website.ActivateWebsiteLogon](#websiteactivatewebsitelogon)
* [Website.ChangePassword](#websitechangepassword)
* [Website.InsertCustomerOrders](#websiteinsertcustomerorders)
* [Website.InvoiceCustomerOrders](#websiteinvoicecustomerorders)
* [Website.RecordColdRoomTemperatures](#websiterecordcoldroomtemperatures)
* [Website.RecordVehicleTemperature](#websiterecordvehicletemperature)
* [Website.SearchForCustomers](#websitesearchforcustomers)
* [Website.SearchForPeople](#websitesearchforpeople)
* [Website.SearchForStockItems](#websitesearchforstockitems)
* [Website.SearchForStockItemsByTags](#websitesearchforstockitemsbytags)
* [Website.SearchForSuppliers](#websitesearchforsuppliers)

### Application.AddRoleMemberIfNonexistent

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @RoleName | SYSNAME(128) | no |  |
| @UserName | SYSNAME(128) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].AddRoleMemberIfNonexistent
@RoleName sysname,
@UserName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.database_role_members AS drm
                            INNER JOIN sys.database_principals AS dpr
                            ON drm.role_principal_id = dpr.principal_id
                            AND dpr.type = N'R'
                            INNER JOIN sys.database_principals AS dpu
                            ON drm.member_principal_id = dpu.principal_id
                            AND dpu.type = N'S'
                            WHERE dpr.name = @RoleName
                            AND dpu.name = @UserName)
    BEGIN
        BEGIN TRY

            DECLARE @SQL nvarchar(max) = N'ALTER ROLE ' + QUOTENAME(@RoleName)
                                       + N' ADD MEMBER ' + QUOTENAME(@UserName) + N';'
            EXECUTE (@SQL);

            PRINT N'User ' + @UserName + N' added to role ' + @RoleName;

        END TRY
        BEGIN CATCH
            PRINT N'Unable to add user ' + @UserName + N' to role ' + @RoleName;
            THROW;
        END CATCH;
    END;
END;

```

</details>

[Back to top](#wideworldimporters)

### Application.Configuration_ApplyAuditing

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_ApplyAuditing
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AreDatabaseAuditSpecificationsSupported bit = 0;
    DECLARE @SQL nvarchar(max);

    -- TODO !! - currently no separate test for audit
    -- but same editions with XTP support database audit specs
    IF SERVERPROPERTY(N'IsXTPSupported') <> 0 SET @AreDatabaseAuditSpecificationsSupported = 1;

    BEGIN TRY;

        IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'WWI_Audit')
        BEGIN
            SET @SQL = N'
USE master;

CREATE SERVER AUDIT [WWI_Audit]
TO APPLICATION_LOG
WITH
(
    QUEUE_DELAY = 1000,
	ON_FAILURE = CONTINUE
);';
            EXECUTE (@SQL);

            PRINT N'Server audit WWI_Audit created with Application Log as a target.';
            PRINT N'For stronger security, redirect the audit to the security log or a text file in a secure folder.';
            PRINT N'Additional configuration is required when using the security log.';
            PRINT N'For more information see: https://technet.microsoft.com/en-us/library/cc645889.aspx.';
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'WWI_ServerAuditSpecification')
        BEGIN
            SET @SQL = N'
USE master;

CREATE SERVER AUDIT SPECIFICATION [WWI_ServerAuditSpecification]
FOR SERVER AUDIT [WWI_Audit]
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (TRACE_CHANGE_GROUP);';
            EXECUTE (@SQL);
        END;

        IF @AreDatabaseAuditSpecificationsSupported <> 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'WWI_DatabaseAuditSpecification')
            BEGIN
                SET @SQL = N'
CREATE DATABASE AUDIT SPECIFICATION [WWI_DatabaseAuditSpecification]
FOR SERVER AUDIT [WWI_Audit]
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SELECT ON OBJECT::[Sales].[CustomerTransactions] BY [public]),
ADD (SELECT ON OBJECT::[Purchasing].[SupplierTransactions] BY [public]);';
                EXECUTE (@SQL);
            END;
        END;

    END TRY
    BEGIN CATCH
        PRINT N'Unable to apply audit';
        THROW;
    END CATCH;
END;

```

</details>

[Back to top](#wideworldimporters)

### Application.Configuration_ApplyColumnstoreIndexing

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_ApplyColumnstoreIndexing
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0 -- TODO !! - currently no separate test for columnstore
    BEGIN                                    -- but same editions with XTP support columnstore
        PRINT N'Warning: Columnstore indexes cannot be created on this edition.';
    END ELSE BEGIN -- if columnstore can be created
        DECLARE @SQL nvarchar(max) = N'';

        BEGIN TRY;

            BEGIN TRAN;

            -- enable page compression on archive tables
            SET @SQL = N''
            SELECT @SQL +=N'
ALTER INDEX [' + i.name + N'] ON [' + schema_name(o.schema_id) + N'].[' + o.name + N'] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE);  '
            FROM sys.indexes i JOIN sys.tables o ON i.object_id=o.object_id
            WHERE o.temporal_type = 1 AND i.type=1
            EXECUTE (@SQL);

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_OrderLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines
(
    OrderID,
    StockItemID,
	[Description],
    Quantity,
    UnitPrice,
    PickedQuantity
)';
				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'NCCX_Sales_InvoiceLines')
            BEGIN
                SET @SQL = N'
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_InvoiceLines
ON Sales.InvoiceLines
(
    InvoiceID,
    StockItemID,
    Quantity,
    UnitPrice,
    LineProfit,
    LastEditedWhen
)';
				SET @SQL += N';';
                EXECUTE (@SQL);
            END;

            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CCX_Warehouse_StockItemTransactions')
            BEGIN
                SET @SQL = N'
ALTER TABLE Warehouse.StockItemTransactions
DROP CONSTRAINT PK_Warehouse_StockItemTransactions;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.StockItemTransactions
ADD CONSTRAINT PK_Warehouse_StockItemTransactions PRIMARY KEY NONCLUSTERED (StockItemTransactionID);';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE CLUSTERED COLUMNSTORE INDEX CCX_Warehouse_StockItemTransactions
ON Warehouse.StockItemTransactions;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER INDEX CCX_Warehouse_StockItemTransactions
ON Warehouse.StockItemTransactions
REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);';
                EXECUTE (@SQL);

                PRINT N'Successfully applied columnstore indexing';
            END; -- of if need to apply to stock item transactions

            COMMIT;
        END TRY
        BEGIN CATCH
            PRINT N'Unable to apply columnstore indexing';
            THROW;
        END CATCH;
    END; -- of columnstore is allowed
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Configuration_ConfigureForEnterpriseEdition]](#applicationconfiguration_configureforenterpriseedition) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Configuration_ApplyFullTextIndexing

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_ApplyFullTextIndexing
WITH EXECUTE AS OWNER
AS
BEGIN
    IF SERVERPROPERTY(N'IsFullTextInstalled') = 0
    BEGIN
        PRINT N'Warning: Full text options cannot be configured because full text indexing is not installed.';
    END ELSE BEGIN -- if full text is installed
        DECLARE @SQL nvarchar(max) = N'';

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'FTCatalog')
        BEGIN
            SET @SQL =  N'CREATE FULLTEXT CATALOG FTCatalog AS DEFAULT;'
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'[Application].People'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON [Application].People (SearchName, CustomFields, OtherLanguages)
KEY INDEX PK_Application_People
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Sales.Customers'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON Sales.Customers (CustomerName)
KEY INDEX PK_Sales_Customers
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Purchasing.Suppliers'))
        BEGIN
            SET @SQL = N'
CREATE FULLTEXT INDEX
ON Purchasing.Suppliers (SupplierName)
KEY INDEX PK_Purchasing_Suppliers
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;


        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes AS fti WHERE fti.object_id = OBJECT_ID(N'Warehouse.StockItems'))
        BEGIN
            SET @SQL = N'CREATE FULLTEXT INDEX
ON Warehouse.StockItems (SearchDetails, CustomFields, Tags)
KEY INDEX PK_Warehouse_StockItems
WITH CHANGE_TRACKING AUTO;';
            EXECUTE (@SQL);
        END;

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForPeople;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForPeople
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT p.PersonID,
           p.FullName,
           p.PreferredName,
           CASE WHEN p.IsSalesperson <> 0 THEN N''Salesperson''
                WHEN p.IsEmployee <> 0 THEN N''Employee''
                WHEN c.CustomerID IS NOT NULL THEN N''Customer''
                WHEN sp.SupplierID IS NOT NULL THEN N''Supplier''
                WHEN sa.SupplierID IS NOT NULL THEN N''Supplier''
           END AS Relationship,
           COALESCE(c.CustomerName, sp.SupplierName, sa.SupplierName, N''WWI'') AS Company
    FROM [Application].People AS p
    INNER JOIN FREETEXTTABLE([Application].People, SearchName, @SearchText, @MaximumRowsToReturn) AS ft
    ON p.PersonID = ft.[KEY]
    LEFT OUTER JOIN Sales.Customers AS c
    ON c.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sp
    ON sp.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sa
    ON sa.AlternateContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''People'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForSuppliers;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForSuppliers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT s.SupplierID,
           s.SupplierName,
           c.CityName,
           s.PhoneNumber,
           s.FaxNumber ,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Purchasing.Suppliers AS s
    INNER JOIN FREETEXTTABLE(Purchasing.Suppliers, SupplierName, @SearchText, @MaximumRowsToReturn) AS ft
    ON s.SupplierID = ft.[KEY]
    INNER JOIN [Application].Cities AS c
    ON s.DeliveryCityID = c.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON s.PrimaryContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''Suppliers'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForCustomers;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForCustomers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT c.CustomerID,
           c.CustomerName,
           ct.CityName,
           c.PhoneNumber,
           c.FaxNumber,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Sales.Customers AS c
    INNER JOIN FREETEXTTABLE(Sales.Customers, CustomerName, @SearchText, @MaximumRowsToReturn) AS ft
    ON c.CustomerID = ft.[KEY]
    INNER JOIN [Application].Cities AS ct
    ON c.DeliveryCityID = ct.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON c.PrimaryContactPersonID = p.PersonID
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''Customers'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForStockItems;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForStockItems
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    INNER JOIN FREETEXTTABLE(Warehouse.StockItems, SearchDetails, @SearchText, @MaximumRowsToReturn) AS ft
    ON si.StockItemID = ft.[KEY]
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''StockItems'');
END;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP PROCEDURE IF EXISTS Website.SearchForStockItemsByTags;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE PROCEDURE Website.SearchForStockItemsByTags
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    INNER JOIN FREETEXTTABLE(Warehouse.StockItems, Tags, @SearchText, @MaximumRowsToReturn) AS ft
    ON si.StockItemID = ft.[KEY]
    ORDER BY ft.[RANK]
    FOR JSON AUTO, ROOT(N''StockItems'');
END;';
        EXECUTE (@SQL);

        PRINT N'Full text successfully enabled';
    END;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Configuration_ConfigureForEnterpriseEdition]](#applicationconfiguration_configureforenterpriseedition) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Configuration_ApplyPartitioning

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_ApplyPartitioning
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0 -- TODO Check for a better way to check for partitioning
    BEGIN                                    -- Currently versions that support in-memory OLTP also support partitions
        PRINT N'Warning: Partitions are not supported in this edition.';
    END ELSE BEGIN -- if partitions are permitted

        BEGIN TRAN;

        DECLARE @SQL nvarchar(max) = N'';

        IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = N'PF_TransactionDateTime')
        BEGIN
            SET @SQL =  N'
CREATE PARTITION FUNCTION PF_TransactionDateTime(datetime)
AS RANGE RIGHT
FOR VALUES (N''20140101'', N''20150101'', N''20160101'', N''20170101'');';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = N'PF_TransactionDate')
        BEGIN
            SET @SQL =  N'
CREATE PARTITION FUNCTION PF_TransactionDate(date)
AS RANGE RIGHT
FOR VALUES (N''20140101'', N''20150101'', N''20160101'', N''20170101'');';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'PS_TransactionDateTime')
        BEGIN

            -- for Azure DB, assign to primary filegroup
            IF SERVERPROPERTY('EngineEdition') = 5
                SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDateTime
AS PARTITION PF_TransactionDateTime
ALL TO ([PRIMARY]);';
            -- for other engine editions, assign to user data filegroup
            IF SERVERPROPERTY('EngineEdition') != 5
                SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDateTime
AS PARTITION PF_TransactionDateTime
ALL TO ([USERDATA]);';

            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = N'PS_TransactionDate')
        BEGIN
        -- for Azure DB, assign to primary filegroup
        IF SERVERPROPERTY('EngineEdition') = 5
            SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDate
AS PARTITION PF_TransactionDate
ALL TO ([PRIMARY]);';
        -- for other engine editions, assign to user data filegroup
        IF SERVERPROPERTY('EngineEdition') != 5
            SET @SQL =  N'
CREATE PARTITION SCHEME PS_TransactionDate
AS PARTITION PF_TransactionDate
ALL TO ([USERDATA]);';

            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CX_Sales_CustomerTransactions')
        BEGIN
            SET @SQL =  N'
ALTER TABLE Sales.CustomerTransactions
DROP CONSTRAINT PK_Sales_CustomerTransactions;';
            EXECUTE (@SQL);

            SET @SQL = N'
ALTER TABLE Sales.CustomerTransactions
ADD CONSTRAINT PK_Sales_CustomerTransactions PRIMARY KEY NONCLUSTERED
(
	CustomerTransactionID
);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE CLUSTERED INDEX CX_Sales_CustomerTransactions
ON Sales.CustomerTransactions
(
	TransactionDate
)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_CustomerID
ON Sales.CustomerTransactions
(
	CustomerID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_InvoiceID
ON Sales.CustomerTransactions
(
	InvoiceID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_PaymentMethodID
ON Sales.CustomerTransactions
(
	PaymentMethodID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX FK_Sales_CustomerTransactions_TransactionTypeID
ON Sales.CustomerTransactions
(
	TransactionTypeID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE INDEX IX_Sales_CustomerTransactions_IsFinalized
ON Sales.CustomerTransactions
(
	IsFinalized
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'CX_Purchasing_SupplierTransactions')
        BEGIN
            SET @SQL =  N'
ALTER TABLE Purchasing.SupplierTransactions
DROP CONSTRAINT PK_Purchasing_SupplierTransactions;';
            EXECUTE (@SQL);

            SET @SQL =  N'
ALTER TABLE Purchasing.SupplierTransactions
ADD CONSTRAINT PK_Purchasing_SupplierTransactions PRIMARY KEY NONCLUSTERED
(
	SupplierTransactionID
);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE CLUSTERED INDEX CX_Purchasing_SupplierTransactions
ON Purchasing.SupplierTransactions
(
	TransactionDate
)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_PaymentMethodID
ON Purchasing.SupplierTransactions
(
	PaymentMethodID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_PurchaseOrderID
ON Purchasing.SupplierTransactions
(
	PurchaseOrderID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_SupplierID
ON Purchasing.SupplierTransactions
(
	SupplierID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX FK_Purchasing_SupplierTransactions_TransactionTypeID
ON Purchasing.SupplierTransactions
(
	TransactionTypeID
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);

            SET @SQL =  N'
CREATE INDEX IX_Purchasing_SupplierTransactions_IsFinalized
ON Purchasing.SupplierTransactions
(
	IsFinalized
)
WITH (DROP_EXISTING = ON)
ON PS_TransactionDate(TransactionDate);';
            EXECUTE (@SQL);
        END;

        COMMIT;

        PRINT N'Partitioning successfully enabled';
    END;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Configuration_ConfigureForEnterpriseEdition]](#applicationconfiguration_configureforenterpriseedition) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Configuration_ApplyRowLevelSecurity

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_ApplyRowLevelSecurity
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SQL nvarchar(max);

    BEGIN TRY;

        SET @SQL = N'DROP SECURITY POLICY IF EXISTS [Application].FilterCustomersBySalesTerritoryRole;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP FUNCTION IF EXISTS [Application].DetermineCustomerAccess;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N''db_owner'') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N'' Sales'') <> 0
	    OR (ORIGINAL_LOGIN() = N''Website''
		    AND EXISTS (SELECT 1
		                FROM [Application].Cities AS c
				        INNER JOIN [Application].StateProvinces AS sp
				        ON c.StateProvinceID = sp.StateProvinceID
				        WHERE c.CityID = @CityID
				        AND sp.SalesTerritory = SESSION_CONTEXT(N''SalesTerritory''))));';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers,
ADD BLOCK PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers AFTER UPDATE;';
        EXECUTE (@SQL);

        PRINT N'Successfully applied row level security';
    END TRY
    BEGIN CATCH
        PRINT N'Unable to apply row level security';
		PRINT ERROR_MESSAGE();
        THROW 51000, N'Unable to apply row level security', 1;
    END CATCH;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[ReactivateTemporalTablesAfterDataLoad]](#dataloadsimulationreactivatetemporaltablesafterdataload) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Configuration_ConfigureForEnterpriseEdition

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].[Configuration_ConfigureForEnterpriseEdition]
AS
BEGIN

    EXEC [Application].[Configuration_ApplyColumnstoreIndexing];

    EXEC [Application].[Configuration_ApplyFullTextIndexing];

    EXEC [Application].[Configuration_EnableInMemory];

    EXEC [Application].[Configuration_ApplyPartitioning];

END;

```

</details>

[Back to top](#wideworldimporters)

### Application.Configuration_EnableInMemory

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].[Configuration_EnableInMemory]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF SERVERPROPERTY(N'IsXTPSupported') = 0
    BEGIN
        PRINT N'Warning: In-memory tables cannot be created on this edition.';
    END ELSE BEGIN -- if in-memory can be created

		DECLARE @SQL nvarchar(max) = N'';

		BEGIN TRY
			IF CAST(SERVERPROPERTY(N'EngineEdition') AS int) <> 5   -- Not an Azure SQL DB
			BEGIN
				DECLARE @SQLDataFolder nvarchar(max) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(max));
				DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + N'WideWorldImporters_InMemory_Data_1';

				IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = N'WWI_InMemory_Data')
				BEGIN
				    SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILEGROUP WWI_InMemory_Data CONTAINS MEMORY_OPTIMIZED_DATA;';
					EXECUTE (@SQL);

					SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''WWI_InMemory_Data_1'', filename = '''
		                 + @MemoryOptimizedFilegroupFolder + N''')
TO FILEGROUP WWI_InMemory_Data;';
					EXECUTE (@SQL);

				END;
            END;

			SET @SQL = N'
ALTER DATABASE CURRENT
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;';
			EXECUTE (@SQL);

            IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ColdRoomTemperatures' AND is_memory_optimized <> 0)
            BEGIN

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Warehouse.ColdRoomTemperatures DROP PERIOD FOR SYSTEM_TIME;
ALTER TABLE Warehouse.ColdRoomTemperatures DROP CONSTRAINT PK_Warehouse_ColdRoomTemperatures;';
                EXECUTE (@SQL);

                SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.ColdRoomTemperatures'',
                   @newname = N''ColdRoomTemperatures_Backup'',
                   @objtype = N''OBJECT'';';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE TABLE Warehouse.ColdRoomTemperatures
(
    ColdRoomTemperatureID bigint IDENTITY(1,1) NOT NULL,
    ColdRoomSensorNumber int NOT NULL,
    RecordedWhen datetime2(7) NOT NULL,
    Temperature decimal(10, 2) NOT NULL,
    ValidFrom datetime2(7) NOT NULL,
    ValidTo datetime2(7) NOT NULL,
    INDEX [IX_Warehouse_ColdRoomTemperatures_ColdRoomSensorNumber] NONCLUSTERED (ColdRoomSensorNumber),
    CONSTRAINT PK_Warehouse_ColdRoomTemperatures PRIMARY KEY NONCLUSTERED (ColdRoomTemperatureID)
) WITH (MEMORY_OPTIMIZED = ON ,DURABILITY = SCHEMA_AND_DATA);';
                EXECUTE (@SQL);

                SET @SQL = N'
SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures ON;

INSERT Warehouse.ColdRoomTemperatures (ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature,
                                       ValidFrom, ValidTo)
SELECT ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo
FROM Warehouse.ColdRoomTemperatures_Backup;

SET IDENTITY_INSERT Warehouse.ColdRoomTemperatures OFF;';
                EXECUTE (@SQL);

                SET @SQL = N'DROP TABLE Warehouse.ColdRoomTemperatures_Backup;';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
ADD PERIOD FOR SYSTEM_TIME(ValidFrom, ValidTo);';
                EXECUTE (@SQL);

                SET @SQL = N'
ALTER TABLE Warehouse.ColdRoomTemperatures
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Warehouse.ColdRoomTemperatures_Archive, DATA_CONSISTENCY_CHECK = ON));';
                EXECUTE (@SQL);

            END; -- of if we need to move ColdRoomTemperatures

            IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'VehicleTemperatures' AND is_memory_optimized <> 0)
            BEGIN

                SET @SQL = N'
ALTER TABLE Warehouse.VehicleTemperatures DROP CONSTRAINT PK_Warehouse_VehicleTemperatures;';
                EXECUTE (@SQL);

                SET @SQL = N'
EXEC dbo.sp_rename @objname = N''Warehouse.VehicleTemperatures'',
                   @newname = N''VehicleTemperatures_Backup'',
                   @objtype = N''OBJECT'';';
                EXECUTE (@SQL);

                SET @SQL = N'
CREATE TABLE Warehouse.VehicleTemperatures
(
	VehicleTemperatureID bigint IDENTITY(1,1) NOT NULL,
	VehicleRegistration nvarchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
	ChillerSensorNumber int NOT NULL,
	RecordedWhen datetime2(7) NOT NULL,
	Temperature decimal(10, 2) NOT NULL,
	FullSensorData nvarchar(1000) COLLATE Latin1_General_CI_AS NULL,
    IsCompressed bit NOT NULL,
    CompressedSensorData varbinary(max) NULL,
    CONSTRAINT PK_Warehouse_VehicleTemperatures PRIMARY KEY NONCLUSTERED (VehicleTemperatureID)
) WITH (MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA);';
                EXECUTE (@SQL);

                SET @SQL = N'
SET IDENTITY_INSERT Warehouse.VehicleTemperatures ON;

INSERT Warehouse.VehicleTemperatures
    (VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData)
SELECT VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CompressedSensorData
FROM Warehouse.VehicleTemperatures_Backup;

SET IDENTITY_INSERT Warehouse.VehicleTemperatures OFF;';
                EXECUTE (@SQL);

                SET @SQL = N'DROP TABLE Warehouse.VehicleTemperatures_Backup;';
                EXECUTE (@SQL);

            END; -- of if we need to move VehicleTemperatures

            -- Drop the procedures that are used by the table types

            SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InvoiceCustomerOrders;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP PROCEDURE IF EXISTS Website.InsertCustomerOrders;';
            EXECUTE (@SQL);
			SET @SQL = N'DROP PROCEDURE IF EXISTS Website.RecordColdRoomTemperatures;';
			EXECUTE (@SQL);

            -- Drop the table types

            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderIDList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderLineList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.OrderList;';
            EXECUTE (@SQL);
            SET @SQL = N'DROP TYPE IF EXISTS Website.SensorDataList;';
            EXECUTE (@SQL);

            -- Create the new table types

            SET @SQL = N'
CREATE TYPE Website.OrderIDList AS TABLE
(
    OrderID int PRIMARY KEY NONCLUSTERED
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.OrderList AS TABLE
(
    OrderReference int PRIMARY KEY NONCLUSTERED,
    CustomerID int,
    ContactPersonID int,
    ExpectedDeliveryDate date,
    CustomerPurchaseOrderNumber nvarchar(20),
    IsUndersupplyBackordered bit,
    Comments nvarchar(max),
    DeliveryInstructions nvarchar(max)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.OrderLineList AS TABLE
(
    OrderReference int,
    StockItemID int,
    [Description] nvarchar(100),
    Quantity int,
    INDEX IX_Website_OrderLineList NONCLUSTERED (OrderReference)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE TYPE Website.SensorDataList AS TABLE
(
	SensorDataListID int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	ColdRoomSensorNumber int,
	RecordedWhen datetime2(7),
	Temperature decimal(18,2)
)
WITH (MEMORY_OPTIMIZED = ON);';
            EXECUTE (@SQL);

            SET @SQL = N'
CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @I
/************************************************************************************************/
/* sp_doc: Max 8000 characters reached. Set @LimitStoredProcLength = 0 to show full definition. */
/************************************************************************************************/
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[Configuration_ConfigureForEnterpriseEdition]](#applicationconfiguration_configureforenterpriseedition) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.Configuration_RemoveAuditing

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_RemoveAuditing
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AreDatabaseAuditSpecificationsSupported bit = 0;
    DECLARE @SQL nvarchar(max);

    -- TODO !! - currently no separate test for audit
    -- but same editions with XTP support database audit specs
    IF SERVERPROPERTY(N'IsXTPSupported') <> 0 SET @AreDatabaseAuditSpecificationsSupported = 1;

    BEGIN TRY;

        IF @AreDatabaseAuditSpecificationsSupported <> 0
        BEGIN
            IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'WWI_DatabaseAuditSpecification')
            BEGIN
                SET @SQL = N'
DROP DATABASE AUDIT SPECIFICATION WWI_DatabaseAuditSpecification;';
                EXECUTE (@SQL);
            END;
        END;

        IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'WWI_ServerAuditSpecification')
        BEGIN
            SET @SQL = N'
USE master;

DROP SERVER AUDIT SPECIFICATION WWI_ServerAuditSpecification;';
            EXECUTE (@SQL);
        END;

        IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'WWI_Audit')
        BEGIN
            SET @SQL = N'
USE master;

DROP SERVER AUDIT [WWI_Audit];';
            EXECUTE (@SQL);

        END;

    END TRY
    BEGIN CATCH
        PRINT N'Unable to remove audit';
        THROW;
    END CATCH;
END;

```

</details>

[Back to top](#wideworldimporters)

### Application.Configuration_RemoveRowLevelSecurity

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].Configuration_RemoveRowLevelSecurity
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SQL nvarchar(max);

    BEGIN TRY;

        SET @SQL = N'DROP SECURITY POLICY IF EXISTS [Application].FilterCustomersBySalesTerritoryRole;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP FUNCTION IF EXISTS [Application].DetermineCustomerAccess;';
        EXECUTE (@SQL);

        PRINT N'Successfully removed row level security';
    END TRY
    BEGIN CATCH
        PRINT N'Unable to remove row level security';
        THROW 51000, N'Unable to remove row level security', 1;
    END CATCH;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[DeactivateTemporalTablesBeforeDataLoad]](#dataloadsimulationdeactivatetemporaltablesbeforedataload) | sql stored procedure |

[Back to top](#wideworldimporters)

### Application.CreateRoleIfNonexistent

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @RoleName | SYSNAME(128) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE [Application].CreateRoleIfNonexistent
@RoleName sysname
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @RoleName AND type = N'R')
    BEGIN
        BEGIN TRY

            DECLARE @SQL nvarchar(max) = N'CREATE ROLE ' + QUOTENAME(@RoleName) + N';'
            EXECUTE (@SQL);

            PRINT N'Role ' + @RoleName + N' created';

        END TRY
        BEGIN CATCH
            PRINT N'Unable to create role ' + @RoleName;
            THROW;
        END CATCH;
    END;
END;

```

</details>

[Back to top](#wideworldimporters)

### DataLoadSimulation.Configuration_ApplyDataLoadSimulationProcedures

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE DataLoadSimulation.Configuration_ApplyDataLoadSimulationProcedures
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	EXEC DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad;

	DECLARE @SQL nvarchar(max);

	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'GetAreaCode'
	                                         AND type = N'FN'
											 AND SCHEMA_NAME(schema_id) = N'DataLoadSimulation')
	BEGIN
		SET @SQL = N'
CREATE FUNCTION DataLoadSimulation.GetAreaCode
(
    @StateProvinceCode nvarchar(2)
)
RETURNS INT
WITH EXECUTE AS OWNER
AS
BEGIN
    DECLARE @AreaCode int;

    WITH AreaCodes
    AS
    (
        SELECT StateProvinceCode, AreaCode
        FROM
        (VALUES (''NJ'', 201),
                (''DC'', 202),
                (''CT'', 203),
                (''MB'', 204),
                (''AL'', 205),
                (''WA'', 206),
                (''ME'', 207),
                (''ID'', 208),
                (''CA'', 209),
                (''TX'', 210),
                (''NY'', 212),
                (''CA'', 213),
                (''TX'', 214),
                (''PA'', 215),
                (''OH'', 216),
                (''IL'', 217),
                (''MN'', 218),
                (''IN'', 219),
                (''OH'', 220),
                (''IL'', 224),
                (''LA'', 225),
                (''ON'', 226),
                (''MS'', 228),
                (''GA'', 229),
                (''MI'', 231),
                (''OH'', 234),
                (''BC'', 236),
                (''FL'', 239),
                (''MD'', 240),
                (''MI'', 248),
                (''BC'', 250),
                (''AL'', 251),
                (''NC'', 252),
                (''WA'', 253),
                (''TX'', 254),
                (''AL'', 256),
                (''IN'', 260),
                (''WI'', 262),
                (''PA'', 267),
                (''MI'', 269),
                (''KY'', 270),
                (''PA'', 272),
                (''VA'', 276),
                (''MI'', 278),
                (''TX'', 281),
                (''OH'', 283),
                (''ON'', 289),
                (''MD'', 301),
                (''DE'', 302),
                (''CO'', 303),
                (''WV'', 304),
                (''FL'', 305),
                (''SK'', 306),
                (''WY'', 307),
                (''NE'', 308),
                (''IL'', 309),
                (''CA'', 310),
                (''IL'', 312),
                (''MI'', 313),
                (''MO'', 314),
                (''NY'', 315),
                (''KS'', 316),
                (''IN'', 317),
                (''LA'', 318),
                (''IA'', 319),
                (''MN'', 320),
                (''FL'', 321),
                (''CA'', 323),
                (''TX'', 325),
                (''OH'', 330),
                (''IL'', 331),
                (''AL'', 334),
                (''NC'', 336),
                (''LA'', 337),
                (''MA'', 339),
                (''VI'', 340),
                (''CA'', 341),
                (''ON'', 343),
                (''NY'', 347),
                (''MA'', 351),
                (''FL'', 352),
                (''WA'', 360),
                (''TX'', 361),
                (''ON'', 365),
                (''CA'', 369),
                (''OH'', 380),
                (''UT'', 385),
                (''FL'', 386),
                (''RI'', 401),
                (''NE'', 402),
                (''AB'', 403),
                (''GA'', 404),
                (''OK'', 405),
                (''MT'', 406),
                (''FL'', 407),
                (''CA'', 408),
                (''TX'', 409),
                (''MD'', 410),
                (''PA'', 412),
                (''MA'', 413),
                (''WI'', 414),
                (''CA'', 415),
                (''ON'', 416),
                (''MO'', 417),
                (''QC'', 418),
                (''OH'', 419),
                (''TN'', 423),
                (''CA'', 424),
                (''WA'', 425),
                (''TX'', 430),
                (''MB'', 431),
                (''TX'', 432),
                (''VA'', 434),
                (''UT'', 435),
                (''ON'', 437),
                (''QC'', 438),
                (''OH'', 440),
                (''CA'', 442),
                (''MD'', 443),
                (''QC'', 450),
                (''OR'', 458),
                (''IL'', 464),
                (''TX'', 469),
                (''GA'', 470),
                (''CT'', 475),
                (''GA'', 478),
                (''AR'', 479),
                (''AZ'', 480),
                (''QC'', 481),
                (''PA'', 484),
                (''AR'', 501),
                (''KY'', 502),
                (''OR'', 503),
                (''LA'', 504),
                (''NM'', 505),
                (''NB'', 506),
                (''MN'', 507),
                (''MA'', 508),
                (''WA'', 509),
                (''CA'', 510),
                (''TX'', 512),
                (''OH'', 513),
                (''QC'', 514),
                (''IA'', 515),
                (''NY'', 516),
                (''MI'', 517),
                (''NY'', 518),
                (''ON'', 519),
                (''AZ'', 520),
                (''CA'', 530),
                (''OK'', 539),
                (''VA'', 540),
                (''OR'', 541),
                (''ON'', 548),
                (''NJ'', 551),
                (''MO'', 557),
                (''CA'', 559),
                (''FL'', 561),
                (''CA'', 562),
                (''IA'', 563),
                (''WA'', 564),
                (''OH'', 567),
                (''PA'', 570),
                (''VA'', 571),
                (''MO'', 573),
                (''IN'', 574),
                (''NM'', 575),
                (''QC'', 579),
                (''OK'', 580),
                (''NY'', 585),
                (''MI'', 586),
                (''AB'', 587),
                (''MS'', 601),
                (''AZ'', 602),
                (''NH'', 603),
                (''BC'', 604),
                (''SD'', 605),
                (''KY'', 606),
                (''NY'', 607),
                (''WI'', 608),
                (''NJ'', 609),
                (''PA'', 610),
                (''MN'', 612),
                (''ON'', 613),
                (''OH'', 614),
                (''TN'', 615),
                (''MI'', 616),
                (''MA'', 617),
                (''IL'', 618),
                (''CA'', 619),
                (''KS'', 620),
                (''AZ'', 623),
                (''CA'', 626),
                (''CA'', 627),
                (''CA'', 628),
                (''TN'', 629),
                (''IL'', 630),
                (''NY'', 631),
                (''MO'', 636),
                (''SK'', 639),
                (''IA'', 641),
                (''NY'', 646),
                (''ON'', 647),
                (''CA'', 650),
                (''MN'', 651),
                (''CA'', 657),
                (''MO'', 660),
                (''CA'', 661),
                (''MS'', 662),
                (''CA'', 669),
                (''MP'', 670),
                (''GU'', 671),
                (''GA'', 678),
                (''MI'', 679),
                (''WV'', 681),
                (''TX'', 682),
                (''FL'', 689),
                (''ND'', 701),
                (''NV'', 702),
                (''VA'', 703),
                (''NC'', 704),
                (''ON'', 705),
                (''GA'', 706),
                (''CA'', 707),
                (''IL'', 708),
                (''NL'', 709),
               
/************************************************************************************************/
/* sp_doc: Max 8000 characters reached. Set @LimitStoredProcLength = 0 to show full definition. */
/************************************************************************************************/
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[PopulateDataToCurrentDate]](#dataloadsimulationpopulatedatatocurrentdate) | sql stored procedure |

[Back to top](#wideworldimporters)

### DataLoadSimulation.Configuration_RemoveDataLoadSimulationProcedures

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE DataLoadSimulation.Configuration_RemoveDataLoadSimulationProcedures
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DROP PROCEDURE IF EXISTS DataLoadSimulation.ActivateWebsiteLogons;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.AddCustomers;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.AddSpecialDeals;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.AddStockItems;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.ChangePasswords;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.CreateCustomerOrders;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.DailyProcessToCreateHistory;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.InvoicePickedOrders;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.MakeTemporalChanges;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.PaySuppliers;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.PerformStocktake;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.PickStockForCustomerOrders;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.PlaceSupplierOrders;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.ProcessCustomerPayments;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.ReceivePurchaseOrders;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.RecordColdRoomTemperatures;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.RecordDeliveryVanTemperatures;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.RecordInvoiceDeliveries;
	DROP PROCEDURE IF EXISTS DataLoadSimulation.UpdateCustomFields;
	DROP FUNCTION IF EXISTS DataLoadSimulation.GetAreaCode;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[PopulateDataToCurrentDate]](#dataloadsimulationpopulatedatatocurrentdate) | sql stored procedure |

[Back to top](#wideworldimporters)

### DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad

#### Definition

<details><summary>Click to expand</summary>

```sql
 
CREATE PROCEDURE DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad
AS BEGIN
    -- Disables the temporal nature of the temporal tables before a simulated data load
    SET NOCOUNT ON;
 
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N'Configuration_RemoveRowLevelSecurity')
    BEGIN
        EXEC [Application].Configuration_RemoveRowLevelSecurity;
    END;
 
    DECLARE @SQL nvarchar(max) = N'';
    DECLARE @CrLf nvarchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @Indent nvarchar(4) = N'    ';
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @NormalColumnList nvarchar(max);
    DECLARE @NormalColumnListWithDPrefix nvarchar(max);
    DECLARE @PrimaryKeyColumn sysname;
    DECLARE @TemporalFromColumnName sysname = N'ValidFrom';
    DECLARE @TemporalToColumnName sysname = N'ValidTo';
    DECLARE @TemporalTableSuffix nvarchar(max) = N'Archive';
    DECLARE @LastEditedByColumnName sysname;
 
    ALTER TABLE [Application].[Cities] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[Cities] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[Countries] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[Countries] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[DeliveryMethods] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[DeliveryMethods] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[PaymentMethods] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[PaymentMethods] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[People] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[People] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[StateProvinces] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[StateProvinces] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Application].[TransactionTypes] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Application].[TransactionTypes] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Purchasing].[SupplierCategories] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Purchasing].[SupplierCategories] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Purchasing].[Suppliers] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Purchasing].[Suppliers] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Sales].[BuyingGroups] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[BuyingGroups] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Sales].[CustomerCategories] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[CustomerCategories] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Sales].[Customers] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Sales].[Customers] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Warehouse].[Colors] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[Colors] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Warehouse].[PackageTypes] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[PackageTypes] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Warehouse].[StockGroups] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[StockGroups] DROP PERIOD FOR SYSTEM_TIME;
 
    ALTER TABLE [Warehouse].[StockItems] SET (SYSTEM_VERSIONING = OFF);
    ALTER TABLE [Warehouse].[StockItems] DROP PERIOD FOR SYSTEM_TIME;
 
    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'Cities';
    SET @PrimaryKeyColumn = N'CityID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CityID], [CityName], [StateProvinceID], [Location], [LatestRecordedPopulation],';
    SET @NormalColumnListWithDPrefix = N' d.[CityID], d.[CityName], d.[StateProvinceID], d.[Location], d.[LatestRecordedPopulation],';
 
    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);
 
    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @Crlf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' + @NormalColumnList + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + QUOTENAME(@TemporalFromColumnName) + N',' + QUOTENAME(@TemporalToColumnName) + N')' + @CrLf
              + @Indent + N'SELECT' + @NormalColumnListWithDPrefix + CASE WHEN COALESCE(@LastEditedByColumnName, N'') <> N'' THEN N'd.' + QUOTENAME(@LastEditedByColumnName) + N', ' ELSE N'' END
                                  + N' d.' + QUOTENAME(@TemporalFromColumnName) + N', i.' + QUOTENAME(@TemporalFromColumnName) + @CrLf
              + @Indent + N'FROM inserted AS i' + @CrLf
              + @Indent + N'INNER JOIN deleted AS d' + @CrLf
              + @Indent + N'ON i.' + QUOTENAME(@PrimaryKeyColumn) + N' = d.' + QUOTENAME(@PrimaryKeyColumn) + N';' + @CrLf
              + N'END;';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName AND is_memory_optimized <> 0)
    BEGIN
        EXECUTE (@SQL);
    END;
 
    SET @SQL = N'';
    SET @SchemaName = N'Application';
    SET @TableName = N'Countries';
    SET @PrimaryKeyColumn = N'CountryID';
    SET @LastEditedByColumnName = N'LastEditedBy';
    SET @NormalColumnList = N' [CountryID], [CountryName], [FormalName], [IsoAlpha3Code], [IsoNumericCode], [CountryType], [LatestRecordedPopulation], [Continent], [Region], [Subregion], [Border],';
    SET @NormalColumnListWithDPrefix = N' d.[CountryID], d.[CountryName], d.[FormalName], d.[IsoAlpha3Code], d.[IsoNumericCode], d.[CountryType], d.[LatestRecordedPopulation], d.[Continent], d.[Region], d.[Subregion], d.[Border],';
 
    SET @SQL = N'DROP TRIGGER IF EXISTS ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify];'
    EXECUTE (@SQL);
 
    SET @SQL = N'CREATE TRIGGER ' + QUOTENAME(@SchemaName) + N'.[TR_' + @SchemaName + N'_' + @TableName + N'_DataLoad_Modify]' + @CrLf
              + N'ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + @CrLf
              + N'AFTER INSERT, UPDATE' + @CrLf
              + N'AS' + @CrLf
              + N'BEGIN' + @CrLf
              + @Indent + N'SET NOCOUNT ON;' + @CrLf + @CrLf
              + @Indent + N'IF NOT UPDATE(' + QUOTENAME(@TemporalFromColumnName) + N')' + @CrLf
              + @Indent + N'BEGIN' + @CrLf
              + @Indent + @Indent + N'THROW 51000, ''' + QUOTENAME(@TemporalFromColumnName)
                                  + N' must be updated when simulating data loads'', 1;' + @CrLf
              + @Indent + @Indent + N'ROLLBACK TRAN;' + @CrLf
              + @Indent + N'END;' + @Crlf + @CrLf
              + @Indent + N'INSERT ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName + N'_' + @TemporalTableSuffix) + @CrLf
              + @Indent + @Indent + N'(' +
/************************************************************************************************/
/* sp_doc: Max 8000 characters reached. Set @LimitStoredProcLength = 0 to show full definition. */
/************************************************************************************************/
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[Configuration_ApplyDataLoadSimulationProcedures]](#dataloadsimulationconfiguration_applydataloadsimulationprocedures) | sql stored procedure |

[Back to top](#wideworldimporters)

### DataLoadSimulation.PopulateDataToCurrentDate

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @AverageNumberOfCustomerOrdersPerDay | INT | no |  |
| @SaturdayPercentageOfNormalWorkDay | INT | no |  |
| @SundayPercentageOfNormalWorkDay | INT | no |  |
| @IsSilentMode | BIT | no |  |
| @AreDatesPrinted | BIT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE DataLoadSimulation.PopulateDataToCurrentDate
@AverageNumberOfCustomerOrdersPerDay int,
@SaturdayPercentageOfNormalWorkDay int,
@SundayPercentageOfNormalWorkDay int,
@IsSilentMode bit,
@AreDatesPrinted bit
AS
BEGIN
    SET NOCOUNT ON;

	EXEC DataLoadSimulation.Configuration_ApplyDataLoadSimulationProcedures;

    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20121231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);
    DECLARE @EndingDate date = CAST(DATEADD(day, -1, SYSDATETIME()) AS date);

    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @EndingDate,
        @AverageNumberOfCustomerOrdersPerDay = @AverageNumberOfCustomerOrdersPerDay,
        @SaturdayPercentageOfNormalWorkDay = @SaturdayPercentageOfNormalWorkDay,
        @SundayPercentageOfNormalWorkDay = @SundayPercentageOfNormalWorkDay,
        @UpdateCustomFields = 0, -- they were done in the initial load
        @IsSilentMode = @IsSilentMode,
        @AreDatesPrinted = @AreDatesPrinted;

	EXEC DataLoadSimulation.Configuration_RemoveDataLoadSimulationProcedures;
END;

```

</details>

[Back to top](#wideworldimporters)

### DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad

#### Definition

<details><summary>Click to expand</summary>

```sql
 
CREATE PROCEDURE DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad
AS BEGIN
    -- Re-enables the temporal nature of the temporal tables after a simulated data load
    SET NOCOUNT ON;
 
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N'Configuration_ApplyRowLevelSecurity')
    BEGIN
        EXEC [Application].Configuration_ApplyRowLevelSecurity;
    END;
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_Cities_DataLoad_Modify];
    ALTER TABLE [Application].[Cities] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[Cities] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[Cities_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_Countries_DataLoad_Modify];
    ALTER TABLE [Application].[Countries] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[Countries] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[Countries_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_DeliveryMethods_DataLoad_Modify];
    ALTER TABLE [Application].[DeliveryMethods] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[DeliveryMethods] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[DeliveryMethods_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_PaymentMethods_DataLoad_Modify];
    ALTER TABLE [Application].[PaymentMethods] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[PaymentMethods] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[PaymentMethods_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_People_DataLoad_Modify];
    ALTER TABLE [Application].[People] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[People] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[People_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_StateProvinces_DataLoad_Modify];
    ALTER TABLE [Application].[StateProvinces] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[StateProvinces] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[StateProvinces_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Application].[TR_Application_TransactionTypes_DataLoad_Modify];
    ALTER TABLE [Application].[TransactionTypes] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Application].[TransactionTypes] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Application].[TransactionTypes_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Purchasing].[TR_Purchasing_SupplierCategories_DataLoad_Modify];
    ALTER TABLE [Purchasing].[SupplierCategories] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Purchasing].[SupplierCategories] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Purchasing].[SupplierCategories_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Purchasing].[TR_Purchasing_Suppliers_DataLoad_Modify];
    ALTER TABLE [Purchasing].[Suppliers] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Purchasing].[Suppliers] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Purchasing].[Suppliers_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_BuyingGroups_DataLoad_Modify];
    ALTER TABLE [Sales].[BuyingGroups] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[BuyingGroups] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[BuyingGroups_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_CustomerCategories_DataLoad_Modify];
    ALTER TABLE [Sales].[CustomerCategories] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[CustomerCategories] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[CustomerCategories_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Sales].[TR_Sales_Customers_DataLoad_Modify];
    ALTER TABLE [Sales].[Customers] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Sales].[Customers] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Sales].[Customers_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_ColdRoomTemperatures_DataLoad_Modify];
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[ColdRoomTemperatures] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[ColdRoomTemperatures_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_Colors_DataLoad_Modify];
    ALTER TABLE [Warehouse].[Colors] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[Colors] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[Colors_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_PackageTypes_DataLoad_Modify];
    ALTER TABLE [Warehouse].[PackageTypes] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[PackageTypes] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[PackageTypes_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_StockGroups_DataLoad_Modify];
    ALTER TABLE [Warehouse].[StockGroups] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[StockGroups] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[StockGroups_Archive], DATA_CONSISTENCY_CHECK = ON));
 
    DROP TRIGGER IF EXISTS [Warehouse].[TR_Warehouse_StockItems_DataLoad_Modify];
    ALTER TABLE [Warehouse].[StockItems] ADD PERIOD FOR SYSTEM_TIME([ValidFrom], [ValidTo]);
    ALTER TABLE [Warehouse].[StockItems] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Warehouse].[StockItems_Archive], DATA_CONSISTENCY_CHECK = ON));
 
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[DataLoadSimulation].[Configuration_ApplyDataLoadSimulationProcedures]](#dataloadsimulationconfiguration_applydataloadsimulationprocedures) | sql stored procedure |

[Back to top](#wideworldimporters)

### Integration.GetCityUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetCityUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20130101';

    CREATE TABLE #CityChanges
    (
        [WWI City ID] int,
        City nvarchar(50),
        [State Province] nvarchar(50),
        Country nvarchar(50),
        Continent nvarchar(30),
        [Sales Territory] nvarchar(50),
        Region nvarchar(30),
        Subregion nvarchar(30),
        [Location] geography,
        [Latest Recorded Population] bigint,
        [Valid From] datetime2(7),
        [Valid To] datetime2(7) NULL
    );

    DECLARE @CountryID int;
    DECLARE @StateProvinceID int;
    DECLARE @CityID int;
    DECLARE @ValidFrom datetime2(7);

    -- first need to find any country changes that have occurred since initial load

    DECLARE CountryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT co.CountryID,
           co.ValidFrom
    FROM [Application].Countries_Archive AS co
    WHERE co.ValidFrom > @LastCutoff
    AND co.ValidFrom <= @NewCutoff
    AND co.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT co.CountryID,
           co.ValidFrom
    FROM [Application].Countries AS co
    WHERE co.ValidFrom > @LastCutoff
    AND co.ValidFrom <= @NewCutoff
    AND co.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN CountryChangeList;
    FETCH NEXT FROM CountryChangeList INTO @CountryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE co.CountryID = @CountryID;

        FETCH NEXT FROM CountryChangeList INTO @CountryID, @ValidFrom;
    END;

    CLOSE CountryChangeList;
    DEALLOCATE CountryChangeList;

    -- next need to find any stateprovince changes that have occurred since initial load

    DECLARE StateProvinceChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT sp.StateProvinceID,
           sp.ValidFrom
    FROM [Application].StateProvinces_Archive AS sp
    WHERE sp.ValidFrom > @LastCutoff
    AND sp.ValidFrom <= @NewCutoff
    AND sp.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT sp.StateProvinceID,
           sp.ValidFrom
    FROM [Application].StateProvinces AS sp
    WHERE sp.ValidFrom > @LastCutoff
    AND sp.ValidFrom <= @NewCutoff
    AND sp.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN StateProvinceChangeList;
    FETCH NEXT FROM StateProvinceChangeList INTO @StateProvinceID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE sp.StateProvinceID = @StateProvinceID;

        FETCH NEXT FROM StateProvinceChangeList INTO @StateProvinceID, @ValidFrom;
    END;

    CLOSE StateProvinceChangeList;
    DEALLOCATE StateProvinceChangeList;

    -- finally need to find any city changes that have occurred, including during the initial load

    DECLARE CityChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.CityID,
           c.ValidFrom
    FROM [Application].Cities_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.CityID,
           c.ValidFrom
    FROM [Application].Cities AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN CityChangeList;
    FETCH NEXT FROM CityChangeList INTO @CityID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CityChanges
            ([WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion,
             [Location], [Latest Recorded Population], [Valid From], [Valid To])
        SELECT c.CityID, c.CityName, sp.StateProvinceName, co.CountryName, co.Continent, sp.SalesTerritory, co.Region, co.Subregion,
               c.[Location], COALESCE(c.LatestRecordedPopulation, 0), @ValidFrom, NULL
        FROM [Application].Cities FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN [Application].StateProvinces FOR SYSTEM_TIME AS OF @ValidFrom AS sp
        ON c.StateProvinceID = sp.StateProvinceID
        INNER JOIN [Application].Countries FOR SYSTEM_TIME AS OF @ValidFrom AS co
        ON sp.CountryID = co.CountryID
        WHERE c.CityID = @CityID;

        FETCH NEXT FROM CityChangeList INTO @CityID, @ValidFrom;
    END;

    CLOSE CityChangeList;
    DEALLOCATE CityChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_CityChanges ON #CityChanges ([WWI City ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same city but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #CityChanges AS cc2
                                                        WHERE cc2.[WWI City ID] = cc.[WWI City ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #CityChanges AS cc;

    SELECT [WWI City ID], City, [State Province], Country, Continent, [Sales Territory],
           Region, Subregion, [Location] geography, [Latest Recorded Population], [Valid From],
           [Valid To]
    FROM #CityChanges
    ORDER BY [Valid From];

    DROP TABLE #CityChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetCustomerUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetCustomerUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20130101';

    CREATE TABLE #CustomerChanges
    (
        [WWI Customer ID] int,
        Customer nvarchar(100),
        [Bill To Customer] nvarchar(100),
        Category nvarchar(50),
        [Buying Group] nvarchar(50),
        [Primary Contact] nvarchar(50),
        [Postal Code] nvarchar(10),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7) NULL
    );

    DECLARE @BuyingGroupID int;
    DECLARE @CustomerCategoryID int;
    DECLARE @CustomerID int;
    DECLARE @ValidFrom datetime2(7);

    -- first need to find any buying group changes that have occurred since initial load

    DECLARE BuyingGroupChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT bg.BuyingGroupID,
           bg.ValidFrom
    FROM Sales.BuyingGroups_Archive AS bg
    WHERE bg.ValidFrom > @LastCutoff
    AND bg.ValidFrom <= @NewCutoff
    AND bg.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT bg.BuyingGroupID,
           bg.ValidFrom
    FROM Sales.BuyingGroups AS bg
    WHERE bg.ValidFrom > @LastCutoff
    AND bg.ValidFrom <= @NewCutoff
    AND bg.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN BuyingGroupChangeList;
    FETCH NEXT FROM BuyingGroupChangeList INTO @BuyingGroupID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        WHERE c.BuyingGroupID = @BuyingGroupID;

        FETCH NEXT FROM BuyingGroupChangeList INTO @BuyingGroupID, @ValidFrom;
    END;

    CLOSE BuyingGroupChangeList;
    DEALLOCATE BuyingGroupChangeList;

    -- next need to find any customer category changes that have occurred since initial load

    DECLARE CustomerCategoryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT cc.CustomerCategoryID,
           cc.ValidFrom
    FROM Sales.CustomerCategories_Archive AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT cc.CustomerCategoryID,
           cc.ValidFrom
    FROM Sales.CustomerCategories AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN CustomerCategoryChangeList;
    FETCH NEXT FROM CustomerCategoryChangeList INTO @CustomerCategoryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        WHERE cc.CustomerCategoryID = @CustomerCategoryID;

        FETCH NEXT FROM CustomerCategoryChangeList INTO @CustomerCategoryID, @ValidFrom;
    END;

    CLOSE CustomerCategoryChangeList;
    DEALLOCATE CustomerCategoryChangeList;

    -- finally need to find any customer changes that have occurred, including during the initial load

    DECLARE CustomerChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.CustomerID,
           c.ValidFrom
    FROM Sales.Customers_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.CustomerID,
           c.ValidFrom
    FROM Sales.Customers AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN CustomerChangeList;
    FETCH NEXT FROM CustomerChangeList INTO @CustomerID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #CustomerChanges
            ([WWI Customer ID], Customer, [Bill To Customer], Category,
             [Buying Group], [Primary Contact], [Postal Code],
             [Valid From], [Valid To])
        SELECT c.CustomerID, c.CustomerName, bt.CustomerName, cc.CustomerCategoryName,
               bg.BuyingGroupName, p.FullName, c.DeliveryPostalCode,
               c.ValidFrom, c.ValidTo
        FROM Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS c
        INNER JOIN Sales.BuyingGroups FOR SYSTEM_TIME AS OF @ValidFrom AS bg
        ON c.BuyingGroupID = bg.BuyingGroupID
        INNER JOIN Sales.CustomerCategories FOR SYSTEM_TIME AS OF @ValidFrom AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Customers FOR SYSTEM_TIME AS OF @ValidFrom AS bt
        ON c.BillToCustomerID = bt.CustomerID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON c.PrimaryContactPersonID = p.PersonID
        WHERE c.CustomerID = @CustomerID;

        FETCH NEXT FROM CustomerChangeList INTO @CustomerID, @ValidFrom;
    END;

    CLOSE CustomerChangeList;
    DEALLOCATE CustomerChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_CustomerChanges ON #CustomerChanges ([WWI Customer ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same customer but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #CustomerChanges AS cc2
                                                        WHERE cc2.[WWI Customer ID] = cc.[WWI Customer ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #CustomerChanges AS cc;

    SELECT [WWI Customer ID], Customer, [Bill To Customer], Category,
           [Buying Group], [Primary Contact], [Postal Code],
           [Valid From], [Valid To]
    FROM #CustomerChanges
    ORDER BY [Valid From];

    DROP TABLE #CustomerChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetEmployeeUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetEmployeeUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #EmployeeChanges
    (
        [WWI Employee ID] int,
        Employee nvarchar(50),
        [Preferred Name] nvarchar(50),
        [Is Salesperson] bit,
        Photo varbinary(max),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @PersonID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any employee changes that have occurred, including during the initial load

    DECLARE EmployeeChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT p.PersonID,
           p.ValidFrom
    FROM [Application].People_Archive AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    AND p.IsEmployee <> 0
    UNION ALL
    SELECT p.PersonID,
           p.ValidFrom
    FROM [Application].People AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    AND p.IsEmployee <> 0
    ORDER BY ValidFrom;

    OPEN EmployeeChangeList;
    FETCH NEXT FROM EmployeeChangeList INTO @PersonID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #EmployeeChanges
            ([WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo,
             [Valid From], [Valid To])
        SELECT p.PersonID, p.FullName, p.PreferredName, p.IsSalesperson, p.Photo,
               p.ValidFrom, p.ValidTo
        FROM [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.PersonID = @PersonID;

        FETCH NEXT FROM EmployeeChangeList INTO @PersonID, @ValidFrom;
    END;

    CLOSE EmployeeChangeList;
    DEALLOCATE EmployeeChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_EmployeeChanges ON #EmployeeChanges ([WWI Employee ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #EmployeeChanges AS cc2
                                                        WHERE cc2.[WWI Employee ID] = cc.[WWI Employee ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #EmployeeChanges AS cc;

    SELECT [WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], Photo,
           [Valid From], [Valid To]
    FROM #EmployeeChanges
    ORDER BY [Valid From];

    DROP TABLE #EmployeeChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetMovementUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetMovementUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(sit.TransactionOccurredWhen AS date) AS [Date Key],
           sit.StockItemTransactionID AS [WWI Stock Item Transaction ID],
           sit.InvoiceID AS [WWI Invoice ID],
           sit.PurchaseOrderID AS [WWI Purchase Order ID],
           CAST(sit.Quantity AS int) AS Quantity,
           sit.StockItemID AS [WWI Stock Item ID],
           sit.CustomerID AS [WWI Customer ID],
           sit.SupplierID AS [WWI Supplier ID],
           sit.TransactionTypeID AS [WWI Transaction Type ID],
           sit.TransactionOccurredWhen AS [Transaction Occurred When]
    FROM Warehouse.StockItemTransactions AS sit
    WHERE sit.LastEditedWhen > @LastCutoff
    AND sit.LastEditedWhen <= @NewCutoff
    ORDER BY sit.StockItemTransactionID;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetOrderUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetOrderUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    SELECT CAST(o.OrderDate AS date) AS [Order Date Key],
           CAST(ol.PickingCompletedWhen AS date) AS [Picked Date Key],
           o.OrderID AS [WWI Order ID],
           o.BackorderOrderID AS [WWI Backorder ID],
           ol.[Description],
           pt.PackageTypeName AS Package,
           ol.Quantity AS Quantity,
           ol.UnitPrice AS [Unit Price],
           ol.TaxRate AS [Tax Rate],
           ROUND(ol.Quantity * ol.UnitPrice, 2) AS [Total Excluding Tax],
           ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Tax Amount],
           ROUND(ol.Quantity * ol.UnitPrice, 2) + ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Total Including Tax],
           c.DeliveryCityID AS [WWI City ID],
           c.CustomerID AS [WWI Customer ID],
           ol.StockItemID AS [WWI Stock Item ID],
           o.SalespersonPersonID AS [WWI Salesperson ID],
           o.PickedByPersonID AS [WWI Picker ID],
           CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Orders AS o
    INNER JOIN Sales.OrderLines AS ol
    ON o.OrderID = ol.OrderID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON ol.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
    ON c.CustomerID = o.CustomerID
    WHERE CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END > @LastCutoff
    AND CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END <= @NewCutoff
    ORDER BY o.OrderID;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetPaymentMethodUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetPaymentMethodUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #PaymentMethodChanges
    (
        [WWI Payment Method ID] int,
        [Payment Method] nvarchar(50),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @PaymentMethodID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any payment method changes that have occurred, including during the initial load

    DECLARE ChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT p.PaymentMethodID,
           p.ValidFrom
    FROM [Application].PaymentMethods_Archive AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT p.PaymentMethodID,
           p.ValidFrom
    FROM [Application].PaymentMethods AS p
    WHERE p.ValidFrom > @LastCutoff
    AND p.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN ChangeList;
    FETCH NEXT FROM ChangeList INTO @PaymentMethodID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #PaymentMethodChanges
            ([WWI Payment Method ID], [Payment Method], [Valid From], [Valid To])
        SELECT p.PaymentMethodID, p.PaymentMethodName, p.ValidFrom, p.ValidTo
        FROM [Application].PaymentMethods FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.PaymentMethodID = @PaymentMethodID;

        FETCH NEXT FROM ChangeList INTO @PaymentMethodID, @ValidFrom;
    END;

    CLOSE ChangeList;
    DEALLOCATE ChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_PaymentMethodChanges ON #PaymentMethodChanges ([WWI Payment Method ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #PaymentMethodChanges AS cc2
                                                        WHERE cc2.[WWI Payment Method ID] = cc.[WWI Payment Method ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #PaymentMethodChanges AS cc;

    SELECT [WWI Payment Method ID], [Payment Method], [Valid From], [Valid To]
    FROM #PaymentMethodChanges
    ORDER BY [Valid From];

    DROP TABLE #PaymentMethodChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetPurchaseUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetPurchaseUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    SELECT CAST(po.OrderDate AS date) AS [Date Key],
           po.PurchaseOrderID AS [WWI Purchase Order ID],
           pol.OrderedOuters AS [Ordered Outers],
           pol.OrderedOuters * si.QuantityPerOuter AS [Ordered Quantity],
           pol.ReceivedOuters AS [Received Outers],
           pt.PackageTypeName AS Package,
           pol.IsOrderLineFinalized AS [Is Order Finalized],
           po.SupplierID AS [WWI Supplier ID],
           pol.StockItemID AS [WWI Stock Item ID],
           CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END AS [Last Modified When]
    FROM Purchasing.PurchaseOrders AS po
    INNER JOIN Purchasing.PurchaseOrderLines AS pol
    ON po.PurchaseOrderID = pol.PurchaseOrderID
    INNER JOIN Warehouse.StockItems AS si
    ON pol.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON pol.PackageTypeID = pt.PackageTypeID
    WHERE CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END > @LastCutoff
    AND CASE WHEN pol.LastEditedWhen > po.LastEditedWhen THEN pol.LastEditedWhen ELSE po.LastEditedWhen END <= @NewCutoff
    ORDER BY po.PurchaseOrderID;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetSaleUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetSaleUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(i.InvoiceDate AS date) AS [Invoice Date Key],
           CAST(i.ConfirmedDeliveryTime AS date) AS [Delivery Date Key],
           i.InvoiceID AS [WWI Invoice ID],
           il.[Description],
           pt.PackageTypeName AS Package,
           il.Quantity,
           il.UnitPrice AS [Unit Price],
           il.TaxRate AS [Tax Rate],
           il.ExtendedPrice - il.TaxAmount AS [Total Excluding Tax],
           il.TaxAmount AS [Tax Amount],
           il.LineProfit AS Profit,
           il.ExtendedPrice AS [Total Including Tax],
           CASE WHEN si.IsChillerStock = 0 THEN il.Quantity ELSE 0 END AS [Total Dry Items],
           CASE WHEN si.IsChillerStock <> 0 THEN il.Quantity ELSE 0 END AS [Total Chiller Items],
           c.DeliveryCityID AS [WWI City ID],
           i.CustomerID AS [WWI Customer ID],
           i.BillToCustomerID AS [WWI Bill To Customer ID],
           il.StockItemID AS [WWI Stock Item ID],
           i.SalespersonPersonID AS [WWI Saleperson ID],
           CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Invoices AS i
    INNER JOIN Sales.InvoiceLines AS il
    ON i.InvoiceID = il.InvoiceID
    INNER JOIN Warehouse.StockItems AS si
    ON il.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes AS pt
    ON il.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
    ON i.CustomerID = c.CustomerID
    INNER JOIN Sales.Customers AS bt
    ON i.BillToCustomerID = bt.CustomerID
    WHERE CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END > @LastCutoff
    AND CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END <= @NewCutoff
    ORDER BY i.InvoiceID, il.InvoiceLineID;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetStockHoldingUpdates

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetStockHoldingUpdates
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT sih.QuantityOnHand AS [Quantity On Hand],
           sih.BinLocation AS [Bin Location],
           sih.LastStocktakeQuantity AS [Last Stocktake Quantity],
           sih.LastCostPrice AS [Last Cost Price],
           sih.ReorderLevel AS [Reorder Level],
           sih.TargetStockLevel AS [Target Stock Level],
           sih.StockItemID AS [WWI Stock Item ID]
    FROM Warehouse.StockItemHoldings AS sih
    ORDER BY sih.StockItemID;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetStockItemUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetStockItemUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #StockItemChanges
    (
        [WWI Stock Item ID] int,
        [Stock Item] nvarchar(100),
        Color nvarchar(20),
        [Selling Package] nvarchar(50),
        [Buying Package] nvarchar(50),
        Brand nvarchar(50),
        Size nvarchar(20),
        [Lead Time Days] int,
        [Quantity Per Outer] int,
        [Is Chiller Stock] bit,
        Barcode nvarchar(50),
        [Tax Rate] decimal(18,3),
        [Unit Price] decimal(18,2),
        [Recommended Retail Price] decimal(18,2),
        [Typical Weight Per Unit] decimal(18,3),
        Photo varbinary(max),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @StockItemID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any StockItem changes that have occurred, including during the initial load

    DECLARE StockItemChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.StockItemID,
           c.ValidFrom
    FROM Warehouse.StockItems_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.StockItemID,
           c.ValidFrom
    FROM Warehouse.StockItems AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN StockItemChangeList;
    FETCH NEXT FROM StockItemChangeList INTO @StockItemID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #StockItemChanges
            ([WWI Stock Item ID], [Stock Item], Color, [Selling Package],
             [Buying Package], Brand, Size, [Lead Time Days], [Quantity Per Outer],
             [Is Chiller Stock], Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price],
             [Typical Weight Per Unit], Photo, [Valid From], [Valid To])
        SELECT si.StockItemID, si.StockItemName, c.ColorName, spt.PackageTypeName,
               bpt.PackageTypeName, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
               si.IsChillerStock, si.Barcode, si.LeadTimeDays, si.UnitPrice, si.RecommendedRetailPrice,
               si.TypicalWeightPerUnit, si.Photo, si.ValidFrom, si.ValidTo
        FROM Warehouse.StockItems FOR SYSTEM_TIME AS OF @ValidFrom AS si
        INNER JOIN Warehouse.PackageTypes FOR SYSTEM_TIME AS OF @ValidFrom AS spt
        ON si.UnitPackageID = spt.PackageTypeID
        INNER JOIN Warehouse.PackageTypes FOR SYSTEM_TIME AS OF @ValidFrom AS bpt
        ON si.OuterPackageID = bpt.PackageTypeID
        LEFT OUTER JOIN Warehouse.Colors FOR SYSTEM_TIME AS OF @ValidFrom AS c
        ON si.ColorID = c.ColorID
        WHERE si.StockItemID = @StockItemID;

        FETCH NEXT FROM StockItemChangeList INTO @StockItemID, @ValidFrom;
    END;

    CLOSE StockItemChangeList;
    DEALLOCATE StockItemChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_StockItemChanges ON #StockItemChanges ([WWI Stock Item ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same StockItem but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #StockItemChanges AS cc2
                                                        WHERE cc2.[WWI Stock Item ID] = cc.[WWI Stock Item ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #StockItemChanges AS cc;

    SELECT [WWI Stock Item ID], [Stock Item],
           ISNULL(Color, N'N/A') AS Color,
           [Selling Package], [Buying Package],
           ISNULL(Brand, N'N/A') AS Brand,
           ISNULL(Size, N'N/A') AS Size,
           [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock],
           ISNULL(Barcode, N'N/A') AS Barcode,
           [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit],
           Photo, [Valid From], [Valid To]
    FROM #StockItemChanges
    ORDER BY [Valid From];

    DROP TABLE #StockItemChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetSupplierUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetSupplierUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';
    DECLARE @InitialLoadDate date = '20130101';

    CREATE TABLE #SupplierChanges
    (
        [WWI Supplier ID] int,
        Supplier nvarchar(100),
        Category nvarchar(50),
        [Primary Contact] nvarchar(50),
        [Supplier Reference] nvarchar(20),
        [Payment Days] int,
        [Postal Code] nvarchar(10),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @SupplierCategoryID int;
    DECLARE @SupplierID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any Supplier category changes that have occurred since initial load

    DECLARE SupplierCategoryChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT cc.SupplierCategoryID,
           cc.ValidFrom
    FROM Purchasing.SupplierCategories_Archive AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    UNION ALL
    SELECT cc.SupplierCategoryID,
           cc.ValidFrom
    FROM Purchasing.SupplierCategories AS cc
    WHERE cc.ValidFrom > @LastCutoff
    AND cc.ValidFrom <= @NewCutoff
    AND cc.ValidFrom <> @InitialLoadDate
    ORDER BY ValidFrom;

    OPEN SupplierCategoryChangeList;
    FETCH NEXT FROM SupplierCategoryChangeList INTO @SupplierCategoryID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #SupplierChanges
            ([WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
             [Payment Days], [Postal Code], [Valid From], [Valid To])
        SELECT s.SupplierID, s.SupplierName, sc.SupplierCategoryName, p.FullName, s.SupplierReference,
               s.PaymentDays, s.DeliveryPostalCode, s.ValidFrom, s.ValidTo
        FROM Purchasing.Suppliers FOR SYSTEM_TIME AS OF @ValidFrom AS s
        INNER JOIN Purchasing.SupplierCategories FOR SYSTEM_TIME AS OF @ValidFrom AS sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON s.PrimaryContactPersonID = p.PersonID
        WHERE sc.SupplierCategoryID = @SupplierCategoryID;

        FETCH NEXT FROM SupplierCategoryChangeList INTO @SupplierCategoryID, @ValidFrom;
    END;

    CLOSE SupplierCategoryChangeList;
    DEALLOCATE SupplierCategoryChangeList;

    -- finally need to find any Supplier changes that have occurred, including during the initial load

    DECLARE SupplierChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.SupplierID,
           c.ValidFrom
    FROM Purchasing.Suppliers_Archive AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT c.SupplierID,
           c.ValidFrom
    FROM Purchasing.Suppliers AS c
    WHERE c.ValidFrom > @LastCutoff
    AND c.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN SupplierChangeList;
    FETCH NEXT FROM SupplierChangeList INTO @SupplierID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #SupplierChanges
            ([WWI Supplier ID], Supplier, Category, [Primary Contact], [Supplier Reference],
             [Payment Days], [Postal Code], [Valid From], [Valid To])
        SELECT s.SupplierID, s.SupplierName, sc.SupplierCategoryName, p.FullName, s.SupplierReference,
               s.PaymentDays, s.DeliveryPostalCode, s.ValidFrom, s.ValidTo
        FROM Purchasing.Suppliers FOR SYSTEM_TIME AS OF @ValidFrom AS s
        INNER JOIN Purchasing.SupplierCategories FOR SYSTEM_TIME AS OF @ValidFrom AS sc
        ON s.SupplierCategoryID = sc.SupplierCategoryID
        INNER JOIN [Application].People FOR SYSTEM_TIME AS OF @ValidFrom AS p
        ON s.PrimaryContactPersonID = p.PersonID
        WHERE s.SupplierID = @SupplierID;

        FETCH NEXT FROM SupplierChangeList INTO @SupplierID, @ValidFrom;
    END;

    CLOSE SupplierChangeList;
    DEALLOCATE SupplierChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_SupplierChanges ON #SupplierChanges ([WWI Supplier ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same Supplier but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #SupplierChanges AS cc2
                                                        WHERE cc2.[WWI Supplier ID] = cc.[WWI Supplier ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #SupplierChanges AS cc;

    SELECT [WWI Supplier ID], Supplier, Category, [Primary Contact],
           [Supplier Reference], [Payment Days], [Postal Code],
           [Valid From], [Valid To]
    FROM #SupplierChanges
    ORDER BY [Valid From];

    DROP TABLE #SupplierChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetTransactionTypeUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetTransactionTypeUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime2(7) = '99991231 23:59:59.9999999';

    CREATE TABLE #TransactionTypeChanges
    (
        [WWI Transaction Type ID] int,
        [Transaction Type] nvarchar(50),
        [Valid From] datetime2(7),
        [Valid To] datetime2(7)
    );

    DECLARE @TransactionTypeID int;
    DECLARE @ValidFrom datetime2(7);

    -- need to find any Transaction Type changes that have occurred, including during the initial load

    DECLARE ChangeList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT tt.TransactionTypeID,
           tt.ValidFrom
    FROM [Application].TransactionTypes_Archive AS tt
    WHERE tt.ValidFrom > @LastCutoff
    AND tt.ValidFrom <= @NewCutoff
    UNION ALL
    SELECT tt.TransactionTypeID,
           tt.ValidFrom
    FROM [Application].TransactionTypes AS tt
    WHERE tt.ValidFrom > @LastCutoff
    AND tt.ValidFrom <= @NewCutoff
    ORDER BY ValidFrom;

    OPEN ChangeList;
    FETCH NEXT FROM ChangeList INTO @TransactionTypeID, @ValidFrom;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT #TransactionTypeChanges
            ([WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To])
        SELECT p.TransactionTypeID, p.TransactionTypeName, p.ValidFrom, p.ValidTo
        FROM [Application].TransactionTypes FOR SYSTEM_TIME AS OF @ValidFrom AS p
        WHERE p.TransactionTypeID = @TransactionTypeID;

        FETCH NEXT FROM ChangeList INTO @TransactionTypeID, @ValidFrom;
    END;

    CLOSE ChangeList;
    DEALLOCATE ChangeList;

    -- add an index to make lookups faster

    CREATE INDEX IX_TransactionTypeChanges ON #TransactionTypeChanges ([WWI Transaction Type ID], [Valid From]);

    -- work out the [Valid To] value by taking the [Valid From] of any row that's for the same entry but later
    -- otherwise take the end of time

    UPDATE cc
    SET [Valid To] = COALESCE((SELECT MIN([Valid From]) FROM #TransactionTypeChanges AS cc2
                                                        WHERE cc2.[WWI Transaction Type ID] = cc.[WWI Transaction Type ID]
                                                        AND cc2.[Valid From] > cc.[Valid From]), @EndOfTime)
    FROM #TransactionTypeChanges AS cc;

    SELECT [WWI Transaction Type ID], [Transaction Type], [Valid From], [Valid To]
    FROM #TransactionTypeChanges
    ORDER BY [Valid From];

    DROP TABLE #TransactionTypeChanges;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Integration.GetTransactionUpdates

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @LastCutoff | DATETIME2(7) | no |  |
| @NewCutoff | DATETIME2(7) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Integration.GetTransactionUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(ct.TransactionDate AS date) AS [Date Key],
           ct.CustomerTransactionID AS [WWI Customer Transaction ID],
           CAST(NULL AS int) AS [WWI Supplier Transaction ID],
           ct.InvoiceID AS [WWI Invoice ID],
           CAST(NULL AS int) AS [WWI Purchase Order ID],
           CAST(NULL AS nvarchar(20)) AS [Supplier Invoice Number],
           ct.AmountExcludingTax AS [Total Excluding Tax],
           ct.TaxAmount AS [Tax Amount],
           ct.TransactionAmount AS [Total Including Tax],
           ct.OutstandingBalance AS [Outstanding Balance],
           ct.IsFinalized AS [Is Finalized],
           COALESCE(i.CustomerID, ct.CustomerID) AS [WWI Customer ID],
           ct.CustomerID AS [WWI Bill To Customer ID],
           CAST(NULL AS int) AS [WWI Supplier ID],
           ct.TransactionTypeID AS [WWI Transaction Type ID],
           ct.PaymentMethodID AS [WWI Payment Method ID],
           ct.LastEditedWhen AS [Last Modified When]
    FROM Sales.CustomerTransactions AS ct
    LEFT OUTER JOIN Sales.Invoices AS i
    ON ct.InvoiceID = i.InvoiceID
    WHERE ct.LastEditedWhen > @LastCutoff
    AND ct.LastEditedWhen <= @NewCutoff

    UNION ALL

    SELECT CAST(st.TransactionDate AS date) AS [Date Key],
           CAST(NULL AS int) AS [WWI Customer Transaction ID],
           st.SupplierTransactionID AS [WWI Supplier Transaction ID],
           CAST(NULL AS int) AS [WWI Invoice ID],
           st.PurchaseOrderID AS [WWI Purchase Order ID],
           st.SupplierInvoiceNumber AS [Supplier Invoice Number],
           st.AmountExcludingTax AS [Total Excluding Tax],
           st.TaxAmount AS [Tax Amount],
           st.TransactionAmount AS [Total Including Tax],
           st.OutstandingBalance AS [Outstanding Balance],
           st.IsFinalized AS [Is Finalized],
           CAST(NULL AS int) AS [WWI Customer ID],
           CAST(NULL AS int) AS [WWI Bill To Customer ID],
           st.SupplierID AS [WWI Supplier ID],
           st.TransactionTypeID AS [WWI Transaction Type ID],
           st.PaymentMethodID AS [WWI Payment Method ID],
           st.LastEditedWhen AS [Last Modified When]
    FROM Purchasing.SupplierTransactions AS st
    WHERE st.LastEditedWhen > @LastCutoff
    AND st.LastEditedWhen <= @NewCutoff;

    RETURN 0;
END;

```

</details>

[Back to top](#wideworldimporters)

### Sequences.ReseedAllSequences

#### Definition

<details><summary>Click to expand</summary>

```sql
 
CREATE PROCEDURE Sequences.ReseedAllSequences
AS BEGIN
    -- Ensures that the next sequence values are above the maximum value of the related table columns
    SET NOCOUNT ON;
 
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'BuyingGroupID', @SchemaName = 'Sales', @TableName = 'BuyingGroups', @ColumnName = 'BuyingGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CityID', @SchemaName = 'Application', @TableName = 'Cities', @ColumnName = 'CityID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'ColorID', @SchemaName = 'Warehouse', @TableName = 'Colors', @ColumnName = 'ColorID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CountryID', @SchemaName = 'Application', @TableName = 'Countries', @ColumnName = 'CountryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerCategoryID', @SchemaName = 'Sales', @TableName = 'CustomerCategories', @ColumnName = 'CustomerCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'CustomerID', @SchemaName = 'Sales', @TableName = 'Customers', @ColumnName = 'CustomerID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'DeliveryMethodID', @SchemaName = 'Application', @TableName = 'DeliveryMethods', @ColumnName = 'DeliveryMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceID', @SchemaName = 'Sales', @TableName = 'Invoices', @ColumnName = 'InvoiceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'InvoiceLineID', @SchemaName = 'Sales', @TableName = 'InvoiceLines', @ColumnName = 'InvoiceLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderID', @SchemaName = 'Sales', @TableName = 'Orders', @ColumnName = 'OrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'OrderLineID', @SchemaName = 'Sales', @TableName = 'OrderLines', @ColumnName = 'OrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PackageTypeID', @SchemaName = 'Warehouse', @TableName = 'PackageTypes', @ColumnName = 'PackageTypeID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PaymentMethodID', @SchemaName = 'Application', @TableName = 'PaymentMethods', @ColumnName = 'PaymentMethodID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PersonID', @SchemaName = 'Application', @TableName = 'People', @ColumnName = 'PersonID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrders', @ColumnName = 'PurchaseOrderID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'PurchaseOrderLineID', @SchemaName = 'Purchasing', @TableName = 'PurchaseOrderLines', @ColumnName = 'PurchaseOrderLineID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SpecialDealID', @SchemaName = 'Sales', @TableName = 'SpecialDeals', @ColumnName = 'SpecialDealID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StateProvinceID', @SchemaName = 'Application', @TableName = 'StateProvinces', @ColumnName = 'StateProvinceID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockGroups', @ColumnName = 'StockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemID', @SchemaName = 'Warehouse', @TableName = 'StockItems', @ColumnName = 'StockItemID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'StockItemStockGroupID', @SchemaName = 'Warehouse', @TableName = 'StockItemStockGroups', @ColumnName = 'StockItemStockGroupID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierCategoryID', @SchemaName = 'Purchasing', @TableName = 'SupplierCategories', @ColumnName = 'SupplierCategoryID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SupplierID', @SchemaName = 'Purchasing', @TableName = 'Suppliers', @ColumnName = 'SupplierID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'SystemParameterID', @SchemaName = 'Application', @TableName = 'SystemParameters', @ColumnName = 'SystemParameterID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Purchasing', @TableName = 'SupplierTransactions', @ColumnName = 'SupplierTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Sales', @TableName = 'CustomerTransactions', @ColumnName = 'CustomerTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionID', @SchemaName = 'Warehouse', @TableName = 'StockItemTransactions', @ColumnName = 'StockItemTransactionID';
    EXEC Sequences.ReseedSequenceBeyondTableValues @SequenceName = 'TransactionTypeID', @SchemaName = 'Application', @TableName = 'TransactionTypes', @ColumnName = 'TransactionTypeID';
END;

```

</details>

[Back to top](#wideworldimporters)

### Sequences.ReseedSequenceBeyondTableValues

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SequenceName | SYSNAME(128) | no |  |
| @SchemaName | SYSNAME(128) | no |  |
| @TableName | SYSNAME(128) | no |  |
| @ColumnName | SYSNAME(128) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql
 
CREATE PROCEDURE Sequences.ReseedSequenceBeyondTableValues
@SequenceName sysname,
@SchemaName sysname,
@TableName sysname,
@ColumnName sysname
AS BEGIN
    -- Ensures that the next sequence value is above the maximum value of the supplied table column
    SET NOCOUNT ON;
 
    DECLARE @SQL nvarchar(max);
    DECLARE @CurrentTableMaximumValue bigint;
    DECLARE @NewSequenceValue bigint;
    DECLARE @CurrentSequenceMaximumValue bigint
        = (SELECT CAST(current_value AS bigint) FROM sys.sequences
                                                WHERE name = @SequenceName
                                                AND SCHEMA_NAME(schema_id) = N'Sequences');
    CREATE TABLE #CurrentValue
    (
        CurrentValue bigint
    )
 
    SET @SQL = N'INSERT #CurrentValue (CurrentValue) SELECT COALESCE(MAX(' + QUOTENAME(@ColumnName) + N'), 0) FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N';';
    EXECUTE (@SQL);
    SET @CurrentTableMaximumValue = (SELECT CurrentValue FROM #CurrentValue);
    DROP TABLE #CurrentValue;
 
    IF @CurrentTableMaximumValue >= @CurrentSequenceMaximumValue
    BEGIN
        SET @NewSequenceValue = @CurrentTableMaximumValue + 1;
        SET @SQL = N'ALTER SEQUENCE Sequences.' + QUOTENAME(@SequenceName) + N' RESTART WITH ' + CAST(@NewSequenceValue AS nvarchar(20)) + N';';
        EXECUTE (@SQL);
    END;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Sequences].[ReseedAllSequences]](#sequencesreseedallsequences) | sql stored procedure |

[Back to top](#wideworldimporters)

### Website.ActivateWebsiteLogon

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @PersonID | INT | no |  |
| @LogonName | NVARCHAR(50) | no |  |
| @InitialPassword | NVARCHAR(40) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.ActivateWebsiteLogon
@PersonID int,
@LogonName nvarchar(50),
@InitialPassword nvarchar(40)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE [Application].People
    SET IsPermittedToLogon = 1,
        LogonName = @LogonName,
        HashedPassword = HASHBYTES(N'SHA2_256', @InitialPassword + FullName),
        UserPreferences = (SELECT UserPreferences FROM [Application].People WHERE PersonID = 1) -- Person 1 has User Preferences template
    WHERE PersonID = @PersonID
    AND PersonID <> 1
    AND IsPermittedToLogon = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'The PersonID must be valid, must not be person 1, and must not already be enabled';
        THROW 51000, N'Invalid PersonID', 1;
        RETURN -1;
    END;
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.ChangePassword

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @PersonID | INT | no |  |
| @OldPassword | NVARCHAR(40) | no |  |
| @NewPassword | NVARCHAR(40) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.ChangePassword
@PersonID int,
@OldPassword nvarchar(40),
@NewPassword nvarchar(40)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE [Application].People
    SET IsPermittedToLogon = 1,
        HashedPassword = HASHBYTES(N'SHA2_256', @NewPassword + FullName)
    WHERE PersonID = @PersonID
    AND PersonID <> 1
    AND HashedPassword = HASHBYTES(N'SHA2_256', @OldPassword + FullName);

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'The PersonID must be valid, and the old password must be valid.';
        PRINT N'If the user has also changed name, please contact the IT staff to assist.';
        THROW 51000, N'Invalid Password Change', 1;
        RETURN -1;
    END;
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.InsertCustomerOrders

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @Orders | ORDERLIST | no |  |
| @OrderLines | ORDERLINELIST | no |  |
| @OrdersCreatedByPersonID | INT | no |  |
| @SalespersonPersonID | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.InsertCustomerOrders
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdersToGenerate AS TABLE
    (
        OrderReference int PRIMARY KEY,   -- reference from the application
        OrderID int
    );

    -- allocate the new order numbers

    INSERT @OrdersToGenerate (OrderReference, OrderID)
    SELECT OrderReference, NEXT VALUE FOR Sequences.OrderID
    FROM @Orders;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Sales.Orders
            (OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
             ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments,
             PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
               o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered, o.Comments, o.DeliveryInstructions, NULL,
               NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @Orders AS o
        ON otg.OrderReference = o.OrderReference;

        INSERT Sales.OrderLines
            (OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
             TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
        SELECT otg.OrderID, ol.StockItemID, ol.[Description], si.UnitPackageID, ol.Quantity,
               Website.CalculateCustomerPrice(o.CustomerID, ol.StockItemID, SYSDATETIME()),
               si.TaxRate, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
        FROM @OrdersToGenerate AS otg
        INNER JOIN @OrderLines AS ol
        ON otg.OrderReference = ol.OrderReference
		INNER JOIN @Orders AS o
		ON ol.OrderReference = o.OrderReference
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to create the customer orders.';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
```

</details>

[Back to top](#wideworldimporters)

### Website.InvoiceCustomerOrders

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @OrdersToInvoice | ORDERIDLIST | no |  |
| @PackedByPersonID | INT | no |  |
| @InvoicedByPersonID | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InvoicesToGenerate TABLE
    (
        OrderID int PRIMARY KEY,
        InvoiceID int NOT NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL
    );

    BEGIN TRY;

        -- Check that all orders exist, have been fully picked, and not already invoiced. Also allocate new invoice numbers.
        INSERT @InvoicesToGenerate (OrderID, InvoiceID, TotalDryItems, TotalChillerItems)
        SELECT oti.OrderID,
               NEXT VALUE FOR Sequences.InvoiceID,
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 0 ELSE 1 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0),
               COALESCE((SELECT SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END)
                         FROM Sales.OrderLines AS ol
                         INNER JOIN Warehouse.StockItems AS si
                         ON ol.StockItemID = si.StockItemID
                         WHERE ol.OrderID = oti.OrderID), 0)
        FROM @OrdersToInvoice AS oti
        INNER JOIN Sales.Orders AS o
        ON oti.OrderID = o.OrderID
        WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i
                                   WHERE i.OrderID = oti.OrderID)
        AND o.PickingCompletedWhen IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @OrdersToInvoice AS oti WHERE NOT EXISTS (SELECT 1 FROM @InvoicesToGenerate AS itg WHERE itg.OrderID = oti.OrderID))
        BEGIN
            PRINT N'At least one order ID either does not exist, is not picked, or is already invoiced';
            THROW 51000, N'At least one orderID either does not exist, is not picked, or is already invoiced', 1;
        END;

        BEGIN TRAN;

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,  DeliveryRun, RunPosition,
             ReturnedDeliveryData,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, c.CustomerID, c.BillToCustomerID, itg.OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, SYSDATETIME(), o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2, NULL,
               itg.TotalDryItems, itg.TotalChillerItems, c.DeliveryRun, c.RunPosition,
               JSON_MODIFY(N'{"Events": []}', N'append $.Events',
                   JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'{ }', N'$.Event', N'Ready for collection'),
                   N'$.EventTime', CONVERT(nvarchar(20), SYSDATETIME(), 126)),
                   N'$.ConNote', N'EAN-125-' + CAST(itg.InvoiceID + 1050 AS nvarchar(20)))),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Orders AS o
        ON itg.OrderID = o.OrderID
        INNER JOIN Sales.Customers AS c
        ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
        ON btc.CustomerID = c.BillToCustomerID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.OrderLines AS ol
        ON itg.OrderID = ol.OrderID
        INNER JOIN Warehouse.StockItems AS si
        ON ol.StockItemID = si.StockItemID
        INNER JOIN Warehouse.StockItemHoldings AS sih
        ON si.StockItemID = sih.StockItemID
        ORDER BY ol.OrderID, ol.OrderLineID;

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Stock Issue'),
               i.CustomerID, i.InvoiceID, NULL, NULL,
               SYSDATETIME(), 0 - il.Quantity, @InvoicedByPersonID, SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.InvoiceLines AS il
        ON itg.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Invoices AS i
        ON il.InvoiceID = i.InvoiceID
        ORDER BY il.InvoiceID, il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
            FROM Sales.InvoiceLines aS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM @InvoicesToGenerate)
            GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicedByPersonID,
            sih.LastEditedWhen = SYSDATETIME()
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        SELECT i.BillToCustomerID,
               (SELECT TransactionTypeID FROM [Application].TransactionTypes WHERE TransactionTypeName = N'Customer Invoice'),
               itg.InvoiceID,
               NULL,
               SYSDATETIME(),
               (SELECT SUM(il.ExtendedPrice - il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.TaxAmount) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               (SELECT SUM(il.ExtendedPrice) FROM Sales.InvoiceLines AS il WHERE il.InvoiceID = itg.InvoiceID),
               NULL,
               @InvoicedByPersonID,
               SYSDATETIME()
        FROM @InvoicesToGenerate AS itg
        INNER JOIN Sales.Invoices AS i
        ON itg.InvoiceID = i.InvoiceID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to invoice these orders';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
```

</details>

[Back to top](#wideworldimporters)

### Website.RecordColdRoomTemperatures

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SensorReadings | SENSORDATALIST | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
	TRANSACTION ISOLATION LEVEL = SNAPSHOT,
	LANGUAGE = N'English'
)
    BEGIN TRY

		DECLARE @NumberOfReadings int = (SELECT MAX(SensorDataListID) FROM @SensorReadings);
		DECLARE @Counter int = (SELECT MIN(SensorDataListID) FROM @SensorReadings);

		DECLARE @ColdRoomSensorNumber int;
		DECLARE @RecordedWhen datetime2(7);
		DECLARE @Temperature decimal(18,2);

		-- note that we cannot use a merge here because multiple readings might exist for each sensor

		WHILE @Counter <= @NumberOfReadings
		BEGIN
			SELECT @ColdRoomSensorNumber = ColdRoomSensorNumber,
			       @RecordedWhen = RecordedWhen,
				   @Temperature = Temperature
			FROM @SensorReadings
			WHERE SensorDataListID = @Counter;

			UPDATE Warehouse.ColdRoomTemperatures
				SET RecordedWhen = @RecordedWhen,
				    Temperature = @Temperature
			WHERE ColdRoomSensorNumber = @ColdRoomSensorNumber;

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT Warehouse.ColdRoomTemperatures
					(ColdRoomSensorNumber, RecordedWhen, Temperature)
				VALUES (@ColdRoomSensorNumber, @RecordedWhen, @Temperature);
			END;

			SET @Counter += 1;
		END;

    END TRY
    BEGIN CATCH
        THROW 51000, N'Unable to apply the sensor data', 2;

        RETURN 1;
    END CATCH;
END;
```

</details>

[Back to top](#wideworldimporters)

### Website.RecordVehicleTemperature

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @FullSensorDataArray | NVARCHAR(1000) | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.RecordVehicleTemperature
@FullSensorDataArray nvarchar(1000)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET XACT_ABORT ON;

    DECLARE @CrLf nchar(2) = nchar(13) + nchar(10);
    DECLARE @HelpMessage nvarchar(max) = N'JSON sensor data is invalid. An example of what is required is as follows:' + @CrLf + @CrLf
              + N'{"Recordings":' + @CrLf
              + N'    [' + @CrLf
              + N'        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":1,"when":"2016-01-01T07:00:00","temp":3.96}},' + @CrLf
              + N'        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":2,"when":"2016-01-01T07:00:00","temp":3.98}}' + @CrLf
              + N'    ]' + @CrLf
              + N'}';

    IF ISJSON(@FullSensorDataArray) = 0
    BEGIN
        PRINT @HelpMessage;
        THROW 51000, N'FullSensorDataArray must be valid JSON data', 1;
        RETURN 1;
    END;

    BEGIN TRY

        BEGIN TRAN;

        INSERT Warehouse.VehicleTemperatures
            (VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature,
			 FullSensorData, IsCompressed, CompressedSensorData)
		SELECT VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature,
		       FullSensorData, 0, NULL
		FROM OPENJSON(@FullSensorDataArray, N'$.Recordings')
        WITH ( VehicleRegistration nvarchar(40) N'$.properties.rego',
               ChillerSensorNumber int N'$.properties.sensor',
        	   RecordedWhen datetime2(7) N'$.properties.when',
        	   Temperature decimal(18,2) N'$.properties.temp',
        	   FullSensorData nvarchar(max) N'$' AS JSON);

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT N'Warning: No valid sensor data found';
            PRINT @HelpMessage;
        END;

        COMMIT;

    END TRY
    BEGIN CATCH
        PRINT @HelpMessage;

        THROW 51000, N'Valid JSON was supplied but does not match the temperature recordings array structure', 2;

        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        RETURN 1;
    END CATCH;
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.SearchForCustomers

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SearchText | NVARCHAR(1000) | no |  |
| @MaximumRowsToReturn | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.SearchForCustomers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           c.CustomerID,
           c.CustomerName,
           ct.CityName,
           c.PhoneNumber,
           c.FaxNumber,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Sales.Customers AS c
    INNER JOIN [Application].Cities AS ct
    ON c.DeliveryCityID = ct.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON c.PrimaryContactPersonID = p.PersonID
    WHERE CONCAT(c.CustomerName, N' ', p.FullName, N' ', p.PreferredName) LIKE N'%' + @SearchText + N'%'
    ORDER BY c.CustomerName
    FOR JSON AUTO, ROOT(N'Customers');
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.SearchForPeople

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SearchText | NVARCHAR(1000) | no |  |
| @MaximumRowsToReturn | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.SearchForPeople
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           p.PersonID,
           p.FullName,
           p.PreferredName,
           CASE WHEN p.IsSalesperson <> 0 THEN N'Salesperson'
                WHEN p.IsEmployee <> 0 THEN N'Employee'
                WHEN c.CustomerID IS NOT NULL THEN N'Customer'
                WHEN sp.SupplierID IS NOT NULL THEN N'Supplier'
                WHEN sa.SupplierID IS NOT NULL THEN N'Supplier'
           END AS Relationship,
           COALESCE(c.CustomerName, sp.SupplierName, sa.SupplierName, N'WWI') AS Company
    FROM [Application].People AS p
    LEFT OUTER JOIN Sales.Customers AS c
    ON c.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sp
    ON sp.PrimaryContactPersonID = p.PersonID
    LEFT OUTER JOIN Purchasing.Suppliers AS sa
    ON sa.AlternateContactPersonID = p.PersonID
    WHERE p.SearchName LIKE N'%' + @SearchText + N'%'
    ORDER BY p.FullName
    FOR JSON AUTO, ROOT(N'People');
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.SearchForStockItems

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SearchText | NVARCHAR(1000) | no |  |
| @MaximumRowsToReturn | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.SearchForStockItems
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.SearchDetails LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.SearchForStockItemsByTags

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SearchText | NVARCHAR(1000) | no |  |
| @MaximumRowsToReturn | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.SearchForStockItemsByTags
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.Tags LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;

```

</details>

[Back to top](#wideworldimporters)

### Website.SearchForSuppliers

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SearchText | NVARCHAR(1000) | no |  |
| @MaximumRowsToReturn | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE PROCEDURE Website.SearchForSuppliers
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           s.SupplierID,
           s.SupplierName,
           c.CityName,
           s.PhoneNumber,
           s.FaxNumber ,
           p.FullName AS PrimaryContactFullName,
           p.PreferredName AS PrimaryContactPreferredName
    FROM Purchasing.Suppliers AS s
    INNER JOIN [Application].Cities AS c
    ON s.DeliveryCityID = c.CityID
    LEFT OUTER JOIN [Application].People AS p
    ON s.PrimaryContactPersonID = p.PersonID
    WHERE CONCAT(s.SupplierName, N' ', p.FullName, N' ', p.PreferredName) LIKE N'%' + @SearchText + N'%'
    ORDER BY s.SupplierName
    FOR JSON AUTO, ROOT(N'Suppliers');
END;

```

</details>

[Back to top](#wideworldimporters)

</details>

## Scalar Functions

<details><summary>Click to expand</summary>

* [Website.CalculateCustomerPrice](#websitecalculatecustomerprice)

### Website.CalculateCustomerPrice

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| *Output* | DECIMAL(18,2) | yes |  |
| @CustomerID | INT | no |  |
| @StockItemID | INT | no |  |
| @PricingDate | DATE | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE FUNCTION Website.CalculateCustomerPrice
(
    @CustomerID int,
    @StockItemID int,
    @PricingDate date
)
RETURNS decimal(18,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    DECLARE @CalculatedPrice decimal(18,2);
    DECLARE @UnitPrice decimal(18,2);
    DECLARE @LowestUnitPrice decimal(18,2);
    DECLARE @HighestDiscountAmount decimal(18,2);
    DECLARE @HighestDiscountPercentage decimal(18,3);
    DECLARE @BuyingGroupID int;
    DECLARE @CustomerCategoryID int;
    DECLARE @DiscountedUnitPrice decimal(18,2);

    SELECT @BuyingGroupID = BuyingGroupID,
           @CustomerCategoryID = CustomerCategoryID
    FROM Sales.Customers
    WHERE CustomerID = @CustomerID;

    SELECT @UnitPrice = si.UnitPrice
    FROM Warehouse.StockItems AS si
    WHERE si.StockItemID = @StockItemID;

    SET @CalculatedPrice = @UnitPrice;

    SET @LowestUnitPrice = (SELECT MIN(sd.UnitPrice)
                            FROM Sales.SpecialDeals AS sd
                            WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                            AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                            AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                            AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                            AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                               WHERE sisg.StockItemID = @StockItemID
                                                                               AND sisg.StockGroupID = sd.StockGroupID))
                            AND sd.UnitPrice IS NOT NULL
                            AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @LowestUnitPrice IS NOT NULL AND @LowestUnitPrice < @UnitPrice
    BEGIN
        SET @CalculatedPrice = @LowestUnitPrice;
    END;

    SET @HighestDiscountAmount = (SELECT MAX(sd.DiscountAmount)
                                  FROM Sales.SpecialDeals AS sd
                                  WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                                  AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                                  AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                                  AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                                  AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                                     WHERE sisg.StockItemID = @StockItemID
                                                                                     AND sisg.StockGroupID = sd.StockGroupID))
                                  AND sd.DiscountAmount IS NOT NULL
                                  AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @HighestDiscountAmount IS NOT NULL AND (@UnitPrice - @HighestDiscountAmount) < @CalculatedPrice
    BEGIN
        SET @CalculatedPrice = @UnitPrice - @HighestDiscountAmount;
    END;

    SET @HighestDiscountPercentage = (SELECT MAX(sd.DiscountPercentage)
                                      FROM Sales.SpecialDeals AS sd
                                      WHERE ((sd.StockItemID = @StockItemID) OR (sd.StockItemID IS NULL))
                                      AND ((sd.CustomerID = @CustomerID) OR (sd.CustomerID IS NULL))
                                      AND ((sd.BuyingGroupID = @BuyingGroupID) OR (sd.BuyingGroupID IS NULL))
                                      AND ((sd.CustomerCategoryID = @CustomerCategoryID) OR (sd.CustomerCategoryID IS NULL))
                                      AND ((sd.StockGroupID IS NULL) OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups AS sisg
                                                                                         WHERE sisg.StockItemID = @StockItemID
                                                                                         AND sisg.StockGroupID = sd.StockGroupID))
                                      AND sd.DiscountPercentage IS NOT NULL
                                      AND @PricingDate BETWEEN sd.StartDate AND sd.EndDate);

    IF @HighestDiscountPercentage IS NOT NULL
    BEGIN
        SET @DiscountedUnitPrice = ROUND(@UnitPrice * @HighestDiscountPercentage / 100.0, 2);
        IF @DiscountedUnitPrice < @CalculatedPrice SET @CalculatedPrice = @DiscountedUnitPrice;
    END;


    RETURN @CalculatedPrice;
END;

```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

</details>

## Table Functions

<details><summary>Click to expand</summary>

* [Application.DetermineCustomerAccess](#applicationdeterminecustomeraccess)

### Application.DetermineCustomerAccess

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @CityID | INT | no |  |

#### Definition

<details><summary>Click to expand</summary>

```sql

CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N'db_owner') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N' Sales') <> 0
	    OR (ORIGINAL_LOGIN() = N'Website'
		    AND EXISTS (SELECT 1
		                FROM [Application].Cities AS c
				        INNER JOIN [Application].StateProvinces AS sp
				        ON c.StateProvinceID = sp.StateProvinceID
				        WHERE c.CityID = @CityID
				        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
```

</details>

#### Referenced By

| Object | Type |
| --- | --- |
| [[Application].[FilterCustomersBySalesTerritoryRole]](#applicationfiltercustomersbysalesterritoryrole) | security policy |

[Back to top](#wideworldimporters)

</details>

## User Defined Table Types

<details><summary>Click to expand</summary>

* [Website.OrderIDList](#websiteorderidlist)
* [Website.OrderLineList](#websiteorderlinelist)
* [Website.OrderList](#websiteorderlist)
* [Website.SensorDataList](#websitesensordatalist)

### Website.OrderIDList

| Column | Type | Null | Default | Description |
| --- | ---| --- | --- | --- |
| **OrderID** | INT | no |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[InvoiceCustomerOrders]](#websiteinvoicecustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Website.OrderLineList

| Column | Type | Null | Default | Description |
| --- | ---| --- | --- | --- |
| OrderReference | INT | yes |  |  |
| StockItemID | INT | yes |  |  |
| Description | NVARCHAR(100) | yes |  |  |
| Quantity | INT | yes |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Website.OrderList

| Column | Type | Null | Default | Description |
| --- | ---| --- | --- | --- |
| **OrderReference** | INT | no |  |  |
| CustomerID | INT | yes |  |  |
| ContactPersonID | INT | yes |  |  |
| ExpectedDeliveryDate | DATE | yes |  |  |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | yes |  |  |
| IsUndersupplyBackordered | BIT | yes |  |  |
| Comments | NVARCHAR(MAX) | yes |  |  |
| DeliveryInstructions | NVARCHAR(MAX) | yes |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[InsertCustomerOrders]](#websiteinsertcustomerorders) | sql stored procedure |

[Back to top](#wideworldimporters)

### Website.SensorDataList

| Column | Type | Null | Default | Description |
| --- | ---| --- | --- | --- |
| **SensorDataListID** | INT | no |  |  |
| ColdRoomSensorNumber | INT | yes |  |  |
| RecordedWhen | DATETIME2(7) | yes |  |  |
| Temperature | DECIMAL(18,2) | yes |  |  |

#### Referenced By

| Object | Type |
| --- | --- |
| [[Website].[RecordColdRoomTemperatures]](#websiterecordcoldroomtemperatures) | sql stored procedure |

[Back to top](#wideworldimporters)

</details>

----
