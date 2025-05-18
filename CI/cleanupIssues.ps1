# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Delete obsolete bot-created issues.
.DESCRIPTION
    Deletes obsolete issues created by a specified author or any bot.
.OUTPUTS
    A single result object with properties Issues, Errors, and RateLimit.
.NOTES
    An issue is considered obsolete and therefore deletable if:
    - The issue has been created by the specified author, or by any bot if no author is specified.
    - The issue has been closed as 'not planned', or -AnyClosed has been specified.
    - The issue doesn't have any comments and is not referenced anywhere.
#>

#Requires -Version 7.4

using namespace System
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Text

[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
param(

    # The name of the repository to process.
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Repo,

    # The owner of the repository to process (default: 'mawosoft').
    [ValidateNotNullOrEmpty()]
    [string]$Owner = 'mawosoft',

    # Pre-filter for issues created by the specified author (default: 'github-actions[bot]').
    # If set to null or empty, any issue created by a bot is a candidate (post-filter).
    [string]$Author = 'github-actions[bot]',

    # Any closed issue is a candidate, not just those closed as 'not planned'.
    [switch]$AnyClosed,

    # The GitHub token to use for authentication.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [securestring]$Token
)

$query = Get-Content -LiteralPath "$PSScriptRoot/cleanupIssues.graphql" -Raw
$requestBody = [PSCustomObject]@{
    operationName = $null
    query         = $query
    variables     = @{
        owner  = $Owner
        repo   = $Repo
        author = $Author ? $Author : $null
        first  = 100 # GitHub limit
        after  = $null
    }
}

$params = @{
    Uri            = 'https://api.github.com/graphql'
    Authentication = 'Bearer'
    Token          = $Token
    Method         = 'Post'
    Body           = $null
    ContentType    = 'application/json'
}

[HashSet[string]]$nonDeletableEvents = @(
    'ReferencedEvent'
    'CrossReferencedEvent'
    'IssueComment'
)

$resultObject = [PSCustomObject]@{
    Issues    = [ArrayList]::new()
    Errors    = [ArrayList]::new()
    RateLimit = [PSCustomObject]@{
        Remaining = $null
        Reset     = $null
    }
}

function InvokeWebRequest {
    param([hashtable]$params)
    $response = $null
    $result = $null
    try {
        if ($resultObject.RateLimit.Remaining -eq 0) {
            throw 'Rate limit reached.'
        }
        $response = Invoke-WebRequest @params -SkipHttpErrorCheck -ProgressAction SilentlyContinue
        try {
            $remaining = $response.Headers['X-RateLimit-Remaining']?[0]
            if ($null -ne $remaining) {
                $resultObject.RateLimit.Remaining = [int]$remaining
            }
            $reset = $response.Headers['X-RateLimit-Reset']?[0]
            if ($null -ne $reset) {
                $resultObject.RateLimit.Reset = [datetime]::new(
                    [long]$reset * [timespan]::TicksPerSecond + [datetime]::UnixEpoch.Ticks,
                    [DateTimeKind]::Utc).ToLocalTime()
            }
        }
        catch {}
        $result = $response.Content | ConvertFrom-Json -Depth 64 -AsHashtable -NoEnumerate
    }
    catch {
        $result = @{
            errors = @(@{
                    message            = "$_"
                    ResponseRawContent = ${response}?.RawContent
                })
        }
    }
    return $result
}

try {
    $pageInfo = @{
        hasNextPage = $true
        endCursor   = $null
    }

    while ($pageInfo.hasNextPage) {
        $requestBody.variables.after = $pageInfo.endCursor
        $params.Body = $requestBody | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
        $result = InvokeWebRequest $params
        if (${result}?['errors']) {
            $resultObject.Errors.AddRange($result['errors'])
        }
        if (-not ${result}?['data']) {
            break
        }
        $issues = $result['data']?['repository']?['issues']
        $pageInfo = $issues['pageInfo']
        foreach ($node in $issues['edges']) {
            $issue = $node['node']
            [bool]$canDelete = $true
            if (-not $Author -and $issue['author']['__typename'] -cne 'Bot') {
                $canDelete = $false
            }
            elseif (-not $AnyClosed -and $issue['stateReason'] -cne 'NOT_PLANNED') {
                $canDelete = $false
            }
            elseif ($issue['timelineItems']['totalCount'] -gt $issue['timelineItems']['edges'].Length) {
                $canDelete = $false
            }
            else {
                foreach ($item in $issue['timelineItems']['edges']) {
                    $typeName = $item['node']['__typename']
                    if ($typeName -ceq 'ClosedEvent') {
                        if ($null -ne $item['node']['closer']) {
                            # Closed by a commit or PR.
                            $canDelete = $false
                            break
                        }
                    }
                    elseif ($nonDeletableEvents.Contains($typeName)) {
                        $canDelete = $false
                        break
                    }
                }
            }
            if ($canDelete) {
                $null = $resultObject.Issues.Add([PSCustomObject]@{
                        Id           = $issue['id']
                        Number       = $issue['number']
                        Title        = $issue['title']
                        State        = $issue['state'] + ':' + $issue['stateReason']
                        Author       = $issue['author']['login']
                        Timeline     = $issue['timelineItems']['edges'].ForEach({ $_['node']['__typename'] }) -join ','
                        DeleteStatus = 'pending'
                    })
            }
        }
    }

    if ($resultObject.Errors.Count -eq 0 -and $resultObject.Issues.Count -ne 0 -and
        $PSCmdlet.ShouldProcess("$Owner/$Repo", "Delete $($resultObject.Issues.Count) issues")) {
        # deleteIssue mutation may time out if there are too many in a single request.
        [int]$chunkSize = 10
        $sb = [StringBuilder]::new()
        $nodeVariables = [ArrayList]::new($chunkSize)
        for ([int]$issueIndex = 0; $issueIndex -lt $resultObject.Issues.Count; $issueIndex += $chunkSize) {
            [int]$chunkEnd = $resultObject.Issues.Count
            if (($chunkEnd - $issueIndex) -gt $chunkSize) { $chunkEnd = $issueIndex + $chunkSize }
            $nodeVariables.Clear()
            $null = $sb.Clear().AppendLine('mutation {')
            for ([int]$i = $issueIndex; $i -lt $chunkEnd; $i++) {
                $issue = $resultObject.Issues[$i]
                $issue.DeleteStatus = 'sent'
                $null = $sb.Append('  d').Append($i).Append(': deleteIssue(input: {issueId: "')
                $null = $sb.Append($issue.Id).AppendLine('"}) { clientMutationId }')
                $null = $nodeVariables.Add($issue.Id)
            }
            $null = $sb.AppendLine('}')
            $requestBody.variables = $null
            $requestBody.query = $sb.ToString()
            $params.Body = $requestBody | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
            $result = InvokeWebRequest $params
            if (${result}?['errors']) {
                $resultObject.Errors.AddRange($result['errors'])
            }
            # GitHub may silently fail to delete issues (even via the Web interface).
            # Verify deletion by querying the issue nodes by id.
            $requestBody.variables = @{ ids = $nodeVariables }
            $requestBody.query = @'
query ($ids: [ID!]!) {
    nodes(ids: $ids) { id, __typename }
}
'@
            $params.Body = $requestBody | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
            $result = InvokeWebRequest $params
            $nodes = ${result}?['data']?['nodes']
            if (${nodes}?.Count -ne $nodeVariables.Count) {
                if (${result}?['errors']) {
                    $resultObject.Errors.AddRange($result['errors'])
                }
                $null = $resultObject.Errors.Add(@{
                        message      = 'Querying deleted nodes: ' + $nodeVariables -join ','
                        ResponseData = ${result}?['data']
                    })
            }
            for ([int]$i = 0; $i -lt $nodeVariables.Count; $i++) {
                if ($null -eq $nodes[$i]) {
                    $resultObject.Issues[$i + $issueIndex].DeleteStatus = 'deleted'
                }
            }
        }
    }
}
catch {
    $null = $resultObject.Errors.Add(@{message = "$_" })
}

$resultObject
