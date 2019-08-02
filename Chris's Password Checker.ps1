<#
      .SYNOPSIS
      Test-PasswordComplexity is passed a unicode string value and tests to see if it passes a defined set of complexity requirements.

      .DESCRIPTION
      Test-PasswordComplexity is passed a unicode string value and tests to see if it passes a defined set of complexity requirements.
      When run in the default pipeline mode it will return a TRUE or FALSE value. When run in the optional console mode
      it will display a dialog message that provides information regarding which password requirements failed.

      Password complexity requirements tested are:
      * Has at least 12 characters
      * Has no more than 24 characters
      * Must contain at least one lowercase character
      * Must contain at least one uppercase character
      * Must contain at least one digit
      * Must contain at least one approved special character
      * Must NOT contain a character repeating more than twice in a row (e.g. "...aaa..." fails, but "...aa...a..." passes assuming all other conditions are met).

      .PARAMETER Passphrase
      A unicode text string that will be tested against the password complexity requirements

      .PARAMETER Output
      Optional parameter for selecting either pipeline, or interactive use.

      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcd2*ajsdl;A'
      True

      Tests the supplied passphrase and determines that it pass the password requirements.
      Returning $true

      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcd2*ajsdl;'
      False

      Tests the supplied passphrase and determines that it pass the password requirements.
      Returning $false

      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcdA2*Á' -Output console

      Tests the supplied passphrase and determines that it fails the password requirements.
      It displays the following status message.

      Password Complexity Validation
      The passphrase submitted does not pass the following validation requirements:
       * Must be at least 12 characters long
      [V] Validate New Password  [E] Exit  [?] Help (default is "E"):


      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcd2*' -Output console

      Tests the supplied passphrase and determines that it fails the password requirements.
      It displays the following status message.

      Password Complexity Validation
      The passphrase submitted does not pass the following validation requirements:
       * Must be at least 12 characters long
       * Must contain at least one uppercase letter
      [V] Validate New Password  [E] Exit  [?] Help (default is "E"):


      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcd2*ajsdl;fjaeops98ujlaalskdfj' -Output console

      Tests the supplied passphrase and determines that it fails the password requirements.
      It displays the following status message.

      Password Complexity Validation
      The passphrase submitted does not pass the following validation requirements:
       * Must be no longer than 24 characters long
       * Must contain at least one uppercase letter
      [V] Validate New Password  [E] Exit  [?] Help (default is "E"):

      .EXAMPLE
      Test-PasswordComplexity -Passphrase 'ébcd2*ajsdl;A' -Output console

      Tests the supplied passphrase and determines that it fails the password requirements.
      It displays the following status message.

      Password Complexity Validation
      The passphrase submitted passes all validation tests.
      [V] Validate New Password  [E] Exit  [?] Help (default is "E"):


      .NOTES
      We could use the regular expression of '\p{Ll}+' because it allows us to determine if the 
      character specified is categorized as a Unicode lowercase letter vs the standard ASCII a-z characters.
      However, depending which Unicode code point is used this could provide a false positive. 
        
      For example, in Unicode, à can be encoded as two code points: U+0061 (a) followed by U+0300 (grave accent),
      or as a single Unicode code point U+00E0 (a with grave accent).

      The simplest method to match a lowercase letter including any diacritics, we'd like to use:

      "\p{Ll}\p{M}*+"

      Unfortunately .NET languages does not currently support regex possessive qualifiers (e.g. *+).
      Attempting to do so would result in the following error:

      parsing "\p{Ll}\p{M}*+" - Nested quantifier +.

      So we use atomic group to end up with the following instead: 
        
      "(?>\p{Ll}\p{M}*)"

      Likewise, for testing the existence of Unicode uppercase letter the simplest
      method to match an uppercase letter including any diacritics, we'd like to use:
        
      "\p{Lu}\p{M}*+"

      So we use atomic group to end up with the following instead:
        
      "(?>\p{Lu}\p{M}*)"


      Version:       1.0
      Author:        Chris Axtell
      Creation Date: 20190605


      .INPUTS
      System.String. Test-PasswordComplexity accepts a string object passed from the pipeline

      .OUTPUTS
      System.Boolean. Test-PasswordComplexity returns a boolean value to the pipeline by default. It returns nothing when ran in console mode.
#>
param
(
  [parameter(position=0,ValueFromPipeline=$true)]
  [string]$Passphrase,
  [parameter(position=1)]
  [ValidateSet('console','pipeline')]
  [string]$Output='pipeline'
)

# ------------------------------------ Declarations  -------------------------------
#region Declarations

# Define passphrase requirements in an object to allow easy updates to requirements as needs change.
$passphraseRequirements = [PSCustomObject] @{
  minimumLength                       = 12     # Indicates the minimum number of characters that are required.
  maximumLength                       = 24     # Indicates the maximum number of characters that are allowed.
  oneLowerCaseCharacter               = $true  # Any valid unicode lowercase letter e.g. a, b, c, etc.
  oneUpperCaseCharacter               = $true  # Any valid unicode uppercase letter e.g. A, B, C, etc.
  oneDigit                            = $true  # Any valid unicode number in any language. e.g. Arabric: 0 - 9; Greek: ō α β
  specialCharacter                    = $true  # e.g. ~ ! @ # $ % ^ & * _ - + = ` | \ ( ) { } [ ] : ; " ' < > , . ? /
  allowCharacterToRepeatMoreThanTwice = $false # Indicates if a character can be repeated more than twice in a row.
}

# Define a list of special characters that are allowed/supported by Active Directory
# Character list retrieved from Microsoft - Password must meet complexity requirements documentation
# URL: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
$adAllowedSpecialCharacterList = @( '~', '!', '@', '#', '$', '%', '^', '&', '*', '_', '-', '+', '=', "``", '|', '\', '(', ')', '{', '}', '[', ']', ':', ';', '"', "'", '<', '>', ',', '.', '?', '/' )

# Declare variable used when running in console mode
$action = $null

#endregion
# ------------------------------------ End Declarations ----------------------------
  
# ------------------------------------ Functions     -------------------------------
#region Functions

function Get-Password
{
  <#
      .SYNOPSIS
      Get-Password presents a prompt requesting the entry of a password.

      .DESCRIPTION
      Get-Password presents a prompt requesting the entry of a password.

      .EXAMPLE
      Get-Password
      Describe what this call does

      .NOTES
      Place additional notes here.

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      System.String. Get-Password returns a string value.
  #>

  $value = Read-Host -Prompt 'Please enter a passphrase to validate' -AsSecureString
    
  # Convert the secure string to a plain (unsecure) string for validation purposes
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
  $Passphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
  return $Passphrase
} # End function Get-Password


function Show-DialogMessage
{
  <#
        .SYNOPSIS
        Show-DialogMessage displays a dialog window in order to display an interactive window with a message.

        .DESCRIPTION
        Show-DialogMessage displays a dialog window in order to display an interactive window with a message.
        This is usually used in cases where some information/explanation should be displayed, and there
        is a desire to have acknowledgement of the message.

        .PARAMETER Caption
        Provides a text string that will be used as the dialog window's header text.

        .PARAMETER Message
        Provides the text information to be displayed in the dialog window's main body.

        .PARAMETER ValidationFailure
        Object containing information regarding which specific validation errors were found

        .EXAMPLE
        Show-DialogMessage -Caption 'Password Complexity Validation' -Message 'The passphrase submitted does not pass the following validation requirements:' -ValidationResult $validationResult
        Will display a dialog similar to the following:

        ---------------------------------------------------------------------------------
        | Password Complexity Validation                                                |
        |-------------------------------------------------------------------------------|
        | The passphrase submitted does not pass the following validation requirements: |
        |   * Must be at least 12 characters long                                       |
        |   * Must contain at least one uppercase letter                                |
        |   * Must contain at least one special character                               |
        |                    _________________________  ________                        |
        |                    | Validate New Password |  | Exit |                        |
        |                    -------------------------  --------                        |
        ---------------------------------------------------------------------------------

        .INPUTS
        None. Does not accept values from the pipeline.

        .OUTPUTS
        System.String. Show-DialogMessage returns a string to the pipeline.
  #>
  # Defining parameters
  [CmdletBinding()]
  param(
    [Parameter(Position=0)]
    [String]$Caption,
    [Parameter(Position=1)]
    [String]$Message,
    [Parameter(Position=2)]
    [Object]$ValidationResult,
    [Parameter(Position=3)]
    [switch]$DefaultNo
  )
  
  # Define the choices
  $prompChoices = New-Object -TypeName Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
  $prompChoices.Add((New-Object -TypeName Management.Automation.Host.ChoiceDescription -ArgumentList '&Validate New Password'))
  $prompChoices.Add((New-Object -TypeName Management.Automation.Host.ChoiceDescription -ArgumentList '&Exit'))

  if ( ![string]::IsNullOrWhiteSpace( $ValidationResult ) )
  {
    ForEach ( $item in $ValidationResult )
    {
      If ( [string]::IsNullOrWhiteSpace( $Message ) )
      {
        $Message = $item
      }
      else
      {
        $Message = $Message+"`r`n`t* "+$Item
      }
    }
  }

  if ( $DefaultNo )
  {
    # Display the prompt and store the result as a boolean (True/False) value. Default is 'False'
    $decision = [bool]$Host.UI.PromptForChoice($Caption, $Message, $prompChoices, 0)
  }
  else
  {
    # Display the prompt and store the result as a boolean (True/False) value. Default is 'True'
    $decision = [bool]$Host.UI.PromptForChoice($Caption, $Message, $prompChoices, 1)
  }

  # Return the decision
  If ( $decision -eq $true )
  {
    return 'close'
  }
  else
  {
    return 'continue'
  }
} # End function Show-DialogMessage

#endregion
# ------------------------------------ End Functions -------------------------------

# ------------------------------------ Main Body     -------------------------------
#region MainBody

While ( $action -ne 'close' )
{
  if ( [string]::IsNullOrWhiteSpace( $Passphrase ) )
  {
    $Passphrase = Get-Password
  }
  
  # Parse the supplied passphrase to examine the individual component elements
  $passphraseResult = [PSCustomObject] @{
      # Store the total length of the supplied password
      length                             = $Passphrase.Length
      meetsLengthRequirement             = $null
      # Test for valid unicode lowercase character, with or without an accent mark, anywhere in the string.
      hasLowerCaseCharacter              = $($Passphrase -cmatch '(?>\p{Ll}\p{M}*)')
      meetsLowerCaseRequirement          = $null
      # Test for valid unicode uppercase character, with or without an accent mark, anywhere in the string.
      hasUpperCaseCharacter              = $($Passphrase -cmatch '(?>\p{Lu}\p{M}*)')
      meetsUpperCaseRequirement          = $null
      # Test for valid unicode number in any language, not just the Arabic numerals 0-9, anywhere in the string.
      hasDigit                           = $($Passphrase -match '\p{N}')
      meetsDigitRequirement              = $null
      # Test to see if there is at least 1 allowed special character
      hasSpecialCharacter                = $( [bool]( $Passphrase.IndexOfAny($adAllowedSpecialCharacterList) -ne -1 ) )
      meetsSpecialCharacterRequirement   = $null
      # Test to see if any unicode character is repeated more than twice consecutively anywhere in the string.
      # Because we support unicode characters, a letter with an accent repeated twice, followed by the letter without
      # an accent will return false (i.e. 'é' does not equal 'e')
      # Example:
      # 'ééé' returns TRUE
      # 'éée' returns FALSE
      hasConsecutiveRepeatingCharacter   = $($Passphrase -match '([(?>\p{L}\p{M}*)\p{N}])\1\1' )
      meetsRepeatingCharacterRequirement = $null
  }

  # Now that we've defined an object with the results of the test we evaluate each result
  # in order to see if the results pass the requirements. For those requirements that fail
  # we provide a human readable explanation of why the passphrase failed the test.
  # The explanations are only displayed in when ran in console mode.
  $validationResult = @()
  if ( $passphraseResult.length -ge $passphraseRequirements.minimumLength -and $passphraseResult.length -le $passphraseRequirements.maximumLength )
  {
    $passphraseResult.meetsLengthRequirement = $true
  }
  else
  {
    $passphraseResult.meetsLengthRequirement = $false
    if ( $passphraseResult.length -lt $passphraseRequirements.minimumLength )
    {
      $validationResult += ('Must be at least {0} characters long' -f $passphraseRequirements.minimumLength)
    }
    elseif ( $passphraseResult.length -gt $passphraseRequirements.maximumLength )
    {
      $validationResult += ('Must be no longer than {0} characters long' -f $passphraseRequirements.maximumLength)
    }
    else
    {
      $validationResult += 'Passphrase length should be examined'
    }
  }

  if ( ($passphraseResult.hasLowerCaseCharacter -eq $true -and $passphraseRequirements.oneLowerCaseCharacter -eq $true ) -or
     ($passphraseResult.hasLowerCaseCharacter -eq $true -and $passphraseRequirements.oneLowerCaseCharacter -eq $false ) -or
     ($passphraseResult.hasLowerCaseCharacter -eq $false -and $passphraseRequirements.oneLowerCaseCharacter -eq $false )
  )
  {
    $passphraseResult.meetsLowerCaseRequirement = $true
  }
  else
  {
    $passphraseResult.meetsLowerCaseRequirement = $false
    $validationResult += 'Must contain at least one lowercase letter'
  }

  if ( ( $passphraseResult.hasUpperCaseCharacter -eq $true -and $passphraseRequirements.oneUpperCaseCharacter -eq $true ) -or
       ( $passphraseResult.hasUpperCaseCharacter -eq $true -and $passphraseRequirements.oneUpperCaseCharacter -eq $false ) -or
       ( $passphraseResult.hasUpperCaseCharacter -eq $false -and $passphraseRequirements.oneUpperCaseCharacter -eq $false )
  )
  {
    $passphraseResult.meetsUpperCaseRequirement = $true
  }
  else
  {
    $passphraseResult.meetsUpperCaseRequirement = $false
    $validationResult += 'Must contain at least one uppercase letter'
  }

  if ( ( $passphraseResult.hasDigit -eq $true -and $passphraseRequirements.oneDigit -eq $true ) -or
       ( $passphraseResult.hasDigit -eq $true -and $passphraseRequirements.oneDigit -eq $false ) -or
       ( $passphraseResult.hasDigit -eq $false -and $passphraseRequirements.oneDigit -eq $false )
  )
  {
    $passphraseResult.meetsDigitRequirement = $true
  }
  else
  {
    $passphraseResult.meetsDigitRequirement = $false
    $validationResult += 'Must contain at least one number'
  }

  if ( ( $passphraseResult.hasSpecialCharacter -eq $true -and $passphraseRequirements.specialCharacter -eq $true ) -or
       ( $passphraseResult.hasSpecialCharacter -eq $true -and $passphraseRequirements.specialCharacter -eq $false ) -or
       ( $passphraseResult.hasSpecialCharacter -eq $false -and $passphraseRequirements.specialCharacter -eq $false )
  )
  {
    $passphraseResult.meetsSpecialCharacterRequirement = $true
  }
  else
  {
    $passphraseResult.meetsSpecialCharacterRequirement = $false
    $validationResult += 'Must contain at least one special character'
  }
        
  if ( ($passphraseResult.hasConsecutiveRepeatingCharacter -eq $true -and $passphraseRequirements.allowCharacterToRepeatMoreThanTwice -eq $true ) -or
       ($passphraseResult.hasConsecutiveRepeatingCharacter -eq $false -and $passphraseRequirements.allowCharacterToRepeatMoreThanTwice -eq $true ) -or 
       ($passphraseResult.hasConsecutiveRepeatingCharacter -eq $false -and $passphraseRequirements.allowCharacterToRepeatMoreThanTwice -eq $false ) )
  {
    $passphraseResult.meetsRepeatingCharacterRequirement = $true
  }
  else
  {
    $passphraseResult.meetsRepeatingCharacterRequirement = $false
    $validationResult += 'The same character cannot consecutively repeat more than twice'
  }
  
  if ( $passphraseResult.meetsLengthRequirement -and $passphraseResult.meetsLowerCaseRequirement -and $passphraseResult.meetsUpperCaseRequirement -and
       $passphraseResult.meetsDigitRequirement -and $passphraseResult.meetsSpecialCharacterRequirement -and $passphraseResult.meetsRepeatingCharacterRequirement )
  {
    if ( $Output -eq 'pipeline' )
    {
      return $true
    }
    else
    {
      $action = Show-DialogMessage -Caption 'Password Complexity Validation' -Message 'The passphrase submitted passes all validation tests.'
    }
  }
  else
  {
    if ( $Output -eq 'pipeline' )
    {
      return $false
    }
    else
    {
      $action = Show-DialogMessage -Caption 'Password Complexity Validation' -Message 'The passphrase submitted does not pass the following validation requirements:' -ValidationResult $validationResult
    }
  }

  if ( $action -eq 'continue' )
  { # clear the existing passphrase in preparation for next pass.
    $Passphrase = $null
  }
} # End While loop

#endregion