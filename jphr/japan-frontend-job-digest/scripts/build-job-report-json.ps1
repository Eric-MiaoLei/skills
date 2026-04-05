param(
    [Parameter(Mandatory = $true)]
    [string]$InputJson,

    [Parameter(Mandatory = $true)]
    [string]$OutputJson,

    [switch]$WriteCanonicalCopy,

    [string]$ReportTitle = "Japan Frontend Job Opportunities",
    [string]$CreatedAt = "",
    [string]$TargetProfile = "Frontend engineer with React experience",
    [string]$SearchScope = "Tokyo and remote-friendly roles in Japan",
    [string]$Methodology = "Verified against live listing pages and normalized into a shortlist."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$MaxJobsPerFamily = 20
$RoleFamilyOrder = @("frontend", "backend", "qa")

function Normalize-Text {
    param([AllowNull()]$Value, [string]$Fallback = "Unknown")

    if ($null -eq $Value) {
        return $Fallback
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $Fallback
    }

    return $text.Trim()
}

function Normalize-Score {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return 0.0
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return 0.0
    }

    $parsed = 0.0
    if ([double]::TryParse($text, [ref]$parsed)) {
        return [Math]::Round($parsed, 2)
    }

    return 0.0
}

function Normalize-StringArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    $items = @()
    foreach ($entry in @($Value)) {
        $segments = @()
        if ($entry -is [System.Array]) {
            $segments = @($entry)
        } else {
            $textValue = [string]$entry
            if ([string]::IsNullOrWhiteSpace($textValue)) {
                $segments = @()
            } elseif ($textValue -match "[;|/]") {
                $segments = $textValue -split "\s*[;|/]\s*"
            } elseif ($textValue -match ",") {
                $segments = $textValue -split "\s*,\s*"
            } else {
                $segments = @($textValue)
            }
        }

        foreach ($segment in $segments) {
            $text = Normalize-Text $segment ""
            if (-not [string]::IsNullOrWhiteSpace($text) -and -not ($items -contains $text)) {
                $items += $text
            }
        }
    }

    return @($items)
}

function Normalize-Url {
    param([AllowNull()]$Value)

    $text = Normalize-Text $Value
    if ($text -eq "Unknown") {
        return $text
    }

    return $text.TrimEnd("/")
}

function Normalize-DateText {
    param([AllowNull()]$Value, [string]$Fallback = "")

    $text = Normalize-Text $Value $Fallback
    if ([string]::IsNullOrWhiteSpace($text) -or $text -eq "Unknown") {
        return $Fallback
    }

    return $text
}

function Normalize-HiringStatus {
    param([AllowNull()]$Value)

    $text = Normalize-Text $Value ""
    if ([string]::IsNullOrWhiteSpace($text)) {
        return "unknown"
    }

    $normalized = $text.ToLowerInvariant()
    if (
        $normalized -match "closed|expired|inactive|position filled|filled|no longer hiring|no longer accepting|applications closed|not accepting|archived|stopped" -or
        $text -match "募集終了|掲載終了|応募終了|受付終了|採用終了|充足|募集を終了|現在募集しておりません|応募受付を終了"
    ) {
        return "closed"
    }

    if (
        $normalized -match "open|active|hiring|recruiting|accepting applications|available" -or
        $text -match "募集中|採用中|応募受付中|エントリー受付中|積極採用中"
    ) {
        return "open"
    }

    return "unknown"
}

function Get-ObjectPropertyValue {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }

        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

function Get-FirstMatchingPhrase {
    param(
        [AllowNull()][string]$Text,
        [string[]]$Phrases
    )

    $normalizedText = Normalize-Text $Text ""
    if ([string]::IsNullOrWhiteSpace($normalizedText)) {
        return ""
    }

    foreach ($phrase in $Phrases) {
        if (-not [string]::IsNullOrWhiteSpace($phrase) -and $normalizedText -match [Regex]::Escape($phrase)) {
            return $phrase
        }
    }

    return ""
}

function Get-StatusEvidenceText {
    param($Job)

    $fields = @(
        "html_validation_text",
        "validation_text",
        "page_text",
        "response_text",
        "raw_text",
        "html_text",
        "body_text",
        "rendered_text",
        "extracted_text",
        "status_reason",
        "hiring_status"
    )

    $parts = @()
    foreach ($field in $fields) {
        $value = Get-ObjectPropertyValue $Job $field
        foreach ($candidate in @($value)) {
            $text = Normalize-Text $candidate ""
            if (-not [string]::IsNullOrWhiteSpace($text) -and -not ($parts -contains $text)) {
                $parts += $text
            }
        }
    }

    return ($parts -join "`n")
}

function Resolve-HiringStatusData {
    param($Job)

    $explicitStatus = Normalize-HiringStatus (Get-ObjectPropertyValue $Job "hiring_status")
    $explicitReason = Normalize-Text (Get-ObjectPropertyValue $Job "status_reason") ""
    $evidenceText = Get-StatusEvidenceText $Job

    $closedPhrases = @(
        "This job is no longer available.",
        "This position is closed and is no longer accepting applications.",
        "no longer available",
        "no longer accepting applications",
        "applications closed",
        "position filled",
        "listing expired",
        "募集終了",
        "掲載終了",
        "応募終了",
        "受付終了",
        "採用終了",
        "充足",
        "募集を終了",
        "現在募集しておりません",
        "応募受付を終了"
    )

    $openPhrases = @(
        "accepting applications",
        "currently hiring",
        "open role",
        "active listing",
        "募集中",
        "採用中",
        "応募受付中",
        "エントリー受付中",
        "積極採用中"
    )

    $closedPhrase = Get-FirstMatchingPhrase $evidenceText $closedPhrases
    if ($closedPhrase) {
        return @{
            HiringStatus = "closed"
            StatusReason = if ($explicitReason) { $explicitReason } else { $closedPhrase }
        }
    }

    if ($explicitStatus -eq "closed") {
        return @{
            HiringStatus = "closed"
            StatusReason = $explicitReason
        }
    }

    $openPhrase = Get-FirstMatchingPhrase $evidenceText $openPhrases
    if ($openPhrase) {
        return @{
            HiringStatus = "open"
            StatusReason = $explicitReason
        }
    }

    return @{
        HiringStatus = $explicitStatus
        StatusReason = $explicitReason
    }
}

function Get-DedupKey {
    param($Job)

    $url = Normalize-Url $Job.url
    if ($url -ne "Unknown") {
        return "url::$($url.ToLowerInvariant())"
    }

    $company = (Normalize-Text $Job.company).ToLowerInvariant()
    $title = (Normalize-Text $Job.title).ToLowerInvariant()
    $location = (Normalize-Text $Job.location).ToLowerInvariant()
    return "fallback::$company|$title|$location"
}

function Get-RoleFamily {
    param($Job)

    $explicitFamily = Normalize-Text (Get-ObjectPropertyValue $Job "job_family") ""
    if ($explicitFamily) {
        $normalizedExplicit = $explicitFamily.ToLowerInvariant()
        if ($normalizedExplicit -in @("frontend", "backend", "qa")) {
            return $normalizedExplicit
        }
        if ($normalizedExplicit -in @("test", "testing", "sdet")) {
            return "qa"
        }
    }

    $title = Normalize-Text (Get-ObjectPropertyValue $Job "title") ""
    $summary = Normalize-Text (Get-ObjectPropertyValue $Job "summary") ""
    $stack = Normalize-Text (Get-ObjectPropertyValue $Job "tech_stack") ""
    $combined = "$title $summary $stack".ToLowerInvariant()

    if (
        $combined -match "(^|[^a-z])(qa|quality assurance|test engineer|tester|sdet|automation test|test automation)([^a-z]|$)" -or
        $combined -match "qaエンジニア|テストエンジニア|品質保証|自動テスト"
    ) {
        return "qa"
    }

    if (
        $combined -match "(^|[^a-z])(backend|back-end|server-side|server side|api engineer|platform engineer|java|go|golang|python|ruby|php|node\.js|nodejs|spring|django|laravel)([^a-z]|$)" -or
        $combined -match "バックエンド|サーバーサイド|バックエンドエンジニア|サーバーサイドエンジニア|apiエンジニア|基盤"
    ) {
        return "backend"
    }

    if (
        $combined -match "(^|[^a-z])(frontend|front-end|web ui engineer|react engineer)([^a-z]|$)" -or
        $combined -match "フロントエンド|フロントエンドエンジニア|webエンジニア|ui"
    ) {
        return "frontend"
    }

    return "frontend"
}

if (-not (Test-Path -LiteralPath $InputJson)) {
    throw "Input JSON not found: $InputJson"
}

$inputPath = (Resolve-Path -LiteralPath $InputJson).Path
$outputParent = Split-Path -Parent $OutputJson

if (-not [string]::IsNullOrWhiteSpace($outputParent) -and -not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$raw = Get-Content -LiteralPath $inputPath -Raw -Encoding UTF8
$parsed = $raw | ConvertFrom-Json

$jobSource = @()
$inputAssumptions = @()
$inputTakeaways = @()
$inputReportTitle = ""
$inputCreatedAt = ""
$inputTargetProfile = ""
$inputSearchScope = ""
$inputMethodology = ""

if ($parsed -is [System.Array]) {
    $jobSource = @($parsed)
} elseif ($parsed.PSObject.Properties.Name -contains "jobs") {
    $jobSource = @(Get-ObjectPropertyValue $parsed "jobs")
    $inputAssumptions = Normalize-StringArray (Get-ObjectPropertyValue $parsed "assumptions")
    $inputTakeaways = Normalize-StringArray (Get-ObjectPropertyValue $parsed "key_takeaways")
    $inputReportTitle = Normalize-Text (Get-ObjectPropertyValue $parsed "report_title") ""
    $inputCreatedAt = Normalize-Text (Get-ObjectPropertyValue $parsed "created_at") ""
    $inputTargetProfile = Normalize-Text (Get-ObjectPropertyValue $parsed "target_profile") ""
    $inputSearchScope = Normalize-Text (Get-ObjectPropertyValue $parsed "search_scope") ""
    $inputMethodology = Normalize-Text (Get-ObjectPropertyValue $parsed "methodology") ""
} else {
    throw "The input JSON must be a jobs array or an object containing a jobs array."
}

if ($jobSource.Count -eq 0) {
    throw "The input JSON must be a jobs array or an object containing a non-empty jobs array."
}

$dedupedJobs = @{}
foreach ($job in $jobSource) {
    $statusData = Resolve-HiringStatusData $job
    $normalizedJob = [PSCustomObject]@{
        title = Normalize-Text (Get-ObjectPropertyValue $job "title")
        company = Normalize-Text (Get-ObjectPropertyValue $job "company")
        location = Normalize-Text (Get-ObjectPropertyValue $job "location")
        work_mode = Normalize-Text (Get-ObjectPropertyValue $job "work_mode")
        employment_type = Normalize-Text (Get-ObjectPropertyValue $job "employment_type")
        salary = Normalize-Text (Get-ObjectPropertyValue $job "salary")
        japanese_level = Normalize-Text (Get-ObjectPropertyValue $job "japanese_level")
        english_level = Normalize-Text (Get-ObjectPropertyValue $job "english_level")
        visa_support = Normalize-Text (Get-ObjectPropertyValue $job "visa_support")
        tech_stack = Normalize-Text (Get-ObjectPropertyValue $job "tech_stack")
        company_size = Normalize-Text (Get-ObjectPropertyValue $job "company_size")
        benefits = Normalize-StringArray (Get-ObjectPropertyValue $job "benefits")
        education_requirements = Normalize-Text (Get-ObjectPropertyValue $job "education_requirements")
        experience_requirements = Normalize-Text (Get-ObjectPropertyValue $job "experience_requirements")
        other_requirements = Normalize-Text (Get-ObjectPropertyValue $job "other_requirements")
        summary = Normalize-Text (Get-ObjectPropertyValue $job "summary")
        url = Normalize-Url (Get-ObjectPropertyValue $job "url")
        source = Normalize-Text (Get-ObjectPropertyValue $job "source")
        source_url = Normalize-Url (Get-ObjectPropertyValue $job "source_url")
        source_date = Normalize-Text (Get-ObjectPropertyValue $job "source_date")
        first_posted_at = Normalize-DateText (Get-ObjectPropertyValue $job "first_posted_at") (Normalize-Text (Get-ObjectPropertyValue $job "source_date"))
        hiring_status = $statusData.HiringStatus
        status_reason = $statusData.StatusReason
        match_score = Normalize-Score (Get-ObjectPropertyValue $job "match_score")
        notes = Normalize-Text (Get-ObjectPropertyValue $job "notes")
        job_family = Get-RoleFamily $job
    }

    if ($normalizedJob.source_url -eq "Unknown") {
        $normalizedJob.source_url = $normalizedJob.url
    }

    $dedupKey = Get-DedupKey $normalizedJob
    if (-not $dedupedJobs.ContainsKey($dedupKey) -or $normalizedJob.match_score -gt $dedupedJobs[$dedupKey].match_score) {
        $dedupedJobs[$dedupKey] = $normalizedJob
    }
}

$sortedJobs =
    $dedupedJobs.Values |
    Sort-Object -Property @{ Expression = { $_.match_score }; Descending = $true }, @{ Expression = { $_.company }; Descending = $false }, @{ Expression = { $_.title }; Descending = $false }

$normalizedJobs = @()
foreach ($family in $RoleFamilyOrder) {
    $familyJobs = @(
        $sortedJobs |
        Where-Object { $_.job_family -eq $family } |
        Select-Object -First $MaxJobsPerFamily
    )

    if ($familyJobs.Count -gt 0) {
        $normalizedJobs += @($familyJobs)
    }
}

$otherFamilyJobs = @(
    $sortedJobs |
    Where-Object { $_.job_family -notin $RoleFamilyOrder } |
    Select-Object -First $MaxJobsPerFamily
)

if ($otherFamilyJobs.Count -gt 0) {
    $normalizedJobs += @($otherFamilyJobs)
}

$normalizedJobs =
    $normalizedJobs |
    ForEach-Object {
        [PSCustomObject]@{
            title = $_.title
            company = $_.company
            location = $_.location
            work_mode = $_.work_mode
            employment_type = $_.employment_type
            salary = $_.salary
            japanese_level = $_.japanese_level
            english_level = $_.english_level
            visa_support = $_.visa_support
            tech_stack = $_.tech_stack
            company_size = $_.company_size
            benefits = @($_.benefits)
            education_requirements = $_.education_requirements
            experience_requirements = $_.experience_requirements
            other_requirements = $_.other_requirements
            summary = $_.summary
            url = $_.url
            source = $_.source
            source_url = $_.source_url
            source_date = $_.source_date
            first_posted_at = $_.first_posted_at
            hiring_status = $_.hiring_status
            status_reason = $_.status_reason
            job_family = $_.job_family
            match_score = $_.match_score
            notes = $_.notes
        }
    }

if ([string]::IsNullOrWhiteSpace($CreatedAt)) {
    $CreatedAt = if (-not [string]::IsNullOrWhiteSpace($inputCreatedAt)) { $inputCreatedAt } else { Get-Date -Format "yyyy-MM-dd" }
}

$finalReportTitle = if ($PSBoundParameters.ContainsKey("ReportTitle")) { Normalize-Text $ReportTitle "Japan Frontend Job Opportunities" } elseif (-not [string]::IsNullOrWhiteSpace($inputReportTitle)) { Normalize-Text $inputReportTitle "Japan Frontend Job Opportunities" } else { Normalize-Text $ReportTitle "Japan Frontend Job Opportunities" }
$finalTargetProfile = if ($PSBoundParameters.ContainsKey("TargetProfile")) { Normalize-Text $TargetProfile } elseif (-not [string]::IsNullOrWhiteSpace($inputTargetProfile)) { Normalize-Text $inputTargetProfile } else { Normalize-Text $TargetProfile }
$finalSearchScope = if ($PSBoundParameters.ContainsKey("SearchScope")) { Normalize-Text $SearchScope } elseif (-not [string]::IsNullOrWhiteSpace($inputSearchScope)) { Normalize-Text $inputSearchScope } else { Normalize-Text $SearchScope }
$finalMethodology = if ($PSBoundParameters.ContainsKey("Methodology")) { Normalize-Text $Methodology } elseif (-not [string]::IsNullOrWhiteSpace($inputMethodology)) { Normalize-Text $inputMethodology } else { Normalize-Text $Methodology }

$reportObject = [PSCustomObject]@{
    report_title = $finalReportTitle
    created_at = Normalize-Text $CreatedAt (Get-Date -Format "yyyy-MM-dd")
    target_profile = $finalTargetProfile
    search_scope = $finalSearchScope
    methodology = $finalMethodology
    assumptions = @($inputAssumptions)
    key_takeaways = @($inputTakeaways)
    jobs = @($normalizedJobs)
}

$json = $reportObject | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($OutputJson, $json, [System.Text.UTF8Encoding]::new($true))
Write-Output "Report JSON written to $OutputJson"

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputJson)
$canonicalOutputPath = Join-Path ([System.IO.Path]::GetDirectoryName($resolvedOutputPath)) "jobs.json"

if ($WriteCanonicalCopy -and $resolvedOutputPath -ne $canonicalOutputPath) {
    [System.IO.File]::WriteAllText($canonicalOutputPath, $json, [System.Text.UTF8Encoding]::new($true))
    Write-Output "Canonical jobs JSON written to $canonicalOutputPath"
}
