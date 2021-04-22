Write-Host "Information: Documentation for Meriworks.PowerShell.Sign can be found @ https://github.com/meriworks/PowerShell.Sign"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$global:timestampUrl ="http://timestamp.globalsign.com/?signature=sha2"
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
		Write-Host "Signing file $path -TimestampServer $($global:timestampUrl)"
		$cert = Get-CodeSigningCert
		Set-AuthenticodeSignature $path $cert -TimestampServer $global:timestampUrl -Force
		$verify = (Get-AuthenticodeSignature $path)
		if($verify.Status -ne "Valid") {
			throw "Failed to sign $path Status :$($verify.Status)"
		}
	}
}

function SignScriptsInFolder($folder) {
	Write-Host "Singning scripts in folder $folder"
	Foreach($file in Get-ChildItem $folder|Where-Object {$_.Name.EndsWith(".ps1") -or $_.Name.EndsWith(".psm1") }){
		SignScript($file.FullName)
	}
}

function SignMsi($url, $name, $path) {
	#Don't use set authenticode since it cannot set the program name (as with signtools /d option)
	#Set-AuthenticodeSignature -Certificate $csc "$outputFile"

	$signTool = Get-SignToolPath
	$cert = Get-CodeSigningCert

	Write-Host "SignTool: $signTool sign /sha1 ""$($cert.Thumbprint)"" /du ""$url"" /d ""$name"" /t ""$($global:timestampUrl)"" ""$path"""
	&$signTool sign /sha1 "$($cert.Thumbprint)" /du "$url" /d "$name" /t $global:timestampUrl "$path"
}

# SIG # Begin signature block
# MIIlHAYJKoZIhvcNAQcCoIIlDTCCJQkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJ9WJLdmx1JZDFlBAta9XHu64
# QBCggh8HMIIDXzCCAkegAwIBAgILBAAAAAABIVhTCKIwDQYJKoZIhvcNAQELBQAw
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMDkwMzE4MTAwMDAwWhcN
# MjkwMzE4MTAwMDAwWjBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBS
# MzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMwldpB5BngiFvXAg7aEyiie/QV2
# EcWtiHL8RgJDx7KKnQRfJMsuS+FggkbhUqsMgUdwbN1k0ev1LKMPgj0MK66X17YU
# hhB5uzsTgHeMCOFJ0mpiLx9e+pZo34knlTifBtc+ycsmWQ1z3rDI6SYOgxXG71uL
# 0gRgykmmKPZpO/bLyCiR5Z2KYVc3rHQU3HTgOu5yLy6c+9C7v/U9AOEGM+iCK65T
# pjoWc4zdQQ4gOsC0p6Hpsk+QLjJg6VfLuQSSaGjlOCZgdbKfd/+RFO+uIEn8rUAV
# SNECMWEZXriX7613t2Saer9fwRPvm2L7DWzgVGkWqQPabumDk3F2xmmFghcCAwEA
# AaNCMEAwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYE
# FI/wS3+oLkUkrk1Q+mOai97i3Ru8MA0GCSqGSIb3DQEBCwUAA4IBAQBLQNvAUKr+
# yAzv95ZURUm7lgAJQayzE4aGKAczymvmdLm6AC2upArT9fHxD4q/c2dKg8dEe3jg
# r25sbwMpjjM5RcOO5LlXbKr8EpbsU8Yt5CRsuZRj+9xTaGdWPoO4zzUhw8lo/s7a
# wlOqzJCK6fBdRoyV3XpYKBovHd7NADdBj+1EbddTKJd+82cEHhXXipa0095MJ6RM
# G3NzdvQXmcIfeg7jLQitChws/zyrVQ4PkX4268NXSb7hLi18YIvDQVETI53O9zJr
# lAGomecsMx86OyXShkDOOyyGeMlhLxS67ttVb9+E7gUJTb0o2HLO02JQZR7rkpeD
# MdmztcpHWD9fMIIElDCCA3ygAwIBAgIOSBtqBybS6D8mAtSCWs0wDQYJKoZIhvcN
# AQELBQAwTDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNV
# BAoTCkdsb2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTYwNjE1MDAw
# MDAwWhcNMjQwNjE1MDAwMDAwWjBaMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xv
# YmFsU2lnbiBudi1zYTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBD
# QSAtIFNIQTI1NiAtIEczMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# jYVVI6kfU6/J7TbCKbVu2PlC9SGLh/BDoS/AP5fjGEfUlk6Iq8Zj6bZJFYXx2Zt7
# G/3YSsxtToZAF817ukcotdYUQAyG7h5LM/MsVe4hjNq2wf6wTjquUZ+lFOMQ5pPK
# +vldsZCH7/g1LfyiXCbuexWLH9nDoZc1QbMw/XITrZGXOs5ynQYKdTwfmOPLGC+M
# nwhKkQrZ2TXZg5J2Yl7fg67k1gFOzPM8cGFYNx8U42qgr2v02dJsLBkwXaBvUt/R
# nMngDdl1EWWW2UO0p5A5rkccVMuxlW4l3o7xEhzw127nFE2zGmXWhEpX7gSvYjjF
# EJtDjlK4PrauniyX/4507wIDAQABo4IBZDCCAWAwDgYDVR0PAQH/BAQDAgEGMB0G
# A1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCTASBgNVHRMBAf8ECDAGAQH/AgEA
# MB0GA1UdDgQWBBQPOueslJF0LZYCc4OtnC5JPxmqVDAfBgNVHSMEGDAWgBSP8Et/
# qC5FJK5NUPpjmove4t0bvDA+BggrBgEFBQcBAQQyMDAwLgYIKwYBBQUHMAGGImh0
# dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9yb290cjMwNgYDVR0fBC8wLTAroCmg
# J4YlaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9yb290LXIzLmNybDBjBgNVHSAE
# XDBaMAsGCSsGAQQBoDIBMjAIBgZngQwBBAEwQQYJKwYBBAGgMgFfMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMA0G
# CSqGSIb3DQEBCwUAA4IBAQAVhCgM7aHDGYLbYydB18xjfda8zzabz9JdTAKLWBoW
# CHqxmJl/2DOKXJ5iCprqkMLFYwQL6IdYBgAHglnDqJQy2eAUTaDVI+DH3brwaeJK
# RWUtTUmQeGYyDrBowLCIsI7tXAb4XBBIPyNzujtThFKAzfCzFcgRCosFeEZZCNS+
# t/9L9ZxqTJx2ohGFRYzUN+5Q3eEzNKmhHzoL8VZEim+zM9CxjtEMYAfuMsLwJG+/
# r/uBAXZnxKPo4KvcM1Uo42dHPOtqpN+U6fSmwIHRUphRptYCtzzqSu/QumXSN4NT
# S35nfIxA9gccsK8EBtz4bEaIcpzrTp3DsLlUo7lOl8oUMIIE9zCCA9+gAwIBAgIM
# KYDysFj73Q3Kq1scMA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNVBAYTAkJFMRkwFwYD
# VQQKExBHbG9iYWxTaWduIG52LXNhMTAwLgYDVQQDEydHbG9iYWxTaWduIENvZGVT
# aWduaW5nIENBIC0gU0hBMjU2IC0gRzMwHhcNMjAxMTE5MTYyNjI5WhcNMjIxMjIy
# MDk0MzQzWjBxMQswCQYDVQQGEwJTRTEPMA0GA1UEBxMGS0FMTUFSMRUwEwYDVQQK
# EwxNZXJpd29ya3MgQUIxFTATBgNVBAMTDE1lcml3b3JrcyBBQjEjMCEGCSqGSIb3
# DQEJARYUc3VwcG9ydEBtZXJpd29ya3Muc2UwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQDCwHSz9jsRUBViLeMm/R4od1ETiOxWO3i574S0ptC0yC7fFYvW
# 5VvaXzDEXGZmDDdkjZtUds5IDljSaMZUloVhrZqqfOesCiMmcULlFWLsWj7Wa9CP
# Rv3YPDSkCuOD1LGE+IGOp+mPcB0YaVTYR2cwVzrqNiFAa81W/EqATl7d6csHLRuv
# vkibhZEjHt4dlikXS01G7QBKLCHoeQaFFClvaJ37b/HaI3UdVfRybbdsnA3s40Q4
# u9lnD3+Tex+ueY00SAajH7yoDklsrRnoDEcMvUL7O+H1IoHGQ8W+raZS+4vYE9te
# 6zM9nZddfphExcRGRKV2XE4CcFHmx6U3BohlAgMBAAGjggGkMIIBoDAOBgNVHQ8B
# Af8EBAMCB4AwgZQGCCsGAQUFBwEBBIGHMIGEMEgGCCsGAQUFBzAChjxodHRwOi8v
# c2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduc2hhMmczb2Nz
# cC5jcnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9n
# c2NvZGVzaWduc2hhMmczMFYGA1UdIARPME0wQQYJKwYBBAGgMgEyMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAgG
# BmeBDAEEATAJBgNVHRMEAjAAMD8GA1UdHwQ4MDYwNKAyoDCGLmh0dHA6Ly9jcmwu
# Z2xvYmFsc2lnbi5jb20vZ3Njb2Rlc2lnbnNoYTJnMy5jcmwwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMwHwYDVR0jBBgwFoAUDzrnrJSRdC2WAnODrZwuST8ZqlQwHQYDVR0O
# BBYEFF340qrXt1rYsSyIgSCJ61M7+BPZMA0GCSqGSIb3DQEBCwUAA4IBAQBzYZwd
# 3+y34qpecwe6l3Hi0UmnSV7llv4/5bv+sLI41nbNhjO+rrIdkD6B81T/Obn/ZIvk
# 2W6oZ3gadIONO8RncPzGyyqB17xPpJiMiNnKlXQ3nEENU7WwyMK3QjnSYdCdnlFl
# SQc1970DvncsJBypLS2/JlEgZx4AGjFpg7dJgIyZHO6TEYmUJkpC3cgQu5ayCK/k
# WJDaPZijz3BBDcyLMe/QHqeHoS+um9Svac6CdqqrxeQE6g+wyMrmPN3Bc6h8fTS5
# R5QgZCumoMxDrYv/dV8I7sXeg2vwiuLMvn9i684FmyUOCs5JTYySEfXsWfAFymX9
# iCAZejb6TNRpy+ELMIIFRzCCBC+gAwIBAgINAfJAQkDO/SLb6Wxx/DANBgkqhkiG
# 9w0BAQwFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEG
# A1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xOTAyMjAw
# MDAwMDBaFw0yOTAzMTgxMDAwMDBaMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9v
# dCBDQSAtIFI2MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxT
# aWduMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAlQfoc8pm+ewUyns8
# 9w0I8bRFCyyCtEjG61s8roO4QZIzFKRvf+kqzMawiGvFtonRxrL/FM5RFCHsSt0b
# WsbWh+5NOhUG7WRmC5KAykTec5RO86eJf094YwjIElBtQmYvTbl5KE1SGooagLcZ
# gQ5+xIq8ZEwhHENo1z08isWyZtWQmrcxBsW+4m0yBqYe+bnrqqO4v76CY1DQ8BiJ
# 3+QPefXqoh8q0nAue+e8k7ttU+JIfIwQBzj/ZrJ3YX7g6ow8qrSk9vOVShIHbf2M
# sonP0KBhd8hYdLDUIzr3XTrKotudCd5dRC2Q8YHNV5L6frxQBGM032uTGL5rNrI5
# 5KwkNrfw77YcE1eTtt6y+OKFt3OiuDWqRfLgnTahb1SK8XJWbi6IxVFCRBWU7qPF
# OJabTk5aC0fzBjZJdzC8cTflpuwhCHX85mEWP3fV2ZGXhAps1AJNdMAU7f05+4Py
# XhShBLAL6f7uj+FuC7IIs2FmCWqxBjplllnA8DX9ydoojRoRh3CBCqiadR2eOoYF
# AJ7bgNYl+dwFnidZTHY5W+r5paHYgw/R/98wEfmFzzNI9cptZBQselhP00sIScWV
# ZBpjDnk99bOMylitnEJFeW4OhxlcVLFltr+Mm9wT6Q1vuC7cZ27JixG1hBSKABlw
# g3mRl5HUGie/Nx4yB9gUYzwoTK8CAwEAAaOCASYwggEiMA4GA1UdDwEB/wQEAwIB
# BjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSubAWjkxPioufi1xzWx/B/yGdT
# oDAfBgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDA+BggrBgEFBQcBAQQy
# MDAwLgYIKwYBBQUHMAGGImh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9yb290
# cjMwNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9y
# b290LXIzLmNybDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0
# cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEM
# BQADggEBAEmsXsWD81rLYSpNl0oVKZ/kFJCqCfnEep81GIoKMxVtcociTkE/bQqe
# GK7b4l/8ldEsmBQ7jsHwNll5842Bz3T2GKTk4WjP739lWULpylU5vNPFJu5xOPrX
# IQMPt07ZW2BqQ7R9CdBgYd2q7QBeTjIe4LJsnjyywruY05B2ammtGtyoidpYT9LC
# izJKzlT7OOk7Bwt1ChHbC3wlJ/GsJs8RU+bcxuJhNTL0zt2D4xk668Joo3IAyCQ8
# TrhTPLEXq+Y1LPnTQinmX2ADrEJhprFXajNC3zUxhso+NyvaxNok9U4S8ra5t0fq
# uyCtYRa3oDPjLYmnvLM8AX8jGoAJNOkwggZZMIIEQaADAgECAg0B7BySQN79LkBd
# fEd0MA0GCSqGSIb3DQEBDAUAMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBD
# QSAtIFI2MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWdu
# MB4XDTE4MDYyMDAwMDAwMFoXDTM0MTIxMDAwMDAwMFowWzELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24g
# VGltZXN0YW1waW5nIENBIC0gU0hBMzg0IC0gRzQwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQDwAuIwI/rgG+GadLOvdYNfqUdSx2E6Y3w5I3ltdPwx5HQS
# GZb6zidiW64HiifuV6PENe2zNMeswwzrgGZt0ShKwSy7uXDycq6M95laXXauv0So
# fEEkjo+6xU//NkGrpy39eE5DiP6TGRfZ7jHPvIo7bmrEiPDul/bc8xigS5kcDoen
# JuGIyaDlmeKe9JxMP11b7Lbv0mXPRQtUPbFUUweLmW64VJmKqDGSO/J6ffwOWN+B
# auGwbB5lgirUIceU/kKWO/ELsX9/RpgOhz16ZevRVqkuvftYPbWF+lOZTVt07XJL
# og2CNxkM0KvqWsHvD9WZuT/0TzXxnA/TNxNS2SU07Zbv+GfqCL6PSXr/kLHU9ykV
# 1/kNXdaHQx50xHAotIB7vSqbu4ThDqxvDbm19m1W/oodCT4kDmcmx/yyDaCUsLKU
# zHvmZ/6mWLLU2EESwVX9bpHFu7FMCEue1EIGbxsY1TbqZK7O/fUF5uJm0A4FIayx
# EQYjGeT7BTRE6giunUlnEYuC5a1ahqdm/TMDAd6ZJflxbumcXQJMYDzPAo8B/XLu
# kvGnEt5CEk3sqSbldwKsDlcMCdFhniaI/MiyTdtk8EWfusE/VKPYdgKVbGqNyiJc
# 9gwE4yn6S7Ac0zd0hNkdZqs0c48efXxeltY9GbCX6oxQkW2vV4Z+EDcdaxoU3wID
# AQABo4IBKTCCASUwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAw
# HQYDVR0OBBYEFOoWxmnn48tXRTkzpPBAvtDDvWWWMB8GA1UdIwQYMBaAFK5sBaOT
# E+Ki5+LXHNbH8H/IZ1OgMD4GCCsGAQUFBwEBBDIwMDAuBggrBgEFBQcwAYYiaHR0
# cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL3Jvb3RyNjA2BgNVHR8ELzAtMCugKaAn
# hiVodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL3Jvb3QtcjYuY3JsMEcGA1UdIARA
# MD4wPAYEVR0gADA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWdu
# LmNvbS9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQwFAAOCAgEAf+KI2VdnK0JfgacJ
# C7rEuygYVtZMv9sbB3DG+wsJrQA6YDMfOcYWaxlASSUIHuSb99akDY8elvKGohfe
# Qb9P4byrze7AI4zGhf5LFST5GETsH8KkrNCyz+zCVmUdvX/23oLIt59h07VGSJiX
# Amd6FpVK22LG0LMCzDRIRVXd7OlKn14U7XIQcXZw0g+W8+o3V5SRGK/cjZk4GVjC
# qaF+om4VJuq0+X8q5+dIZGkv0pqhcvb3JEt0Wn1yhjWzAlcfi5z8u6xM3vreU0yD
# /RKxtklVT3WdrG9KyC5qucqIwxIwTrIIc59eodaZzul9S5YszBZrGM3kWTeGCSzi
# RdayzW6CdaXajR63Wy+ILj198fKRMAWcznt8oMWsr1EG8BHHHTDFUVZg6HyVPSLj
# 1QokUyeXgPpIiScseeI85Zse46qEgok+wEr1If5iEO0dMPz2zOpIJ3yLdUJ/a8vz
# pWuVHwRYNAqJ7YJQ5NF7qMnmvkiqK1XZjbclIA4bUaDUY6qD6mxyYUrJ+kPExlfF
# nbY8sIuwuRwx773vFNgUQGwgHcIt6AvGjW2MtnHtUiH+PvafnzkarqzSL3ogsfSs
# qh3iLRSd+pZqHcY8yvPZHL9TTaRHWXyVxENB+SXiLBB+gfkNlKd98rUJ9dhgckBQ
# lSDUQ0S++qCV5yBZtnjGpGqqIpswggZlMIIETaADAgECAhABGHiD7/Q+QELMxYGa
# BbmHMA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIFNIQTM4NCAtIEc0MB4XDTIxMDEyODExMDQxN1oXDTMyMDMwMTExMDQxN1ow
# YzELMAkGA1UEBhMCQkUxGTAXBgNVBAoMEEdsb2JhbFNpZ24gbnYtc2ExOTA3BgNV
# BAMMMEdsb2JhbHNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgYWR2YW5jZWQg
# LSBHNDCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAKaV00lrWI2tLB1g
# JZAiXM7DjXVVR4XHS/dn8FkAa1S66qV1fNPf6QAAP9AosLc5ADcGE5pXTIY2w2Ss
# aTxdS1CO1TkRA35dGuYLokCTLxxlxT0G2LKMKVkWRwEN6I5R40IaljJuZ2X6pUra
# IUrJkW/lxVIXkZCpWxo5Rk1i7U0H5XRM8SoPV/CyeHK/oanR48QSRVNhjsx+4aqq
# L2QlYf5jU/X4NC1M2651GNhVE8GSzfQFu3pR6L4U8fl4VfwUvPjMRiIP9m8rjp1n
# QBEVTyaokyxrSwOC4oKAREnNuYIalHnw3Y5AAGVoXlztrDiIaLVL3QBHV/5AhYd9
# WAqrAkOHi5mm7KdGN+QJqpComoO/QBrv+CvbW6UN7gqyuBJOHs/8zqIVV7syyrMT
# PqBRXLenBirdZBcLH5VPuzv4WsmW+ec/uytyhxKVUQ0BNigT5tCdgmkYEjUo5ca2
# Axl7ax+H1tsO8MNsroJCbuh9LwvSu2QKk2DWmggILU6zOCYeDQIDAQABo4IBmzCC
# AZcwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMB0GA1Ud
# DgQWBBQPEYQ6ncul39j6eXop758HmwK9LDBMBgNVHSAERTBDMEEGCSsGAQQBoDIB
# HjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBv
# c2l0b3J5LzAJBgNVHRMEAjAAMIGQBggrBgEFBQcBAQSBgzCBgDA5BggrBgEFBQcw
# AYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY2EvZ3N0c2FjYXNoYTM4NGc0
# MEMGCCsGAQUFBzAChjdodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2Vy
# dC9nc3RzYWNhc2hhMzg0ZzQuY3J0MB8GA1UdIwQYMBaAFOoWxmnn48tXRTkzpPBA
# vtDDvWWWMEEGA1UdHwQ6MDgwNqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5j
# b20vY2EvZ3N0c2FjYXNoYTM4NGc0LmNybDANBgkqhkiG9w0BAQsFAAOCAgEAkRkG
# piHW+IHUOCC5yhUn2NO8oy4kfKYj8olXVdV9bardDWS6YlQ4rjojMdff0NJisA/e
# OIH9k0bpln7OcQ2CbZkHut/GN72ofhiWRjw0c2y88n0GOv7qTnsxIxx5vt6GFe1I
# aSjnyzMiBIKforVJHD1upo9Q4NwMVkMvQdL8KgCbkzeDOZOZwzXQyIR52094waxY
# N3S9GgyTnf7mUeInejuwlzgiznVkQzSt4ahiNSWhBLPvvEowhdBt5antMETyCqyQ
# MVyOvSRqk/IVezXE4mLJA9Sm22uh1ku5RWj3ThcG4LH2fX4CkNJ76ST4uvvkRM+y
# 2/9Bemlv8/BxpPQEWXgPccHcwe2E8s8CE/ADUWOWQhobnFeF4UZlq8RKXg1bLyKa
# AHi7CZtJYw5aJUssYOK82UcCmBm0x8iYuR2tvfQM42TetHaOxs3Sd+JVMILCLIoc
# MLnXU/EsdNVItc1Y9a9v7GyHBa1Y1rEGC66mvaTePRZ4ETgwbCGTHTl5xKjqlj3b
# MLk8wUTQ/xHP0lyfp09vVT/PHCAUHbagDFb7WIL3Y14LXw8N0tH4NJ03nXQ8Kczp
# 2iTkAmCAsZKagZFMSLVQti7vP2bd6fM3DfsNQ7rtFoaGLJTtJ1CZKKlZdNLFYu4E
# wzmSJkPlsEWPjp7RA+WeQMiRlxQe4m1mzo67SG0xggV/MIIFewIBATBqMFoxCzAJ
# BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTAwLgYDVQQDEydH
# bG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gU0hBMjU2IC0gRzMCDCmA8rBY+90N
# yqtbHDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUo8/7IaTTacNrxY5ZhAyq2Urbl5wwDQYJKoZI
# hvcNAQEBBQAEggEABp9A6e1rZmxkCGufd4+iul1CyOyQgsazhHYVVqgO1bHiu5Rw
# ZTyKtIC9GvRkIOLdcIElkKj22ic9DeYepR6u0RflhP24Fsk/F+wRJAQYTO2adnBI
# zdY38SUZCfH13CGPZelbFpULrzBmr5vW/F5HbFWPiBcVUf7paUf1D/V+vMQMBRZt
# DIy94FhEY96eyyOPdhao4NMHFzETDT5lxQHBlV7UkoqtfdN2jcyfgCfouJ9ih2D4
# ptSyqy4YNq7M5IKNnNo7oV7U5FwZI+SzSHgc3FZYPDhcN0VX9IWnJ2rbwshSpizm
# w5FSrRPoYtPm47Nc9HZba5ogHdJmik/Z/tDDQKGCA3AwggNsBgkqhkiG9w0BCQYx
# ggNdMIIDWQIBATBvMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWdu
# IG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNI
# QTM4NCAtIEc0AhABGHiD7/Q+QELMxYGaBbmHMA0GCWCGSAFlAwQCAQUAoIIBPzAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMTA0MjIw
# ODQ0MzJaMC0GCSqGSIb3DQEJNDEgMB4wDQYJYIZIAWUDBAIBBQChDQYJKoZIhvcN
# AQELBQAwLwYJKoZIhvcNAQkEMSIEIB21V577j+wQQ1KRqU1HyixMeL5yypmKtm1W
# vPVBfR8bMIGkBgsqhkiG9w0BCRACDDGBlDCBkTCBjjCBiwQUcIBGwmg4vIsFgR9p
# D6mriIGNSPcwczBfpF0wWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# U0hBMzg0IC0gRzQCEAEYeIPv9D5AQszFgZoFuYcwDQYJKoZIhvcNAQELBQAEggGA
# NjieMKrcL5+eLis7P7545kWYAN4Jqd+LFVAU2F7TWdkmeSRoQLksH5AN8HI2Irp3
# Gb/r1IcemEnEzTzP/9C3al0UUjycTEzfXzKptbCeSufoDlfFnyQUmyn3B43G3t+6
# R60l8+qbSC8tbCMiv7mkXLbQ0XqavLe8LRF5Vh/qPd81H1L289s2OHv8zhDioJNb
# SJ8+7a28XWIJaQKoJdsY+9SNqq23ZP/XNOqmvJrGRSuGxuY+jmoLAMSJXA7OJWiu
# kb4abCtyDrGiwomp6QdKQ5j1lPmxstAjrgC7bSwuezK28Jcvf2rqnKQUBPxNxdfL
# FAyAAIs0lZBIP/YkGhQ4/oDbMJXOIzqZtAJR/QpyWa5wdAvLQx4eM4CbpfEXQRkH
# 5cI0DMe2micmZV2cVeaeXALXKFBHstT4zP2E4N+Ah6MvOkxc7TAnhkzvRU3yuQh9
# N+fiTL3aRVTMa9cNexKGKA5QOa8po24/aTHQY1Q3DAKCSVOYAV8XgwQ83AgrN2fe
# SIG # End signature block
