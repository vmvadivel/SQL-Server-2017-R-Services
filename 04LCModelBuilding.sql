USE lendingclub
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