[CmdLetBinding()]

param(
    [string]$SqlInstance,
    [PScredential]$SqlCredential,
    [string]$Database,
    [string[]]$PropertyName
)

if (-not $SqlInstance) {
    Write-Error "Please enter a SQL Server instance"
    return
}

if (-not $PropertyName) {
    Write-Error "Please enter a property to search for"
    return
}

try {
    $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
}
catch {
    Write-Error "Could not connect to instance '$SqlInstance'"
    return
}

if (-not $Database) {
    Write-Verbose "Setting database to 'master'"
    $Database = 'master'
}

if ($Database -notin $server.Databases.Name) {
    Write-Warning "Database could not be found"
    return
}

$db = $server.Databases[$Database]

$objects = $db | Get-Member | Where-Object { $_.MemberType -eq 'Property' -and $_.Definition -like 'Microsoft*' }

foreach ($object in $objects) {
    Write-Verbose "Retrieving properties for $($object.Name)"
    $dbObjectProperties = $null

    $dbObjectProperties = $db.($object.Name) | Get-Member -ErrorAction SilentlyContinue | Where-Object Membertype -eq 'Property' | Select-Object Name

    if ($dbObjectProperties) {
        $results = Compare-Object -ReferenceObject $dbObjectProperties.Name -DifferenceObject $PropertyName -IncludeEqual

        if ($results.SideIndicator -contains "==") {
            $object.Name
        }
    }
}