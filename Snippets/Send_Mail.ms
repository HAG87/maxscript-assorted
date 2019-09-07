(
	-- WEBMAIL PROTOCOL
	struct _comSrv
	(
		public
		fn composeMail body sub FromAdress ToAdress AttachFile:undefined =
		(
			local MailMessage = dotNetObject "System.Net.Mail.MailMessage"
			local MailMessageFrom = dotNetObject "System.Net.Mail.MailAddress" FromAdress
			MailMessage.From = (dotNetObject "System.Net.Mail.MailAddress" MAIL_TO)
			local  MailAdressTo = (dotNet.ValueToDotNetObject ToAdress (dotNetClass "System.String"))
			MailMessage.To.Add MailAdressTo
			MailMessage.CC.Add FromAdress
			MailMessage.Subject = if sub != undefined then sub else "no subject"
			MailMessage.Body = if body != undefined then body else " "
			if AttachFile != undefined then (
				local MailAttachment = dotNetObject "System.Net.Mail.Attachment" AttachFile
				MailMessage.Attachments.Add(MailAttachment)
			)
			return MailMessage
		),
		fn MailSender MailMessage Username Password Host port ssl:true =
		(
			Client = dotNetObject "System.Net.Mail.SmtpClient" --Host Port
			NetworkCred = dotNetObject "System.Net.NetworkCredential"
			NetworkCred.UserName = Username
			NetworkCred.Password = Password
			Client.Credentials = NetworkCred
			Client.Host = Host
			Client.Port = port --25 --587;
			Client.EnableSsl = ssl
			Client.Send MailMessage
		)
	)
	-- EXAMPLE FORM
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	rollout roll_email "Send Email" width:450
	(
		fn fullWidth div:1 th:10 =
		(
			if div > 1 then (
				( (roll_email.width - th) / div ) - (th / div)
			) else (
				( (roll_email.width - th) / div )
			)
		)
		editText txt_dest "Adress" text:"" labelOnTop:true fieldWidth:(fullWidth()-15) align:#left
		editText txt_cpt "Caption" text:"Send Email" labelOnTop:true fieldWidth:(fullWidth()-15) align:#left
		editText txt_c1 "Email text" text:("Example email body.\n" + localTime) labelOnTop:true fieldWidth:(fullWidth()-15) height:150 align:#left
		imgTag sep1 width:(fullWidth()) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center
			label lbl_c1 "Email" align:#left across:2
			label lbl_c2 "Password" align:#left
			editText txt_c3 "" text:"mail@gmail.com" labelOnTop:true align:#left fieldWidth:200 height:20 across:2
			dotNetControl txt_c4 "TextBox" text:"PASSWORD" width:200
		imgTag sep2 width:(fullWidth()) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center
			editText txt_c5 "SMTP Server" labelOnTop:true align:#left fieldWidth:220 offset:[0,5] across:3
			editText txt_c6 "Port" text:"587" labelOnTop:true align:#left width:35 offset:[80,5]
			CheckBox chk_c1 "USE SSL CONECTION" checked:true offset:[-30,24] align:#right
		imgTag sep3 width:(fullWidth()) height:1 bitmap:(bitmap 1 2 color: (color 5 5 5)) align:#center
		dotNetControl txt_c7 "label" width:220 height:16 offset:[0,5] across:2
		button btn_c1 "SEND" width:120 height:30 align:#right offset:[10,0] enabled:false
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local SMTP = #("smtp.gmail", "smtp-mail.outlook", "smtp.live", "smtp.mail.yahoo", "smtp.btconnect", "mail.o2online", "outgoing.verizon", "smtp.zoho", "smtp.mail", "smtp.aol", "smtp.gmx")
		local fSMTP = for i in SMTP collect (filterString i ".")
		local SMTP = "smtp.gmail.com"
		local PORT = #("587","25")
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local compose = StringStream ""
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Automated HTML email template example.
		fn load_data var1 var2 var3 var5 var5 =
		(
				format "<div style=\" padding: 15px; margin:0 auto; width:600px; background-color:#EFEFEF; border:thin solid #C1C1C1;\">
						  <p>Hi;<br>EXAMPLE TEXT</b>!</p>
						  <hr/>
						  <p>MORE EXAMPLE TEXT</p>
						  <p style=\"background-color:rgb(255,255,0);font-weight:bold;\">VAR1: %</p>
						  <p>CONTENT TEXT:<span style=\" font-size:smaller;\"><br>
							VAR2: %<br>
							VAR3: %<br>
							VAR4: %<br>
							VAR5: %</span></p>
						  <br>
						  <hr/>
						  <p>Regards;</p>
						</div>" VAR1 VAR2 VAR3 VAR4 VAR5 to:compose
				txt_c1.text = compose as string
				btn_c1.enabled = true
		)
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		on roll_email open do (
			-- Password of the email account
			txt_c4.PasswordChar = "x"; txt_c4.MaxLength = 16
			txt_c5.TEXT = SMTP
		)
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SSL connection option
		on chk_c1 changed state do (if state then txt_c6.text = PORT[1] else txt_c6.text = PORT[2])

		-- email of the sender
		on txt_c3 changed args do (
			if (MatchPattern args pattern:"*@*") == true then (
				local members = filterString args "@"
				if members[2] != undefined then (
					local
					provider = filterString members[2] ".",
					lk = _cm.arFind fSMTP (if provider[1] == "hotmail" then "live" else provider[1]),
					serv = if lk !=undefined then SMTP[lk],
					dom = if serv != undefined then substituteString members[2] provider[1] serv
					txt_c5.text = if dom != undefined then dom else ""
				)
			)
		)
		-- compose and send the email
		on btn_c1 pressed do (
			try (
				local mailbody = _comSrv.composeMail txt_c1.text txt_cpt.text txt_c3.text txt_dest.text --AttachFile:file_attach --> you can attach a file....

				_comSrv.MailSender mailbody txt_c3.text txt_c4.text txt_c5.text (execute txt_c6.text) ssl:chk_c1.state

				txt_c7.text = "MAIL SENT"
				txt_c7.BackColor = ((dotNetClass "System.Drawing.Color").Lightgreen)

			) catch (
				txt_c7.text =  getCurrentException()
				txt_c7.BackColor = ((dotNetClass "System.Drawing.Color").IndianRed)
			)
		)
	) -- END ROLLOUT --

	-- load a bunch of values in the template
	roll_email.load_data "ONE" "TWO" "THREE" "FOUR" "FIVE"
	-- show the dialog
	CreateDialog roll_email
)