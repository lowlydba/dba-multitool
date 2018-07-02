# SQL 2018
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql10_50.SQL2008R2SP2\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpDynamicPorts -value '0'
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql10_50.SQL2008R2SP2\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpPort -value ''

# SQL 2012
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql11.SQL2012SP1\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpDynamicPorts -value '0'
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql11.SQL2012SP1\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpPort -value ''

# SQL 2014
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql12.SQL2014\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpDynamicPorts -value '0'
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql12.SQL2014\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpPort -value ''

# SQL 2016
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql13.SQL2016\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpDynamicPorts -value '0'
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql13.SQL2016\mssqlserver\supersocketnetlib\tcp\ipall' -name TcpPort -value ''