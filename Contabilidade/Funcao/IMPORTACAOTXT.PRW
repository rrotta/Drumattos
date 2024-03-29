#Include "rwmake.ch"
#Include "TbiConn.ch"
#Include "TopConn.ch"
#Include "Protheus.ch"
#include "fileio.ch"

/*======================================================================
== Programa  �MARHOT01  �Autor  �TOTVS NE         � Data �  23/05/23  ==
==--------------------------------------------------------------------==
== Descri��o �Integra��o Protheus (Contabilidade).  			      ==
==           �                                                        ==
==--------------------------------------------------------------------==
== Uso       �Contabilidade                                           ==
==--------------------------------------------------------------------==
========================================================================*/
User Function IMPTXT	

Local aButtons 	:= {}
Local aSays    	:= {}
Local cTitulo	:= "Integra��o Protheus (Contabilidade)"
Local nOpcao 	:= 0

    AADD(aSays,OemToAnsi("Esta rotina ir� importar arquivos .csv ou .txt, com os lan�amentos contab�is,"))	
	AADD(aSays,OemToAnsi("para o Protheus - Contabilidade."))	
    AADD(aSays,"")
    AADD(aSays,OemToAnsi("Obs.: Os dados devem est� separados por ponto e virgula."))
    AADD(aSays,OemToAnsi("      Exemplo: 003;01/01/1999;0101010101  ;01010101  ;01010101"))
    
    AADD(aButtons, { 1,.T.,{|o| nOpcao:= 1,o:oWnd:End()} } )
    AADD(aButtons, { 2,.T.,{|o| nOpcao:= 2,o:oWnd:End()} } )
    
    //Para mostrar uma mensagem na tela e as op��es dispon�veis para o usu�rio. (https://tdn.totvs.com/pages/viewpage.action?pageId=24346908)
    FormBatch( cTitulo, aSays, aButtons,,230,530 )

    if nOpcao == 1
        Processa({|| ExecBlock("JOBMAR01",.F.,.F.,{"01","X"}) }, "Integra��o Contabilidade PROTHEUS")
    endif

Return

/*
========================================================================
== Programa  �JOBPRMPT02  �Autor  �TOTVS NE         � Data � 23/05/23 ==
==--------------------------------------------------------------------==
== Descri��o �Rotina de integra��o RM x Protheus. (Contabilidade)     ==
==           �                                                        ==
==--------------------------------------------------------------------==
== Uso       �Financeiro                                              ==
==--------------------------------------------------------------------==
========================================================================*/
User Function JOBMAR01(_cEmp)
	//Local cQuery      := ""
	Local nQtReg      := 0
	Local nQtLido     := 0
	Local nQtGrav     := 0
	Local nPer        := 0
	//Local nSeq        := 0
	//Local nVlDeb      := 0
	//Local nVlCre      := 0
	Local aCampos     := {}
	Local aRegAux     := {}
	//Local dSistema    := dDataBase
	Local cMV_ATUSAL  := GetMv("MV_ATUSAL")
	Local cMV_CONTSB  := GetMv("MV_CONTSB")
	Local cMV_CONTBAT := GetMv("MV_CONTBAT")
	Local cMV_NUMLIN  := GetMv("MV_NUMLIN")
	Local bGrvCT2     := .T.
	Local cTexto	  := ""

	PutMv("MV_ATUSAL","N")
	PutMv("MV_CONTSB","S")
	PutMv("MV_CONTBAT","S")
	PutMv("MV_NUMLIN",99999)

	// --- Variaveis de Contabiliza��o
	Private cLote        := "008890"
	Private cPadrao      := ""                 // C�digo de Lan�amento Padrao criado para contabiliza��o dos rateios da CTK
	Private lDigita      := .F.                // Mostra lancamentos cont�beis. Se via schedule = .F.
	Private lContabiliza := .T.
	Private nTotal       := 0
	Private nLinha       := 0
	Private lCabecalho   := .T.
	Private nHdlPrv
	Private cArquivo

	//cDiret	:= cGetFile("'Arquivo CSV|*.csv| Arquivo TXT|*.txt ","TOTVS - Selecione o Arquivo",,"C:\TOTVS",.T.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)
	cDiret	:= TFileDialog( "Arquivo CSV (*.csv) | Arquivos texto (*.txt)" ,,,, .F., /*GETF_MULTISELECT*/ )
	nHandle := FT_FUse(cDiret)

	If nHandle == -1
		MsgAlert("Opera��o Cancelada")
		Return
	EndIf

	aAdd(aCampos,{"LP"    ,"C",03,0})
	aAdd(aCampos,{"DTLAN" ,"D",08,0})
	aAdd(aCampos,{"DEBIT" ,"C",20,0})
	aAdd(aCampos,{"CREDI" ,"C",20,0})
	aAdd(aCampos,{"CCD"   ,"C",20,0})
	aAdd(aCampos,{"CCC"   ,"C",20,0})
	aAdd(aCampos,{"ICD"   ,"C",20,0})
	aAdd(aCampos,{"ICC"   ,"C",20,0})
	aAdd(aCampos,{"CLD"   ,"C",20,0})
	aAdd(aCampos,{"CLC"   ,"C",20,0})
	aAdd(aCampos,{"VALOR" ,"N",13,2})
	aAdd(aCampos,{"HIST"  ,"C",200,0})

	cNomeArq := CriaTrab(aCampos)
	cChave   := ""
	cArqNtx  := CriaTrab(Nil,.f.)

	If Select("TRP") > 0
		TRP->(DbCloseArea())
	EndIf

	dbUseArea(.T.,,cNomeArq,"TRP",.F.,)

	ProcessMessages()

	nQtReg := FT_FLastRec()

	ProcRegua(nQtReg)

	While !FT_FEOF()
		nQtLido++
		nPer := (nQtLido / nQtReg) * 100
		IncProc("Lendo o Registro: " + Alltrim(Str(nQtLido)) + " de: " + Alltrim(Str(nQtReg)) + " (" + Alltrim(Str(nPer,6,2)) + "%)") //-- Incremeta Termometro

		cTexto := FT_FReadLn()
		If !Empty(cTexto)
				
			aRegAux := {}
			aRegAux := Separa(cTexto,";",.T.)

			 RecLock("TRP",.T.)
			  Replace TRP->FILIAL With aRegAux[1]
			  Replace TRP->LP	  With aRegAux[2]
			  Replace TRP->DTLAN  With CToD(aRegAux[3])
			  Replace TRP->DEBIT  With aRegAux[4]
			  Replace TRP->CREDI  With aRegAux[5]
			  Replace TRP->CCD    With aRegAux[6]
			  Replace TRP->CCC    With aRegAux[7]
			  Replace TRP->ICD    With aRegAux[8]
			  Replace TRP->ICC    With aRegAux[9]
			  Replace TRP->CLD    With aRegAux[10]
			  Replace TRP->CLC    With aRegAux[11]
			  Replace TRP->VALOR  With Val(StrTran(aRegAux[12], ",", "."))
		      Replace TRP->HIST   With aRegAux[13]
			 MsUnlock()
		EndIf 
		FT_FSKIP()
	EndDo

	If TRP->(Eof())
		bGrvCT2 := .F.
	EndIf

	dbSelectArea("TRP")
	TRP->(dbGoTop())

	dLancto := TRP->DTLAN

	ProcRegua(nQtReg)

	nPer := 0
	While !TRP->(Eof())
		nQtGrav++
		nPer := (nQtGrav / nQtReg) * 100
		IncProc("Gravando o Registro: " + Alltrim(Str(nQtGrav)) + " de: " + Alltrim(Str(nQtReg)) + " (" + Alltrim(Str(nPer,6,2)) + "%)") //-- Incremeta Termometro

		ProcessMessages()

		If dLancto <> TRP->DTLAN
			fnGrvCT2()
			dLancto := TRP->DTLAN
		EndIf

		cPadrao := TRP->LP

		LoteCont("GPE")

		If lContabiliza
			If lCabecalho
				nHdlPrv := HeadProva(cLote,"MHFIN",Substr(cUsuario,7,6),@cArquivo)
				lCabecalho := .F.
			EndIf
			nTotal += DetProva(nHdlPrv,cPadrao,"MHFIN",cLote,nLinha)
			nLinha++
		EndIf

		TRP->(dbSkip())
	EndDo

	If bGrvCT2
		Processa({|| fnGrvCT2()}, "Gravando saldos cont�beis.")
		FT_FUSE()
	EndIf

	TRP->(dbCloseArea())

	// ---- Retornar os parametros
	PutMv("MV_ATUSAL",cMV_ATUSAL)
	PutMv("MV_CONTSB",cMV_CONTSB)
	PutMv("MV_CONTBAT",cMV_CONTBAT)
	PutMv("MV_NUMLIN",cMV_NUMLIN)

	FWAlertSuccess("Grava��o dos saldos cont�beis.","Processo finalizado.")

Return

/*-----------------------------------------------
--  Fun��o: Gravando dados na Contabilidade.   --
--                                             --
-------------------------------------------------*/
Static Function fnGrvCT2()
	RodaProva(nHdlPrv,nTotal)
	cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,.T.,dLancto)
Return
