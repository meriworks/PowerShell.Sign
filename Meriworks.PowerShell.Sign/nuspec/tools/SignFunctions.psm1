Write-Host "Information: Documentation for Meriworks.PowerShell.Sign can be found @ https://github.com/meriworks/PowerShell.Sign"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$timeStampUrl = "http://timestamp.globalsign.com/scripts/timestamp.dll"

function Get-RegValue([String] $KeyPath, [String] $ValueName) {
    (Get-ItemProperty -LiteralPath $KeyPath -Name $ValueName).$ValueName
}

function Get-CodeSigningCert() {
	$csc = Get-ChildItem -Recurse cert:\CurrentUser\My -CodeSigningCert|where-object {$_.NotAfter -ge [System.DateTime]::Now -and $_.PrivateKey -ne $null}
	if($csc -is [system.array]){
		$csc=$csc[0]
	}
	if($csc -eq $null) {
		throw "Cannot find a valid CodeSigningCertificate"
	}
	Write-Host "Found signing certificate $($csc.Subject)"
	return $csc
}

function Get-SignToolPath(){

	 if($global:signToolPath -ne $null -and (test-path $global:signToolPath) ) {
        return $global:signToolPath
    }
    $kitsroot = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"|Select-Object -ExpandProperty Property|where {$_ -like "kitsroot*"}
	$arch = $ENV:PROCESSOR_ARCHITECTURE
	if($arch -eq "AMD64")
	{
		$arch = "x64"
	}
    foreach ($kit in $kitsroot) {
        $kitPath = Get-RegValue "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots" $kit
        $path = join-path $kitPath "bin\$arch\signtool.exe"
        if( test-path $path) {
            return $path
        }
    }
	#Windows 10 kits are registered in another way
	$kitVersions = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
	foreach($kv in $kitVersions){
		$version = split-path -leaf $kv.Name
		$major = $version.split('.')[0]
		$kitPath = Get-RegValue "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots" "KitsRoot$major"
        
	    $path = join-path $kitPath "bin\$version\$arch\signtool.exe"
        if( test-path $path) {
            return $path
        }
    }
	throw "Cannot find any installed Signtool.exe. Please install windows Sdk first or set the `$global:signToolPath variable to the path to the signtool.exe you would like to use"
}

function SignScript($path) {
	$verify = (Get-AuthenticodeSignature $path)
	if($verify.Status -eq "Valid") {
		Write-Host "File has already a valid signature" $path
	} else {
		Write-Host "Debug: Verify: $($verify.Status) $($verify.StatusMessage)"
		Write-Host "Signing file $path"
		$cert = Get-CodeSigningCert
		Set-AuthenticodeSignature $path $cert -TimestampServer $timeStampUrl -Force
		$verify = (Get-AuthenticodeSignature $path)
		if($verify.Status -ne "Valid") {
			throw "Failed to sign $path Status :$($verify.Status)"
		}
	}
}

function SignScriptsInFolder($folder) {
	echo "Singning scripts in folder $folder"
	Foreach($file in Get-ChildItem $folder|Where-Object {$_.Name.EndsWith(".ps1") -or $_.Name.EndsWith(".psm1") }){
		SignScript($file.FullName)
	}
}

function SignMsi($url, $name, $path) {
	#Don't use set authenticode since it cannot set the program name (as with signtools /d option)
	#Set-AuthenticodeSignature -Certificate $csc "$outputFile"

	$signTool = Get-SignToolPath
	$cert = Get-CodeSigningCert

	Write-Host "SignTool: $signTool sign /sha1 ""$($cert.Thumbprint)"" /du ""$url"" /d ""$name"" /t ""$($timeStampUrl)"" ""$path"""
	&$signTool sign /sha1 "$($cert.Thumbprint)" /du "$url" /d "$name" /t $timeStampUrl "$path"
}

# SIG # Begin signature block
# MIIMNAYJKoZIhvcNAQcCoIIMJTCCDCECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURTxrJ7ka3xAtYeqVUuHktyB+
# rqugggmTMIIElDCCA3ygAwIBAgIOSBtqBybS6D8mAtSCWs0wDQYJKoZIhvcNAQEL
# BQAwTDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNVBAoT
# Ckdsb2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTYwNjE1MDAwMDAw
# WhcNMjQwNjE1MDAwMDAwWjBaMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAt
# IFNIQTI1NiAtIEczMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjYVV
# I6kfU6/J7TbCKbVu2PlC9SGLh/BDoS/AP5fjGEfUlk6Iq8Zj6bZJFYXx2Zt7G/3Y
# SsxtToZAF817ukcotdYUQAyG7h5LM/MsVe4hjNq2wf6wTjquUZ+lFOMQ5pPK+vld
# sZCH7/g1LfyiXCbuexWLH9nDoZc1QbMw/XITrZGXOs5ynQYKdTwfmOPLGC+MnwhK
# kQrZ2TXZg5J2Yl7fg67k1gFOzPM8cGFYNx8U42qgr2v02dJsLBkwXaBvUt/RnMng
# Ddl1EWWW2UO0p5A5rkccVMuxlW4l3o7xEhzw127nFE2zGmXWhEpX7gSvYjjFEJtD
# jlK4PrauniyX/4507wIDAQABo4IBZDCCAWAwDgYDVR0PAQH/BAQDAgEGMB0GA1Ud
# JQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCTASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBQPOueslJF0LZYCc4OtnC5JPxmqVDAfBgNVHSMEGDAWgBSP8Et/qC5F
# JK5NUPpjmove4t0bvDA+BggrBgEFBQcBAQQyMDAwLgYIKwYBBQUHMAGGImh0dHA6
# Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9yb290cjMwNgYDVR0fBC8wLTAroCmgJ4Yl
# aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9yb290LXIzLmNybDBjBgNVHSAEXDBa
# MAsGCSsGAQQBoDIBMjAIBgZngQwBBAEwQQYJKwYBBAGgMgFfMDQwMgYIKwYBBQUH
# AgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMA0GCSqG
# SIb3DQEBCwUAA4IBAQAVhCgM7aHDGYLbYydB18xjfda8zzabz9JdTAKLWBoWCHqx
# mJl/2DOKXJ5iCprqkMLFYwQL6IdYBgAHglnDqJQy2eAUTaDVI+DH3brwaeJKRWUt
# TUmQeGYyDrBowLCIsI7tXAb4XBBIPyNzujtThFKAzfCzFcgRCosFeEZZCNS+t/9L
# 9ZxqTJx2ohGFRYzUN+5Q3eEzNKmhHzoL8VZEim+zM9CxjtEMYAfuMsLwJG+/r/uB
# AXZnxKPo4KvcM1Uo42dHPOtqpN+U6fSmwIHRUphRptYCtzzqSu/QumXSN4NTS35n
# fIxA9gccsK8EBtz4bEaIcpzrTp3DsLlUo7lOl8oUMIIE9zCCA9+gAwIBAgIMKYDy
# sFj73Q3Kq1scMA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVTaWdu
# aW5nIENBIC0gU0hBMjU2IC0gRzMwHhcNMjAxMTE5MTYyNjI5WhcNMjIxMjIyMDk0
# MzQzWjBxMQswCQYDVQQGEwJTRTEPMA0GA1UEBxMGS0FMTUFSMRUwEwYDVQQKEwxN
# ZXJpd29ya3MgQUIxFTATBgNVBAMTDE1lcml3b3JrcyBBQjEjMCEGCSqGSIb3DQEJ
# ARYUc3VwcG9ydEBtZXJpd29ya3Muc2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQDCwHSz9jsRUBViLeMm/R4od1ETiOxWO3i574S0ptC0yC7fFYvW5Vva
# XzDEXGZmDDdkjZtUds5IDljSaMZUloVhrZqqfOesCiMmcULlFWLsWj7Wa9CPRv3Y
# PDSkCuOD1LGE+IGOp+mPcB0YaVTYR2cwVzrqNiFAa81W/EqATl7d6csHLRuvvkib
# hZEjHt4dlikXS01G7QBKLCHoeQaFFClvaJ37b/HaI3UdVfRybbdsnA3s40Q4u9ln
# D3+Tex+ueY00SAajH7yoDklsrRnoDEcMvUL7O+H1IoHGQ8W+raZS+4vYE9te6zM9
# nZddfphExcRGRKV2XE4CcFHmx6U3BohlAgMBAAGjggGkMIIBoDAOBgNVHQ8BAf8E
# BAMCB4AwgZQGCCsGAQUFBwEBBIGHMIGEMEgGCCsGAQUFBzAChjxodHRwOi8vc2Vj
# dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduc2hhMmczb2NzcC5j
# cnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9nc2Nv
# ZGVzaWduc2hhMmczMFYGA1UdIARPME0wQQYJKwYBBAGgMgEyMDQwMgYIKwYBBQUH
# AgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAgGBmeB
# DAEEATAJBgNVHRMEAjAAMD8GA1UdHwQ4MDYwNKAyoDCGLmh0dHA6Ly9jcmwuZ2xv
# YmFsc2lnbi5jb20vZ3Njb2Rlc2lnbnNoYTJnMy5jcmwwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHwYDVR0jBBgwFoAUDzrnrJSRdC2WAnODrZwuST8ZqlQwHQYDVR0OBBYE
# FF340qrXt1rYsSyIgSCJ61M7+BPZMA0GCSqGSIb3DQEBCwUAA4IBAQBzYZwd3+y3
# 4qpecwe6l3Hi0UmnSV7llv4/5bv+sLI41nbNhjO+rrIdkD6B81T/Obn/ZIvk2W6o
# Z3gadIONO8RncPzGyyqB17xPpJiMiNnKlXQ3nEENU7WwyMK3QjnSYdCdnlFlSQc1
# 970DvncsJBypLS2/JlEgZx4AGjFpg7dJgIyZHO6TEYmUJkpC3cgQu5ayCK/kWJDa
# PZijz3BBDcyLMe/QHqeHoS+um9Svac6CdqqrxeQE6g+wyMrmPN3Bc6h8fTS5R5Qg
# ZCumoMxDrYv/dV8I7sXeg2vwiuLMvn9i684FmyUOCs5JTYySEfXsWfAFymX9iCAZ
# ejb6TNRpy+ELMYICCzCCAgcCAQEwajBaMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBDb2RlU2lnbmlu
# ZyBDQSAtIFNIQTI1NiAtIEczAgwpgPKwWPvdDcqrWxwwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FI5BzIE0p62gyM7JySc+0hpMaoJTMA0GCSqGSIb3DQEBAQUABIIBADunDsLlLjZI
# 7pCtPRg0ap1JzPGNU8X+WLfGXChEYLmr/bKebIEs4QmoX0Gp33tfu0U4UytKGs9P
# hvbPUzl6ZSu81cryEfgnc0+HbXMlGugZ6IEg6kd41D92HXqppo8SDRnWhPlqT6GO
# uhYKu2qxCObLvMfy6ZRttMFwDrlucrvGaBEwCWrgoD772mIf85pTFdy/nDOmUwQu
# OZW7DvnaDQ9CurPju3wp4AX3btqpTO5LglQZUpASWKoBU1UENoFEJnHK58NGtR9h
# c8+rFpwxY9cOLSRWksY3QCm5IV9BfWi/6wTGhrr7vx1q/BoIvW+JFYGviLjVPTqL
# FNWHPRJvghE=
# SIG # End signature block
