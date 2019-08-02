param
(
  [int]$length=20
)

# Create a seed string containing mostly alphabetic, numeric, and a few special character that will be used to generate a random password for the new account.
$script:ascii=$NULL
For ($a=48;$a –le 122;$a++) {$ascii+=,[char][byte]$a }


For ($loop=1; $loop -le $length; $loop++) {
    $TempPassword+=($ascii | GET-RANDOM)
}

return $TempPassword
