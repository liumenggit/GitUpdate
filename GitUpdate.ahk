#Persistent
#SingleInstance force
;作者：请勿打扰
;功能：适用GItHub项目更新，加入脚本中即可使用自己的GitHub项目地址
;介绍：根据GitHub中Commitkey获取是否更新
;注意：能够使用GitHub的朋友应该对代码都非常熟悉那么有其他需要请自行修改
Git_Update("https://github.com/liumenggit/GitUpdate","Show")
Return

Git_Update(GitUrl,GressSet:="Hide"){
	if not W_InternetCheckConnection(GitUrl)
		Return
	SplitPath,GitUrl,Project_Name
	RegRead,Reg_Commitkey,HKEY_CURRENT_USER,%Project_Name%,Commitkey
	;MsgBox % "reg" Reg_Commitkey "`nProject_Name" Project_Name
	if GressSet=Show
		Progress,100,% Reg_Commitkey " >>> " Git_CcommitKey.Edition,检查更新请稍等...,% Project_Name
	Git_CcommitKey:=Git_CcommitKey(GitUrl)
	;MsgBox % Git_CcommitKey.Down
	if not Git_CcommitKey.Down{	;获取更新失败返回
		Progress,100,% Reg_Commitkey " >>> " Git_CcommitKey.Key,检查更新失败,% Project_Name
		Sleep 500
		Progress,Off
		return
	}
	if not Reg_Commitkey or (Reg_Commitkey<>Git_CcommitKey.Key){	;存在更新开始更新
		Progress,1 T Cx0 FM10,初始化下载,% Reg_Commitkey " >>> " Git_CcommitKey.Key " 简介：" Git_CcommitKey.Edition,% Project_Name
		Git_Downloand(Git_CcommitKey,Project_Name)
	}else{
		Sleep 500
		Progress,,,暂无更新,% Project_Name
	}
	Progress,Off
	return
}

Git_Downloand(DownloandInfo,Project_Name){
	DownUrl:="https://codeload.github.com" DownloandInfo.Down
	;MsgBox % DownUrl
	SplitPath,A_ScriptName,,,,A_name
	SplitPath,DownUrl,DownName,,,OutNameNoExt
	DownName:=DownName ".zip"
	if ((E:=InternetFileRead( binData, DownUrl, False, 1024)) > 0 && !ErrorLevel){
		UncoilUrl:=A_Temp "\" A_NowUTC
		InternetFileRead_VarZ_Save(binData,A_Temp "\" DownName) ;保存文件
		SmartZip(A_Temp "\" DownName,UncoilUrl)	;解压文件
		FileDelete,% A_Temp "\" DownName
		Git_Bat(UncoilUrl "\" Project_Name "-" OutNameNoExt,Project_Name,DownloandInfo.Key)
		ExitApp
	}else{
		Progress,Off
		MsgBox, 4,更新失败,是否执行手动更新
		IfMsgBox Yes
    		Run %DownUrl%
		return
	}
}

Git_Bat(File,RegAdd_name,Add_Key){
bat=
		(LTrim
:start
	ping 127.0.0.1 -n 2>nul
	del `%1
	if exist `%1 goto start
	xcopy %File% %A_ScriptDir% /s/e/y
	reg add HKEY_CURRENT_USER\%RegAdd_name% /v Commitkey /t REG_SZ /d %Add_Key% /f
	start %A_ScriptFullPath%
	del `%0
	)
	IfExist GitDelete.bat
		FileDelete GitDelete.bat
	FileAppend,%bat%,GitDelete.bat
	Run,GitDelete.bat,,Hide
	ExitApp
}

SmartZip(s, o, t = 16)	;内置解压函数
{
	IfNotExist, %s%
		return, -1
	oShell := ComObjCreate("Shell.Application")
	if InStr(FileExist(o), "D") or (!FileExist(o) and (SubStr(s, -3) = ".zip"))
	{
		if !o
			o := A_ScriptDir
		else ifNotExist, %o%
			FileCreateDir, %o%
		Loop, %o%, 1
			sObjectLongName := A_LoopFileLongPath
		oObject := oShell.NameSpace(sObjectLongName)
		Loop, %s%, 1
		{
			oSource := oShell.NameSpace(A_LoopFileLongPath)
			oObject.CopyHere(oSource.Items, t)
		}
	}
}

Git_CcommitKey(Project_Url){
	whr:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET",Project_Url "/commits/master",True)
	whr.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
	Try
	{
		whr.Send()
		whr.WaitForResponse()
		Clipboard:=whr.ResponseText
		; RegExMatch(whr.ResponseText,"`a)(?<=""sha btn btn-outline BtnGroup-item"">\n\s{6})\S{7}(?=\n)",NewEdition)
		;RegExMatch(whr.ResponseText,"`a)<.*aria-label=""(.*?(\n\r\n|.).*?)"".*data-pjax=""true"".*href=""(.*?)""",Downloand)
		RegExMatch(whr.ResponseText,"`a)<.*aria-label=""(.*?)(\n\n\S.*?|.*?)"".*data-pjax=""true"".*href=""(.*?)""",Downloand)
		RegExMatch(whr.ResponseText,"`a)relative-time.*datetime=""(.*?)""",Committitle)
		Downloand3 := StrReplace(Downloand3,"commit","zip")
		Key:=SubStr(Downloand3,-39)
		;MsgBox % Downloand1 "`n" Downloand3 "`n" Committitle1 "`n" Key "`n-------------------------"
		Return {Edition:Downloand1,Down:Downloand3,Commit:Committitle1,Key:Key}
	}catch e {
		Return
	}
}

W_InternetCheckConnection(lpszUrl){ ;检查FTP服务是否可连接
	FLAG_ICC_FORCE_CONNECTION := 0x1
	dwReserved := 0x0
	return, DllCall("Wininet.dll\InternetCheckConnection", "Ptr", &lpszUrl, "UInt", FLAG_ICC_FORCE_CONNECTION, "UInt", dwReserved, "Int")
}

InternetFileRead( ByRef V, URL="", RB=0, bSz=1024, DLP="InternetFileRead_DLP", F=0x84000000 ){
	SetBatchLines, -1
	Static LIB="WININET\", QRL=16, CL="00000000000000", N=""
	if ! DllCall( "GetModuleHandle", Str,"wininet.dll" )
		DllCall( "LoadLibrary", Str,"wininet.dll" )
	if ! hIO:=DllCall( LIB "InternetOpen", Str,N, UInt,4, Str,N, Str,N, UInt,0 )
		return -1
	if ! ( ( hIU:=DllCall( LIB "InternetOpenUrl", UInt,hIO, Str,URL, Str,N, Int,0, UInt,F , UInt,0 ) ) || ErrorLevel )
		return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 2
	if ! ( RB )
		if ( SubStr(URL,1,4) = "ftp:" )
			CL := DllCall( LIB "FtpGetFileSize", UInt,hIU, UIntP,0 )
		else if ! DllCall( LIB "HttpQueryInfo", UInt,hIU, Int,5, Str,CL, UIntP,QRL, UInt,0 )
			return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 4
	VarSetCapacity( V,64 ), VarSetCapacity( V,0 )
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN), CL:=(RB ? RB : CL), VarSetCapacity( V,CL,32 ), P:=&V,
	B:=(bSz>CL ? CL : bSz), TtlB:=0, LP := RB ? "Unknown" : CL, %DLP%( True,CL,FN )
	loop{
		if ( DllCall( LIB "InternetReadFile", UInt,hIU, UInt,P, UInt,B, UIntP,R ) && !R )
			break
		P:=(P+R), TtlB:=(TtlB+R), RemB:=(CL-TtlB), B:=(RemB<B ? RemB : B), %DLP%( TtlB,LP )
		Sleep -1
	}
	TtlB<>CL ? VarSetCapacity( T,TtlB ) DllCall( "RtlMoveMemory", Str,T, Str,V, UInt,TtlB ) . VarSetCapacity( V,0 ) . VarSetCapacity( V,TtlB,32 ) . DllCall( "RtlMoveMemory", Str,V , Str,T, UInt,TtlB ) . %DLP%( TtlB, TtlB ) : N
	if ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) + ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) )
		return -6
	return, VarSetCapacity(V)+((ErrorLevel:=(RB>0 && TtlB<RB)||(RB=0 && TtlB=CL) ? 0 : 1)<<64)
}

InternetFileRead_DLP( WP=0, LP=0, Msg="" ) {
	if ( WP=1 ) {
		SysGet, m, MonitorWorkArea, 1
		y:=(mBottom-46-2), x:=(mRight-370-2), VarSetCapacity( Size,16,0 )
		DllCall( "shlwapi.dll\StrFormatByteSize64A", Int64,LP, Str,Size, UInt,16 )
		Size := ( Size="0 bytes" ) ? N : "«" Size "»"
		;Progress, CWE6E3E4 CT000020 CBF73D00 x0 y0 w370 h46 B1 FS8 WM700 WS400 FM8 ZH8 ZY3,,%Msg%  %Size%, InternetFileRead(), Tahoma
		WinSet, Transparent, 210, InternetFileRead()
	}
	P:=Round(WP/LP*100)
	WP:= ((WP:= Round(WP/1024)) < 1024) ? WP . " KB" : Round(WP/1024, 2) . " MB"
	LP:= ((LP:= Round(LP/1024)) < 1024) ? LP . " KB" : Round(LP/1024, 2) . " MB"
	Progress,% p,% wp " / " lp " [ " P "`% ]"	
	IfEqual,wP,0, Progress, Off
}

InternetFileRead_VarZ_Save( byRef V, File="" ) { ;   www.autohotkey.net/~Skan/wrapper/FileIO16/FileIO16.ahk ;?Added Prefix
Return ( ( hFile := DllCall( "_lcreat", AStr,File, UInt,0 ) ) > 0 )
 ? DllCall( "_lwrite", UInt,hFile, Str,V, UInt,VarSetCapacity(V) )
 + ( DllCall( "_lclose", UInt,hFile ) << 64 ) : 0
}
