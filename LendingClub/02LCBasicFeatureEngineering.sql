USE lendingclub
GO

--DROP unnecessary column desc 
ALTER TABLE [dbo].[LoanStats] DROP COLUMN [desc]
GO

--Remove % from int_rate and convert its type to float 
UPDATE [dbo].[LoanStats] SET [int_rate] = REPLACE([int_rate], '%', '')
ALTER TABLE [dbo].[LoanStats] ALTER COLUMN [int_rate] float
GO

--Remove % from revol_util and convert its type to float
UPDATE [dbo].[LoanStats] SET [revol_util] = REPLACE([revol_util], '%', '')
ALTER TABLE [dbo].[LoanStats] ALTER COLUMN [revol_util] float
GO

--Remove rows where loan_status is empty
DELETE FROM [dbo].[LoanStats] where [loan_status] IS NULL
GO

--Classify all loans as good/bad based on its status and store it in a column named “is_bad”
ALTER TABLE [dbo].[LoanStats] ADD [is_bad] int
GO

UPDATE [dbo].[LoanStats] 
SET [is_bad] = (CASE WHEN loan_status IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') THEN 1 ELSE 0 END)
GO

/*
	Open the Rgui (Run as Administrator) and install any required R packages using install.packages
*/
