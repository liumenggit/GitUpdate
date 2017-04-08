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
	if GressSet=Show
		Progress,100,% Reg_Commitkey " >>> " Git_CcommitKey.Edition,检查更新请稍等...,% Project_Name
	Git_CcommitKey:=Git_CcommitKey(GitUrl)
	if not Git_CcommitKey.Edition{	;获取更新失败返回
		Progress,Off
		return
	}
	if not Reg_Commitkey or (Reg_Commitkey<>Git_CcommitKey.Edition){	;存在更新开始更新
		Progress,1 T Cx0 FM10,初始化下载,% Reg_Commitkey " >>> " Git_CcommitKey.Edition " 简介：" Git_CcommitKey.Commit,% Project_Name
		Git_Downloand(Git_CcommitKey,Project_Name)
	}else{
		Progress,,,暂无更新,% Project_Name
	}
	Progress,Off
	return
}

Git_Downloand(DownloandInfo,Project_Name){
	DownUrl:="https://github.com" DownloandInfo.Down
	SplitPath,A_ScriptName,,,,A_name
	SplitPath,DownUrl,DownName,,,OutNameNoExt
	Z_Down(DownUrl,"",A_name,A_Temp "\" DownName)
	UncoilUrl:=A_Temp "\" A_NowUTC
	SmartZip(A_Temp "\" DownName,UncoilUrl)
	FileDelete,% A_Temp "\" DownName
	Git_Bat(UncoilUrl "\" Project_Name "-" OutNameNoExt,Project_Name,DownloandInfo.Edition)
	ExitApp
}

Git_Bat(File,RegAdd_name,Add_Edition){
bat=
		(LTrim
:start
	ping 127.0.0.1 -n 2>nul
	del `%1
	if exist `%1 goto start
	xcopy %File% %A_ScriptDir% /s/e/y
	reg add HKEY_CURRENT_USER\%RegAdd_name% /v Commitkey /t REG_SZ /d %Add_Edition% /f
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
	;whr.SetProxy("HTTPREQUEST_PROXYSETTING_PROXY","proxy_server:80","*.GitHub.com") ;https://msdn.microsoft.com/en-us/library/aa384059(v=VS.85).aspx
	whr.Open("GET",Project_Url,True)
	whr.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
	Try
	{
		whr.Send()
		whr.WaitForResponse()
		RegExMatch(whr.ResponseText,"`a)(?<=data-pjax>\n\s{8})\S{7}",NewEdition)
		RegExMatch(whr.ResponseText,"`a)\/.*\.zip",Downloand)
		RegExMatch(whr.ResponseText,"`a)(?<=class=""message"" data-pjax=""true"" title="").+(?="">)",Committitle)
		;MsgBox % NewEdition "`n" Downloand "`n" Committitle "`n-------------------------"
		Return {Edition:NewEdition,Down:Downloand,Commit:Committitle}
	}catch e {
		Return
	}
}

W_InternetCheckConnection(lpszUrl){ ;检查FTP服务是否可连接
	FLAG_ICC_FORCE_CONNECTION := 0x1
	dwReserved := 0x0
	return, DllCall("Wininet.dll\InternetCheckConnection", "Ptr", &lpszUrl, "UInt", FLAG_ICC_FORCE_CONNECTION, "UInt", dwReserved, "Int")
}
Z_Down(url:="http://61.135.169.125/forbiddenip/forbidden.html", Proxy:="",e:="utf-8", File:="",byref buf:=""){
	if (!(File?o:=FileOpen(File, "w"):1) or !DllCall("LoadLibrary", "str", "wininet") or !(h := DllCall("wininet\InternetOpen", "str", "", "uint", Proxy?3:1, "str", Proxy, "str", "", "uint", 0)))
		return 0
	c:=s:=0
	if (f := DllCall("wininet\InternetOpenUrl", "ptr", h, "str", url, "ptr", 0, "uint", 0, "uint", 0x80003000, "ptr", 0, "ptr"))
		{
			if File or IsByRef(buf)
			{
				VarSetCapacity(buffer,1024,0),VarSetCapacity(bufferlen,4,0)
				Loop, 5
				if (DllCall("wininet\HttpQueryInfo","uint",f, "uint", 22, "uint", &buffer, "uint", &bufferlen, "uint", 0) = 1)
				{
					Progress,+20
					y:= Trim(StrGet(&buffer)," `r`n"),q:=[]
					Loop,parse,y,`r`n
						(x:=InStr(A_LoopField,":"))?q[SubStr(A_LoopField, 1,x-1)]:=Trim(SubStr(A_LoopField, x+1)):q[A_LoopField]:=""
					if (e=0)
						return q
					((i:= Round((fj:=q["Content-Length"])/1024)) < 1024) ?(fx:=1024,fz:= "/" i " K",percent:=i) : (fx:=1048576,fz:= "/" Round(i/1024, 1) " M",percent:=i/1024)
					,VarSetCapacity(Buf, fj, 0),DllCall("QueryPerformanceFrequency", "Int64*", i), DllCall("QueryPerformanceCounter", "Int64*", x)
					break
				}
			}
			Progress,100
			While (DllCall("Wininet.dll\InternetQueryDataAvailable", "Ptr", F, "UIntP", S, "UInt", 0, "Ptr", 0) && (S > 0)) {             
				fj	?(DllCall("Wininet.dll\InternetReadFile", "Ptr", F, "Ptr", &Buf + C, "UInt", S, "UIntP", R),C += R,DllCall("QueryPerformanceCounter", "Int64*", y),((t:=(y-x)/i) >=1)?(Test(e,Round(c/fx,2) fz " | " Round(((c-w)/1024)/t) "KB/秒",Round(c/fx/percent*100)),x:=y,w:=c):"")
					:(VarSetCapacity(b, c+s, 0),DllCall("RtlMoveMemory", "ptr", &b, "ptr", &buf, "ptr", c),DllCall("wininet\InternetReadFile", "ptr", f, "ptr", &b+c, "uint", s, "uint*", r),VarSetCapacity(buf, c+=r, 0), DllCall("RtlMoveMemory", "ptr", &buf, "ptr", &b, "ptr", c))
			}
			(q?((fj=c)?"":q["Error"]:=c):""),(File?(o.rawWrite(buf, c), o.close()):""), DllCall("wininet\InternetCloseHandle", "ptr", f)
		}
	DllCall("wininet\InternetCloseHandle", "ptr", h)
	return (File or IsByRef(buf)?q:StrGet(&buf, c>>(e="utf-16"||e="cp1200"), e))
}
Test(A,b,c){
	Progress,%c%,%b%
}
