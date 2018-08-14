/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

/* Turn off CLR Strict if 2017 */
DECLARE @Version INT =(SELECT CAST(LEFT(@version, CHARINDEX('.', @version, 0)-1) AS INT));

IF (@Version = 14)
BEGIN
	EXEC sp_configure 'clr strict security', 0;
	RECONFIGURE;
END
GO