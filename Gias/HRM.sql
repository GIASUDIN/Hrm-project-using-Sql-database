--====================================================================
--							         DDL PART
--====================================================================
USE master
GO
--Drop database HumanResourceManagement
--go

DECLARE @data_path nvarchar(256);
SET @data_path = (SELECT SUBSTRING(physical_name,1,CHARINDEX(N'master.mdf', LOWER(physical_name))-1)
	FROM master.sys.master_files
	WHERE database_id=1 AND file_id=1
);

EXECUTE ('CREATE DATABASE HumanResourceManagement
ON PRIMARY (NAME=HumanResourceManagement_data, FILENAME='''+@data_path+'HumanResourceManagement_data.mdf'', SIZE=100MB, MAXSIZE=UNLIMITED, FILEGROWTH=5%)
LOG ON (NAME=HumanResourceManagement_log, FILENAME='''+@data_path+'HumanResourceManagement_log.ldf'', SIZE=50MB, MAXSIZE=200MB, FILEGROWTH=2%)
');
GO

USE HumanResourceManagement
GO

--===============================================================================
--							Create Schema
--===============================================================================
CREATE SCHEMA hrm
GO

--===============================================================================
--			All infomation of Employee at the Joining time.  T_1
--===============================================================================
USE HumanResourceManagement
Go
DROP TABLE IF EXISTS hrm.Employees
CREATE TABLE hrm.Employees
(
EmployeeID int PRIMARY KEY IDENTITY(1001,1),
FirstName varchar(20) NOT NULL,
LastName varchar(20) NOT NULL,
JoiningDate date NOT NULL,
PsesentAddress nvarchar(60) CONSTRAINT CN_EmployeeAddress DEFAULT ('UNKNOWN'),                                                                     
PermanentAddress nvarchar(60) sparse,
MobileNo char(15) NOT NULL CHECK ((MobileNo like '[0][1][0-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]')),
EmailAddress nvarchar(50) sparse CHECK ((EmailAddress Like '%@%')),
EmpNID varchar(30)
);
GO

--=============================================================================
--					All infomation of DEPARTMENT====T_2
--=============================================================================
CREATE TABLE hrm.Department
(
DepartmentId int PRIMARY KEY IDENTITY(101,1),
DeptName nvarchar(50) NOT NULL,
[Description] nvarchar(50) sparse
);
GO

--=============================================================================
--			All infomation of DEPARTMENT WISE DESIGNATION.      T_3
--=============================================================================
CREATE TABLE hrm.Designations
(
DesignationId int PRIMARY KEY,
Designation nvarchar(50) not null,
Remarks nvarchar(50) sparse
);
GO

--=============================================================================
--					Job Location========T_4
--=============================================================================
CREATE TABLE hrm.JobLocation
(
LocationId int PRIMARY KEY identity(1,1),
PostingLocation varchar(50) not null,
[Description] varchar(30)
);
GO

--=============================================================================
--						Employee Posting =====T_5
--=============================================================================
CREATE TABLE hrm.RecruitmentInfo
(
RecruitmentID int IDENTITY(1,1),
EmployeeID int FOREIGN KEY REFERENCES hrm.Employees(EmployeeID) NOT NULL,
DepartmentId int FOREIGN KEY REFERENCES hrm.Department(DepartmentId) ON UPDATE CASCADE NOT NULL,
DesignationId int FOREIGN KEY REFERENCES hrm.Designations(DesignationId) ON UPDATE CASCADE NOT NULL,
LocationId int FOREIGN KEY REFERENCES hrm.JobLocation(LocationId) ON UPDATE CASCADE NOT NULL,
[Description] varchar(30)
);
GO

--=============================================================================
--								Salary_Sheet=====T_6
--=============================================================================
CREATE TABLE hrm.Salary_Sheet
(
SalaryID int identity(1,1),
EmployeeID int NOT NULL FOREIGN KEY REFERENCES hrm.Employees(EmployeeID) ON DELETE CASCADE,
BasicSalary Money,
Houserent Money,
Medical Money,
MobileBill Money,
travelAllowance Money
);
GO

Select * From hrm.Employees
Select * From hrm.Department
Select * From hrm.Designations
Select * From hrm.JobLocation
Select * From hrm.Salary_Sheet
Go

--================================ADD More Table In Future=============================================
--Employee Transpar
--Employee Promotion
--Employee Attendance
--Salary increment
--======================================================================================================

--======================================================================================================
---										ADD COLUMN
--======================================================================================================
Alter Table hrm.Employees
ADD DateofBirth nvarchar(30);
GO

--====================================================================================================
--										DElETE column 
--====================================================================================================
ALTER Table hrm.Employees
DROP Column DateofBirth;
GO

--====================================================================================================
--								Index(clustered,non-clustered)
--====================================================================================================
CREATE Clustered Index CI_SalaryID ON hrm.Salary_Sheet(SalaryID)
GO

CREATE NonClustered Index NCI_JoiningDate ON hrm.Employees(JoiningDate)
GO

CREATE NonClustered Index NCI_DeptName ON hrm.Department(DeptName)
GO

CREATE NonClustered Index NCI_PostingLocation ON hrm.JobLocation(PostingLocation)
GO

--================================================================================================================
--									Create Sequence
--================================================================================================================
Use HumanResourceManagement
Create Sequence sq_Sequence
	As Bigint
	Start With 1
	Increment By 1
	Minvalue 1
	Maxvalue 99999
	No Cycle
	Cache 10;
	GO

Select Next value for sq_Sequence
GO
--================================================================================================================
--								A Simple View With Encryption (View: vw_EmployeeInfo)
--================================================================================================================

CREATE View vw_EmployeeInfo
With Encryption
As
Select EmployeeID, FirstName, LastName,  JoiningDate, PsesentAddress, PermanentAddress, MobileNo, EmailAddress
From hrm.Employees;
GO

Select * From vw_EmployeeInfo
GO

sp_helptext vw_EmployeeInfo
GO
--=================================================================================================================
--								Renaming The View (SP_Rename 'Old Name', 'New name'
--=================================================================================================================

SP_Rename 'vw_EmployeeInfo', 'vw_EmployeeInfoDetails'
GO


--==============================================================================================================
--									View with Schemabinding
--==============================================================================================================
Create View vw_RecruitmentInfo
With Schemabinding
As
Select EmployeeID, DepartmentId, DesignationId, LocationId
From hrm.RecruitmentInfo
GO

Select * From vw_RecruitmentInfo
GO

--==============================================================================================================
--					Join More than one Tables & Create a Complex Query From Your Both Tables
--==============================================================================================================
CREATE VIEW vw_SalaryDetails AS
    WITH CteEmp (MyID,MaxPayDate) AS (
        SELECT EmployeeID, MAX(BasicSalary) AS MaxBasic
        FROM hrm.Salary_Sheet AS SP
        GROUP BY EmployeeID
    )
    SELECT e.EmployeeID,e.FirstName,e.LastName, d.DeptName, s.BasicSalary, s.Houserent, s.Medical, s.MobileBill
    FROM hrm.Employees AS e
    JOIN hrm.Salary_Sheet AS s ON s.EmployeeID = e.EmployeeID
	JOIN hrm.RecruitmentInfo AS r ON e.EmployeeID = r.EmployeeID
    JOIN hrm.Department as d ON d.DepartmentId = r.DepartmentId
    GROUP BY e.EmployeeID, e.FirstName,e.LastName,d.DeptName, s.BasicSalary, s.Houserent, s.Medical, s.MobileBill
GO

SELECT * FROM vw_SalaryDetails 
GO

--=================================================================================================================
---								Procedure Create (Search By Name)
--=================================================================================================================
Create PROC sp_SearchName
@Name nvarchar(20)
AS
Select FirstName, LastName 
From hrm.Employees
Where FirstName like @Name +'%'  or LastName like @Name +'%'
GO

EXEC sp_SearchName 'Iftekhar'

Select * From hrm.Employees
GO


--drop proc sp_SearchName
--GO
--===================================================================================================================
--											Store Procedure For Insert
--===================================================================================================================
CREATE PROC sp_EmployeeInfo_Insert
(
	@EmployeeID int,
	@FirstName varchar(20),
	@LastName varchar(20),
	@JoiningDate date,
	@PsesentAddress nvarchar(60),
	@PermanentAddress nvarchar(60),
	@MobileNo varchar(15),
	@EmailAddress nvarchar(50),
	@EmpNID varchar(25)	
)
AS
BEGIN
	INSERT INTO hrm.Employees ( EmployeeID,FirstName,LastName,JoiningDate,PsesentAddress,PermanentAddress,MobileNo,EmailAddress,EmpNID)
	Values(@EmployeeID,@FirstName,@LastName,@JoiningDate,@PsesentAddress,@PermanentAddress,@MobileNo,@EmailAddress,@EmpNID)
END
GO

EXEC sp_EmployeeInfo_Insert 1001, 'Tarrq', 'Abdullah', '01/03/2022', 'Dhaka', 'Noakhali', '01975684571','Tareq@gmail.com', '5684856952';
GO

Select * From hrm.Employees
GO

--===================================================================================================================
--							CrudOperation: Insert Update Delete By Store Procedure
--====================================================================================================================

Create Proc sp_Employees

	@EmployeeID int,
	@FirstName varchar(20),
	@LastName varchar(20),
	@JoiningDate date,
	@PsesentAddress nvarchar(60),
	@PermanentAddress nvarchar(60),
	@MobileNo varchar(15),
	@EmailAddress nvarchar(50),
	@EmpNID varchar(25),

	@tablename varchar(25),
	@operationname varchar(30)
AS
Begin
	IF @tablename='hrm.Employees' and @operationname='Insert'
		Begin
			Insert hrm.Employees Values(@FirstName,@LastName,@JoiningDate,@PsesentAddress,@PermanentAddress,@MobileNo,@EmailAddress,@EmpNID)
		End
	IF @tablename='hrm.Employees' and @operationname='Update'
		Begin
			Update hrm.Employees Set FirstName=@firstname, LastName=@lastname, MobileNo=@MobileNo, EmpNID=@EmpNID Where EmployeeID=@employeeid
		End
	IF @tablename='hrm.Employees' and @operationname='Delete'
		Begin
			Delete From hrm.Employees Where EmployeeID=@employeeid
		End
	IF @tablename='hrm.Employees' and @operationname='Select'
		Begin
			Select * From hrm.Employees
		End
End
GO

 --==============================================================================================================
--											Function Create (function hrm.Salary_details)
--===============================================================================================================
create function hrm.Salary_details
(
	@BasicSalary Money,
	@Houserent Money,
	@Medical Money,
	@MobileBill Money,
	@travelAllowance Money
	
)
returns money
as
begin
	declare @total money 
	set @total= @BasicSalary + @Houserent + @Medical + @MobileBill + @travelAllowance
	return @total
end
GO

--==============================================================================================================
--										Create Trigger on Employee Table
--==============================================================================================================
USE HumanResourceManagement
GO
Create Table hrm.Employee_Audit
(
EmployeeID int,
FirstName varchar(20),
LastName varchar(20),
JoiningDate date,
PsesentAddress nvarchar(60),                                                                     
PermanentAddress nvarchar(60),
MobileNo char(15),
EmailAddress nvarchar(50),
EmpNID varchar(30),
Audit_Action varchar(100),
Audit_Timestamp datetime
);
GO

--==============================================================================================================
--										Create Trigger on Employee Table (After Insert Tr_1)
--==============================================================================================================
CREATE TRIGGER trg_AfterInsert on hrm.Employees
For Insert
AS
Declare @EmployeeID int,@FirstName varchar(20),@LastName varchar(20),@JoiningDate date,@PsesentAddress nvarchar(60),
		@PermanentAddress nvarchar(60),@MobileNo char(15),@EmailAddress nvarchar(50),@EmpNID varchar(30),@audit_action varchar(100);

Select @EmployeeID =i.employeeID from inserted i;
Select @firstname=i.FirstName from inserted i;
Select @lastname=i.LastName from inserted i;
Select @JoiningDate=i.JoiningDate from inserted i;
Select @PsesentAddress=i.PsesentAddress from inserted i;
Select @PermanentAddress=i.PermanentAddress from inserted i;
Select @MobileNo=i.MobileNo from inserted i;
Select @EmailAddress=i.EmailAddress from inserted i;
Select @EmpNID=i.EmpNID from inserted i;
Set @audit_action='Inserted Record -- After Insert Trigger.';

Insert Into Employee_Audit(EmployeeID,FirstName,LastName,JoiningDate,PsesentAddress,PermanentAddress,MobileNo,EmailAddress,EmpNID,Audit_Action,Audit_Timestamp)
Values(@employeeid,@firstname,@lastname,@JoiningDate,@PsesentAddress,@MobileNo,@EmailAddress,@EmpNID,@audit_action,GETDATE());

PRINT 'After Insert Trigger Fired.'
GO

--Insert Into hrm.Employees Values('Hasan','Rahman','01/06/2019','Rajsahi','Srimongol','01812 222 566', 'rahman56@gmail.com', 'Dhaka','2214962007',2,8);
--Go

Select * From hrm.Employees
Select * From hrm.Employee_Audit
GO

--==============================================================================================================
--										Create Trigger on Employee Table (After UPDATE Tr_1)
--==============================================================================================================
Create Trigger trg_AfterUpdate ON hrm.Employees
For UPDATE
AS
	Declare @EmployeeID int,@FirstName varchar(20),@LastName varchar(20),@JoiningDate date,@PsesentAddress nvarchar(60),
		@PermanentAddress nvarchar(60),@MobileNo char(15),@EmailAddress nvarchar(50),@EmpNID varchar(30),@audit_action varchar(100);

Select @EmployeeID =i.employeeID from inserted i;
Select @firstname=i.FirstName from inserted i;
Select @lastname=i.LastName from inserted i;
Select @JoiningDate=i.JoiningDate from inserted i;
Select @PsesentAddress=i.PsesentAddress from inserted i;
Select @PermanentAddress=i.PermanentAddress from inserted i;
Select @MobileNo=i.MobileNo from inserted i;
Select @EmailAddress=i.EmailAddress from inserted i;
Select @EmpNID=i.EmpNID from inserted i;
Set @audit_action='Update Record -- After Insert Trigger.';

	IF Update(FirstName)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(LastName)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(JoiningDate)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(PsesentAddress)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(PermanentAddress)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(MobileNo)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(EmailAddress)
		set @audit_action='Updated Record -- After Update Trigger.';
	IF Update(EmpNID)
		set @audit_action='Updated Record -- After Update Trigger.';
	
	Insert Into Employee_Audit(EmployeeID,FirstName,LastName,JoiningDate,PsesentAddress,PermanentAddress,MobileNo,EmailAddress,EmpNID,Audit_Action,Audit_Timestamp)
	Values(@employeeid,@firstname,@lastname,@JoiningDate,@PsesentAddress,@MobileNo,@EmailAddress,@EmpNID,@audit_action,GETDATE());

	PRINT 'After Update Trigger Fired.'
GO

--Update hrm.Employees Set MobileNo='01854 654 800' where EmployeeID=8
--GO

--==============================================================================================================
--										Create Trigger on Employee Table (After Delete Tr_1)
--==============================================================================================================
Create Trigger trg_AfterDelete On hrm.Employees
For Delete
AS
	Declare @EmployeeID int,@FirstName varchar(20),@LastName varchar(20),@JoiningDate date,@PsesentAddress nvarchar(60),
		@PermanentAddress nvarchar(60),@MobileNo char(15),@EmailAddress nvarchar(50),@EmpNID varchar(30),@audit_action varchar(100);

Select @EmployeeID =i.employeeID from inserted i;
Select @firstname=i.FirstName from inserted i;
Select @lastname=i.LastName from inserted i;
Select @JoiningDate=i.JoiningDate from inserted i;
Select @PsesentAddress=i.PsesentAddress from inserted i;
Select @PermanentAddress=i.PermanentAddress from inserted i;
Select @MobileNo=i.MobileNo from inserted i;
Select @EmailAddress=i.EmailAddress from inserted i;
Select @EmpNID=i.EmpNID from inserted i;
Set @audit_action='Deleted -- After Delete Trigger.';

Insert Into Employee_Audit(EmployeeID,FirstName,LastName,JoiningDate,PsesentAddress,PermanentAddress,MobileNo,EmailAddress,EmpNID,Audit_Action,Audit_Timestamp)
Values(@employeeid,@firstname,@lastname,@JoiningDate,@PsesentAddress,@MobileNo,@EmailAddress,@EmpNID,@audit_action,GETDATE());

PRINT 'After Delete Trigger Fired.'
Go

--Delete From hrm.Employees Where EmployeeID=8
--GO

Drop Trigger trg_AfterInsert
Drop Trigger trg_AfterDelete
Drop Trigger trg_AfterUpdate

--=================================================================================================================
--							Instead of Trigger on Employee Table (insert, Update, Delete Tr_1)
--=================================================================================================================
USE HumanResourceManagement
GO

Create Trigger trg_InsertUpdateDelete on hrm.Employees
Instead of insert, Update, Delete
AS
Declare @rowcount int
Set @rowcount=@@ROWCOUNT
IF(@rowcount>1)
				BEGIN
				Raiserror('You cannot Update or Delete more than 1 Record',16,1)	
				END
Else 
	Print 'Insert, Update or Delete Successful'
GO

Insert into hrm.Employees(PsesentAddress) Values ('Ctg');

Delete From hrm.Employees Where EmployeeID=9;
GO
Select * From hrm.Employees
GO

--==================================================================================
--									Temporary Table(Local and Global)
--==================================================================================
CREATE TABLE #Tmp_HRM
(
ID int identity,
Address Varchar(30) CONSTRAINT CN_Defaultaddress DEFAULT ('UNKNOWN'),
Phone Char(15) Not Null  CHECK ((Phone Like '[0][1][1-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]' )),
DateInSystem DATE Not Null CONSTRAINT CN_dateinsystem DEFAULT (GETDATE())
);
GO

CREATE TABLE ##Tmp_Resource
(
ID int identity ,
Address Varchar(30) CONSTRAINT CN_Dfltaddress DEFAULT ('UNKNOWN'),
Phone Char(15) Not Null  CHECK ((Phone Like '[0][1][1-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]' )),
DateInSystem DATE Not Null CONSTRAINT CN_dateinmethod DEFAULT (GETDATE())
);
GO

Drop Table #tmp_HRM
GO
Drop Table ##tmp_Resource
GO

--==================================================================================
--									Scalar Function to Get Total Recruitment 
--==================================================================================
Create Function hrm.fn_recruitment()
Returns int 
AS
Begin
	Return(Select SUM(RecruitmentID) From hrm.RecruitmentInfo) 
End
GO

print hrm.fn_rec()
Go

--==================================================================================
--						                Tabular Function
--==================================================================================
Create Function hrm.fn_SalaryHistory()
Returns table
As
Return
(
Select *
From hrm.Salary_Sheet where SalaryID=1
)
GO

Select * From hrm.fn_SalaryHistory()
GO


--====================================================================
--							         DML PART
--====================================================================

TRUNCATE TABLE hrm.Employee
TRUNCATE TABLE hrm.Department
TRUNCATE TABLE hrm.Designations
TRUNCATE TABLE hrm.JobLocation
TRUNCATE TABLE hrm.Salary_Sheet
GO

Select * From hrm.Employees
Select * From hrm.Department
Select * From hrm.Designations
Select * From hrm.JobLocation
Select * From hrm.Salary_Sheet
Go

USE HumanResourceManagement
GO

--==================================================================================================================
--                     INSERT INTO EMPLOYEEES TABLE  T_1
--==================================================================================================================

INSERT INTO hrm.Employees (FirstName, LastName,  JoiningDate, PsesentAddress, PermanentAddress, MobileNo, EmailAddress) 
				Values ('Iftekhar', 'Ahammed', '01/01/2022', ' Ctg', ' Feni ', '01829628862', 'iftekharahammed1@gmail.com'),
					   ('Hasan', 'Mahmud', '01/01/2020', ' Ctg', ' Dhaka ', '01658628462', 'hasan@gmail.com'),
					   ('Khalil', 'Ahammed', '01/05/2019', ' Ctg', ' Comilla ', '01658628842', 'Khalil@gmail.com'),
					   ('Subhan', 'Mahmud', '07/07/2018', ' Ctg', ' Maymansing ', '01929628567', 'subhan@gmail.com');
GO


--==================================================================================================================
--                     INSERT INTO DEPARTMENT TABLE     T_2
--==================================================================================================================

INSERT INTO hrm.Department (DeptName, [Description]) 
				Values ('Accounts', ''), ('Sales & Marketing', ''), ('Brand & Marketing', ''), 
					   ('Audit', ''), ('Purchase', '');
GO

--==================================================================================================================
--                     INSERT INTO Designations TABLE          T_3
--==================================================================================================================
INSERT INTO hrm.Designations (DesignationId, Designation, Remarks) 
				Values (1, 'Junior Accounts', 'Accounts Department'), 
					   (30, 'Junior Sales Officer', 'Sales & Marketing'), 
					   (60,'Brand Officer', 'Brand & Marketing'), 
					   (90,'Junior Audit officer', 'Audit Department'), 
					   (120, 'Junior Officer', 'Purchase Department');
GO

--==================================================================================================================
--                     INSERT INTO JobLocation TABLE           T_4
--==================================================================================================================

INSERT INTO hrm.JobLocation (PostingLocation, [Description]) 
				Values ('Dhaka', ''), ('Gazipur', ''), ('Narayanganj', ''), ('MunshiGanj', ''), ('Narsingdee', '');
GO

--==================================================================================================================
--									   INSERT INTO RecruitmentInfo TABLE			T_5
--==================================================================================================================

INSERT INTO hrm.RecruitmentInfo (EmployeeID, DepartmentId, DesignationId, LocationId) 
				Values (1001, 3, 60, 1);
GO

--==================================================================================================================
--									  INSERT INTO Salary_Sheet TABLE			T_6
--==================================================================================================================

INSERT INTO hrm.Salary_Sheet (EmployeeID, BasicSalary, Houserent, Medical, MobileBill, travelAllowance) 
				Values (1001, 20000.00, 2500.00, 1500.00, 1000.00, 2000.00);
GO

--==================================================================================================
--					Crud operation in (View: vw_EmployeeInfo) view_01
--==================================================================================================
Insert into vw_EmployeeInfo (FirstName, LastName,  JoiningDate, PsesentAddress, PermanentAddress, MobileNo, EmailAddress)
						Values ('Golam', 'Azam', '01/01/2022', ' Dhaka', ' Feni ', '01825628862', 'azam@gmail.com'),
							   ('Abdur', 'Rahman', '01/03/2022', ' Dhaka', ' Cumilla ', '01985628862', 'abdur12@gmail.com');

UPDATE vw_EmployeeInfo 
SET MobileNo = '01985635415' Where EmployeeID = 1003

DELETE FROM vw_EmployeeInfo
Where EmployeeID = 1002
GO

--===================================================================================================================
--							CrudOperation: Insert Update Delete By Store Procedure (Proc sp_Employees) sp_01
--====================================================================================================================

Exec sp_Employees 1005,'Jamal','Uddin', '01/05/2020','Ctg','Comilla','01698547569','jamal@gmail.com', '0125875668798', 'hrm.Employees', 'Insert';
GO

Exec sp_Employees 1006,'Jamal','Uddin', '01/05/2020','Ctg','Comilla','01698547569','jamal@gmail.com', '0125875668798', 'hrm.Employees', 'Update';
GO

Exec sp_Employees 1006,'Jamal','Uddin', '01/05/2020','Ctg','Comilla','01698547569','jamal@gmail.com', '0125875668798', 'hrm.Employees', 'Delete';
GO

Select * From hrm.Employees
GO

 --================================================================================================================
--										Query from function hrm.Salary_details fn_01
--=================================================================================================================
declare @result int = hrm.Salary_details (20000, 2500, 1500, 1000, 2500)
select @result
GO	

SELECT hrm.Salary_details (20000, 2500, 1500, 1000, 2500)
PRINT hrm.Salary_details (20000, 2500, 1500, 1000, 2500)
GO

--================================================================================================================
--										INNER JOIN
--================================================================================================================
SELECT e.EmployeeID,e.FirstName,e.JoiningDate,e.EmailAddress,d.DeptName,des.Designation,BasicSalary,sa.Houserent,sa.Medical,sa.Medical,sa.MobileBill,sa.travelAllowance
FROM hrm.Employees e
INNER JOIN hrm.RecruitmentInfo r ON e.EmployeeID = r.EmployeeID
INNER JOIN hrm.Department d ON d.DepartmentId = r.DepartmentId
INNER JOIN hrm.Designations des ON des.DesignationId = r.DesignationId
INNER JOIN hrm.Salary_Sheet sa ON sa.EmployeeID = e.EmployeeID
ORDER BY e.EmployeeID
GO

SELECT e.EmployeeID, (e.FirstName + ' ' +e.LastName +', ' + EmailAddress) AS [Employee Info], DeptName
FROM hrm.Employees e
INNER JOIN hrm.RecruitmentInfo r ON e.EmployeeID = r.EmployeeID
INNER JOIN hrm.Department d ON d.DepartmentId = r.DepartmentId
ORDER BY e.EmployeeID
GO

--================================================================================================================
--											LEFT JOIN
--================================================================================================================
SELECT *
FROM hrm.Employees e
LEFT JOIN hrm.Salary_Sheet s ON e.EmployeeID = s.EmployeeID
ORDER BY e.EmployeeID
GO

--================================================================================================================
--											RIGHT JOIN
--================================================================================================================
SELECT *
FROM hrm.Salary_Sheet s
RIGHT JOIN hrm.Employees e 
ON e.EmployeeID = s.EmployeeID
ORDER BY e.EmployeeID
GO

--================================================================================================================
--											FULL JOIN
--================================================================================================================
SELECT e.EmployeeID,e.FirstName,e.JoiningDate,e.EmailAddress,d.DeptName,des.Designation,BasicSalary,sa.Houserent,sa.Medical,sa.Medical,sa.MobileBill,sa.travelAllowance
FROM hrm.Employees e
FULL JOIN hrm.RecruitmentInfo r ON e.EmployeeID = r.EmployeeID
FULL JOIN hrm.Department d ON d.DepartmentId = r.DepartmentId
FULL JOIN hrm.Designations des ON des.DesignationId = r.DesignationId
FULL JOIN hrm.Salary_Sheet sa ON sa.EmployeeID = e.EmployeeID
ORDER BY e.EmployeeID
GO

--================================================================================================================
--											CROSS JOIN
--================================================================================================================
SELECT *
FROM hrm.Department
CROSS JOIN hrm.Designations
GO

--================================================================================================================
--											SELF JOIN
--================================================================================================================
SELECT DISTINCT e1.EmployeeID
FROM hrm.Employees e1, hrm.Employees e2
WHERE e1.EmployeeID <> e2.EmployeeID
GO

SELECT * FROM hrm.Employees
GO

--================================================================================================================
--										UNION Operator
--================================================================================================================
SELECT EmployeeID FROM hrm.Employees
UNION
SELECT EmployeeID FROM hrm.Salary_Sheet
ORDER BY EmployeeID;

--================================================================================================================
--										Six Clauses
--================================================================================================================
SELECT PsesentAddress, count(employeeID)
FROM hrm.Employees
WHERE JoiningDate> '07/07/2018'
GROUP BY PsesentAddress
HAVING count(employeeID)>0

--================================================================================================================
--										Sub Query
--================================================================================================================
SELECT * 
FROM hrm.JobLocation
WHERE PostingLocation in (SELECT PostingLocation FROM hrm.JobLocation WHERE PostingLocation= 'Narayanganj')
GO

--================================================================================================================
--											CTE
--================================================================================================================
WITH cte_Salary
AS
(SELECT EmployeeID,BasicSalary, Houserent, Medical, MobileBill, travelAllowance
FROM hrm.Salary_Sheet WHERE Houserent<MobileBill)

SELECT *
FROM hrm.Salary_Sheet ss
FULL JOIN cte_Salary s ON ss.SalaryID= s.BasicSalary
GO

--================================================================================================================
--											Cube
--================================================================================================================
SELECT s.EmployeeID, SUM(Houserent) AS TotalHouseRant 
FROM hrm.Salary_Sheet s
JOIN hrm.Employees e ON e.EmployeeID = s.EmployeeID
GROUP BY s.EmployeeID WITH CUBE
GO

--==================================================================================================================
--Rollup
--==================================================================================================================
SELECT s.EmployeeID, SUM(Houserent) AS TotalHouseRant 
FROM hrm.Salary_Sheet s
JOIN hrm.Employees e ON e.EmployeeID = s.EmployeeID
GROUP BY s.EmployeeID WITH ROLLUP
GO

--==================================================================================================================
--Grouping sets
--==================================================================================================================
SELECT s.EmployeeID, e.JoiningDate, SUM(Houserent) AS TotalHouseRant 
FROM hrm.Salary_Sheet s
JOIN hrm.Employees e ON e.EmployeeID = s.EmployeeID
GROUP BY GROUPING SETS (s.EmployeeID, e.JoiningDate)
GO

--==================================================================================================================
-----------==--Case
--==================================================================================================================
SELECT EmployeeID, FirstName,
	CASE FirstName
		WHEN 'Hasan' THEN 'RIGHT'
		WHEN 'Khalil' THEN 'BAD'
		ELSE 'Bad' 
	END AS Name
FROM hrm.Employees

--==================================================================================================================
-------=====-- BETWEEN
--==================================================================================================================

WHERE EmployeeID BETWEEN 2 AND 3
GO

--==================================================================================================================
------==== Query with OR 
--==================================================================================================================
SELECT*
FROM hrm.Employees 
WHERE FirstName='Hasan' OR LastName='Mahmud'
GO

--================================================================================================================== 
----========Query  with AND 
--==================================================================================================================FROM sm.Students
SELECT*
FROM hrm.Salary_Sheet
WHERE EmployeeID =1001 AND BasicSalary=20000.00
GO


--==========================================================
--================ Query with IN 
--==========================================================
SELECT EmployeeID
FROM hrm.Employees 
WHERE EmployeeID IN '1'
GO

--============================================================
--=============--Query with NOT IN 
--============================================================

SELECT * 
FROM hrm.Employees 
WHERE PermanentAddress NOT IN ('Dhaka')
GO

--============================================================
---=============---TOP
--============================================================
SELECT TOP 2 HE.EmployeeID, FirstName, JoiningDate, DeptName
FROM hrm.Employees as HE JOIN hrm.RecruitmentInfo as HR
on HE.EmployeeID =  HR.EmployeeID
JOIN hrm.Department as D ON HR.RecruitmentID = D.DepartmentId
ORDER BY  JoiningDate 
GO

--=================================================================
---==============--WildCard & Like
--=================================================================
SELECT * 
FROM hrm.Employees
WHERE MobileNo LIKE '01852%'
GO

----===============================================================
-----==== ----While Loop
---================================================================
DECLARE @g int
SET @g=2
WHILE @g<=4
BEGIN
		PRINT 'Value  ' + CAST(@g AS varchar)
		SET @g=@g+1
END
GO

---===================================================================
-----===============--IIF
---===================================================================
SELECT EmployeeID, BasicSalary, Houserent,
	IIF(EmployeeID<=1001, 20000.00, 1500.00) AS Due
FROM hrm.Salary_Sheet
GO

--=======================================================================
----================--Choose
---======================================================================
SELECT EmployeeID, BasicSalary, Houserent,
	CHOOSE(EmployeeID<=1001, 20000.00, 1500.00) AS Due
FROM hrm.Salary_Sheet
WHERE BasicSalary + Houserent >10500
GO

--========================================================================
---===========Isnull
--========================================================================
SELECT EmployeeID, BasicSalary, Houserent,
	ISNULL(BasicSalary,'basic') AS basicS
FROM hrm.Salary_Sheet
GO

----===============================================================================
--Coalesce
---================================================================================

SELECT EmployeeID, BasicSalary, Houserent,
	COALESCE(BasicSalary, 'basic') AS Due
FROM hrm.Salary_Sheet
GO

-----===========================================================================
--==========--Ranking Functions
--==============================================================================
SELECT ROW_NUMBER() OVER(PARTITION BY FirstName ORDER BY EmployeeID) AS RowNumbr, FirstName, EmployeeID
FROM hrm.Employees

SELECT RANK() OVER(PARTITION BY FirstName ORDER BY EmployeeID) AS RANK, FirstName, EmployeeID
FROM hrm.Employees

SELECT DENSE_RANK() OVER(PARTITION BY FirstName ORDER BY EmployeeID) AS DENSE_RANK, FirstName, EmployeeID
FROM hrm.Employees

SELECT NTILE(LastName) OVER(PARTITION BY FirstName ORDER BY EmployeeID) AS NTILE, FirstName, EmployeeID
FROM hrm.Employees

---=========================================================================
--Analytical functions
---=========================================================================
SELECT FIRST_VALUE(FirstName) OVER(PARTITION BY MobileNo ORDER BY EmployeeID) AS FirstName, EmployeeID
FROM hrm.Employees

SELECT LAST_VALUE(FirstName) OVER(PARTITION BY MobileNo ORDER BY EmployeeID) AS FirstName, EmployeeID
FROM hrm.Employees

SELECT PERCENT_RANK() OVER(PARTITION BY JoiningDate ORDER BY EmployeeID) AS FirstName,LastName, EmployeeID
FROM hrm.Employees

SELECT PERCENTILE_CONT(.4) WITHIN GROUP  (ORDER BY EmployeeID)OVER(PARTITION BY EmployeeID) AS PERCENTILECOUNT, FirstName,LastName, EmployeeID
FROM hrm.Employees

SELECT CUME_DIST() WITHIN GROUP (ORDER BY EmployeeID)  OVER(PARTITION BY StudentID) AS FirstName, LastName, EmployeeID
FROM hrm.Employees

SELECT PERCENTILE_DISC(.5) WITHIN GROUP  (ORDER BY EmployeeID)OVER(PARTITION BY EmployeeID) AS PERCENTILE_DISC, FirstName,LastName, EmployeeID
FROM hrm.Employees

--======================================================================================================
--Ceiling, Floor, Round
--======================================================================================================
SELECT CEILING(10.75) AS [Ceiling Value];
GO
SELECT FLOOR(60.50) AS [Floor Value];
GO
SELECT ROUND(37.65,1) AS [Round Value];
GO
SELECT ABS(-54.65) AS [Absolute Value];
GO
SELECT RAND(-56.65) AS [Random Value];
GO
SELECT ISNUMERIC('ABC') AS [IS NUMERIC?];
GO

--=================================================================================================
--										Aggregate functions
--=================================================================================================
SELECT COUNT(BasicSalary) Basics, SUM(Houserent) Houserent, AVG(Medical) Medical
FROM hrm.Salary_Sheet
GO


--Mathematical Operator
SELECT 10+2 as [Sum]
GO
SELECT 10-2 as [Substraction]
GO
SELECT 10*3 as [Multiplication]
GO
SELECT 10/2 as [Divide]
GO
SELECT 10%3 as [Remainder]
GO

--Cast, Convert, Concatenation
SELECT 'Today : ' + CAST(GETDATE() as varchar)
Go

SELECT 'Today : ' + CONVERT(varchar,GETDATE(),1)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),2)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),3)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),4)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),5)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),6)
GO

--Isdate
SELECT ISDATE('2030-05-21')
--Datepart
SELECT DATEPART(MONTH,'2030-05-21')
--Datename
SELECT DATENAME(MONTH,'2030-05-21')
--Sysdatetime
SELECT Sysdatetime()
--UTC
SELECT GETUTCDATE()


