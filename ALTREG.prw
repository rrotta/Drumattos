#INCLUDE 'totvs.ch'

/*/{Protheus.doc} ALTREG
Alterar Registro da tabela
@type function
@version 
@author TOTVS Nordeste
@since 23/05/2022
@return
/*/
User Function ALTREG()

	Private  aReg           := {}
	Private  lMsErroAuto    := .F.
	Private  lMsHelpAuto	:= .T.
    Private  lAutoErrNoFile := .T.
	Private  cAlias         := Space(3)
	Private  nIndice        := Space(2)
	Private  cCampo         := Space(10)
	
	FWMsgRun(, {|oSay| RunProcA(oSay)}, "Aguarde...","Lendo Arquivo...")
	
	If Len(aReg) > 0
		TelaCampo() //Tela para informar o campo a ser alterado
		If !Empty(cAlias) .And. !Empty(nIndice) .And. !Empty(cCampo)
			Processa( {|| RunProcB() },"Aguarde", "Gravando Altera��es...",.T.)
		EndIf 
	Endif
	
	If !Empty(cAlias) .And. !Empty(nIndice) .And. !Empty(cCampo)
		FWAlertSuccess("Processo de altera�ao finalizado com sucesso...", "")
	 Else 
		FWAlertInfo("Processo abortado pelo usu�rio.", "")
	EndIf
Return Nil

/*/{Protheus.doc} RunProcA
Ler arquivo .CSV
@type function
@version 
@author TOTVS Nordeste
@since 23/05/2022
@return 
/*/

Static Function RunProcA(oSay)

	Local aLinFor    := {} 
	Local aLinha     := {}
	Local cArq       := ".txt"
	Local cLinha     := ""
	Local cLog       := ""
	Local nAux       := 0
	Local x
	
	Private aErro   := {}
	Private cTipo   := "Database (*.txt) | *.txt | "

	cArq := cGetFile(cTipo,"TOTVS - Alterar Registros",,"C:\TOTVS")
	If !File(cArq)
		MsgStop("O arquivo " +cArq + " n�o foi encontrado. A importa��o ser� abortada!","ATENCAO")
		Return
	EndIf
	cLog += "ALT_REGISTRO"  + CHR(13)+CHR(10)
	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	
		While !FT_FEOF()
			
			cLinha := FT_FREADLN()
			
			If !Empty(cLinha)
				aLinFor := {}
				++nAux

					aLinFor := Separa(cLinha,";",.T.)
					
					For x := 1 To 1
					 aLinha := {}
						
						aAdd( aLinha, { aLinFor[1],aLinFor[2] } )

					 aAdd(aReg, aLinha)
					Next x

			Endif
		 FT_FSKIP()
		EndDo

	FT_FUSE()
Return

/*/{Protheus.doc} RunProcB
Faz altera��o do registro
@type function
@version 
@author TOTVS Nordeste
@since 23/05/2022
@return 
/*/

Static Function RunProcB()
  Local aArea     := GetArea()
  Local nAtual    := 0
  Local lAlter    := .F.
  Local x


	ProcRegua(Len(aReg))

   	For x := 1 To Len(aReg)
		
		//Incrementa a mensagem na r�gua
        nAtual++
		IncProc("Gravando altera��o " + cValToChar(nAtual) + " de " + cValToChar(Len(aReg)) + "...")
		sleep(300)
		PROCESSMESSAGES()

		lAlter := .F.

		DbSelectArea(cAlias)
		&(cAlias)->(DbSetOrder(nIndice))
		&(cAlias)->(DbGoTop())
		If  &(cAlias)->(DbSeek(FWxFilial(cAlias)+aReg[x][1][1])) 
			
			RecLock(cAlias, .F.)
				
				&(cAlias)->(&(cCampo)) := aReg[x][1][2]
				
				lAlter := .T.
			
			&(cAlias)->(MsUnlock())

			If !lAlter
				FWAlertError("Erro na altera��o do registros, linha do arquivo: "+cValToChar(nAtual),;
				"Erro RecLock")
			EndIf 

		EndIf 

	Next x
  
  RestArea(aArea)

Return

/*/{Protheus.doc} TelaCampo
Tela para informar o campo a ser alterado
@type function
@version 
@author TOTVS Nordeste
@since 23/05/2022
@return 
/*/

Static Function TelaCampo()

Local oDialog 

// M�todo respons�vel por criar a janela e montar os paineis.
oDialog := FWDialogModal():New()

// M�todos para configurar o uso da classe.
oDialog:SetBackground( .T. ) 
oDialog:SetTitle( 'Informe o campo a ser alterado' )
oDialog:SetSize( 120, 200 )
oDialog:EnableFormBar( .T. )
oDialog:SetCloseButton( .T. )
oDialog:SetEscClose( .T. )
oDialog:CreateDialog()
oDialog:CreateFormBar()
oDialog:AddCloseButton({|| oDialog:OOWNER:END()})
oDialog:AddButton('Confirmar' , { || IIF(!Empty(cAlias) .And. !Empty(cCampo),oDialog:DeActivate(),;
									 MsgAlert("O preenchimento dos campos � obrigat�rio.","")) },;
									 'Confirmar' ,,.T.,.F.,.T.,)

// Capturar o objeto do FwDialogModal para alocar outros objetos se necess�rio.
oPanel := oDialog:GetPanelMain()

	oSay1  := TSay():New(17,5,{|| "Tabela: "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 17,33 MSGET cAlias SIZE 010,010 OF oPanel PIXEL 
	oSay1  := TSay():New(31,5,{|| "Indice: "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 31,33 MSGET nIndice SIZE 010,010 OF oPanel PIXEL 
	oSay1  := TSay():New(45,5,{|| "Campo: "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 45,33 MSGET cCampo SIZE 040,010 OF oPanel PIXEL 

oDialog:Activate()  

	Do Case
		Case Empty(cAlias)
				MsgStop("Por favor informar a tabela.", "")
				TelaCampo()
		
		Case Empty(nIndice)
				MsgStop("Por favor informar o indice da tabela.", "")
				TelaCampo()
		
		Case !Empty(cAlias)
			DbSelectArea(cAlias)

		Case !Empty(cCampo) .And. FieldPos(cCampo) <= 0
				MsgStop("O campo "+cCampo+" n�o existe!", "")
				TelaCampo()
	EndCase

Return
