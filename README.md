# user_wrong_password

0. You need to add the linked server ADSI to the root of the forest 
1. Replace LDAP://controller-01.domain.corp and LDAP://controller-02.domain.corp to your FQDN name.
2. Add @user_id IN ('jirasupport') your exceptions to this list, separated by commas
3. Replace src="https://domain.com/logo.png" to your corporate logo URL
4. Replace @profile_name = 'user_not'; to your profile name in MSSQL
5. Replace security@domain.com to your admininstrator or security department email

The field badPwdCount is not replicated between domain controllers, so data must be taken from all controllers separately
