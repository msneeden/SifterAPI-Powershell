. .\Config.ps1
Add-Type -Assembly System.ServiceModel.Web,System.Runtime.Serialization

Function getProjects() {
    $xml = makeApiCall("$baseUrl/projects")
    $projectNodes = $xml.FirstChild.SelectNodes("//item")
    $projects = @()
    Foreach ($project in $projectNodes) {
        $projects += getProject($project.Item("api_url").InnerText)
    }
    
    return $projects
}

Function getProject([string]$url) {
    $xml = makeApiCall($url)
    
    $project = New-Object Object
    $project | Add-Member -type NoteProperty -name api_url -value $xml.FirstChild.FirstChild.Item("api_url").InnerText
    $project | Add-Member -type NoteProperty -name api_categories_url -value $xml.FirstChild.FirstChild.Item("api_categories_url").InnerText
    $project | Add-Member -type NoteProperty -name api_issues_url -value $xml.FirstChild.FirstChild.Item("api_issues_url").InnerText
    $project | Add-Member -type NoteProperty -name api_milestones_url -value $xml.FirstChild.FirstChild.Item("api_milestones_url").InnerText
    $project | Add-Member -type NoteProperty -name api_people_url -value $xml.FirstChild.FirstChild.Item("api_people_url").InnerText
    $project | Add-Member -type NoteProperty -name name -value $xml.FirstChild.FirstChild.Item("name").InnerText
    
    return $project
}

Function getProjectByName([string]$projectName) {
    $projects = getProjects
    foreach ($project in $projects) {
        if ($project.name -eq $projectName) {
            $targetProject = $project
            break
        }
    }
    
    if($targetProject -eq $null) {
        throw ("Project not found! Does your account have access to the requested project?")
    }
    
    return $targetProject
}

Function getIssues([string]$url) {
    $xml = makeApiCall($url)
    
    $totalPages = [int]$xml.SelectSingleNode("//total_pages").InnerText
    $perPage = [int]$xml.SelectSingleNode("//per_page").InnerText
    $issues = @()
    
    if ($totalPages -gt 1) {
        For ($i=1; $i -lt $totalPages + 1; $i++) {
            $xmlPage = makeApiCall("$url&page=$i")
            Foreach ($issue in $xmlPage.FirstChild.SelectNodes("//item")) {
                $issues += @{api_url=$issue.Item("api_url").InnerText; priority=$issue.Item("api_url").InnerText; created_at=$issue.Item("created_at").InnerText; status=$issue.Item("status").InnerText; subject=$issue.Item("subject").InnerText; url=$issue.Item("url").InnerText}
            }
        }
    }
    else {
        Foreach ($issue in $xml.FirstChild.SelectNodes("//item")) {
            $issues += @{api_url=$issue.Item("api_url").InnerText; priority=$issue.Item("api_url").InnerText; created_at=$issue.Item("created_at").InnerText; status=$issue.Item("status").InnerText; subject=$issue.Item("subject").InnerText; url=$issue.Item("url").InnerText}
        }
    }
    
    return $issues
}

Function getIssueBySubject($project, [string]$issueName) {
    $url = New-Object System.Uri("$($project.api_issues_url)?q=$issueName")
    $xml = makeApiCall($url.AbsoluteUri)
    
    $issueXml = $xml.FirstChild.SelectSingleNode("//item")
    $issue = @{api_url=$issueXml.Item("api_url").InnerText; priority=$issueXml.Item("api_url").InnerText; created_at=$issueXml.Item("created_at").InnerText; status=$issueXml.Item("status").InnerText; subject=$issueXml.Item("subject").InnerText; url=$issueXml.Item("url").InnerText}

    return $issue
}

Function getIssuesCount([string]$url) {
    $xml = makeApiCall($url)
    
    $totalPages = [int]$xml.SelectSingleNode("//total_pages").InnerText
    $perPage = [int]$xml.SelectSingleNode("//per_page").InnerText
    $issuesCount = 0
    
    if ($totalPages -gt 1) {
        $issuesCount += $perPage * ($totalPages - 1)
        $lastPageXml = makeApiCall("$url&page=$totalPages")
        
        $issuesCount += $lastPageXml.FirstChild.SelectNodes("//item").Count
    }
    else {
        $issuesCount = $xml.FirstChild.SelectNodes("//item").Count
    }
    
    return $issuesCount
}

Function getCategories([string]$url) {
    $xml = makeApiCall($url)
    $categoryNodes = $xml.FirstChild.SelectNodes("//item")
    $categories = @()
    Foreach ($category in $categoryNodes) {
        $categories += @{api_issues_url=$category.Item("api_issues_url").InnerText; issues_url=$category.Item("issues_url").InnerText; name=$category.Item("name").InnerText}
    }
    
    return $categories
}

Function getMilestones([string]$url) {
    $xml = makeApiCall($url)
    $milestoneNodes = $xml.FirstChild.SelectNodes("//item")
    $milestones = @()
    Foreach ($milestone in $milestoneNodes) {
        $milestones += @{api_issues_url=$milestone.Item("api_issues_url").InnerText; due_date=$milestone.Item("due_date").InnerText; issues_url=$milestone.Item("issues_url").InnerText; name=$milestone.Item("name").InnerText}
    }
    
    return $milestones
}

Function parseJsonResponseToXml([System.Net.HttpWebResponse] $response) {
    $reader = New-Object IO.StreamReader($response.GetResponseStream())
    $json = $reader.ReadToEnd()
    $response.Close()
        
    $bytes = [byte[]][char[]]$json
    $quotas = [System.Xml.XmlDictionaryReaderQuotas]::Max
    $jsonReader = [System.Runtime.Serialization.Json.JsonReaderWriterFactory]::CreateJsonReader($bytes, $quotas)

    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($jsonReader)
    
    return $xml
}

Function makeApiCall([string]$url) {
    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.Headers.Add("X-Sifter-Token", $token)
    $request.Accept = "application/json"
    $response = $request.GetResponse()
    
    return parseJsonResponseToXml($response)
}