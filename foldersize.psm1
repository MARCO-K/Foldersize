function Get-Foldersize {
    <#
        .SYNOPSIS
        Returns file sizes using provided path.
        .DESCRIPTION
        The function will calculate the file sizes for given folders.
        .PARAMETER Paths
        The path that will be searched for files.
        .PARAMETER Creationtime
        The Creationtime has to be in format: 'MM/dd/yyy'.
        .EXAMPLE
        Get-Foldersize -Path 'C:\temp' -Creationtime '02/02/2022'
        .INPUTS
        System.String
        .OUTPUTS
        PSCustomObject
        .NOTES
        This module is an example of what a well documented function could look.
    #>
  
    [CmdletBinding()]
    param(
      [parameter(Mandatory,ValueFromPipeline)][ValidateScript({Test-Path -Path $_ -PathType 'Container'})][string[]]$paths,
      [ValidateLength(2,10)][ValidatePattern('\*\.\S+')][string[]]$include,
      [ValidateLength(2,10)][ValidatePattern('\*\.\S+')][string[]]$exclude,
      [parameter(Mandatory,Helpmessage='Input format: MM/dd/yyyy')][ValidateScript(`
        { ([datetime]::ParseExact($_,'MM/dd/yyyy',[cultureinfo]::CreateSpecificCulture('en-US')) -le (Get-Date)) })]
        $CreationTime,
      [switch]$detailed
    )
    begin   { [string]$MeasureProp = 'length'
          $result = @()
          $checkdate = ([datetime]::ParseExact($CreationTime,'MM/dd/yyyy',$null))
          }
    process {
      $result +=
      foreach($path in $paths) {
          if($include){
              $new_path = Join-Path -Path $path -ChildPath '*'
              }
              else {
              $new_path = $path
              }
          try {
            Write-Verbose -Message $PSBoundParameters.Keys
            if($PSBoundParameters.ContainsKey("include") -and $PSBoundParameters.ContainsKey("exclude")) { throw 'not both parameters allowed'}
            elseif($PSBoundParameters.ContainsKey("include") -and !$PSBoundParameters.ContainsKey("exclude")) 
                { Write-Verbose -Message $new_path 
                $res = Get-ChildItem -Path $new_path -include $include -File `
              | Where-Object { $_.CreationTime -ge $checkdate } `
              | Measure-Object -Property $MeasureProp -Minimum -Maximum -Sum -Average}
            elseif(!$PSBoundParameters.ContainsKey("include") -and $PSBoundParameters.ContainsKey("exclude")) 
                { Write-Verbose -Message $new_path
                $res = Get-ChildItem -Path $new_path -Exclude $exclude -File `
              | Where-Object { $_.CreationTime -ge $checkdate } `
              | Measure-Object -Property $MeasureProp -Minimum -Maximum -Sum -Average} 
            else 
                { Write-Verbose -Message $new_path
                $res = Get-ChildItem -Path $new_path -File `
              | Where-Object { $_.CreationTime -ge $checkdate } `
              | Measure-Object -Property $MeasureProp -Minimum -Maximum -Sum -Average }
              ## fix date compare cultural natural
              }
          catch {
              $e = $error[0].CategoryInfo
              Write-Error -Message "Error: $e"
              }
      
  
           New-Object -TypeName PSCustomObject -Property @{ 
           'Count' = $res.Count
           'Sum_kb' = '{0:N2} kb' -f ($res.Sum / 1kb)
           'Average' = '{0:N2}' -f $res.Average
           'Maximum' = '{0:N2}' -f $res.Maximum
           'Minimum' = '{0:N2}' -f $res.Minimum
           'Property' = $res.Property
           'Path' = $path
           'Include' = $include
           }
  
      }
  
  
    }
    end {
      if($detailed)
          { $result }
      else
          { $result | Select-Object -Property Path, Count, Sum_kb} 
      }
  }