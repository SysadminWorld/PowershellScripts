<#
      .SYNOPSIS
      Test-QADPassphraseComplexity (aka Test-QuickAndDirtyPassphraseComplexity) is passed a unicode 
      string value and tests to see if it passes a defined set of complexity requirements.

      .DESCRIPTION
      Test-QADPassphraseComplexity (aka Test-QuickAndDirtyPassphraseComplexity) is passed a unicode 
      string value and tests to see if it passes a defined set of complexity requirements.
      It returns true if valid, and false if not.

      Password complexity requirements tested are:
      * Has at least 12 characters
      * Has no more than 24 characters
      * Must contain at least one lowercase character
      * Must contain at least one uppercase character
      * Must contain at least one number
      * Must contain at least one approved special character
      * Must NOT contain a character repeating more than twice in a row anywhere in the string.
        Note because we support unicode characters, a letter with an accent repeated twice, 
        followed by the letter without an accent will return false (i.e. 'é' does not equal 'e')
        Example:
       '...ééé...' fails
       '...éée...' passes, assuming all other conditions are met
       '...aa...a...' passes, assuming all other conditions are met

      .PARAMETER Passphrase
      A unicode text string that will be tested against the password complexity requirements

      .EXAMPLE
      Test-QADPasswordComplexity -Passphrase 'ébcd2*ajsdl;A'
      True

      Tests the supplied passphrase and determines that it pass the password requirements.
      Returning $true

      .EXAMPLE
      Test-QADPasswordComplexity -Passphrase 'ébcd2*ajsdl;'
      False

      Tests the supplied passphrase and determines that it fails the password requirements.
      Returning $false

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
  [string]$Passphrase
)

# Define a list of special characters that are allowed/supported by Active Directory.
# Character list retrieved from Microsoft - Password must meet complexity requirements documentation
# URL: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
# Note: since AD supports any Unicode character as valid in the password we do not have a character exclusion list.
$adAllowedSpecialCharacterList = @( '~', '!', '@', '#', '$', '%', '^', '&', '*', '_', '-', '+', '=', "``", '|', '\', '(', ')', '{', '}', '[', ']', ':', ';', '"', "'", '<', '>', ',', '.', '?', '/' )

if ( ($Passphrase -cmatch '(?>\p{Ll}\p{M}*)') -and ($Passphrase -cmatch '(?>\p{Lu}\p{M}*)') -and 
     ($Passphrase -match '\p{N}') -and ($Passphrase -notmatch '([(?>\p{L}\p{M}*)\p{N}])\1\1' ) -and 
     ( [bool]( $Passphrase.IndexOfAny($adAllowedSpecialCharacterList) -ne -1 ) ) -and
     ($Passphrase.length -match '^([1][2-9]|[2][0-4])$')
)
{
  return $true
}
else
{
  return $false
}