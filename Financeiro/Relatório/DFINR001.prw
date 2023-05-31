#Include "Colors.ch"
#Include "Font.ch"
#Include "TopConn.ch"
#Include "Protheus.ch"

// ----------------------------------------------------
/*/ Rotina RESTGENER
  
    Impressão do relatório de Caixa Sintético.

  @author  Anderson Almeida - TOTVS NE
  @história
   16/03/2022 - Desenvolvimento da Rotina.
/*/
// ----------------------------------------------------
User Function DFINR001()
  Local oReport

  Local cQuery := ""
  Local cPerg  := "DFINR001"
  Local cAlias := GetNextAlias()
  Local cTitle := "Impressão do Relatório Caixa Sintético."
  Local cHelp  := "Impressão do Relatório Caixa Sintético."

  Private cLogoBmp := GetSrvProfString("StartPath","") + "LOGO.png"

  fCriaPrg(cPerg)

  Pergunte(cPerg,.F.)
  
  oReport := ReportDef(cAlias,cPerg,cTitle)

    // ---- Ler dados dos clientes 
     cQuery := "Select ZAE.ZAE_VLAUTO, ZA1.ZA1_NOME, ZA1.ZA1_CPF, ZA1.ZA1_RG, ZA1.ZA1_ORGEMI"
     cQuery += "  from " + RetSQLName("ZAE") + " ZAE, " + RetSQLName("ZA1") + " ZA1"
     cQuery += "   where ZAE.ZAE_FILIAL = '" + xFilial("ZAE") + "'"
     cQuery += "     and ZAE.ZAE_NUM    = '" + aRegInf[1][1] + "'"
     cQuery += "     and ZAE.ZAE_RENEG  = '" + aRegInf[1][2] + "'"
     cQuery += "     and ZA1.ZA1_FILIAL = '" + xFilial("ZA1") + "'"
     cQuery += "     and ZA1.ZA1_COD    = ZAE.ZAE_CLIENT"
     cQuery += "     and ZAE.D_E_L_E_T_ <> '*'"
     cQuery += "     and ZA1.D_E_L_E_T_ <> '*'"
     cQuery := ChangeQuery(cQuery)
     dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),"QCLI",.F.,.T.)

     If QCLI->(Eof())
        Aviso("ATENÇÃO","Não existe dados á imprimir.",{"OK"})
        QCLI->(dbCloseArea())
        Return
     EndIf   
     
     While ! QCLI->(Eof())
       aAdd(aCliImp, {QCLI->ZA1_NOME,;
                      QCLI->ZA1_CPF,;
                      QCLI->ZA1_RG,;
                      QCLI->ZA1_ORGEMI,;
                      QCLI->ZAE_VLAUTO})
                            	            
       QCLI->(dbSkip())
     EndDo

     oReport := TReport():New("CEAP801",cTitle,cPerg,{|| ReportPrint(oReport,cAlias)},cHelp)
  
     oReport:SetPortrait()
     oReport:HideHeader()			    // Não imprime cabecalho padrao do Protheus
     oReport:HideFooter()			    // Não imprime rodape padrao do Protheus
     oReport:HideParamPage()			// inibe impressao da pagina de parametros

     oReport:nfontbody := 10
     oReport:cfontbody := "Arial"     
     
     QCLI->(dbCloseArea())
   else
     oReport := TReport():New("CEAP801",cTitle,cPerg,{|| ReportPrint(oReport,cAlias)},cHelp)
     oReport := ReportDef(cAlias, cPerg, cTitle)
  
     oReport:SetPortrait()
     oReport:HideHeader()			    // Não imprime cabecalho padrao do Protheus
     oReport:HideFooter()			    // Não imprime rodape padrao do Protheus
     oReport:HideParamPage()			// inibe impressao da pagina de parametros

     oReport:nfontbody := 10
     oReport:cfontbody := "Arial"     
  EndIf
  	
  oReport:printDialog()
Return

/*-----------------------------------------------------------
--  Função: Rotina para montagem dos dados do relatório.   --
--                                                         --
-------------------------------------------------------------*/
Static Function ReportPrint(oReport,cAlias)
  Local nId      := 0
  Local oFont10  := TFont():New("Arial",10,10,,.F.,,,,,.F.,.F.)
  Local oFont10N := TFont():New("Arial",10,10,,.T.,,,,,.F.,.F.)
  Local oFont12  := TFont():New("Arial",12,12,,.F.,,,,,.F.,.F.)
  Local oFont12N := TFont():New("Arial",12,12,,.T.,,,,,.F.,.F.)
  
  For nId := 1 To Len(aCliImp)
      oReport:SayBitmap(10,10,cLogoBmp,400,250)
      oReport:Say(030,450,"Centro de Apoio aos Pequenos Empreendimentos de Pernambuco (" + AllTrim(SM0->M0_FILIAL) + ")",oFont10N)
      oReport:Say(080,450,AllTrim(SM0->M0_ENDENT) + " - " + AllTrim(SM0->M0_BAIRENT) + " - " + AllTrim(SM0->M0_CIDENT) +;
                      "/" + AllTrim(SM0->M0_ESTENT),oFont10)
      oReport:Say(130,450,"Fone: " + AllTrim(SM0->M0_TEL) + " - CNPJ: " + Transform(SM0->M0_CGC,"@R 99.999.999/9999-99") + " - www.ceape-pe.org.br",oFont10)

      oReport:Say(0551,0158,"Ao",oFont12,,0)
      oReport:Say(0597,0158,cBanco,oFont12N,,0)
  
      oReport:Say(0780,0231,"Solicitamos efetuar o pagamento no valor de R$ " + Transform(aCliImp[nId][5], "@E 999,999.99" ) + ;
                         " ("+LOWER(Extenso(aCliImp[nId][5]))+" ) através de ",oFont12,,0)
  
      oReport:Say(0826,0158,"contra-recibo (ordem de pagamento) ao nosso cliente Sr.(a) " + aCliImp[nId][1],oFont12,,0)  
      oReport:Say(0873,0158,"que se identificará através do RG n. " + aCliImp[nId][3] + " " + aCliImp[nId][4] + ", CPF: " + ;
                         Transform(aCliImp[nId][2],"@R 999.999.999-99") + " referente",oFont12,,0)
      oReport:Say(0920,0158,"à liberação de empréstimo concedido por esta empresa.",oFont12,,0)
 
      oReport:Say(1124,1092,"Atenciosamente,",oFont12,,0)
      oReport:Say(1297,1365,"CEAPE/PE - " + AllTrim(SM0->M0_FILIAL),oFont12,,0)
      oReport:Say(1344,1344,"Fone: "+AllTrim(SM0->M0_TEL),oFont12,,0)
      oReport:Box(1284,1092,1286,1932)
  
      oReport:EndPage()
   Next   
Return

//--------------------------------------------------
/*/Função fCriaPrg

  Função para criação das perguntas
  						  
  @version P12.1.27
  @since 28/02/2022	
/*/
//--------------------------------------------------
Static Function fCriaPrg(cPerg)
  Local aAreaSX1 := SX1->(GetArea())
  Local nJ		 := 0
  Local nY       := 0
  Local aRegs    := {}

  aAdd(aRegs,{cPerg,"01","Filial De ?","","","mv_ch1","C",04,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"02","Filial Até ?","","","mv_ch1","C",04,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","",""})

  aAdd(aRegs,{cPerg,"01","Filial ?"    ,"","","mv_ch1","C",TamSX3("NNR_CODIGO")[1],0,0,"G","NaoVazio() .and. ExistCPO('NNR',MV_PAR01)","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","NNR","","","",""})
  aAdd(aRegs,{cPerg,"02","Serviço De ?" ,"","","mv_ch2","C",TamSX3("C4_XSERVIC")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","SX5SV","","","",""})
  aAdd(aRegs,{cPerg,"03","Serviço Até ?","","","mv_ch3","C",TamSX3("C4_XSERVIC")[1],0,0,"G","","MV_PAR03","","","","ZZZZ","","","","","","","","","","","","","","","","","","","","","SX5SV","","","",""})
  aAdd(aRegs,{cPerg,"04","Data De ? "   ,"","","mv_ch4","D",8                      ,0,0,"G","NaoVazio()","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"05","Data Até ? "  ,"","","mv_ch5","D",8                      ,0,0,"G","NaoVazio()","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

  dbSelectArea("SX1")
  SX1->(dbSetOrder(1))

  For nY := 1 To Len(aRegs)
	  If ! SX1->(dbSeek(padr(cPerg,10)+aRegs[nY][02]))
		 RecLock("SX1",.T.)
            For nJ := 1 To FCount()
				If nJ <= Len(aRegs[nY])
				   FieldPut(nJ,aRegs[nY][nJ])
				EndIf
			Next
		 SX1->(MsUnlock())
	  EndIf
  Next

  RestArea(aAreaSX1)
Return
