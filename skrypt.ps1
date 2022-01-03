# Changelog

# Tomasz Wojtyczka
# Created on 30.12.2021
# It is a script that allows you to automate data processing.
# It includes such functionalities as downloading data, loading data into a database,
# sending information about files and their content to e-mail.
# There are also features such as running SQL queries, changing the location of files or
# compressing and decompressing files.

# Path to working directory.
$Path="C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt"

# Variables
${TIMESTAMP}= Get-Date -Format "MM.dd.yyyy"
${TIMESTAMP_precise}= Get-Date -Format "MM.dd.yyyy HH:mm:ss"
$Processed=-join ($Path,"\PROCESSED")
$logFile=-join ($Processed,"\skrypt_${TIMESTAMP}.log")
$Password="agh"
${indexNumber}="402681"
$fileURL="https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip"
$DownloadedZipFile="C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt\Customers_Nov2021.zip"

# Creating directory and log file if it does not exist.
if (-not(Test-Path -Path $Processed -PathType Leaf)){New-Item -ItemType "directory" -Path $Processed -Force}
if (-not(Test-Path -Path $logFile -PathType Leaf)){New-Item -ItemType File -Path $logFile -Force}
Write-Output (" ------------------------------") >> $logFile

# A) Downloading the file using the link.
try {
$DownloadedFile=New-object System.Net.WebClient
$DownloadedFile.DownloadFile($fileURL, $DownloadedZipFile)

# Saving the result to the log file.
Write-Output (${TIMESTAMP_precise} + " ---- Downloading Step: Successful") >> $logFile
} catch{Write-Output (${TIMESTAMP_precise} + " ---- Downloading Step: Unsuccessful") >> $logFile}

# B) Unzipping the file.
try {
Expand-7Zip -ArchiveFileName $DownloadedZipFile -TargetPath $Path -Password $Password

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Unzipping Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Unzipping Step: Unsuccessful") >> $logFile}

# C) Verification the file (rejection of incorrect lines).

try {
# File where incorrect lines will be stored.
$badFile=-join ($Path,"\Customers_Nov2021.bad_${TIMESTAMP}.txt")
# Creating a file if it does not exist.
if (-not(Test-Path -Path $badFile -PathType Leaf)) {New-Item -ItemType File -Path $badFile -Force}

# Filtering the file by removing empty lines and comparing to other file.
Get-Content -Path (-join ( $Path,"\Customers_Nov2021.csv")) | Where-Object{$_ -ne ""}| Where-Object{$FileToCompare -notcontains $_} | Out-File -FilePath (-join ( $Path,"\Customers_verificated.csv"))  -Encoding utf8
$FileToCompare= Get-Content -Path (-join ($Path,"\Customers_old.csv"))
Get-Content -Path (-join ( $Path,"\Customers_Nov2021.csv")) | Where-Object{$_ -ne ""}| Where-Object{$VerificatedFile -notcontains $_} | Out-File -FilePath $badFile
$VerificatedFile= Get-Content -Path (-join ($Path,"\Customers_verificated.csv"))

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Verification Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Verification Step: Unsuccessful") >> $logFile}

# D) Creating a table in the database.

# Setting the location of the database.
Set-Location 'C:\Program Files\PostgreSQL\14\bin\'

# SQL Variables
$hostName="localhost"
$Port="5432"
$Database="cw8-9"
$User="postgres"
$SQLPassword="postgres"
$env:PGPASSWORD = $SQLPassword
$psql = "postgresql://${User}:${SQLPassword}@${hostName}:${Port}/${Database}"
$table="CUSTOMERS_${indexNumber}";

# SQL queries
"CREATE EXTENSION IF NOT EXISTS POSTGIS;" | .\psql --quiet $psql
"DROP TABLE IF EXISTS $table;" | .\psql $psql
"CREATE TABLE IF NOT EXISTS $table (first_name varchar(25), last_name varchar(25), email varchar(50), geom geometry(Point, 4326));"| .\psql $psql

# Saving the result to the log file.
if($?)
{
   Write-Output(${TIMESTAMP_precise} + " ---- Creating a table Step: Successful") >> $logFile
} 
else
{
   Write-Output(${TIMESTAMP_precise} + " ---- Creating a table Step: Unsuccessful") >> $logFile
}

# E) Loading data from validated file into a table in the database.

# Variables
$FileCsv=Import-Csv -Path "C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt\Customers_Nov2021.csv"
$FileToCompareCsv=Import-Csv -Path "C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt\Customers_old.csv"

# An array that stores verified records.
$VerificatedCustomers=@()

# Variable that stores the number of duplicated records.
$DuplicatedRecords=0

# A loop that compares files and checks which lines are repeated.
for($i=0 ; $i -le $FileCsv.Count ; $i++) 
{
    $Quantity=0
    for($j=0 ; $j -le $FileToCompareCsv.Count ; $j++)
    {
        if($FileCsv[$i].email -eq $FileToCompareCsv[$j].email)
        {
            $Quantity=1
            $DuplicatedRecords=$DuplicatedRecords+1
        }
    }
    if($Quantity -eq 0) 
    {
        $VerificatedCustomers=$VerificatedCustomers+$FileCsv[$i]
    }
}

# A loop with SQL query that loads data into a database table.
for($i=0 ; $i -lt $VerificatedCustomers.Count ; $i++) {
    $first_name=$VerificatedCustomers[$i].first_name
    $last_name=$VerificatedCustomers[$i].last_name
    $email=$VerificatedCustomers[$i].email
    $lat=$VerificatedCustomers[$i].lat
    $long=$VerificatedCustomers[$i].long
    "INSERT INTO $table VALUES ('${first_name}', '${last_name}', '${email}', 'POINT(${lat} ${long})');" | .\psql --quiet $psql
}

# Checking if the number of records in the verified file and in the table is the same and saving the result to the log file.
$tableSize = "SELECT COUNT(*) FROM $table;"  | .\psql --quiet $psql
$cCount = $VerificatedCustomers.Count
if($tableSize.Size -eq $cCount.Size) 
    {
        Write-Output(${TIMESTAMP_precise} + " ---- Loading Data Into A Table: Successful") >> $logFile
    }
else
    {
        Write-Output(${TIMESTAMP_precise} + " ---- Loading Data Into A Table: Unsuccessful") >> $logFile
    }

# F) Renaming the file and moving to a subdirectory.

# Checking if the file exists from the previous program run. If so, removing it.
if((Test-Path -Path "$Path\PROCESSED\${TIMESTAMP}_Customers_verificated.csv" -PathType Leaf) -eq 1)
{
    Remove-Item -Path "$Path\PROCESSED\${TIMESTAMP}_Customers_verificated.csv" -Force
}

# Renaming a file.
if (-not(Test-Path -Path "$Path\${TIMESTAMP}_Customers_verificated.csv" -PathType Leaf))
{
    Rename-Item -Path "$Path\Customers_verificated.csv" -NewName "${TIMESTAMP}_Customers_verificated.csv"
}

# Moving the file to a subdirectory. 
if (-not(Test-Path -Path "$Path\PROCESSED\${TIMESTAMP}_Customers_verificated.csv" -PathType Leaf))
{
    Move-Item "$Path\${TIMESTAMP}_Customers_verificated.csv" -Destination "$Path\PROCESSED"
}


# Saving the result to the log file.
if((Test-Path -Path "$Path\PROCESSED\${TIMESTAMP}_Customers_verificated.csv" -PathType Leaf) -eq 1)
{
    Write-Output(${TIMESTAMP_precise} + " ---- Moving The File Step: Successful") >> $logFile
}
else
{
    Write-Output(${TIMESTAMP_precise} + " ---- Moving The File Step: Unsuccessful") >> $logFile
}

# G) Sending the first e-mail containing the report.
try {

# E-mail and report variables
$username = "test.testerski234"
$password = "Testerski254"
$credpassword = ConvertTo-SecureString -AsPlainText "Testerski254" -Force 
[System.Management.Automation.PSCredential]::new( $CredUser, $CredPassword )
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $credpassword
$rows = $customers.Count
$correctRows = $cCount
$tableInserts = $x*5

# Sending the e-mail.
Send-MailMessage -To “naydzel80@gmail.com” -From “test.testerski234@gmail.com” -Subject “CUSTOMERS LOAD - ${TIMESTAMP}” `
                 -Body “The number of lines in the file downloaded from the internet: ${rows}`nThe number of correct lines: ${correctRows}`nThe number of duplicates in the input file: ${DuplicatedRecords}`nThe amount of data loaded into the table: ${tableInserts}” `
                 -Credential $cred -UseSsl -SmtpServer “smtp.gmail.com” -Port 587 

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Sending The First E-mail Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Sending The First E-mail Step: Unsuccessful") >> $logFile}

# H) Running a SQL query that finds first names and last names of customers living within 50 km of the point.
try {

# SQL queries
"DROP TABLE IF EXISTS BEST_CUSTOMERS_${indexNumber};" | .\psql $psql
"SELECT first_name, last_name INTO BEST_CUSTOMERS_${indexNumber} FROM $table WHERE ST_DISTANCESpheroid( geom::geometry, 'SRID=4326; POINT( 41.39988501005976 -75.67329768604034)'::geometry, 'SPHEROID[""WGS 84"",6378137,298.257223563]')/1000< 50;" | .\psql $psql

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- SQL Query Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- SQL Query Step: Unsuccessful") >> $logFile}

# I) Exporting the content of the table to a file with the same name.
try {

# SQL query (exporting the content)
"\copy BEST_CUSTOMERS_${indexNumber} to '$Path\BEST_CUSTOMERS_${indexNumber}.csv' csv header " | .\psql $psql

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Exporting The Content Of The Table Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Exporting The Content Of The Table Step: Unsuccessful") >> $logFile}

# J) Compressing the file.

try {

#Compressing the file.
if (-not(Test-Path -Path "$Path\BEST_CUSTOMERS_${indexNumber}.zip" -PathType Leaf)){Compress-Archive -Path "$Path\BEST_CUSTOMERS_${indexNumber}.csv" -DestinationPath "$Path\BEST_CUSTOMERS_${indexNumber}.zip" }

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Compressing File Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Compressing File Step: Unsuccessful") >> $logFile}

# K) Sending a compressed file with the report to e-mail address.

try {

# Report variables
$bestCustomers = Import-Csv -Path "C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt\BEST_CUSTOMERS_402681.csv" | Measure-Object
$bestCustomersRows = $bestCustomers.Count
$lastWriteTime = (Get-Item "C:\Users\ASUS\Desktop\Studia\Semestr 5\Bazy danych przestrzennych\Zajęcia8-9\projekt\BEST_CUSTOMERS_402681.csv").LastWriteTime 

# Sending the e-mail with attachment.
Send-MailMessage -To “naydzel80@gmail.com” -From “test.testerski234@gmail.com” -Subject “CUSTOMERS LOAD - ${TIMESTAMP}” `
                 -Body “Date of last modification: ${lastWriteTime}`nThe number of lines in the CSV file: ${bestCustomersRows}" `
                 -Credential $cred -UseSsl -SmtpServer “smtp.gmail.com” -Port 587 -Attachments "$Path\BEST_CUSTOMERS_${indexNumber}.zip"

# Saving the result to the log file.
Write-Output(${TIMESTAMP_precise} + " ---- Sending First Second Step: Successful") >> $logFile
} catch{Write-Output(${TIMESTAMP_precise} + " ---- Sending Second E-mail Step: Unsuccessful") >> $logFile}