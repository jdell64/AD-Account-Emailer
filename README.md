# AD Account Emailer

##Purpose

The purpose of this set of PowerShell scripts is to email end users when their passwords are about to expire.

##Why?

When a Windows user accesses an account on another domain they don't normally log into, they won't know when their password is about to expire. Admins of systems on other domains or users who access systems on another domain would need to know when to change their password.

##Desired Outcome

If this script is working properly:

- Admins will receive an email if an account is set to never expire.
- Admins will receive an email if an account has expired.
- Users will receive an email if their account is about to expire.
- Users should be able to follow the instructions to reset their password.

##Assumptions

For this script, I assume that the system in question has the ability to email to the user's email address through some sort of forwarder. I also assume that the users AD object has the email field populated with the email you want this to go to. I'll also assume that you configure the 'ad-account-emailer.ps1' script to run on a [scheduled task](http://stackoverflow.com/questions/23953926/how-to-execute-a-powershell-script-automatically-using-windows-task-scheduler). 

##Setup

1. Open the 'ad-account-emailer.ps1' script and check all the variables, specifically these:

        $sendermailaddress = "no-reply@ "            
        $adminmailaddress = "SET THIS"
        $domain_name = "SET THIS"
        $SMTPserver = "SET THIS"           
        $DN = "DC=yourdomain,DC=com"
        $mailSubject = "Your DOMAIN_NAME AD password is about to expire!"

2. Open 'support_scripts\exceptions.txt' and add any accounts that would be exempt from these emails (eg, service accounts):

        service_account1
	    service_account2 
	    super_special_account

    This list is loaded by this line in the script: 

        $exceptionList = Get-Content support_scripts\exceptions.txt

    and it is important to make sure it is accurate.

3. Edit the 'support_scripts\TEMPLATE_EMAIL.html' file to verify the message you want to send to your users.

    Pay close attention to these lines in particular:

        <p>The following applications use this account:
            <ul>
                <li>Application 1</li>
                <li>Application 2</li>
                <li>Application 3</li>
            </ul>
        </p>

    It would be a good idea to stress to the user which applications they will lose if they do not obey the admin.
