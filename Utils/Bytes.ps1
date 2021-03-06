﻿function Measure-HammingDistance {
<#
.SYNOPSIS

    Counts Hamming distance between bytes in arrays.

.DESCRIPTION

    Arrays must be of the same size.

.PARAMETER Message1

    The first byte array.

.PARAMETER Message2

    The second byte array.

.OUTPUTS

    Calculated Hamming distance.
#>
    Param (
        [Parameter(Mandatory = $True, Position = 0)][Byte[]]$Message1,
        [Parameter(Mandatory = $True, Position = 1)][Byte[]]$Message2
    )

    if ($Message1.Length -ne $Message2.Length) {
        Throw [ArgumentException]"Arrays do not have the same length"
    }

    function Local:Count1s {
        Param ([Byte]$Byte)

        $NumberOf1s = 0;
        $Mask = 1
        while ($Mask) {
            if ($Mask -band $Byte) {
                $NumberOf1s++
            }
            $Mask = $Mask -shl 1
        }
        return $NumberOf1s
    }

    $Distance = 0
    for ($i = 0; $i -lt $Message1.Length; $i++) {
        $Distance += Count1s $($Message1[$i] -bxor $Message2[$i])
    }

    return $Distance
}

function Format-HexPrettyPrint {
<#
.SYNOPSIS

    Nicely prints a byte array.

.DESCRIPTION

    It is possible to pass the byte array through a pipeline.

.PARAMETER ByteArray

    A byte array to print.

.EXAMPLE

    gc -Encoding Byte .\test.txt | Format-HexPrettyPrint

.INPUTS

    A byte array.

.OUTPUTS

    Nicely print byte array, with ASCII representation on the right side.
#>
    [CmdletBinding()] Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)][Byte[]]$ByteArray
    )

    BEGIN
    {
        function Local:PrintLine {
            param (
                [Byte[]]$LineBuffer,
                [Int32]$LineOffset
            )

            if (!$LineBuffer) {
                return
            }

            $HexBuffer = @($LineBuffer | % { '{0:x2}' -f $_ }) -join ' '
            $AsciiBuffer = @($LineBuffer | % {
                $Numeric = [Int32]$_
                if ($Numeric -ge 32 -and $Numeric -le 126) {
                    [Char]$_
                } else {
                    [Char]'.'
                }
            }) -join ''

            Write-Host ('{0:x4}: {1,-47}  {2}' -f $LineOffset,$HexBuffer,$AsciiBuffer)
        }

        $LineOffset = 0
        $LineBuffer = @()
        Write-Host '       0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F'
    }

    PROCESS
    {
        foreach ($Byte in $ByteArray) {
            $LineBuffer += $Byte

            if ($LineBuffer.Length -eq 0x10) {
                PrintLine $LineBuffer $LineOffset
                $LineBuffer = @()
                $LineOffset += 0x10
            }
        }
    }

    END
    {
        PrintLine $LineBuffer $LineOffset
    }
}

function Get-RandomBytes {
<#
.SYNOPSIS

    Generates a byte array of randomly (cryptographically secure) generated bytes.

.PARAMETER Length

    The number of bytes in the output array.

.EXAMPLE

    Get-RandomBytes 20

.OUTPUTS

    A byte array of the specified length, containing random bytes.
#>
    Param (
        [Parameter(Mandatory = $True)]
        [UInt32]
        $Length
    )

    $Rng = New-Object Org.BouncyCastle.Crypto.Prng.CryptoApiRandomGenerator

    $Result = New-Object Byte[] $Length

    $Rng.NextBytes($Result)

    $Result
}
