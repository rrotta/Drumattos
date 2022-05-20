#INCLUDE 'totvs.ch'

/*/{Protheus.doc} ALTFOR
Alterar Fornecedores
@type function
@version 
@author TOTVS Nordeste
@since 20/05/2022
@return
/*/
User Function ALTFOR()

	Private  aFornec        := {}
	Private  lMsErroAuto    := .F.
	Private  lMsHelpAuto	:= .T.
    Private  lAutoErrNoFile := .T.
	
	FWMsgRun(, {|oSay| RunProcA(oSay)}, "Aguarde...","Lendo Arquivo - Fornecedores...")
	
	If Len(aFornec) > 0
		Processa( {|| RunProcB() },"Aguarde", "Gravando Alterações nos fornecedores...",.T.)
	Endif

	FWAlertSuccess("Processo de alteraçao finalizado com sucesso...", "Alteração de fornecedores.")

Return Nil

/*/{Protheus.doc} RunProcA
Ler arquivo .CSV
@type function
@version 
@author TOTVS Nordeste
@since 20/05/2022
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

	cArq := cGetFile(cTipo,"TOTVS - Alterar Fornecedores",,"C:\TOTVS")
	If !File(cArq)
		MsgStop("O arquivo " +cArq + " não foi encontrado. A importação será abortada!","ATENCAO")
		Return
	EndIf
	cLog += "ALT_FORNECEDOR"  + CHR(13)+CHR(10)
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

					 aAdd(aFornec, aLinha)
					Next x

			Endif
		 FT_FSKIP()
		EndDo

	FT_FUSE()
Return

/*/{Protheus.doc} RunProcB
Faz alteração no fornecedor
@type function
@version 
@author TOTVS Nordeste
@since 20/05/2022
@return 
/*/

Static Function RunProcB()
  Local aArea     := GetArea()
  Local nAtual    := 0
  Local lAlter    := .F.
  Local x


	ProcRegua(Len(aFornec))

   	For x := 1 To Len(aFornec)
		
		//Incrementa a mensagem na régua
        nAtual++
		IncProc("Gravando alteração " + cValToChar(nAtual) + " de " + cValToChar(Len(aFornec)) + "...")
		sleep(300)
		PROCESSMESSAGES()

		lAlter := .F.

		DbSelectArea("SA2")
		SA2->(DbSetOrder(3))
		SA2->(DbGoTop())
		If  SA2->(DbSeek(FWxFilial("SA2")+aFornec[x][1][1])) 
			
			RecLock("SA2", .F.)
				
				SA2->A2_NATUREZ := aFornec[x][1][2]
				
				lAlter := .T.
			
			SA2->(MsUnlock())

			If !lAlter
				FWAlertError("CNPJ/CPF: " + aFornec[x][1][1] + " Natureza: "+aFornec[x][1][2],;
				"Erro RecLock")
			EndIf 

		EndIf 

	Next x
  
  RestArea(aArea)

Return
