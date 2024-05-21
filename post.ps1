# Description: Create a new post with the specified title, subtitle, and tags
# Usage: post.ps1 [title] [subtitle] [tag1] [tag2] ...

$Source = "."
$PostsDir = Join-Path $Source "_posts"
$PostExt = "md"
$Date = Get-Date -Format "yyyy-MM-dd"

# Create a new post
function New-Post {
    param(
        [string]$Title,
        [string]$Subtitle,
        [System.Collections.ArrayList]$Tags
    )
    
    $FormatTitle = $Title -replace '\s', '_'

    # Define filename based on date, title, and post extension
    $Filename = Join-Path $PostsDir "$Date-$FormatTitle.$PostExt"

    New-Item -Path $PostsDir -ItemType Directory -Force | Out-Null

    # Construct tags section with each tag on a new line
    $tagsString = ""
    foreach ($tag in $Tags) {
        $tagsString += "    - $tag`n"
    }
    $tagsString = $tagsString.TrimEnd("`n")
    
    @"
---
layout:         post
title:          $Title
subtitle:       $Subtitle
date:           $Date
author:         Steel Shadow
# header-img:     img
# header-style:   text
mathjax:        true
tags:
$tagsString
---
"@ | Set-Content -Path $Filename -Encoding UTF8
}

$title = $args.Count -ge 1 ? $args[0] : "new post"
$subtitle = $args.Count -ge 2 ? $args[1] : ""

$tags = New-Object System.Collections.ArrayList
if ($args.Count -lt 3) {
    $tags.Add("tag")
}
else {
    $iter = 2
    while ($iter -lt $args.Count) {
        $tags.Add($args[$iter++]) | Out-Null
    }
}

New-Post -Title $title -Subtitle $subtitle -Tags $tags
