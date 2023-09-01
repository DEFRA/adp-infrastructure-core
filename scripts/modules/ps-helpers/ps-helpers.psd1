#
# Module manifest for module 'ps-helpers'

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'ps-helpers'
    
    # Version number of this module.
    ModuleVersion     = '0.0.1'
    
    # ID used to uniquely identify this module
    GUID              = '4274f633-ab46-401b-8dee-552e1e8b36ba'
    
    # Author of this module
    Author            = 'defra'
    
    # Company or vendor of this module
    CompanyName       = 'Defra'
    
    # Copyright statement for this module
    Copyright         = '(c) Defra. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'Provides PowerShell helper functions'
    
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Invoke-CommandLine'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
    
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
    
        PSData = @{
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
}
    
    