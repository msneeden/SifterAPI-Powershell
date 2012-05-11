SifterAPI-Powershell
====================

Powershell wrapper for the Sifter API.

Provide your API key and Organization in the **Config.ps1** file.  Add a reference to **SifterAPI.ps1** to your Powershell script.

Use of this library is based heavily on the *project* element.
    # Get the target project by name
    $project = getProjectByName "Project Name"
    
    # Get an issue by subject
    $issue = getIssueBySubject $project "Issue Subject"