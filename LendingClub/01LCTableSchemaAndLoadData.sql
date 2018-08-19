CREATE DATABASE [lendingclub]
GO

USE lendingclub
GO

CREATE PROCEDURE [dbo].[LoadData]  
AS  
BEGIN  
	DROP TABLE IF EXISTS [dbo].[LoanStats]
	CREATE TABLE [dbo].[LoanStats]
	(
		[id] [int] NULL,
		[member_id] [int] NULL,
		[loan_amnt] [int] NULL,
		[funded_amnt] [int] NULL,
		[funded_amnt_inv] [int] NULL,
		[term] [nvarchar](max) NULL,
		[int_rate] [nvarchar](max) NULL,
		[installment] [float] NULL,
		[grade] [nvarchar](max) NULL,
		[sub_grade] [nvarchar](max) NULL,
		[emp_title] [nvarchar](max) NULL,
		[emp_length] [nvarchar](max) NULL,
		[home_ownership] [nvarchar](max) NULL,
		[annual_inc] [float] NULL,
		[verification_status] [nvarchar](max) NULL,
		[issue_d] [nvarchar](max) NULL,
		[loan_status] [nvarchar](max) NULL,
		[pymnt_plan] [nvarchar](max) NULL,
		[url] [nvarchar](max) NULL,
		[desc] [nvarchar](max) NULL,
		[purpose] [nvarchar](max) NULL,
		[title] [nvarchar](max) NULL,
		[zip_code] [nvarchar](max) NULL,
		[addr_state] [nvarchar](max) NULL,
		[dti] [float] NULL,
		[delinq_2yrs] [int] NULL,
		[earliest_cr_line] [nvarchar](max) NULL,
		[inq_last_6mths] [int] NULL,
		[mths_since_last_delinq] [int] NULL,
		[mths_since_last_record] [int] NULL,
		[open_acc] [int] NULL,
		[pub_rec] [int] NULL,
		[revol_bal] [int] NULL,
		[revol_util] [nvarchar](max) NULL,
		[total_acc] [int] NULL,
		[initial_list_status] [nvarchar](max) NULL,
		[out_prncp] [float] NULL,
		[out_prncp_inv] [float] NULL,
		[total_pymnt] [float] NULL,
		[total_pymnt_inv] [float] NULL,
		[total_rec_prncp] [float] NULL,
		[total_rec_int] [float] NULL,
		[total_rec_late_fee] [float] NULL,
		[recoveries] [float] NULL,
		[collection_recovery_fee] [float] NULL,
		[last_pymnt_d] [nvarchar](max) NULL,
		[last_pymnt_amnt] [float] NULL,
		[next_pymnt_d] [nvarchar](max) NULL,
		[last_credit_pull_d] [nvarchar](max) NULL,
		[collections_12_mths_ex_med] [int] NULL,
		[mths_since_last_major_derog] [int] NULL,
		[policy_code] [int] NULL,
		[application_type] [nvarchar](max) NULL,
		[annual_inc_joint] [float] NULL,
		[dti_joint] [float] NULL,
		[verification_status_joint] [nvarchar](max) NULL,
		[acc_now_delinq] [int] NULL,
		[tot_coll_amt] [int] NULL,
		[tot_cur_bal] [int] NULL,
		[open_acc_6m] [int] NULL,
		[open_il_6m] [int] NULL,
		[open_il_12m] [int] NULL,
		[open_il_24m] [int] NULL,
		[mths_since_rcnt_il] [int] NULL,
		[total_bal_il] [int] NULL,
		[il_util] [float] NULL,
		[open_rv_12m] [int] NULL,
		[open_rv_24m] [int] NULL,
		[max_bal_bc] [int] NULL,
		[all_util] [float] NULL,
		[total_rev_hi_lim] [int] NULL,
		[inq_fi] [int] NULL,
		[total_cu_tl] [int] NULL,
		[inq_last_12m] [int] NULL
	) 

	INSERT INTO [dbo].[LoanStats]
	EXEC sp_execute_external_script 
	@language = N'R',
	@script = N'OutputDataSet <- read.csv("C:/lendingclub/loan.csv", h=T,sep = ",")'
                                  
END  
GO

--Load the data into the table
EXEC [dbo].[LoadData]


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


uninstall.packages(c("reshape2","ggplot2","ROCR","plyr","Rcpp","stringr","stringi","magrittr","digest","gtable",
"proto","scales","munsell","colorspace","labeling","gplots","gtools","gdata","caTools","bitops"), 
lib = "C:\\Program Files\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\R_SERVICES\\library")


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