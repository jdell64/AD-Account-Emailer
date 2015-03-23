
##############Variables#################           
$verbose = $true           
$notificationstartday = 7         
$sendermailaddress = "no-reply@ "      
$adminmailaddress = "SET THIS" # Can be comma separated list
$domain_name = "SET THIS"
$SMTPserver = "SET THIS"           
$DN = "DC=yourdomain,DC=com"
$mailSubject = "Your $domain_name AD password is about to expire!"
$adminSubject = "AD Password expiration admin email"

$exceptionList = Get-Content .\support_scripts\exceptions.txt
$body_template = Get-Content .\support_scripts\TEMPLATE_EMAIL.html

$num_of_days_reg = '(INT_NUM_OF_DAYS)'
$first_name_reg = '(STRING_FIRST_NAME)'
$domain_reg = '(DOMAIN_NAME)'
########################################           
            
##############Function##################           
           
            
function SendMail ($SMTPserver,$sendermailaddress,$usermailaddress,$mailBody, $subject)           
{                      
    write-host "Sending message to $usermailaddress about $subject"
    send-MailMessage -SmtpServer $SMTPserver  -To $usermailaddress -From $sendermailaddress -Subject $subject -Body ($mailBody |Out-String )-BodyAsHtml -Priority high    
}           
########################################           
            
##############Main######################           
$domainPolicy = Get-ADDefaultDomainPasswordPolicy           
$passwordexpirydefaultdomainpolicy = $domainPolicy.MaxPasswordAge.Days -ne 0
$defaultdomainpolicyMaxPasswordAge = $domainPolicy.MaxPasswordAge.Days           
$adminEmailBody =""         
foreach ($user in (Get-ADUser -SearchBase $DN -Filter * -properties mail)){           
    $samaccountname = $user.samaccountname 
    if ($user.enabled){
        if ($exceptionList -notcontains $samaccountname ){             
            if($passwordexpirydefaultdomainpolicy){           
                $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)           
                $expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)     
                
                     
                $delta = ($expirydate - (Get-Date)).Days  
                if ($delta -ge 1) {
                    $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday)
                    if ($comparionresults){           
                        $mailBody = $body_template -replace $first_name_reg, $user.GivenName
                        $mailBody = $mailBody -replace $num_of_days_reg, $delta
                        $mailBody = $mailBody -replace $domain_reg, $domain_name
                       
                        $usermailaddress = $user.mail           
                        
                        if ($usermailaddress){
                            SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody $mailSubject 
                            
                        } else {
                            $adminEmailBody += $samaccountname
                            $adminEmailBody += "&nbsp;does not have an email address configured, and their $domain_name AD password is about to expire.<br><br>" 
                            
                        }
                    }           
                } else {
                    $usermailaddress = $user.mail           
                    if ( -not $usermailaddress){
                        $adminEmailBody += $samaccountname
                        $adminEmailBody += "&nbsp;does not have an email address configured.<br>" 
                    }
           
                    #password has already expired email.
                    $adminEmailBody += $samaccountname
                    $adminEmailBody += "&nbsp;password has already expired or is set to not expire.<br><br>"
           
                }      
                switch ($delta){
                    {$_ -lt 0} {write-host $samaccountname"'s password expired "$delta "days ago."     }
                    default { write-host $samaccountname"'s password will expire in "$delta "days."     }
                }
               
            }
        }
    }
}
 
if ($adminEmailBody){
    #write-host $adminEmailBody
    SendMail $SMTPserver $sendermailaddress $adminmailaddress $adminEmailBody $adminSubject
}
 