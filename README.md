Excel Automation
====

Objective
----
Previously the data in the Excel file is manually loaded into database (copy-paste), now I was assigned to automate this procedure. See below as requirements:

* Excel file will update the database automatically
* If excel file crashed, reopen it and continue

Simple as that.

How to do
----
There are three main parts about this project.
* Excel VBA: Update the database; write to log file.
* Batch: Entry point of this project, is responsible for reopening and monitoring.
* VBScript Helper: Provide some functions which batch doesn't support.

Instruction
----
_ExcelWatcher2.bat_: Entry point.
_ExcelWatcher.bat_: another *incorrect* version.
_ExcelHelper.vbs_: Provide different functions to support batch file, the batch file gets its return values by trapping the exit codes.
_LCHCME.xls_: The target excel file we want to monitor.
_ExcelHelper.xls_: Support for checking if the target file is opened or not. (Why we need this? See below)
_temp.txt_: Store the temp value generated by _ExcelHelper.xls_

Difficulties I met
----
1. There are different circumstances when opening excel program.
	1. When there is already excel file opened, double click another excel file, it will be in one instance (only one process)
	1. If we use command line (EXCEL.EXE) or double click _EXCEL.EXE_ file, it will create a new instance (two processes).
1. In the VBScript, the *GetObject* function can only get the first instance, so it's infeasible to use *GetObject* to the get the target instance (based on the first point). That's why I would to use the _ExcelHelper.xls_ and _temp.txt_. More details about this will be added. 
1. Many hard-coded.

Usage
----
Just double click the _Excelwatcher2.bat_. It will prompt a CMD window showing what it's doing right now. 

To Be Done
----
1. Convert from VBA to VBScript.
1. Less hard-coded.
1. Enhance robustness.