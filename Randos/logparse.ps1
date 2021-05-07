
$servers = @( 
"dcchq021",
"dcchq022",
"dcchq023",
"dcchq024",
"dcchq025",
"dcchq026",
"dcchq027",
"dcchq028",
"dcchq029",
"dcchq030",
"dcchq033",
"dcchq034",
"dcchq035",
"dcchq036",
"dcchq037",
"dcchq038",
"dcchq039",
"dcchq040",
"dcchq041",
"dcchq042",
"dcchq045",
"dcchq046",
"dcchq047",
"dcchq048",
"dcchq049",
"dcchq050",
"dcchq051",
"dcchq052",
"dcchq053",
"dcchq054"
)
$content = Get-Content .\SironaLog_Advisor.log -ReadCount 1000
foreach ($server in $servers) {
    $content  | foreach {$_ -match $server} | Out-File .\"$($server)".txt
}