#SingleInstance force
#NoEnv
#InstallKeybdHook
#InstallMouseHook

Gui, Add, Checkbox, Section x10 gMouseToggle vMouseEnabled, Listen to mouse
Gui, Add, Checkbox, xs gKbdListen vKbdEnabled, Listen to keyboard
Gui, Add, Checkbox, xs gPhsListen vPhsEnabled, Listen to user input
Gui, Add, Checkbox, ys vMimic Section, Mimic input 
Gui, Add, Checkbox, xs vRandEnabled, Random events
Gui, Add, Checkbox, xs vSequenceEnabled, Sequence send
Gui, Add, Button, Section gRefreshList ys w60, Refresh
Gui, Add, Button, gHelpListen xs w60, Help
Gui, Add, Text, xs, Pause button
Gui, Add, Button, Section gPauseListen ys w60 vPauseButton Default, Pause
Gui, Add, Button, gCoordsListen xs w60, CoordSpy
Gui, Add, Edit, xs vPauseKey gEditChange w50
Gui, Add, Checkbox, ys gAutoRef vAutoEnabled Section, AutoRefresh each
Gui, Add, ComboBox, ys vSecToRef w50, 1|2|3|4|5|6|7|8|9|10||
Gui, Add, Text, ys, sec
Gui, Add, Text, xs Section, Random interval 
Gui, Add, ComboBox, ys vRandStart gRandStartUpdated w50, 0.5|1|1.5|2||2.5|3|3.5|4|4.5|5
Gui, Add, Text, ys, -
Gui, Add, ComboBox, ys vRandEnd w50, 0.5|1|1.5|2|2.5|3||3.5|4|4.5|5
Gui, Add, Text, ys, s
Gui, Add, Button, ys, Apply
Gui, Add, Text, xs Section, Keys to send
Gui, Add, Edit, ys vKeys w150
Gui, Add, ListView, vMyList gMyList w600 h300 Checked SortDesc xm, Name|Class|ID
Menu, FileMenu, Add, LoadProfile(inactive), MenuHandler
Menu, FileMenu, Add, SaveProfile(inactive), MenuHandler
Menu, HelpMenu, Add, Usage, HelpListen
Menu, HelpMenu, Add, About, AboutBox
Menu, MyMenuBar, Add, &File, :FileMenu
Menu, MyMenuBar, Add, &Help, :HelpMenu
Gui, Menu, MyMenuBar

CoordMode, Mouse, Screen
if A_IsCompiled
  Menu, Tray, Icon, %A_ScriptFullPath%, -159

IniRead, SecToRefTemp, CKSSettings.ini, 1, SecToRef, 10
IniRead, RandStartTemp, CKSSettings.ini, 1, RandStart, 0.5
IniRead, RandEndTemp, CKSSettings.ini, 1, RandEnd, 1.0
IniRead, KeysTemp, CKSSettings.ini, 1, Keys, %A_Space%
IniRead, PauseKeyTemp, CKSSettings.ini , 1, PauseKey, #p


if( !FileExist("CKSSettings.ini")  ){
    MsgBox,, First Time Use, It looks like you're using CKS-E for the first time. Setting some defaults. Please read the help to get started."
}

GuiControl,, SecToRef, %SecToRefTemp%||
GuiControl,, RandStart, %RandStartTemp%||
GuiControl,, RandEnd, %RandEndTemp%||
GuiControl,, Keys, %KeysTemp%
GuiControl,, PauseKey, %PauseKeyTemp%

idList := object()
Refresh(idList)
OldPause := PauseKeyTemp
Hotkey, %PauseKeyTemp%, PauseListen
Seq := 0
Timer := 0
Gui, Show,, CKS-E
Gui, Submit, NoHide
Return


MenuHandler(){
	Return
}

EditChange(){
	Gui submit, NoHide
	if (OldPause = PauseKey)
		Return

	if (OldPause != "") {
		Hotkey, %OldPause%, Off
	}

	if (PauseKey = "" )
		Return

	Hotkey, %PauseKey%, PauseListen
	OldPause := PauseKey
	Return
}

CoordsListen(){
	if (Timer) {
		Settimer WatchCursor, off
		Tooltip
		Timer:=0
	} else {
		Settimer WatchCursor, 50
		Timer:=1
	}
	Return
}

WatchCursor(){
	MouseGetPos , mouseX, mouseY
	ToolTip, %mouseX% %mouseY%
	Return
}

KbdListen(){
	Global
	Gui, Submit, NoHide
	while (KbdEnabled)
	{
		Input, SingleKey, L1 V,  {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{Backspace}{Capslock}{Numlock}{PrintScreen}{Pause}
		
		if (Mimic)
			sendkeys(SingleKey, Seq++, SequenceEnabled)
		else
			sendKeys(Keys, Seq++, SequenceEnabled)
	}
	Return
}

PhsListen(){
	lastInput := 100
	while (PhsEnabled)
	{
		if (A_TimeIdlePhysical < lastInput) 
			sendKeys(Keys, Seq++, SequenceEnabled)
		
		lastInput := sleepSpecial(RandStart, RandEnd, RandEnabled)
	}
	Return
}

PauseListen(){
	Global
	if IsPaused
	{
	   Pause off
	   IsPaused := false
	   GuiControl,, PauseButton, Pause
	}
	else
	   SetTimer, OnPause, 10
	Return
}

OnPause(){
	Global
	SetTimer, OnPause, off
	IsPaused := true
	GuiControl,, PauseButton, Unpause
	Pause, on
	Return
}

AboutBox(){
	txtVar := "CKS-E is a tool for duplicating or remapping user input and sending it to one or more applications on your PC. For example, CKS-E could allow you to send a key to perform repetitive crafting actions on an MMO character when you move your mouse while photo-editing or for each key you press while you type a report. CKS-E is based on the Consortium Key Sender by Pliaksi as originally published on the Consortium Gold Forums."
	msgbox ,,Help, %txtVar%
	Return
}

HelpListen(){
	txtVar := "Fill in usage info here"
	msgbox ,,Help, %txtVar%
	Return
}

AutoRef(){
	
	Global idList, AutoEnabled, SecToRef
	
	while (AutoEnabled){
		Refresh(idList)
		if (secToRef="") {
			SecToRef := 10000
			GuiControl,,SecToRef,10||
		} else {
			secToRef*=1000    
		}
		sleep, SecToRef
	}
	Return
}

MouseToggle(){
	Global MouseEnabled
	
	Gui, Submit, NoHide
	
	if( MouseEnabled ){
		SetTimer, MouseListen, -0
	}
	Return
}

OnMouseInput(){
	Global IsPaused, MouseEnabled
	
	if( !IsPaused and MouseEnabled ){
		doSend()
	}
	Return
}

$~WheelUp::
	OnMouseInput()
Return

$~WheelDown::
	OnMouseInput()
Return

MouseListen(){
	Global MouseEnabled
	
	MouseGetPos, xPos, yPos
	
	while( MouseEnabled ){
	
		MouseGetPos, xPosNew, yPosNew
		
		if (xPos <> xPosNew or yPos <> yPosNew){
			xPos := xPosNew
			yPos := yPosNew
			OnMouseInput()
		}else{
			Sleep, 100
		}
	}
}

RefreshList(){
	Global idList
	Refresh(idList)
	Return
}

MyList(){
}

GuiContextMenu(){  
}

GuiClose(){
	FinaliseAndExit()
}

Close(){
	FinaliseAndExit()
}

FinaliseAndExit(){
	Global
	Gui submit, NoHide
	IniWrite, %SecToRef%, CKSSettings.ini , 1, SecToRef
	IniWrite, %RandStart%, CKSSettings.ini , 1, RandStart
	IniWrite, %RandEnd%, CKSSettings.ini , 1, RandEnd
	IniWrite, %Keys%, CKSSettings.ini , 1, Keys
	IniWrite, %PauseKey%, CKSSettings.ini , 1, PauseKey
	ExitApp
}

doSend(){
	Global Keys, Seq, SequenceEnabled, RandStart, RandEnd, RandEnabled
	
	sendKeys(Keys, Seq++, SequenceEnabled)
	sleepSpecial(RandStart, RandEnd, RandEnabled)
}

Refresh(idList) {
	
    WinGet, id, list,,, Program Manager
    Loop, %id%
    {   
        this_id := id%A_Index%
        if (idList[this_id] = 1)
            continue
        WinGetClass, this_class, ahk_id %this_id%
        WinGetTitle, this_title, ahk_id %this_id%
        if (this_title = "" or this_title = "Start")
            continue
        LV_Add("",this_title,this_class,this_id)
        idList[this_id] := 1
    }

    Loop % LV_GetCount()
    {
        LV_GetText(win_id, A_Index,3)
        IfWinNotExist, ahk_id%win_id%
        {
            LV_Delete(a_index)
            insertList.Remove(win_id)
        }
    }
    LV_ModifyCol(1,"Auto")
    LV_ModifyCol(2,"Auto")
    LV_ModifyCol(3,"Auto")
}

sleepSpecial(RandStart, RandEnd, RandEnabled){

    If (RandEnd < RandStart or RandEnd ="" or RandStart="") {
        RandStart := 2000
        RandEnd := 3000
        GuiControl,,RandStart,2||
        GuiControl,,RandEnd,3||
    } else {
        RandStart *=1000
        RandEnd *=1000
    }

    if (RandEnabled) {
        Random, spec, 1, 10
        if (spec = 1) {
            randEventArr := [0.1, 0.5, 0.7, 2, 3, 4, 5]
            Random, modif, 1 ,7
            RandStart *= randEventArr[modif]
            RandEnd *= randEventArr[modif]
        }
    }
    Random, rand, RandStart, RandEnd
    sleep , rand
    Return rand
}

sendKeys(Keys, Sequence, SEnabled){
   
    if (Keys = "")
        Keys := 1
    RowNumber := 0  
    Loop
    {
        RowNumber := LV_GetNext(RowNumber,"Checked")  
        if not RowNumber  
        break
        StringSplit, KeyArr, Keys, `;
        if (SEnabled) {
			rand := Mod(Sequence, KeyArr0) + 1
		} else {
			Random, rand, 1 , KeyArr0
		}
        LV_GetText(win_id, RowNumber,3)
        keyToSend := keyArr%rand%
		IfInString, keyToSend, mclick
		{
			Stringmid, keyToSend, keyToSend, 8
			ControlClick, %keytoSend%, ahk_id%win_id%
		} else
			ControlSend,, %keytoSend%, ahk_id%win_id%
    }
}

RandStartUpdated(){
	If (RandEnd < RandStart){
	}
}