﻿B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=9.5
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: True
#End Region
#IgnoreWarnings: 10, 11, 12 , 20
#Extends: android.support.v7.app.AppCompatActivity

Sub Process_Globals
	Private clsJson As classGetConfig
	Private ftp As SFtp
	Private clsFunc As classFunc
	Dim clsPutJson As classSetConfig
	Dim lstActiveBords As List
End Sub

Sub Globals
	Private tsConfig As TabStrip
	Private toolbar As ACToolBarDark
	Private svSettings As ScrollView
	Private lbl_bord_naam As Label
	Private lbl_ip_nummer As Label
	Private edt_timeout As EditText
	Private lbl_digital As Label
	Private lbl_spel_duur As Label
	Private lbl_sponsor As Label
	Private lbl_timeout As Label
	Private lbl_timeout_min As Label
	Private lbl_timeout_plus As Label
	Private lbl_to_minutes As Label
	Private lbl_yellow As Label
	Private sw_digital_numbers As B4XSwitch
	Private sw_game_time As B4XSwitch
	Private sw_timeout As B4XSwitch
	Private sw_toon_sponsor As B4XSwitch
	Private sw_use_yellow_number As B4XSwitch
	Private edt_regel_1 As EditText
	Private edt_regel_2 As EditText
	Private edt_regel_3 As EditText
	Private edt_regel_4 As EditText
	Private edt_regel_5 As EditText
	Private btn_save As Label
	Private chk_alle_borden As CheckBox
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.LoadLayout("tsBordConfig")
	chk_alle_borden.Initialize("")
	
	clsJson.Initialize
	clsFunc.Initialize
	clsPutJson.Initialize
	svSettings.Initialize(1500)
	chk_alle_borden.Enabled = True
	tsConfig.LoadLayout("configMain", "Instellingen")
	tsConfig.LoadLayout("confScreenSaver", "ScreenSaver")
	svSettings.Panel.LoadLayout("conf_switch")
	lbl_bord_naam.Text = Starter.selectedBordName
	lbl_ip_nummer.Text = Starter.selectedBordIp
	
	retrieveConfig(Starter.selectedBordIp)
	
	
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub




Sub getConfig
	'clsJson.parseConfig(chk_timeout_active, edt_timeout, chk_use_digital)
	clsJson.parseConfig(sw_timeout, edt_timeout, sw_digital_numbers, sw_use_yellow_number, sw_toon_sponsor, sw_game_time)
	'edtFnext
End Sub


Sub retrieveConfig(ipNumber As String)
'	#if debug
'	btn_save.Enabled = True
'	enableView(True)
'	getConfig
'	Return
'	#End If
	Dim msg, unit As String
	unit = Starter.selectedBordName
	
	'ProgressBar.Visible = True
	'Sleep(300)
	
	wait For(clsFunc.pingBord(ipNumber)) Complete (result As Boolean)
	If result = False Then
		'ProgressBar.Visible = False
		clsFunc.createCustomToast($"${unit} niet bereikbaar"$, Colors.Red)
		Return
	End If
	'btn_save.Enabled = False
'	btn_save.Color = Colors.Gray
	ftp.Initialize("ftp", "pi", "0", ipNumber, 22)
	
	
	Try
		ftp.SetKnownHostsStore(Starter.hostPath, "hosts.txt")
	Catch
	'	ProgressBar.Visible = False
		msg =$"${unit} niet bereikbaar"$
		
		clsFunc.createCustomToast(msg, Colors.Red)
		Msgbox(msg, "Bord Config")
		
		ftp.Close
		Return
	End Try

	ftp.DownloadFile("/home/pi/44/cnf.44", Starter.hostPath, "cnf.44")
	ftp.DownloadFile("/home/pi/44/ver.pdg", Starter.hostPath, "ver.pdg")
	
	wait for ftp_DownloadCompleted (ServerPath As String, Success As Boolean)
	If Success = False Then
	'	ProgressBar.Visible = False
		msg =$"Config bestand van ${unit} niet gevonden"$
		clsFunc.createCustomToast(msg, Colors.Red)
	Else
	'	ProgressBar.Visible = False
	'	enableView(True)
		getConfig
		ftp.Close
		'btn_save.Enabled = True
		'btn_save.Color = Colors.Blue
		
		msg =$"Configuratie van ${unit} geladen"$
		'Msgbox(msg, "Bord Config")
		'	clsFunc.createCustomToast(msg, Colors.Blue)
	'	bordVersion
		'clsUpdate.retrieveVersion
	End If
	
End Sub

Sub setMeassage(msg As List)
	edt_regel_1.Text = msg.Get(0)
	edt_regel_2.Text = msg.Get(1)
	edt_regel_3.Text = msg.Get(2)
	edt_regel_4.Text = msg.Get(3)
	edt_regel_5.Text = msg.Get(4)
	
End Sub


Sub btn_save_Click
	'clsPutJson.parseConfig(chk_timeout_active, edt_timeout, chk_use_digital)
	Dim msgList, lstBord As List
	msgList.Initialize
	msgList.AddAll(Array As String(edt_regel_1.text, edt_regel_2.text, edt_regel_3.text, edt_regel_4.text, edt_regel_5.text))
	
	If chk_alle_borden.Checked = False Then
		clsPutJson.ipNumber = Starter.selectedBordIp
		clsPutJson.parseConfig(sw_timeout, edt_timeout, sw_digital_numbers, sw_use_yellow_number, msgList, sw_toon_sponsor, sw_game_time)
		userMessage
	Else
		Dim naam, ip, lstStr As String
		
		lstActiveBords.Initialize
		wait for (getAliveBorden) Complete (result As Boolean)
		lstBord.Initialize
		For i = 0 To lstActiveBords.Size - 1
			lstStr = lstActiveBords.Get(i)
			lstBord = Regex.Split("\|", lstStr)
			naam = lstBord.Get(0)
			ip = lstBord.Get(1)
			
			clsPutJson.bordNaam = naam
			clsPutJson.ipNumber = ip
			clsPutJson.parseConfig(sw_timeout, edt_timeout, sw_digital_numbers, sw_use_yellow_number, msgList, sw_toon_sponsor, sw_game_time)
'			Log(clsPutJson.ipNumber)
'			'Wait For (userMessage) Complete (result As Boolean)
		Next

	End If
End Sub


Sub getAliveBorden As ResumableSub
	Dim curs As Cursor = gnDb.RetieveBoards
	
	If curs.RowCount = 0 Then
		curs.Close
		Return False
	End If
	
	ProgressDialogShow("Borden valideren")
	
	Sleep(300)
	
	For i = 0 To curs.RowCount - 1
		curs.Position = i
		wait for (clsFunc.pingBord(curs.GetString("ip_number"))) Complete (result As Boolean)
		If result = True Then
			lstActiveBords.AddAll(Array As String(curs.GetString("description")&"|"&curs.GetString("ip_number")))
		End If
	Next
	ProgressDialogHide
	curs.Close
	Return False
End Sub



Sub userMessage As ResumableSub
	
	If clsPutJson.updateResult = 2 Then
		Msgbox2Async("Configuratie niet verzonden", clsPutJson.bordNaam, "Oke", "", "", Null, False)
		Wait For Msgbox_Result (oke As Int)
		If oke = DialogResponse.POSITIVE Then
			Return True
		End If
	Else if clsPutJson.updateResult = 1 Then
		Msgbox2Async("Configuratie verzonden", clsPutJson.bordNaam, "Oke", "", "", Null, False)
		Wait For Msgbox_Result (oke As Int)
		If oke = DialogResponse.POSITIVE Then
			Return True
		End If
	End If
	Return True
End Sub