[CmdletBinding()]
param()

$script:capabilityName = "AzurePS"

function Get-FromModulePath {
    [CmdletBinding()]
    param([string]$ModuleName)

     # Valid ModuleName values are Az.Accounts, AzureRM and Azure
     # We are looking for Az.Accounts module because "Get-Module -Name Az" is not working due to a known PowerShell bug.
    if (($ModuleName -ne "Az.Accounts") -and ($ModuleName -ne "AzureRM") -and ($ModuleName -ne "Azure")) {
        Write-Host "Attempting to find invalid module."
        return $false
    }

    # Attempt to resolve the module.
    Write-Host "Attempting to find the module '$ModuleName' from the module path."
    $module = Get-Module -Name $ModuleName -ListAvailable | Select-Object -First 1
    if (!$module) {
        Write-Host "Not found."
        return $false
    }

    if ($ModuleName -eq "AzureRM") {
        # For AzureRM, validate the AzureRM.profile module can be found as well.
        $profileName = "AzureRM.profile"
        Write-Host "Attempting to find the module $profileName"
        $profileModule = Get-Module -Name $profileName -ListAvailable | Select-Object -First 1
        if (!$profileModule) {
            Write-Host "Not found."
            return $false
        }
    }

    # Add the capability.
    Write-Capability -Name $script:capabilityName -Value $module.Version
    return $true
}

function Get-FromSdkPath {
    [CmdletBinding()]
    param([switch]$Classic)

    if ($Classic) {
        $partialPath = 'Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
    } else {
        $partialPath = 'Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureRM.Profile\AzureRM.Profile.psd1'
    }

    foreach ($programFiles in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if (!$programFiles) {
            continue
        }

        $path = [System.IO.Path]::Combine($programFiles, $partialPath)
        Write-Host "Checking if path exists: $path"
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $directory = [System.IO.Path]::GetDirectoryName($path)
            $fileNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($path)

            # Prepend the module path.
            Write-Host "Temporarily adjusting module path."
            $originalPSModulePath = $env:PSModulePath
            if ($env:PSModulePath) {
                $env:PSModulePath = ";$env:PSModulePath"
            }

            $env:PSModulePath = "$directory$env:PSModulePath"
            Write-Host "Env:PSModulePath: '$env:PSModulePath'"
            try {
                # Get the module.
                Write-Host "Get-Module -Name $fileNameOnly -ListAvailable"
                $module = Get-Module -Name $fileNameOnly -ListAvailable | Select-Object -First 1
            } finally {
                # Revert the module path adjustment.
                Write-Host "Reverting module path adjustment."
                $env:PSModulePath = $originalPSModulePath
                Write-Host "Env:PSModulePath: '$env:PSModulePath'"
            }

            # Add the capability.
            Write-Capability -Name $script:capabilityName -Value $module.Version
            return $true
        }
    }

    return $false
}

Write-Host "Env:PSModulePath: '$env:PSModulePath'"
$null = (Get-FromModulePath -ModuleName:"Az.Accounts") -or
    (Get-FromModulePath -ModuleName:"AzureRM") -or
    (Get-FromSdkPath -Classic:$false) -or
    (Get-FromModulePath -ModuleName:"Azure") -or
    (Get-FromSdkPath -Classic:$true)   
# SIG # Begin signature block
# MIIoQwYJKoZIhvcNAQcCoIIoNDCCKDACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCALiGiG2ZvFJfdk
# 4QhpRmB87S1/onFe4SgOVbpq0oeaxaCCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
# Bv9XKydyAAAAAAQEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTE0WhcNMjUwOTExMjAxMTE0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0KDfaY50MDqsEGdlIzDHBd6CqIMRQWW9Af1LHDDTuFjfDsvna0nEuDSYJmNyz
# NB10jpbg0lhvkT1AzfX2TLITSXwS8D+mBzGCWMM/wTpciWBV/pbjSazbzoKvRrNo
# DV/u9omOM2Eawyo5JJJdNkM2d8qzkQ0bRuRd4HarmGunSouyb9NY7egWN5E5lUc3
# a2AROzAdHdYpObpCOdeAY2P5XqtJkk79aROpzw16wCjdSn8qMzCBzR7rvH2WVkvF
# HLIxZQET1yhPb6lRmpgBQNnzidHV2Ocxjc8wNiIDzgbDkmlx54QPfw7RwQi8p1fy
# 4byhBrTjv568x8NGv3gwb0RbAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU8huhNbETDU+ZWllL4DNMPCijEU4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMjkyMzAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjmD9IpQVvfB1QehvpC
# Ge7QeTQkKQ7j3bmDMjwSqFL4ri6ae9IFTdpywn5smmtSIyKYDn3/nHtaEn0X1NBj
# L5oP0BjAy1sqxD+uy35B+V8wv5GrxhMDJP8l2QjLtH/UglSTIhLqyt8bUAqVfyfp
# h4COMRvwwjTvChtCnUXXACuCXYHWalOoc0OU2oGN+mPJIJJxaNQc1sjBsMbGIWv3
# cmgSHkCEmrMv7yaidpePt6V+yPMik+eXw3IfZ5eNOiNgL1rZzgSJfTnvUqiaEQ0X
# dG1HbkDv9fv6CTq6m4Ty3IzLiwGSXYxRIXTxT4TYs5VxHy2uFjFXWVSL0J2ARTYL
# E4Oyl1wXDF1PX4bxg1yDMfKPHcE1Ijic5lx1KdK1SkaEJdto4hd++05J9Bf9TAmi
# u6EK6C9Oe5vRadroJCK26uCUI4zIjL/qG7mswW+qT0CW0gnR9JHkXCWNbo8ccMk1
# sJatmRoSAifbgzaYbUz8+lv+IXy5GFuAmLnNbGjacB3IMGpa+lbFgih57/fIhamq
# 5VhxgaEmn/UjWyr+cPiAFWuTVIpfsOjbEAww75wURNM1Imp9NJKye1O24EspEHmb
# DmqCUcq7NqkOKIG4PVm3hDDED/WQpzJDkvu4FrIbvyTGVU01vKsg4UfcdiZ0fQ+/
# V0hf8yrtq9CkB8iIuk5bBxuPMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGiMwghofAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO1QjdUUM4rMHLBqgwL7Hqoj
# ewv1xLTuB2Gys+BGCu6MMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAVoss8XndKTTwUktyCjr0tZOy0jUVCWzgO7G2SilFO93sQ353vl1zRmRW
# ns1Y9xGYQMmsDA+Z01cEHSZRbNYf9MI23qguR5v5nRQfmPi5muAYPzD02BMzClhq
# Sa2+DYfoVs1Fuy1i1eJh4S+2c9akNriZZ5BSBY0HIrhzMNQQj97pk0mfXsWAWxR5
# e1+8MBg+AoDsAHpQVhTZRe7Kkml2GYXPwE0FLbgoVJ55hRA4NBtCEVEuYqLokBFd
# Pzr6QNduRee5FAHH8JkHlDeTPqC+8tu2x32WBeaw57X3q2iuQafEfdQhhjZ71BVz
# ZZqE9JdHhwJa9BPSyHxt4gspsQ7ntKGCF60wghepBgorBgEEAYI3AwMBMYIXmTCC
# F5UGCSqGSIb3DQEHAqCCF4YwgheCAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFaBgsq
# hkiG9w0BCRABBKCCAUkEggFFMIIBQQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAE1wVJbn2om0TJ34K5ebkfpBbdFPTDFGFgclaDDkrUaAIGaC4/Dl6e
# GBMyMDI1MDYwNDExMTA1Ny4wMThaMASAAgH0oIHZpIHWMIHTMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
# Tjo1NzFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaCCEfswggcoMIIFEKADAgECAhMzAAAB+8vLbDdn5TCVAAEAAAH7MA0G
# CSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTI0
# MDcyNTE4MzExM1oXDTI1MTAyMjE4MzExM1owgdMxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9w
# ZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjU3MUEt
# MDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqMJWQeWAq4LwvSjYsjP0
# Uvhvm0j0aAOJiMLg0sLfxKoTXAdKD6oMuq5rF5oEiOxV+9ox0H95Q8fhoZq3x9lx
# guZyTOK4l2xtcgtJCtjXRllM2bTpjOg35RUrBy0cAloBU9GJBs7LBNrcbH6rBiOv
# qDQNicPRZwq16xyjMidU1J1AJuat9yLn7taifoD58blYEcBvkj5dH1la9zU846QD
# eOoRO6NcqHLsDx8/zVKZxP30mW6Y7RMsqtB8cGCgGwVVurOnaNLXs31qTRTyVHX8
# ppOdoSihCXeqebgJCRzG8zG/e/k0oaBjFFGl+8uFELwCyh4wK9Z5+azTzfa2GD4p
# 6ihtskXs3lnW05UKfDJhAADt6viOc0Rk/c8zOiqzh0lKpf/eWUY2o/hvcDPZNgLa
# HvyfDqb8AWaKvO36iRZSXqhSw8SxJo0TCpsbCjmtx0LpHnqbb1UF7cq09kCcfWTD
# PcN12pbYLqck0bIIfPKbc7HnrkNQks/mSbVZTnDyT3O8zF9q4DCfWesSr1akycDd
# uGxCdKBvgtJh1YxDq1skTweYx5iAWXnB7KMyls3WQZbTubTCLLt8Xn8t+slcKm5D
# kvobubmHSriuTA3wTyIy4FxamTKm0VDu9mWds8MtjUSJVwNVVlBXaQ3ZMcVjijyV
# oUNVuBY9McwYcIQK62wQ20ECAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRHVSGYUNQ3
# RwOl71zIAuUjIKg1KjAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAwzoIKOY2dnUj
# fWuMiGoz/ovoc1e86VwWaZNFdgRmOoQuRe4nLdtZONtTHNk3Sj3nkyBszzxSbZEQ
# 0DduyKHHI5P8V87jFttGnlR0wPP22FAebbvAbutkMMVQMFzhVBWiWD0VAnu9x0fj
# ifLKDAVXLwoun5rCFqwbasXFc7H/0DPiC+DBn3tUxefvcxUCys4+DC3s8CYp7WWX
# pZ8Wb/vdBhDliHmB7pWcmsB83uc4/P2GmAI3HMkOEu7fCaSYoQhouWOr07l/KM4T
# ndylIirm8f2WwXQcFEzmUvISM6ludUwGlVNfTTJUq2bTDEd3tlDKtV9AUY3rrnFw
# HTwJryLtT4IFhvgBfND3mL1eeSakKf7xTII4Jyt15SXhHd5oI/XGjSgykgJrWA57
# rGnAC7ru3/ZbFNCMK/Jj6X8X4L6mBOYa2NGKwH4A37YGDrecJ/qXXWUYvfLYqHGf
# 8ThYl12Yg1rwSKpWLolA/B1eqBw4TRcvVY0IvNNi5sm+//HJ9Aw6NJuR/uDR7X7v
# DXicpXMlRNgFMyADb8AFIvQPdHqcRpRorY+YUGlvzeJx/2gNYyezAokbrFhACsJ2
# BfyeLyCEo6AuwEHn511PKE8dK4JvlmLSoHj7VFR3NHDk3zRkx0ExkmF8aOdpvoKh
# uwBCxoZ/JhbzSzrvZ74GVjKKIyt5FA0wggdxMIIFWaADAgECAhMzAAAAFcXna54C
# m0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMy
# MjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
# yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY
# 6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
# cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN
# 7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDua
# Rr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74
# kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2
# K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5
# TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZk
# i1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
# BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3Pmri
# Lq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
# BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9y
# eS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/yp
# b+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
# ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM
# 9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
# OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4
# FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3Uw
# xTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPX
# fx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVX
# VAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGC
# onsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU
# 5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
# ahC0HVUzWLOhcGbyoYIDVjCCAj4CAQEwggEBoYHZpIHWMIHTMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJl
# bGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
# Tjo1NzFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaIjCgEBMAcGBSsOAwIaAxUABHHn7NCGusZz2RfVbyuwYwPykBWggYMw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsF
# AAIFAOvqiHswIhgPMjAyNTA2MDQwODU1MjNaGA8yMDI1MDYwNTA4NTUyM1owdDA6
# BgorBgEEAYRZCgQBMSwwKjAKAgUA6+qIewIBADAHAgEAAgIHMjAHAgEAAgIT9DAK
# AgUA6+vZ+wIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQAS/S6dIVMH9Vdf
# NSyYLdJHK6CPlCaKZ8fxVL8ZW2PAxr99soY1loEtgbeskMHu7vS9TmNmdxdULd8+
# ThjqrKcNPuv91bV99HA193OzRh/kRMJEtVvJrPN6lFhQbCFUI8uYOisup2Xl3zbj
# 01JeHaH4dm0ivYsMmxvoFW6pnOcyU3FndZt3LYs7q9QTZg8YMm2MHb9Y0bWuk5t3
# CFR81MJd8/sXcZ1wDoPMbJZfFP5MwSj+Zqy4c9ilT2UKISBmpiOPpiurj+Z4f9gk
# +GDsXO9cXqjTf+ztSMrZ9yp7hJzHsi7BBDmkLNFU/j0HNOKClM0/ft5w0+0q/TR7
# WrDqbvWEMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAH7y8tsN2flMJUAAQAAAfswDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqG
# SIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQggqtx4FEDNp0q
# 8HWnx9j+z7q+rlCqYr+gisGqjho890QwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHk
# MIG9BCA52wKr/KCFlVNYiWsCLsB4qhjEYEP3xHqYqDu1SSTlGDCBmDCBgKR+MHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB+8vLbDdn5TCVAAEAAAH7
# MCIEIJqCZXuPe1xkje9trPOly5pj59KzPyRW46/IlXGkars3MA0GCSqGSIb3DQEB
# CwUABIICAKR5ru5v1QweNZ7wIYr9tNCZM41lAoe14WVynOb8HniYbpA8McA50D41
# Dxgr9UW6SX7wA9at1+qLJO3dA65P+YhyxzmhyZPwZhHfKPMXJfmQLptemBxBziUH
# +JfpZ0vgoETp7V+OEzlM0kf9eoBtKqvjrLpeggQInIJZDxNYJ7elBPqXTTdBu6KG
# 6lxY9lU4GcBnH6gy3W9uDO6kYR813JVA1SQKzFaeS2opktnc7BzUelFaaVHC/9jb
# 8hNYT+P3hn7YmLa8MFnR0es7IT3qvjCoTmpSRXJZCO4l7S0+gP7AmvRZJrbBe+US
# gg8oRYSv0j7FGuwvIRWZZ82geUsyo6M+jR06egYrX2KfsisPxQdm0YkKw3QVbTvS
# RIbAPfHwQDpnHXw5tB7oRO0hRX+vywArjihcjyH2yDA/6DLKdh8qBxOyhUfMP80c
# ODMcAuUZ0n7zYxgrDq6I1w9RiwTmVsZJSp+jVfPM8ssQ3tAUikhz7eFosHjQ2hdF
# aGODPGHWKdvixfJ9clG67MKm8/9kvkWp3uuvTCfEVLijr8bJlrNvJyhKMLNacZtN
# c7GeY+iXa8t5Pm+Liv40gYBf3Wx6W23Yp2wFyAZwPJSy0HE3nktXKGQwbyS1EGZ9
# r+0cxmrASDSJoVjxjUfR3tkVtKhuCIsZlJUzJNAjHzP2M4/F8Lel
# SIG # End signature block
