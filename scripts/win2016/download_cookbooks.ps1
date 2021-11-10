$ErrorActionPreference = "Stop"
Set-ExecutionPolicy Bypass -force
Write-Output "Start at: $(Get-Date)"
try
{

# Install 7zip
  # Set start time
  $start_time = Get-Date
  Set-PSDebug -Trace 1

  # Set download URLs
  $7zip_download_url = "https://s3-ap-southeast-2.amazonaws.com/base2.packages.ap-southeast-2.public/windows/7zip/7za465.zip"

  # Create Software folder
  $software_folder = "$env:SystemDrive\software"
  mkdir -force $software_folder

  # Create temp folder
  $temp_folder  = "$env:userprofile\temp\install"
  if (test-path("$temp_folder")) {ri -r -force "$temp_folder"}
  mkdir -force $temp_folder
  cd $temp_folder

  # Download 7zip
  Write-Output "Downloading 7zip from $7zip_download_url"
  $wc = new-object System.Net.WebClient
  $wc.DownloadFile($7zip_download_url,"$temp_folder\" + $7zip_download_url.Split("/")[-1])

  # Install 7-zip (just unzipping file to a 7zip folder)
  Write-Output "Installing 7zip in $software_folder\7zip"
  if (test-path("$software_folder\7zip")) {ri -r -force "$software_folder\7zip"}
  mkdir "$software_folder\7zip"
  $shell_app=new-object -com shell.application
  $zip_file = $shell_app.namespace("$temp_folder\7za465.zip")
  $destination = $shell_app.namespace("$software_folder\7zip")
  $destination.Copyhere($zip_file.items())

  # Add 7zip to path
  Write-Output "Adding 7zip to the PATH"
  [Environment]::SetEnvironmentVariable("PATH","$env:path;$software_folder\7zip","MACHINE")
  $env:path = "$env:path;$software_folder\7zip"

  # Remove temp folder
  Write-Output "Cleaning up"
  cd c:\
  ri -r -force "$temp_folder"
  Write-Output "Time taken: $((Get-Date).Subtract($start_time))"



  $start_time      = Get-Date
  $GzipPath        = "C:\base2\cookbooks.tar.gz"
  $Base2Path       = "C:\base2"
  $TarPath         = "C:\base2\cookbooks.tar"
  $Destination     = "C:\chef\"
  $CookbookDir     = "C:\chef\cookbooks"
  $SourceBucket    = $ENV:SOURCE_BUCKET
  $BucketRegion    = $ENV:BUCKET_REGION
  $CookbookVersion = $ENV:CB_BUILD_NO
  $ChefPath        = $ENV:CHEF_PATH

# Download cookbooks

  if([string]::IsNullOrEmpty($SourceBucket) -And [string]::IsNullOrEmpty($CookbookVersion)) {
    Write-Output "INFO: No Cookbooks to download...this instance must have existing cookbooks"
    exit 0
  }

  try {
    Write-Output "INFO: Downloading chef bundle from s3 location: $SourceBucket/$ChefPath/$CookbookVersion/chef-bundle.tar.gz"
    Read-S3Object -Region $BucketRegion -BucketName $SourceBucket -Key /$ChefPath/$CookbookVersion/chef-bundle.tar.gz -File $GzipPath
  } catch {
    Write-Output "INFO: Bundle not found, downloading cookbooks from s3 location: $SourceBucket/$ChefPath/$CookbookVersion/cookbooks.tar.gz"
    Read-S3Object -Region $BucketRegion -BucketName $SourceBucket -Key /$ChefPath/$CookbookVersion/cookbooks.tar.gz -File $GzipPath
  }

  Write-Output "INFO: Deleting dir $CookbookDir"
  if(Test-Path -Path $CookbookDir ){
    Remove-Item -Recurse -Force $CookbookDir
  }

  Write-Output "INFO: Extracting $GzipPath to $CookbookDir"
  7za x $GzipPath -o"$Base2Path" -y
  7za x $TarPath -o"$Destination" -y

  Write-Output "INFO: Cleaning up $GzipPath $TarPath"
  rm $GzipPath
  rm $TarPath

  Write-Output "INFO: Time taken: $((Get-Date).Subtract($start_time))"
}
catch
{
  Write-Output "ERROR: Caught an exception:"
  Write-Output "ERROR: Exception Type: $($_.Exception.GetType().FullName)"
  Write-Output "ERROR: Exception Message: $($_.Exception.Message)"
  exit 1
}
exit 0
