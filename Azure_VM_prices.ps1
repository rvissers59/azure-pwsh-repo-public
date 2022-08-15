#############################
# This script extracts 1 year and 3 year reserved instance prices
# for Azure VM SKU's available in WestEurope, from the public preview API (202202)
# https://docs.microsoft.com/nl-nl/rest/api/cost-management/retail-prices/azure-retail-prices
# The price info is added to a list of all available VM SKu's for westeurope.
# 
# Note: To run this script you must jhave a valid Azure account and be logged in via powershell.
# Usage: ./Azure_VM_prices.ps1 > AzureVMPrices.csv
#
#############################

# The output is a follows
$hdr = 'SKUName;CPU;Mem(MB);ResourceDisk(MB);€RI(1yr)/hr;€RI(3yr)/hr'
$hdr

# The Azure prices are returned in sets of 100
# This means we need to keep fetching until a row.count of less than 100 is returned
$rowCount = 100
$skipRows = 0

# The prices returned are put into hash tables
$one_yr = @{}     # 1 Year prices
$three_yr = @{}   # 3 Year prices

while ($rowCount -eq 100) {
    $inv_str = 'https://prices.azure.com/api/retail/prices?$filter=serviceName eq ''Virtual Machines'' and priceType eq ''Reservation''and armRegionName eq ''westeurope''&$skip='+$skipRows+'&currencyCode=''USD'''
    $ding = Invoke-RestMethod $inv_str -Method 'GET' | ConvertTo-Json | ConvertFrom-Json

    $rowCount = $ding.Count
    $items = $ding.Items

    foreach ($item in $items){
        
        if ($item.reservationTerm -eq '1 Year'){
            $one_yr[$item.armSkuName] = $item.retailPrice/8760   # convert prices to how much you would pay per hour
                }
        elseif ($item.reservationTerm = '3 Years') {
            $three_yr[$item.armSkuName] = $item.retailPrice/(8760*3)
            }
        else {}
    }
    
    $rowCount = $ding.Count
    $skipRows = $skipRows + 100
    
}

# Get the westeurope VM SKU list
$VMs = Get-AzVMSize -Location 'westeurope'

# Add the prices from the hashtables
# Convert the . to a , in the price for Europe notation and correct processing in Excel
foreach($vm in $VMs){
    $os = '{0};{1};{2};{3};{4};{5}' -f $vm.Name, $vm.NumberOfCores, $vm.MemoryInMB, $vm.ResourceDiskSizeInMB, ([math]::Round($one_yr[$vm.Name],4) -Replace '\.',','), ([math]::Round($three_yr[$vm.Name],4) -Replace '\.',',')
    $os
}
