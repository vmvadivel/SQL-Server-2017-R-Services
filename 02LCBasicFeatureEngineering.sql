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

CREATE PROCEDURE [dbo].[SplitLoans]  
AS  
BEGIN  
  SET NOCOUNT ON;  
  -- 75% Training data 
  DROP TABLE IF EXISTS [dbo].[LoanStatsTrain]
  SELECT * INTO [dbo].[LoanStatsTrain] FROM (SELECT * FROM [dbo].[LoanStats] WHERE (ABS(CAST((BINARY_CHECKSUM(id, NEWID())) as int)) % 100) < 75)a
  -- 25% Test data
  DROP TABLE IF EXISTS [dbo].[LoanStatsTest]
  SELECT * INTO [dbo].[LoanStatsTest] FROM (SELECT * FROM [dbo].[LoanStats] WHERE [id] NOT IN (SELECT [id] FROM [dbo].[LoanStatsTrain]))a

END
GO

EXEC [dbo].[SplitLoans]
GO

CREATE PROCEDURE [dbo].[BuildModel]  
AS  
BEGIN  
  DECLARE @inquery nvarchar(max) = N'SELECT * FROM [dbo].[LoanStatsTrain]'  
  
  DROP TABLE IF EXISTS [dbo].[models]
  CREATE TABLE [dbo].[models]([model] [varbinary](max) NOT NULL)

  INSERT INTO [dbo].[models]
  EXEC sp_execute_external_script 
  @language = N'R',  
  @script = N'  
  randomForestObj <- rxDForest(is_bad ~ revol_util + int_rate + mths_since_last_record + annual_inc_joint + dti_joint + total_rec_prncp + all_util, InputDataSet)
  model <- data.frame(payload = as.raw(serialize(randomForestObj, connection=NULL)))
  ',
  @input_data_1 = @inquery,  
  @output_data_1_name = N'model'  
 
END  
GO

EXEC [dbo].[BuildModel]
GO

CREATE PROCEDURE [dbo].[ScoreLoans] 
AS  
BEGIN  
  DECLARE @inquery nvarchar(max) = N'SELECT * FROM [dbo].[LoanStatsTest]'  
  DECLARE @model varbinary(max) = (SELECT TOP 1 model FROM models)
  
  DROP TABLE IF EXISTS [dbo].[LoanStatsPredictions]
  CREATE TABLE [dbo].[LoanStatsPredictions]([is_bad_Pred] [float] NULL, [id] [int] NULL) 

  INSERT INTO [dbo].[LoanStatsPredictions]   
  EXEC sp_execute_external_script 
  @language = N'R',
  @script = N'  
  rfModel <- unserialize(as.raw(model));  
  OutputDataSet<-rxPredict(rfModel, data = InputDataSet, extraVarsToWrite = c("id"))
  ',
  @input_data_1 = @inquery,
  @params = N'@model varbinary(max)',
  @model = @model
  
END  
GO

EXEC [dbo].[ScoreLoans]
GO

SELECT TOP 10 * FROM [dbo].[LoanStatsPredictions]
GO