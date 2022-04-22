#INCLUDE "PROTHEUS.CH"

#DEFINE ENTER CHR(13)+CHR(10)
//----------------------------------------------------------------------------------------------
User Function RCXSINT()
Local oReport
	oReport:= ReportDef()
	oReport:PrintDialog()
Return

//----------------------------------------------------------------------------------------------------------
Static Function ReportDef()


Local oSection1
Local cPerg     := "RCXSINT01"
Local cPictVl := PesqPict("SE1","E1_VALOR")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao do componente de impressao                                      ³
//³                                                                        ³
//³TReport():New                                                           ³
//³ExpC1 : Nome do relatorio                                               ³
//³ExpC2 : Titulo                                                          ³
//³ExpC3 : Pergunte                                                        ³
//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
//³ExpC5 : Descricao                                                       ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Gera_SX1(cPerg)
oReport:= TReport():New("RCXSINT",'Relatorio de Caixa Sintético',cPerg, {|oReport| ReportPrint(oReport)},'Emissão de Relatorio de Caixa Sintético por Período')
Pergunte(oReport:uParam,.F.)
oReport:nFontBody 	:= 8
oReport:nLineHeight	:= 50 // Define a altura da linha.
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao da secao utilizada pelo relatorio                               ³
//³                                                                        ³
//³TRSection():New                                                         ³
//³ExpO1 : Objeto TReport que a secao pertence                             ³
//³ExpC2 : Descricao da seçao                                              ³
//³ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela   ³
//³        sera considerada como principal para a seção.                   ³
//³ExpA4 : Array com as Ordens do relatório                                ³
//³ExpL5 : Carrega campos do SX3 como celulas                              ³
//³        Default : False                                                 ³
//³ExpL6 : Carrega ordens do Sindex                                        ³
//³        Default : False                                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

oCabec := TRSection():New(oReport,'Empresa')
oCabec:SetTotalInLine(.F.)
TRCell():New(oCabec,'CEMPRESA', ,"Empresa"  	,/*Picture*/	,30,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oCabec,'DDATAINI', ,"Periodo De"  	,/*Picture*/	,20,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oCabec,'DDATAFIM', ,"Período Ate"  ,/*Picture*/	,20,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection1 := TRSection():New(oCabec,'Pagamentos')
oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,'LOCUNID'	,,"Pagamento" 				,/*Picture*/	,TAMSX3("AE_DESC")[1] + 2,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'NCALCL'		,,"Calculado"+ENTER+"(1)" 	,cPictVl	    ,			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'NINFOR'		,,"Informado"+ENTER+"(2)"	,cPictVl	    ,			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'NDIFER'		,,"Diferença"+ENTER+"(2-1)"	,cPictVl	    ,			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'NCONFE'		,,"Conferido"+ENTER+"(3)"	,cPictVl	    ,			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,'NDIFCONF'	,,"Diferenca"+ENTER+"(3-1)"	,cPictVl	    ,			,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection2:=TRSection():New(oSection1,"Resumo",/*Ordem*/)
//oSection2:SetLineStyle() //Define a impressao da secao em linha

TRCell():New(oSection2,'NTOTREC'	,,"Total Recebido" 	,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTVEN'	,,"Total Vendas" 	,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTITE'	,,"Total Itens"		,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTCVAL'	,,"Total C. Vales Emitidos" ,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTDESC'	,,"Total Descontos" 		,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTDIFIT'	,,"Dif.Receb/Itens"			,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection2,'NTOTDIFVD'	,,"Dif.Receb/Vendas"		,cPictVl,TamSX3("E1_VALOR")[1],/*lPixel*/,/*{|| code-block de impressao }*/)

oSection2:Cell('NTOTREC'  ):SetCellBreak()
oSection2:Cell('NTOTVEN'  ):SetCellBreak()
oSection2:Cell('NTOTITE'  ):SetCellBreak()

Return(oReport)
//---------------------------------------------------------------------------------------------------------------------
Static Function ReportPrint(oReport )
Local oCabec     := oReport:Section(1)
Local oSection1  := oReport:Section(1):Section(1)
Local oSection2  := oReport:Section(1):Section(1):Section(1)
Local aArea      := GetArea()
Local aListaFil  := {}
LOCAL aFilsCalc  := {}
Local nForFilial := 1
Local cFilBack   := cFilAnt
Local cNomeFil   := " "
Local aRetSM0	 := FWLoadSM0()
Local cAliasSL1  := GetNextAlias()
Local nVlrDinh   := 0
Local nVlrInf    := 0
Local nVlrConf   := 0
Local nTotRec    := 0
Local nTotVend   := 0
Local nTotIten   := 0
Local nTotVale   := 0
Local nTotDesc   := 0
Local nDifItem   := 0
Local nDifVend   := 0
aFilsCalc:=Ma330FCalc(.T.,aListaFil)
If !Empty(aFilsCalc)
	For nForFilial := 1 to Len(aFilsCalc)
		If aFilsCalc[nForFilial,1]
			// Altera filial corrente
			cFilAnt:=aFilsCalc[nForFilial,2]
			nPos := aScan(aRetSM0,{|x| x[1]+x[2] == cEmpAnt+cFilAnt})
			cNomeFil := aRetSM0[nPos, 7]
			BeginSQL alias cAliasSL1
				SELECT 
					SUM(L1_DINHEIR) L1_DINHEIR
				FROM
					%table:SL1% SL1
				WHERE
					SL1.L1_FILIAL = %XFilial:SL1%
					AND L1_DTLIM >= %Exp:Dtos(mv_par02)%
					AND L1_DTLIM <= %Exp:Dtos(mv_par03)%
					AND L1_OPERADO >= %Exp:mv_par04%
					AND L1_OPERADO <= %Exp:mv_par05%
					AND L1_FORMPG  = 'R$'
					AND SL1.%NotDel%
			EndSql
			nVlrDinh := (cAliasSL1)->L1_DINHEIR
			(cAliasSL1)->(dbCloseArea())
			BeginSQL alias cAliasSL1
				SELECT 
					AE_DESC, L4_ADMINIS, L4_FORMA, SUM(L4_VALOR) L4_VALOR
				FROM
					%table:SL1% SL1, 
					%table:SL4% SL4, 
					%table:SAE% SAE
				WHERE
					SL1.L1_FILIAL = %XFilial:SL1%
					AND L1_DTLIM >= %Exp:Dtos(mv_par02)%
					AND L1_DTLIM <= %Exp:Dtos(mv_par03)%
					AND L1_OPERADO >= %Exp:mv_par04%
					AND L1_OPERADO <= %Exp:mv_par05%
					AND SL1.%NotDel%
					AND L4_FILIAL = %XFilial:SL4%
					AND L4_DATA = L1_DTLIM
					AND L4_NUM = L1_NUM
					AND SL4.%NotDel%
					AND AE_FILIAL = %XFilial:SAE%
					AND L4_ADMINIS = AE_COD
					AND SAE.%NotDel%
				GROUP BY AE_DESC, L4_ADMINIS, L4_FORMA
				ORDER BY AE_DESC, L4_ADMINIS, L4_FORMA
			EndSql
			// cDebug := GetLastQuery()[2]		//Para debugar a query
			DbSelectArea(cAliasSL1)
			If !Eof() .or. nVlrDinh > 0
				oCabec:Init()
				oSection1:Init()
				oCabec:Cell("CEMPRESA"):SetValue(cNomeFil)
				oCabec:Cell("DDATAINI"):SetValue(mv_par02)
				oCabec:Cell("DDATAFIM"):SetValue(mv_par03)
				oCabec:PrintLine()
				If nVlrDinh > 0
					oSection1:Cell("LOCUNID"):SetValue("Dinheiro")
					oSection1:Cell("NCALCL"):SetValue(nVlrDinh)
					oSection1:Cell("NINFOR"):SetValue(nVlrInf)
					oSection1:Cell("NDIFER"):SetValue(nVlrInf - nVlrDinh)
					oSection1:Cell("NCONFE"):SetValue(nVlrConf)
					oSection1:Cell("NDIFCONF"):SetValue(nVlrConf - nVlrDinh)
					oSection1:PrintLine()
					nTotRec += nVlrDinh
				Endif
				While !Eof()
					oSection1:Cell("LOCUNID"):SetValue((cAliasSL1)->AE_DESC)
					oSection1:Cell("NCALCL"):SetValue((cAliasSL1)->L4_VALOR)
					oSection1:Cell("NINFOR"):SetValue(nVlrInf)
					oSection1:Cell("NDIFER"):SetValue(nVlrInf - (cAliasSL1)->L4_VALOR)
					oSection1:Cell("NCONFE"):SetValue(nVlrConf)
					oSection1:Cell("NDIFCONF"):SetValue(nVlrConf - (cAliasSL1)->L4_VALOR)
					nTotRec += (cAliasSL1)->L4_VALOR
					oSection1:PrintLine()
					DbSelectArea(cAliasSL1)
					dbSkip()
				End
			Endif
			(cAliasSL1)->(dbCloseArea())

			BeginSQL alias cAliasSL1
				SELECT 
					SUM(L1_DESCNF) L1_DESCNF
				FROM
					%table:SL1% SL1
				WHERE
					SL1.L1_FILIAL = %XFilial:SL1%
					AND L1_DTLIM >= %Exp:Dtos(mv_par02)%
					AND L1_DTLIM <= %Exp:Dtos(mv_par03)%
					AND L1_OPERADO >= %Exp:mv_par04%
					AND L1_OPERADO <= %Exp:mv_par05%
					AND SL1.%NotDel%
			EndSql
			nTotDesc := (cAliasSL1)->L1_DESCNF
			(cAliasSL1)->(dbCloseArea())
			BeginSQL alias cAliasSL1
				SELECT 
					SUM(L2_VLRITEM) L2_VLRITEM
				FROM
					%table:SL1% SL1,
					%table:SL2% SL2
				WHERE
					SL1.L1_FILIAL = %XFilial:SL1%
					AND L1_DTLIM >= %Exp:Dtos(mv_par02)%
					AND L1_DTLIM <= %Exp:Dtos(mv_par03)%
					AND L1_OPERADO >= %Exp:mv_par04%
					AND L1_OPERADO <= %Exp:mv_par05%
					AND SL1.%NotDel%
					AND SL2.L2_FILIAL =  %XFilial:SL2%
					AND SL2.L2_NUM = SL1.L1_NUM
					AND SL2.%NotDel%
			EndSql
			nTotIten := (cAliasSL1)->L2_VLRITEM
			(cAliasSL1)->(dbCloseArea())
			oSection2:Init()
			oSection2:Cell("NTOTREC"):SetValue(nTotRec)
			oSection2:Cell("NTOTVEN"):SetValue(nTotVend)
			oSection2:Cell("NTOTITE"):SetValue(nTotIten)
			oSection2:Cell("NTOTCVAL"):SetValue(nTotVale)
			oSection2:Cell("NTOTDESC"):SetValue(nTotDesc)
			oSection2:Cell("NTOTDIFIT"):SetValue(nDifItem)
			oSection2:Cell("NTOTDIFVD"):SetValue(nDifVend)
			oSection2:PrintLine()
			oSection2:Finish()
			oReport:SkipLine()
			oReport:SkipLine()
			oReport:PrintText("_______________________________",oReport:Row(),1000)
			oReport:SkipLine()
			oReport:PrintText("          Gerente",oReport:Row(),1000)
			oReport:SkipLine()
		Endif
		oCabec:Finish()
		oSection1:Finish()
		oReport:EndPage() //-- Salta Pagina
	Next
Endif
cFilAnt := cFilBack
RestArea(aArea)
Return

/*/{Protheus.doc} CancelRpt
//TODO Verifica se o usuario cancelou o processamento/impressão do relatorio
@author reynaldo
@since 21/12/2017
@version 1.0
@return logico, se o usuario cancelou o relatorio
@param oReport, object, Obejto do Treport para impressão do relatorio
@param lEnd, logical, Controle de cancelamento de impressão em versão R3
@type function
/*/
Static Function CancelRpt(oReport,lEnd,lMeter)

Default oReport	:= NIL
Default lEnd	:= .F.
Default lMeter	:= .F.

If oReport == NIL
	If lMeter
		IncRegua()
	EndIf

	If lEnd
		@ PROW()+1,001 PSay "CANCELADO PELO OPERADOR"
	EndIf
Else
	If lMeter
		oReport:IncMeter()
	EndIf
	lEnd := oReport:Cancel()
EndIf

Return lEnd

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o    ³ MA330FCalc                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Autor     ³ Rodrigo de Almeida Sartorio              ³ Data ³ 22/01/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o ³ Funcao para selecao das filiais para calculo por empresa   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros ³ ExpL1 = Indica se apresenta tela para selecao              ³±±
±±³           ³ ExpA2 = Lista com as filiais a serem consideradas (Batch)  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³  Uso      ³ MATA330                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MA330FCalc(lMostratela,aListaFil)
Local aFilsCalc:={}
Local aAreaSM0 :=SM0->(GetArea())
Local aSM0     := FWLoadSM0(.T.,,.T.)
Local lIsBlind := IsBlind()

// Variaveis utilizadas na selecao de categorias
Local oChkQual,lQual,oQual,cVarQ
// Carrega bitmaps
Local oOk      := LoadBitmap( GetResources(), "LBOK")
Local oNo      := LoadBitmap( GetResources(), "LBNO")
// Variaveis utilizadas para lista de filiais
Local nx       := 0
Local nAchou   := 0

Default lMostraTela :=.F.
Default aListaFil   :={}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Carrega filiais da empresa corrente                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aEval(aSM0,{|x| If(x[SM0_GRPEMP] == cEmpAnt .And. (x[SM0_USEROK] .Or. lIsBlind) .And. (x[SM0_EMPOK] .Or. lIsBlind) .And. x[SM0_EMPRESA] == FWCompany(),;
Aadd(aFilsCalc,{If((mv_par01==1 .Or. mv_par01==4),.T.,If(mv_par01==2 .And. x[SM0_CODFIL]==cFilAnt,.T.,.F.)),x[SM0_CODFIL],x[SM0_NOMRED],x[SM0_CGC],.F.}),) } )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta tela para selecao de filiais                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (lMostraTela .And. mv_par01==3)
	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Relatório de Caixa Sintético") STYLE DS_MODALFRAME From 145,0 To 445,628 OF oMainWnd PIXEL
	oDlg:lEscClose := .F.
	@ 05,15 TO 125,300 LABEL OemToAnsi("Marque as filiais a serem impressas") OF oDlg  PIXEL
	@ 15,20 CHECKBOX oChkQual VAR lQual PROMPT OemToAnsi("Inverte Seleção") SIZE 50, 10 OF oDlg PIXEL ON CLICK (AEval(aFilsCalc, {|z| z[1] := If(z[1]==.T.,.F.,.T.)}), oQual:Refresh(.F.))
	@ 30,20 LISTBOX oQual VAR cVarQ Fields HEADER "",OemToAnsi("Filial"),OemToAnsi("Descrição") SIZE 273,090 ON DBLCLICK (aFilsCalc:=CA330Troca(oQual:nAt,aFilsCalc),oQual:Refresh()) NOSCROLL OF oDlg PIXEL
	oQual:SetArray(aFilsCalc)
	oQual:bLine := { || {If(aFilsCalc[oQual:nAt,1],oOk,oNo),aFilsCalc[oQual:nAt,2],aFilsCalc[oQual:nAt,3]}}
	DEFINE SBUTTON FROM 134,240 TYPE 1 ACTION (oDlg:End(),oDlg:End()) ENABLE OF oDlg
	DEFINE SBUTTON FROM 134,270 TYPE 2 ACTION (aFilsCalc := {},oDlg:End()) ENABLE OF oDlg
	ACTIVATE MSDIALOG oDlg CENTERED
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida lista de filiais passada como parametro               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ElseIf mv_par01==1 .Or. mv_par01==4 .Or. (!lMostraTela .And. mv_par01==3)
	// Checa parametros enviados
	For nx:=1 to Len(aListaFil)
		nAchou:=ASCAN(aFilsCalc,{|x| alltrim(x[2]) == alltrim(aListaFil[nx,2])})
		If nAchou > 0
			aFilsCalc[nAchou,1]:=.T.
		EndIf
	Next nx
EndIf
RestArea(aAreaSM0)
Return aFilsCalc
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o    ³ CA330Troca                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Autor     ³ Rodrigo de Almeida Sartorio              ³ Data ³ 12/01/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o ³ Troca marcador entre x e branco                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros ³ ExpN1 = Linha onde o click do mouse ocorreu                ³±±
±±³           ³ ExpA2 = Array com as opcoes para selecao                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³  Uso      ³ MATA330                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function CA330Troca(nIt,aArray)
aArray[nIt,1] := !aArray[nIt,1]
Return aArray
//-------------------------------------------------------------------------------------------------------------
Static Function Gera_SX1(cPerg)

Local i := 0
Local j := 0
dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)
aRegs:={}
AADD(aRegs,{cPerg,"01","Empresa             ?"  ,"","","mv_ch1","N",01,0,0,"C","","mv_par01","Todas as Filiais","Todas as Filiais","Todas as Filiais","","","Filial Corrente","Filial Corrente","Filial Corrente","","","Selec.filiais","Selec.filiais","Selec.filiais","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"02","Da Data             ?"  ,"","","mv_ch2","D",8					  ,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"03","Ate Data            ?"  ,"","","mv_ch3","D",8					  ,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"04","Do Operador         ?"  ,"","","mv_ch4","C",TAMSX3("L1_OPERADO")[1] ,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"05","Ate Operador        ?"  ,"","","mv_ch5","C",TAMSX3("L1_OPERADO")[1] ,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","",""})
For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
Return
