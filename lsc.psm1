function getColor ($item) {
    if (isDirectory($item)) {
        if (isHidden($item)) {
            return "Gray"
        }
        return "DarkGreen"
    }
    if (isHidden($item)) {
        return "DarkGray"
    }
    return "DarkBlue"
}

function isHidden ($item) {
    return $item.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)
}

function isDirectory ($item) {
    return $item.Attributes.HasFlag([System.IO.FileAttributes]::Directory)
}
function isFile ($item) {
    return -not (isDirectory($item))
}
function displayLength($ch) {
    if ([int][char]$ch -ge 128) {
        return 2
    }
    return 1
}
function printNameFormat ($item, $style) {
    $maxNameLength = $style.maxSpacePerName - 1
    $nameLength = $item.Name.Length
    $restrictedIdx = 0
    $restrictedLength = 0
    $currentLength = 0
    $restrictedShouldStop = $false
    for ($idx=0;$idx -lt $item.Name.Length; $idx++) {
        $chDisplayLength = displayLength($item.Name[$idx])
        if (!$restrictedShouldStop) {
            if (($restrictedLength+$chDisplayLength) -le ($maxNameLength-3)) {
                $restrictedLength += $chDisplayLength
                $restrictedIdx=$idx
            }
            else {$restrictedShouldStop = $true}
        }
        $currentLength += $chDisplayLength
        if ($currentLength -gt $maxNameLength) {
            return "{0,-$($restrictedIdx+1+$style.maxSpacePerName-$restrictedLength)}" -f `
                ($item.Name.SubString(0, $restrictedIdx+1) + "... ")
        }
    }
    return "{0,-$($item.Name.Length+$style.maxSpacePerName-$currentLength)}" -f $item.Name
}
function printNames ($items, $style) {
    $it = 0
    foreach ($item in $items) {
        $name = printNameFormat $item $style
        Write-Host "$($name)" -ForegroundColor $(getColor $item) -NoNewLine
        $it += 1
        if (($it % $style.nNamePerRow) -eq 0) {Write-Host ""}
    }
    if (($it % $style.nNamePerRow) -ne 0) {Write-Host ""}
}

$printStyles = @{
    "large"=@{"nNamePerRow"=8;"maxSpacePerName"=20};
    "tightLarge"=@{"nNamePerRow"=8;"maxSpacePerName"=15};
    "normal"=@{"nNamePerRow"=4;"maxSpacePerName"=20};
    "wideNormal"=@{"nNamePerRow"=4;"maxSpacePerName"=40};
}
function lsc {
    Param (
        [string]$path = ".",
        $style = $printStyles.normal,
        [switch]$Force=$false
    )
    $items = if ($Force) {Get-ChildItem -Path $Path -Force} else {Get-ChildItem -Path $Path}

    $hiddenDirectories = `
        ($items | foreach {if((isDirectory($_)) -and (isHidden($_))){,@($_)}else{}})
    $normalDirectories = `
        ($items | foreach {if((isDirectory($_))-and -not (isHidden($_))){,@($_)}else{}})
    $hiddenFiles = `
        ($items | foreach {if((isFile($_)) -and (isHidden($_))){,@($_)}else{}})
    $normalfiles = `
        ($items | foreach {if((isFile($_)) -and -not (isHidden($_))){,@($_)}else{}})
    printNames $hiddenDirectories $style
    printNames $hiddenFiles $style
    printNames $normalDirectories $style
    printNames $normalfiles $style
}

Export-ModuleMember -Function "lsc"
Export-ModuleMember -Variable "printStyles"