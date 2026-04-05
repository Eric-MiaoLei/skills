param(
    [Parameter(Mandatory = $true)]
    [string]$InputJson,

    [Parameter(Mandatory = $true)]
    [string]$OutputDoc
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Escape-Html {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Format-Value {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return "&#26410;&#30693;"
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return "&#26410;&#30693;"
    }

    return $text.Trim()
}

function Normalize-Score {
    param([AllowNull()]$Value)

    $parsed = 0.0
    if ([double]::TryParse([string]$Value, [ref]$parsed)) {
        return [Math]::Round($parsed, 2)
    }

    return 0.0
}

function ConvertTo-HtmlList {
    param([AllowNull()]$Items)

    $entries = @()
    foreach ($item in @($Items)) {
        $text = [string]$item
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            $entries += "<li>$([System.Net.WebUtility]::HtmlEncode($text.Trim()))</li>"
        }
    }

    if ($entries.Count -eq 0) {
        return ""
    }

    return "<ul>$($entries -join '`n')</ul>"
}

function Format-ArrayValue {
    param([AllowNull()]$Items)

    $values = @()
    foreach ($item in @($Items)) {
        $text = [string]$item
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            $values += $text.Trim()
        }
    }

    if ($values.Count -eq 0) {
        return "&#26410;&#30693;"
    }

    return ($values | Select-Object -Unique) -join " / "
}

function Get-RecommendationReason {
    param($Job)

    $notes = [string](Format-Value $Job.notes)
    if ($notes -ne "&#26410;&#30693;") {
        return $notes
    }

    $reasons = @()
    if ((Format-Value $Job.salary) -ne "&#26410;&#30693;") {
        $reasons += "salary disclosed"
    }
    if ((Format-Value $Job.work_mode) -match "Remote") {
        $reasons += "remote-friendly"
    }
    if ((Format-Value $Job.english_level) -match "Professional|Native|Conversational") {
        $reasons += "English-accessible"
    }
    if ((Format-Value $Job.tech_stack) -ne "&#26410;&#30693;") {
        $reasons += "clear frontend stack"
    }

    if ($reasons.Count -eq 0) {
        return "listing quality and frontend fit are stronger than the rest of the shortlist"
    }

    return ($reasons -join ", ")
}

if (-not (Test-Path -LiteralPath $InputJson)) {
    throw "Input JSON not found: $InputJson"
}

$inputPath = (Resolve-Path -LiteralPath $InputJson).Path
$outputParent = Split-Path -Parent $OutputDoc

if (-not [string]::IsNullOrWhiteSpace($outputParent) -and -not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$raw = Get-Content -LiteralPath $inputPath -Raw -Encoding UTF8
$data = $raw | ConvertFrom-Json
$jobs = @($data.jobs)

if ($jobs.Count -eq 0) {
    throw "The input JSON must contain a non-empty jobs array."
}

$reportTitle = Format-Value $data.report_title
$createdAt = Format-Value $data.created_at
$targetProfile = Format-Value $data.target_profile
$searchScope = Format-Value $data.search_scope
$methodology = Format-Value $data.methodology
$assumptionsHtml = if ($data.PSObject.Properties.Name -contains "assumptions") { ConvertTo-HtmlList $data.assumptions } else { "" }
$takeawaysHtml = if ($data.PSObject.Properties.Name -contains "key_takeaways") { ConvertTo-HtmlList $data.key_takeaways } else { "" }

$remoteCount = @($jobs | Where-Object { $_.work_mode -match "Remote" }).Count
$visaYesCount = @($jobs | Where-Object { $_.visa_support -match "^(Yes|yes)" }).Count
$salaryCount = @($jobs | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.salary) -and [string]$_.salary -ne "Unknown" }).Count

$tableRows = foreach ($job in $jobs) {
    $title = Escape-Html (Format-Value $job.title)
    $company = Escape-Html (Format-Value $job.company)
    $location = Escape-Html (Format-Value $job.location)
    $workMode = Escape-Html (Format-Value $job.work_mode)
    $salary = Escape-Html (Format-Value $job.salary)
    $jp = Escape-Html (Format-Value $job.japanese_level)
    $visa = Escape-Html (Format-Value $job.visa_support)
    $firstPostedAt = Escape-Html (Format-Value $job.first_posted_at)
    $sourceDate = Escape-Html (Format-Value $job.source_date)
    @"
<tr>
  <td>$title</td>
  <td>$company</td>
  <td>$location</td>
  <td>$workMode</td>
  <td>$salary</td>
  <td>$jp</td>
  <td>$visa</td>
  <td>$firstPostedAt</td>
  <td>$sourceDate</td>
</tr>
"@
}

$detailSections = foreach ($job in $jobs) {
    $title = Escape-Html (Format-Value $job.title)
    $company = Escape-Html (Format-Value $job.company)
    $location = Escape-Html (Format-Value $job.location)
    $workMode = Escape-Html (Format-Value $job.work_mode)
    $employmentType = Escape-Html (Format-Value $job.employment_type)
    $salary = Escape-Html (Format-Value $job.salary)
    $jp = Escape-Html (Format-Value $job.japanese_level)
    $en = Escape-Html (Format-Value $job.english_level)
    $visa = Escape-Html (Format-Value $job.visa_support)
    $stack = Escape-Html (Format-Value $job.tech_stack)
    $companySize = Escape-Html (Format-Value $job.company_size)
    $benefits = Escape-Html (Format-ArrayValue $job.benefits)
    $educationRequirements = Escape-Html (Format-Value $job.education_requirements)
    $experienceRequirements = Escape-Html (Format-Value $job.experience_requirements)
    $otherRequirements = Escape-Html (Format-Value $job.other_requirements)
    $summary = Escape-Html (Format-Value $job.summary)
    $url = Escape-Html (Format-Value $job.url)
    $source = Escape-Html (Format-Value $job.source)
    $sourceUrl = Escape-Html (Format-Value $job.source_url)
    $firstPostedAt = Escape-Html (Format-Value $job.first_posted_at)
    $sourceDate = Escape-Html (Format-Value $job.source_date)
    $hiringStatus = Escape-Html (Format-Value $job.hiring_status)
    $statusReason = Escape-Html (Format-Value $job.status_reason)
    $score = Escape-Html ([string](Normalize-Score $job.match_score))
    $notes = Escape-Html (Format-Value $job.notes)
    @"
<div class="job-card">
  <h3>$title - $company</h3>
  <p><strong>&#22320;&#28857;&#65306;</strong>$location</p>
  <p><strong>&#24037;&#20316;&#26041;&#24335;&#65306;</strong>$workMode</p>
  <p><strong>&#38687;&#20323;&#31867;&#22411;&#65306;</strong>$employmentType</p>
  <p><strong>&#34218;&#36164;&#65306;</strong>$salary</p>
  <p><strong>&#20844;&#21496;&#35268;&#27169;&#65306;</strong>$companySize</p>
  <p><strong>&#26085;&#35821;&#35201;&#27714;&#65306;</strong>$jp | <strong>&#33521;&#35821;&#35201;&#27714;&#65306;</strong>$en</p>
  <p><strong>&#31614;&#35777;&#25903;&#25345;&#65306;</strong>$visa</p>
  <p><strong>&#25216;&#26415;&#26632;&#65306;</strong>$stack</p>
  <p><strong>&#39318;&#27425;&#25307;&#32856;&#26102;&#38388;&#65306;</strong>$firstPostedAt</p>
  <p><strong>&#25307;&#32856;&#29366;&#24577;&#65306;</strong>$hiringStatus</p>
  <p><strong>&#22833;&#25928;&#21407;&#22240;&#65306;</strong>$statusReason</p>
  <p><strong>&#31119;&#21033;&#65306;</strong>$benefits</p>
  <p><strong>&#23398;&#21382;&#35201;&#27714;&#65306;</strong>$educationRequirements</p>
  <p><strong>&#32463;&#39564;&#35201;&#27714;&#65306;</strong>$experienceRequirements</p>
  <p><strong>&#20854;&#20182;&#35201;&#27714;&#65306;</strong>$otherRequirements</p>
  <p><strong>&#23703;&#20301;&#25688;&#35201;&#65306;</strong>$summary</p>
  <p><strong>&#20449;&#24687;&#26469;&#28304;&#65306;</strong>$source&#65288;&#26680;&#39564;&#26085;&#26399;&#65306;$sourceDate&#65289;</p>
  <p><strong>&#26469;&#28304;&#39029;&#38754;&#65306;</strong><a href="$sourceUrl">$sourceUrl</a></p>
  <p><strong>&#21305;&#37197;&#20998;&#65306;</strong>$score</p>
  <p><strong>&#22791;&#27880;&#65306;</strong>$notes</p>
  <p><strong>&#30003;&#35831;&#38142;&#25509;&#65306;</strong><a href="$url">$url</a></p>
</div>
"@
}

$topRecommendations = $jobs |
    Sort-Object { Normalize-Score $_.match_score } -Descending |
    Select-Object -First 3

$recommendationItems = foreach ($job in $topRecommendations) {
    $title = Escape-Html (Format-Value $job.title)
    $company = Escape-Html (Format-Value $job.company)
    $reason = Escape-Html (Get-RecommendationReason $job)
    @"
<li><strong>$title - $company</strong>&#65306;$reason</li>
"@
}

$html = @"
<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-16">
  <meta name="ProgId" content="Word.Document">
  <meta name="Generator" content="Microsoft Word 15">
  <meta name="Originator" content="Microsoft Word 15">
  <title>$([System.Net.WebUtility]::HtmlEncode($reportTitle))</title>
  <style>
    body {
      font-family: "Microsoft YaHei", "SimSun", "Segoe UI", Arial, sans-serif;
      color: #1f2937;
      margin: 28px;
      line-height: 1.45;
    }
    h1, h2, h3 {
      color: #0f172a;
      margin-bottom: 8px;
    }
    h1 {
      border-bottom: 2px solid #d4dbe5;
      padding-bottom: 10px;
    }
    .meta, .summary-box, .job-card {
      border: 1px solid #dbe2ea;
      border-radius: 8px;
      padding: 14px 16px;
      margin: 14px 0;
      background: #fbfdff;
    }
    .summary-grid {
      width: 100%;
      border-collapse: collapse;
      margin-top: 8px;
    }
    .summary-grid td {
      border: 1px solid #dbe2ea;
      padding: 8px 10px;
    }
    table.jobs {
      width: 100%;
      border-collapse: collapse;
      margin-top: 12px;
      font-size: 10.5pt;
    }
    table.jobs th, table.jobs td {
      border: 1px solid #cfd8e3;
      padding: 8px;
      vertical-align: top;
    }
    table.jobs th {
      background: #eef4fa;
      text-align: left;
    }
    ul {
      margin-top: 8px;
    }
    a {
      color: #0b57d0;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <h1>$([System.Net.WebUtility]::HtmlEncode($reportTitle))</h1>

  <div class="meta">
    <p><strong>&#29983;&#25104;&#26085;&#26399;&#65306;</strong>$([System.Net.WebUtility]::HtmlEncode($createdAt))</p>
    <p><strong>&#30446;&#26631;&#30011;&#20687;&#65306;</strong>$([System.Net.WebUtility]::HtmlEncode($targetProfile))</p>
    <p><strong>&#25628;&#32034;&#33539;&#22260;&#65306;</strong>$([System.Net.WebUtility]::HtmlEncode($searchScope))</p>
    <p><strong>&#25972;&#29702;&#26041;&#27861;&#65306;</strong>$([System.Net.WebUtility]::HtmlEncode($methodology))</p>
  </div>

  <h2>&#25688;&#35201;</h2>
  <div class="summary-box">
    <table class="summary-grid">
      <tr><td><strong>&#20837;&#36873;&#23703;&#20301;&#24635;&#25968;</strong></td><td>$($jobs.Count)</td></tr>
      <tr><td><strong>&#36828;&#31243;&#21451;&#22909;&#23703;&#20301;&#25968;</strong></td><td>$remoteCount</td></tr>
      <tr><td><strong>&#26377;&#34218;&#36164;&#20449;&#24687;&#30340;&#23703;&#20301;&#25968;</strong></td><td>$salaryCount</td></tr>
      <tr><td><strong>&#26126;&#30830;&#25552;&#21040;&#31614;&#35777;&#25903;&#25345;&#30340;&#23703;&#20301;&#25968;</strong></td><td>$visaYesCount</td></tr>
    </table>
  </div>

  $(if ($assumptionsHtml) { "<h2>&#20551;&#35774;&#19982;&#36793;&#30028;</h2><div class=""summary-box"">$assumptionsHtml</div>" } else { "" })

  $(if ($takeawaysHtml) { "<h2>&#20851;&#38190;&#32467;&#35770;</h2><div class=""summary-box"">$takeawaysHtml</div>" } else { "" })

  <h2>&#20248;&#20808;&#25512;&#33616;</h2>
  <div class="summary-box">
    <ul>
      $($recommendationItems -join "`n")
    </ul>
  </div>

  <h2>&#23703;&#20301;&#23545;&#27604;&#34920;</h2>
  <table class="jobs">
    <thead>
      <tr>
        <th>&#23703;&#20301;</th>
        <th>&#20844;&#21496;</th>
        <th>&#22320;&#28857;</th>
        <th>&#24037;&#20316;&#26041;&#24335;</th>
        <th>&#34218;&#36164;</th>
        <th>&#26085;&#35821;&#35201;&#27714;</th>
        <th>&#31614;&#35777;&#25903;&#25345;</th>
        <th>&#39318;&#27425;&#25307;&#32856;&#26102;&#38388;</th>
        <th>&#26680;&#39564;&#26085;&#26399;</th>
      </tr>
    </thead>
    <tbody>
      $($tableRows -join "`n")
    </tbody>
  </table>

  <h2>&#23703;&#20301;&#35814;&#24773;</h2>
  $($detailSections -join "`n")
</body>
</html>
"@

[System.IO.File]::WriteAllText($OutputDoc, $html, [System.Text.Encoding]::Unicode)
Write-Output "Report written to $OutputDoc"
