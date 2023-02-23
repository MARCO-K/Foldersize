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
[parameter(Mandatory,ValueFromPipeline)][ValidateScript({Test-Path $_ -PathType 'Container'})][string[]]$paths,
[ValidateLength(2,10)][ValidatePattern('\*\.\S+')][string[]]$include,
[ValidateLength(2,10)][ValidatePattern('\*\.\S+')][string[]]$exclude,
[parameter(Mandatory,Helpmessage='Input format: MM/dd/yyyy')][ValidateScript(
{ ([datetime]::ParseExact($_,"MM/dd/yyyy",[Globalization.CultureInfo]::CreateSpecificCulture('en-US')) -le (Get-Date)) }
)]$CreationTime,
[switch]$detailed
)
begin   { [string]$MeasureProp = 'length'
        $result = @()
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
            $res = Get-ChildItem -Path $new_path -Include $include `
            | Where-Object { $_.CreationTime -ge $CreationTime } `
            | Measure-Object -Property $MeasureProp -Minimum -Maximum -Sum -Average
            ## fix date compare cultural natural
            }
        catch {
            $e = $error[0].CategoryInfo | Select-Object TargetName

            W
            rite-Error "Error: $e"
            #break
            #exit
            #throw 'Hilfe!!!'
            }
    

         New-Object PSCustomObject -Property @{ 
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
        { $result | Select-Object Path, Count, Sum_kb} 
    }
}