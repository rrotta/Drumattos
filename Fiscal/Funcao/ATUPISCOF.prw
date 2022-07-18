#INCLUDE 'totvs.ch'

/*/{Protheus.doc} ATUPISCOF
Funçao para recalcular o PIS e CONFINS a partir de uma planilha
@type function
@version 
@author TOTVS Nordeste
@since 12/07/2022
@return
/*/
User Function ATUPISCOF()
	
Local 	 aFields        := {}

Private  oTempTable     := FWTemporaryTable():New( /*cAlias*/, /*aFields*/)
Private  cAlias         := ""
Private  cTableName     := ""
Private  lMsErroAuto    := .F.
Private  lMsHelpAuto	:= .T.
Private  lAutoErrNoFile := .T.

	aAdd(aFields, {"FILIAL" , GetSx3Cache("FT_FILIAL","X3_TIPO") , GetSx3Cache("FT_FILIAL","X3_TAMANHO") , GetSx3Cache("FT_FILIAL","X3_DECIMAL")})
	aAdd(aFields, {"TIPOMOV", GetSx3Cache("FT_TIPOMOV","X3_TIPO"), GetSx3Cache("FT_TIPOMOV","X3_TAMANHO"), GetSx3Cache("FT_TIPOMOV","X3_DECIMAL")})
	aAdd(aFields, {"SERIE"  , GetSx3Cache("FT_SERIE","X3_TIPO")  , GetSx3Cache("FT_SERIE","X3_TAMANHO")  , GetSx3Cache("FT_SERIE","X3_DECIMAL")})
	aAdd(aFields, {"NFISCAL", GetSx3Cache("FT_NFISCAL","X3_TIPO"), GetSx3Cache("FT_NFISCAL","X3_TAMANHO"), GetSx3Cache("FT_NFISCAL","X3_DECIMAL")})
	aAdd(aFields, {"CLIEFOR", GetSx3Cache("FT_CLIEFOR","X3_TIPO"), GetSx3Cache("FT_CLIEFOR","X3_TAMANHO"), GetSx3Cache("FT_CLIEFOR","X3_DECIMAL")})
	aAdd(aFields, {"LOJA"   , GetSx3Cache("FT_LOJA","X3_TIPO")   , GetSx3Cache("FT_LOJA","X3_TAMANHO")   , GetSx3Cache("FT_LOJA","X3_DECIMAL")})
	aAdd(aFields, {"ITEM"   , GetSx3Cache("FT_ITEM","X3_TIPO")   , GetSx3Cache("FT_ITEM","X3_TAMANHO")   , GetSx3Cache("FT_ITEM","X3_DECIMAL")})
	aAdd(aFields, {"PRODUTO", GetSx3Cache("FT_PRODUTO","X3_TIPO"), GetSx3Cache("FT_PRODUTO","X3_TAMANHO"), GetSx3Cache("FT_PRODUTO","X3_DECIMAL")})
	aAdd(aFields, {"ALIQPIS", GetSx3Cache("FT_ALIQPIS","X3_TIPO"), GetSx3Cache("FT_ALIQPIS","X3_TAMANHO"), GetSx3Cache("FT_ALIQPIS","X3_DECIMAL")})
	aAdd(aFields, {"ALIQCOF", GetSx3Cache("FT_ALIQCOF","X3_TIPO"), GetSx3Cache("FT_ALIQCOF","X3_TAMANHO"), GetSx3Cache("FT_ALIQCOF","X3_DECIMAL")})
	aAdd(aFields, {"CSTPIS" , GetSx3Cache("FT_CSTPIS","X3_TIPO") , GetSx3Cache("FT_CSTPIS","X3_TAMANHO") , GetSx3Cache("FT_ALIQCOF","X3_DECIMAL")})
	aAdd(aFields, {"CSTCOF" , GetSx3Cache("FT_CSTCOF","X3_TIPO") , GetSx3Cache("FT_CSTCOF","X3_TAMANHO") , GetSx3Cache("FT_ALIQCOF","X3_DECIMAL")})
	

	oTempTable:SetFields( aFields )
	oTempTable:Create()
	
	cAlias     := oTempTable:GetAlias()
	cTableName := oTempTable:GetRealName()

	FWMsgRun(, {|oSay| RunProcA(oSay)}, "Aguarde...","Lendo Arquivo...")
	
	If LastRec() > 0
		Processa( {|| RunProcB() },"Aguarde", "Gravando Alterações...",.F.)
		FWAlertSuccess("Processo de alteraçao finalizado com sucesso...", "")
	EndIf 
	
	oTempTable:Delete()

Return Nil

/*/{Protheus.doc} RunProcA
Ler arquivo .CSV
@type function
@version 
@author TOTVS Nordeste
@since 12/07/2022
@return 
/*/

Static Function RunProcA(oSay)

Local aRegAux := {} 
Local cArq    := ".csv"
Local cLinha  := ""
Local cLog    := ""
Local nAux    := 0
	
Private aErro   := {}
Private cTipo   := "'Arquivo CSV|*.csv| Arquivo TXT|*.txt "

	cArq := cGetFile(cTipo,"TOTVS - Alterar Registros",,"C:\TOTVS")
	If !File(cArq)
		MsgStop("O arquivo " +cArq + " não foi encontrado. A importação será abortada!","ATENCAO")
		Return
	EndIf
	cLog += "ALT_REGISTRO"  + CHR(13)+CHR(10)
	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	
		While !FT_FEOF()
			
			cLinha := FT_FREADLN()
			
			If !Empty(cLinha)
				aRegAux := {}
				++nAux

					aRegAux := Separa(cLinha,";",.T.)
					
					(cAlias)->(DBAppend())
					(cAlias)->FILIAL  := aRegAux[1]
					(cAlias)->TIPOMOV := aRegAux[2]
					(cAlias)->SERIE   := aRegAux[3]
					(cAlias)->NFISCAL := aRegAux[4]
					(cAlias)->CLIEFOR := aRegAux[5]
					(cAlias)->LOJA    := aRegAux[6]
					(cAlias)->ITEM    := aRegAux[7]
					(cAlias)->PRODUTO := aRegAux[8]
					(cAlias)->ALIQPIS := Val(aRegAux[9])
					(cAlias)->ALIQCOF := Val(aRegAux[10])
					(cAlias)->CSTPIS  := aRegAux[11]
					(cAlias)->CSTCOF  := aRegAux[12]
					(cAlias)->(DBCommit())

			Endif
		 FT_FSKIP()
		EndDo

	FT_FUSE()
Return

/*/{Protheus.doc} RunProcB
Faz alteração do registro
@type function
@version 
@author TOTVS Nordeste
@since 12/07/2022
@return 
/*/

Static Function RunProcB()
Local aArea    := GetArea()
Local cQry     := ""
Local cAreaQry := GetNextAlias()
Local nAtual   := 0
Local nValor   := 0
Local nLinhas  := LastRec()
Local lAlter   := .F.

	cQry := "SELECT * FROM " + cTableName
    DBUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAreaQry, .T., .T.)
    (cAreaQry)->(dbGoTop())

	ProcRegua(nLinhas)

	DbSelectArea("SFT")
	SFT->(DbSetOrder(1))
	(cAreaQry)->(dbGoTop())
	
	While !(cAreaQry)->(Eof())

		//Incrementa a mensagem na régua
        nAtual++
		IncProc("Gravando alteração " + cValToChar(nAtual) + " de " + cValToChar(nLinhas) + "...")
		sleep(300)
		PROCESSMESSAGES()

		lAlter := .F.
			
			SFT->(DbGoTop())
		If  SFT->(DbSeek((cAreaQry)->FILIAL+;
						 (cAreaQry)->TIPOMOV+;
						 (cAreaQry)->SERIE+;
						 (cAreaQry)->NFISCAL+;
						 (cAreaQry)->CLIEFOR+;
						 (cAreaQry)->LOJA+;
						 (cAreaQry)->ITEM+;
						 (cAreaQry)->PRODUTO)) 
		   
			 nValor := SFT->FT_TOTAL  //Pega o total do item
				
				RecLock("SFT", .F.)
					
					SFT->FT_BASEPIS := nValor
					SFT->FT_BASECOF := nValor
					SFT->FT_ALIQPIS := (cAreaQry)->ALIQPIS
					SFT->FT_ALIQCOF := (cAreaQry)->ALIQCOF
					SFT->FT_VALPIS  := ( nValor * (cAreaQry)->ALIQPIS/100 )
					SFT->FT_VALCOF  := ( nValor * (cAreaQry)->ALIQCOF/100 )
					SFT->FT_CSTPIS  := (cAreaQry)->CSTPIS
					SFT->FT_CSTCOF  := (cAreaQry)->CSTCOF

					lAlter := .T.
				
				SFT->(MsUnlock())

				If !lAlter
					FWAlertError("Erro na alteração do registros, linha do arquivo: "+cValToChar(nAtual),;
								 "Erro RecLock")
				EndIf

		EndIf 
	 
		(cAreaQry)->(DBSkip())
	EndDo

	ProcRegua(nLinhas)
  
  (cAreaQry)->(DBCloseArea())
  RestArea(aArea)

Return
