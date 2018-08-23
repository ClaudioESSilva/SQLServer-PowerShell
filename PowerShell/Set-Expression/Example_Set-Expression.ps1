$replacements = [ordered]@{
    #starting <value> = LIKE '<value>%'
    'starting([ ]{1,})(''\w{1,})'              = "LIKE`$1`$2%"
    #starting with '<value>' = LIKE '<value>%'
    'starting([ ]{1,})with([ ]{1,})(''\w{1,})' = "LIKE`$2`$3%"
}
Set-Expression -Pattern $replacements -Multiline -Overwrite -Encoding "UTF8" -FullName "View.sql"
