GO
	DECLARE @user_id nvarchar(255), @user_name nvarchar(255), @last_login_date smalldatetime,
		@email_address varchar(255), @bad_count nvarchar(10), @disabled int, @distinguishedName nvarchar(255);
	DECLARE @body nvarchar(MAX);
	DECLARE @no_mail int;
DECLARE users CURSOR LOCAL FAST_FORWARD FOR
select MAX(t.sAMAccountName) AS sAMAccountName, MAX(t.displayName) AS displayName, MAX(t.badPasswordTime) AS badPasswordTime, MAX(t.mail) AS mail, SUM(t.badPwdCount) AS badPwdCount, MAX(t.Disabled) AS Disabled, t.distinguishedName from (
SELECT sAMAccountName
, ISNULL(displayName,'') AS displayName
, DATEADD(minute, DATEDIFF(minute, GETUTCDATE(), GETDATE()), CASE WHEN CAST([badPasswordTime] AS bigint) > 0 THEN CAST([badPasswordTime] AS bigint) / (864000000000.0) ELSE 109207 END)
		 - 109207 AS badPasswordTime
, ISNULL(mail,'') AS mail
, badPwdCount
, userAccountControl & 2 AS Disabled 
, distinguishedName
FROM OpenQuery
(
ADSI, 
'SELECT badPasswordTime, badPwdCount, userAccountControl, displayName, sAMAccountName,
mail, distinguishedName
FROM  ''LDAP://controller-01.domain.corp''
WHERE objectClass =  ''User'' AND objectCategory = ''Person'' 
'
) AS tblADSI1 WHERE userAccountControl & 2 = 0 AND badPwdCount > 10 AND DATEADD(minute, DATEDIFF(minute, GETUTCDATE(), GETDATE()), CASE WHEN CAST([badPasswordTime] AS bigint) > 0 THEN CAST([badPasswordTime] AS bigint) / (864000000000.0) ELSE 109207 END)
		 - 109207 BETWEEN DATETIMEFROMPARTS (YEAR(GETDATE()), MONTH(GETDATE()), DAY(GETDATE()), CONVERT(varchar(2), GETDATE(), 108), 00, 00, 0) AND GETDATE()
UNION
SELECT sAMAccountName
, ISNULL(displayName,'') AS displayName
, DATEADD(minute, DATEDIFF(minute, GETUTCDATE(), GETDATE()), CASE WHEN CAST([badPasswordTime] AS bigint) > 0 THEN CAST([badPasswordTime] AS bigint) / (864000000000.0) ELSE 109207 END)
		 - 109207 AS badPasswordTime
, ISNULL(mail,'') AS mail
, badPwdCount
, userAccountControl & 2 AS Disabled 
, distinguishedName
FROM OpenQuery
(
ADSI, 
'SELECT badPasswordTime, badPwdCount, userAccountControl, displayName, sAMAccountName,
mail, distinguishedName
FROM  ''LDAP://controller-02.domain.corp''
WHERE objectClass =  ''User'' AND objectCategory = ''Person'' 
'
) AS tblADSI2 WHERE userAccountControl & 2 = 0 AND badPwdCount > 10 AND DATEADD(minute, DATEDIFF(minute, GETUTCDATE(), GETDATE()), CASE WHEN CAST([badPasswordTime] AS bigint) > 0 THEN CAST([badPasswordTime] AS bigint) / (864000000000.0) ELSE 109207 END)
		 - 109207 BETWEEN DATETIMEFROMPARTS (YEAR(GETDATE()), MONTH(GETDATE()), DAY(GETDATE()), CONVERT(varchar(2), GETDATE(), 108), 00, 00, 0) AND GETDATE()
)t
group by t.distinguishedName
ORDER BY BadPwdCount DESC


	OPEN users
	FETCH NEXT FROM users INTO @user_id, @user_name, @last_login_date, @email_address, @bad_count, @disabled, @distinguishedName
WHILE @@FETCH_STATUS = 0

BEGIN

		IF LEN(@email_address) = 0 OR @user_id IN ('jirasupport','Trainee')
			BEGIN
				SET @email_address = 'security@domain.com'
			END
		ELSE
			BEGIN
				SET @email_address = 'security@domain.com'
			END
		IF LEN(@user_name) = 0
			BEGIN
				SET @user_name = @user_id
			END
		PRINT N'Отправка письма для ' + @email_address + N' for ' + @user_name + ' ...'

		SET @body = N'
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<title>Зафиксирована попытка подбора пароля</title>
</head>
<body>
<p><img style="float:right;" src="https://domain.com/logo.png"/></p>
<p>Здравствуйте, ' + @user_name + N'!</p>
<p>Выявлена попытка подбора пароля для пользователя ' + @user_id + ',
количество попыток <b>' + @bad_count + '</b>. Последняя попытка ввода неправильного пароля <b>' + CONVERT(varchar,@last_login_date,120) + '</b></p>
<p>Обратитесь в отдел информационной безопасности</p>
</body>
</html>';

		EXEC msdb.dbo.sp_send_dbmail
			@recipients = @email_address,
			@subject = N'Зафиксирована попытка подбора пароля для пользователя',
			@body = @body,
			@body_format = 'HTML',
			@blind_copy_recipients ='security@domain.com',
			@profile_name = 'user_not';

		WAITFOR DELAY '00:00:03';
		FETCH NEXT FROM users INTO @user_id, @user_name, @last_login_date, @email_address, @bad_count, @disabled, @distinguishedName
END
CLOSE users
GO