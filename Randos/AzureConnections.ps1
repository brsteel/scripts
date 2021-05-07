$accountInfo = @{
    Environment = "AzureCloud"
    AzureAdDomainName = "onmicrosoft.com"
    AzureAdDomainTenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    AzureSubscription = 'ACE-CXP-BRSTEEL'
    AzureSubscriptionId = "517285d8-de48-4bbc-9620-ec46d2a44cb7"
    UserAccount = "brsteel@microsoft.com"
}

$accountInfo = @{
    Environment = "AzureCloud"
    AzureAdDomainTenantId = "28c16aa6-7090-494b-806a-0cc17d949046"
    AzureSubscription = "Visual Studio Enterprise Subscription"
    AzureSubscriptionId = "c88aee3d-43a6-4819-9f44-c34dd164e5be"
    UserAccount = "brsteel@microsoft.com"
}

$accountInfo = @{
    Environment = "AzureUSGovernment"
    AzureAdDomainTenantId = "8a09f2d7-8415-4296-92b2-80bb4666c5fc"
    AzureSubscription = "CXP-BRSTEEL-Subscription-Gov"
    AzureSubscriptionId = "f0c9eff0-d898-4cdf-b30b-720a799a5cf1"
    UserAccount = "brsteel@mcsinternaltrials.onmicrosoft.com"
}

$accountInfo = @{
    Environment = "AzureUSGovernment"
    AzureAdDomainTenantId = "7f59db05-b34e-432e-a39f-7f2051cd8e48"
    AzureSubscription = "CXP ACE Gov Internal Subscription"
    AzureSubscriptionId = "9ea57abb-990d-4601-94b5-2a2a6d418274"
    UserAccount = "bsteele@cxpacegov.onmicrosoft.us"
}

$null = Connect-AzAccount -Environment $accountInfo.Environment -Subscription $accountInfo.AzureSubscription



