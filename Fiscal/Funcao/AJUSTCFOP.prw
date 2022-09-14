#INCLUDE 'totvs.ch'

/*/{Protheus.doc} AJUSTCFOP
Funçao para ajustar o CFOP a partir de uma planilha
@type function
@version 
@author TOTVS Nordeste
@since 09/09/2022
@return
/*/
User Function AJUSTCFOP()
	
Local 	 aFields        := {}

Private  oTempTable     := FWTemporaryTable():New( /*cAlias*/, /*aFields*/)
Private  cAlias         := ""
Private  cTableName     := ""
Private  lMsErroAuto    := .F.
Private  lMsHelpAuto	:= .T.
Private  lAutoErrNoFile := .T.

	aAdd(aFields, {"FILIAL" , GetSx3Cache("D2_FILIAL" ,"X3_TIPO"), GetSx3Cache("D2_FILIAL" ,"X3_TAMANHO"), GetSx3Cache("D2_FILIAL" ,"X3_DECIMAL")})
	aAdd(aFields, {"NFISCAL", GetSx3Cache("D2_DOC"    ,"X3_TIPO"), GetSx3Cache("D2_DOC"    ,"X3_TAMANHO"), GetSx3Cache("D2_DOC"    ,"X3_DECIMAL")})
	aAdd(aFields, {"SERIE"  , GetSx3Cache("D2_SERIE"  ,"X3_TIPO"), GetSx3Cache("D2_SERIE"  ,"X3_TAMANHO"), GetSx3Cache("D2_SERIE"  ,"X3_DECIMAL")})
	aAdd(aFields, {"CLIENTE", GetSx3Cache("D2_CLIENTE","X3_TIPO"), GetSx3Cache("D2_CLIENTE","X3_TAMANHO"), GetSx3Cache("D2_CLIENTE","X3_DECIMAL")})
	aAdd(aFields, {"LOJA"   , GetSx3Cache("D2_LOJA"   ,"X3_TIPO"), GetSx3Cache("D2_LOJA"   ,"X3_TAMANHO"), GetSx3Cache("D2_LOJA"   ,"X3_DECIMAL")})
	aAdd(aFields, {"PRODUTO", GetSx3Cache("D2_COD"    ,"X3_TIPO"), GetSx3Cache("D2_COD"    ,"X3_TAMANHO"), GetSx3Cache("D2_COD"    ,"X3_DECIMAL")})
	aAdd(aFields, {"ITEM"   , GetSx3Cache("D2_ITEM"   ,"X3_TIPO"), GetSx3Cache("D2_ITEM"   ,"X3_TAMANHO"), GetSx3Cache("D2_ITEM"   ,"X3_DECIMAL")})
	aAdd(aFields, {"CFOP"   , GetSx3Cache("D2_CF"     ,"X3_TIPO"), GetSx3Cache("D2_CF"     ,"X3_TAMANHO"), GetSx3Cache("D2_CF"     ,"X3_DECIMAL")})
	aAdd(aFields, {"CHAVE"  , GetSx3Cache("F2_CHVNFE" ,"X3_TIPO"), GetSx3Cache("F2_CHVNFE" ,"X3_TAMANHO"), GetSx3Cache("F2_CHVNFE" ,"X3_DECIMAL")})

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
@since 09/09/2022
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
					(cAlias)->NFISCAL := aRegAux[2]
					(cAlias)->SERIE   := aRegAux[3]
					(cAlias)->CLIENTE := aRegAux[4]
					(cAlias)->LOJA    := aRegAux[5]
					(cAlias)->PRODUTO := aRegAux[6]
					(cAlias)->ITEM    := aRegAux[7]
					(cAlias)->CFOP    := aRegAux[8]
					(cAlias)->CHAVE   := aRegAux[9]
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
@since 09/09/2022
@return 
/*/

Static Function RunProcB()
Local aArea    := GetArea()
Local cQry     := ""
Local cAreaQry := GetNextAlias()
Local nAtual   := 0
Local nLinhas  := LastRec()
Local lAlter   := .F.

	cQry := "SELECT * FROM " + cTableName
    DBUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAreaQry, .T., .T.)
    (cAreaQry)->(dbGoTop())

	ProcRegua(nLinhas)

	DbSelectArea("SD2")
	SD2->(DbSetOrder(3))
	(cAreaQry)->(dbGoTop())
	
	While !(cAreaQry)->(Eof())

		//Incrementa a mensagem na régua
        nAtual++
		IncProc("Gravando alteração " + cValToChar(nAtual) + " de " + cValToChar(nLinhas) + "...")
		sleep(300)
		PROCESSMESSAGES()

		lAlter := .F.
			
			SD2->(DbGoTop())
		If  SD2->(DbSeek(PADR((cAreaQry)->FILIAL,TamSX3("D2_FILIAL")[1])+;
						 PADR((cAreaQry)->NFISCAL,TamSX3("D2_DOC")[1])+;
						 PADR((cAreaQry)->SERIE,TamSX3("D2_SERIE")[1])+;
						 PADR((cAreaQry)->CLIENTE,TamSX3("D2_CLIENTE")[1])+;
						 PADR((cAreaQry)->LOJA,TamSX3("D2_LOJA")[1])+;
						 PADR((cAreaQry)->PRODUTO,TamSX3("D2_COD")[1])+;
						 PADR((cAreaQry)->ITEM,TamSX3("D2_ITEM")[1]))) 
			
				RecLock("SD2", .F.)					
					SD2->D2_CF  := (cAreaQry)->CFOP
					lAlter := .T.
				SD2->(MsUnlock())

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
