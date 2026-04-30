@{
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingWriteHost',
        'PSMissingModuleManifestField',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCmdletCorrectly',
        'PSUseCompatibleCmdlets',
        'PSUseCompatibleSyntax',
        'PSUseCompatibleTypes',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseOutputTypeCorrectly',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseToExportFieldsInManifest',
        'PSUseUTF8EncodingForHelpFile',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSAlignAssignmentStatement'
    )
    Rules = @{
        PSUseConsistentIndentation  = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace   = @{
            Enable                                  = $true
            CheckInnerBrace                         = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $true
            CheckSeparator                          = $true
            CheckParameter                          = $false
            IgnoreAssignmentOperatorInsideHashTable = $true
        }
        PSPlaceOpenBrace            = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace           = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }
        PSAlignAssignmentStatement  = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSProvideCommentHelp        = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }
        PSUseCompatibleSyntax       = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0', '7.2')
        }
    }
}
