param (
  [Parameter(Mandatory = $true)]
  [string]
  [ValidateNotNullOrEmpty()]
  $TenantName,

  [Parameter(Mandatory = $true)]
  [string]
  [ValidateNotNullOrEmpty()]
  $ClientId,

  [Parameter(Mandatory = $true)]
  [string]
  [ValidateNotNullOrEmpty()]
  $ClientSecret,

  [Parameter(Mandatory = $true)]
  [string]
  [ValidateNotNullOrEmpty()]
  $PolicyDirectory
)

function Get-Token {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $TenantName,

    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $ClientId,

    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $ClientSecret
  )

  try {
    Write-Host "Getting token from tenant $TenantName for client $ClientId..."

    $requestUri = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/Token"

    $requestBody = @{
      grant_type = "client_credentials";
      client_id = $ClientId;
      client_secret = $ClientSecret;
      scope = "https://graph.microsoft.com/.default"
    }

    $responseBody = Invoke-RestMethod -Method Post -Uri $requestUri -Body $requestBody

    Write-Host "Got token from tenant $TenantName for client $ClientId."

    $responseBody.access_Token
  }
  catch {
    Write-Host "Didn't get token from tenant $TenantName for client $ClientId."
    Write-Host "Error response code:" $_.Exception.Response.StatusCode.value__

    $errorResponseBodyStreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errorResponseBody = $errorResponseBodyStreamReader.ReadToEnd()
    $errorResponseBodyStreamReader.Close()

    Write-Host "Error response body: " $errorResponseBody

    throw
  }
}

function Put-Policy {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $TenantName,

    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $Token,

    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $PolicyId,

    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $PolicyDirectory
  )

  try {
    Write-Host "Uploading file for policy $PolicyId to tenant $TenantName..."

    $requestUri = "https://graph.microsoft.com/beta/trustFramework/policies/$PolicyId/" + '$value'
    $requestHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $requestHeaders.Add("Authorization", "Bearer $Token")
    $requestHeaders.Add("Content-Type", "application/xml")
    $policyFile = "$($PolicyDirectory)\$($TenantName)_$($PolicyId).xml"
    $requestBody = Get-Content $policyFile
    $responseBody = Invoke-RestMethod -Method Put -Uri $requestUri -Headers $requestHeaders -Body $requestBody

    Write-Host "Uploaded file for policy $PolicyId to tenant $TenantName"
  }
  catch {
    Write-Host "Didn't upload file for policy $PolicyId to tenant $TenantName"
    Write-Host "Error response code:" $_.Exception.Response.StatusCode.value__

    $errorResponseBodyStreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errorResponseBody = $errorResponseBodyStreamReader.ReadToEnd()
    $errorResponseBodyStreamReader.Close()

    Write-Host "Error response body: " $errorResponseBody

    throw
  }
}

$token = Get-Token -TenantName $TenantName -ClientId $ClientId -ClientSecret $ClientSecret

Put-Policy -TenantName $TenantName -Token $token -PolicyId "B2C_1A_base" -PolicyDirectory $PolicyDirectory
