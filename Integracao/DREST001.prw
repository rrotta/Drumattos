#Include "TOTVS.ch"
#Include "RESTFUL.ch"
#Include "FWMVCDEF.ch"
#Include "TOPCONN.ch"
#Include "RETAILSALESAPI.CH"

// ---------------------------------------------------------
/*/ Rotina DREST001

  WebService REST para integração com o módulo Faturamento 
  e Financeiro.

  @Parâmetro Recebe parâmetros (Requisição em REST)
  @Retorno Confirmação
  @Author Anderson Almeida (TOTVS NE)
  Retorno
  @História 
    08/07/2021 - Desenvolvimento da Rotina.
/*/
// ---------------------------------------------------------
WsRestFul DREST001 Description "API Generica Protheus"

  WsMethod Get  Description "Consulta tabela Protheus" WSSYNTAX "/api/retail/v1/DREST001" PATH "/api/retail/v1/DREST001"
  WsMethod Post Description "Inclusao no PROTHEUS" WSSYNTAX "/api/retail/v1/DREST001" PATH "/api/retail/v1/DREST001"

End WsRestFul

//--------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} DREST001

  Get - Ler informação do PROTHEUS.
  						  
  @version P12.1.27
  @since 14/09/2021	
/*/
//--------------------------------------------------
WsMethod Get WsReceive RECEIVE WsService DREST001
  Local lRet     := .F.
  Local oJson	  := THashMap():New()
  Local cMsg     := ""
  Local cJsonRet := ""
  Local cBody    := ""

  ::SetContentType("application/json")

  cBody := Self:GetContent()
  lRet  := FWJsonDeserialize(cBody,@oJson)

  If lRet
	   lRet := fnR01Ler(oJson, @cJsonRet, @cMsg)
   else	
	   cMSg := "JSon Error"	
  EndIf

  If ! lRet
     SetRestFault(400, cMsg)
   else
	   ::SetResponse(cJsonRet)	
  EndIf
Return lRet

//-----------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} DREST001

  Post - Gravação de dados.

  @version P12.1.27
  @since 14/09/2021	
/*/
//-----------------------------------------------------
WsMethod Post WSReceive RECEIVE WsService DREST001
  Local oJson	   := THashMap():New()
  Local cMensag  := ""
  Local cJsonRet := ""
  Local cJson    := ""
  Local lRet     := .T.

  Private lMsErroAuto    := .F.
  Private lAutoErrNoFile := .T.
  Private lMsHelpAuto    := .T.
  
  ::SetContentType("application/json")
  
  cBody := Self:GetContent()
  lRet  := FWJsonDeserialize(cBody, @oJson)

  If lRet   
     lRet := fnR01Grv(oJson, @cJson, @cMensag)
   
     cJsonRet := '{ "Ret": ['
	  cJsonRet += IIf(! Empty(cMensag),cMensag,cJson)
	  cJsonRet += '] }'
   else	
	  cJsonRet := "JSon Erro"	
  EndIf

  If ! lRet
     SetRestFault(400, cJsonRet)
   else
	  ::SetResponse(cJsonRet)	
  EndIf
Return lRet

//-----------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} DREST001
  Função fnR01Lote
   Gravação Análise de Mercado - Lote

  @Author Anderson Almeida (TOTVS Ne)
  @Parâmetro: oJson	   , objeto
              cJsonRet , String - JSon Retorno
  	          cMensag  , String - Msg Retorno
	
  @Retorno lOk , logico		
  @História
   01/07/2021 - Desenvolvimento da Rotina.
/*/
//-----------------------------------------------------
Static Function fnR01Grv(oJson, cJson, cMensag)
  Local lOk	  	   := .T.
  Local lMVC      := .F.
  Local lLerSL1   := .T.
  Local aArea     := GetArea()
  Local aRet      := {.T.,{}}
  Local aLog	   := {}
  Local aCab      := {}
  Local aItem1    := {}
  Local aItem2    := {}
  Local aItens    := {}
  Local aParcela  := {}
  Local aRJson    := {}
  Local aRegSE5   := {}
  Local aRegSD1   := {}
  Local aRegSE2   := {}
  Local aTitulos  := {}
  Local aCupons   := {}
  Local nX        := 0
  Local nY	      := 0
  Local nY1	      := 0
  Local nPos      := 0
  Local nPos1     := 0
  Local nOpcao    := 0
  Local cIDRot    := ""
  Local cLog	   := ""
  Local cDesChv   := ""
  Local cChave    := ""
  Local cAux      := ""
  Local cJSonAux  := "" 
  Local cCupom    := ""
  Local cSerie    := ""
  Local cDocto    := ""
  Local cChvNFe   := ""
  Local cCodClie  := ""
  Local cLojClie  := ""
  Local cCodForn  := ""
  Local cLojForn  := ""
  Local cPDV      := ""
  Local cModDoc   := ""
  Local cOperador := ""
  Local cNaturOri := ""
  Local cNaturDes := ""
  Local cAdmCar   := ""
  Local cFormaPag := ""
  Local cTpRotina := ""
  Local cDcRotina := "" 
  Local cDcOper   := ""  
  Local cIdLog    := ""
  Local dEmisNFe  := SToD("")
  Local oItem     := Nil

  Private aDados    := {}
  Private aPagtos   := {}
  Private cLogError := ""
  Private INCLUI    := .T. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
  Private ALTERA    := .F. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
 
  If AttIsMemberOf(oJson, "company")	
     cQuery := "Select M0_CODIGO, M0_CODFIL from SYS_COMPANY"
     cQuery += "  where D_E_L_E_T_ <> '*'"
     cQuery += "    and M0_CGC = '" + oJson:company + "'"
     cQuery := ChangeQuery(cQuery)
     dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSM0",.F.,.T.)

     If QSM0->(Eof())
        cMensag := "CNPJ não cadastrado."
        lOk     := .F.

        QSM0->(dbCloseArea())

        Return .T.
      else
        cEmpAnt := QSM0->M0_CODIGO
        cFilAnt := AllTrim(QSM0->M0_CODFIL)
           
        QSM0->(dbCloseArea())

        cNaturOri := SuperGetMv("MV_LJTRNAT",.F.,"")
        cNaturDes := SuperGetMv("MV_LJTRNAT",.F.,"")  
     EndIf     
   else
     cMensag := "CNPJ não informado."
     lOk     := .F.

     Return .T.
  EndIf       
  
  If AttIsMemberOf(oJson, "id") 	
     cIDRot := oJson:id
   else
     cMensag := "ID Rotina não enviado"
     lOk     := .F.

     Return .T.
  EndIf	

  If AttIsMemberOf(oJson, "opcao") 	
	  nOpcao := oJson:opcao
  EndIf

  If AttIsMemberOf(oJson,"itens") 
	  oItem  := oJson:itens  
	  aDados := {}

     For nX := 1 To len(oItem) 
         Do Case
            Case cIDRot == "ENCERRA"
                 aRJson := {}
            
                 aAdd(aRJson, {"CBCOORIG"   , oJson:Itens[nX]:Data[01]:BCOORIGEM         ,Nil})
                 aAdd(aRJson, {"CAGENORIG"  , oJson:Itens[nX]:Data[02]:AGENORIGEM        ,Nil})
                 aAdd(aRJson, {"CCTAORIG"   , oJson:Itens[nX]:Data[03]:CCTAORIGEM        ,Nil})
                 aAdd(aRJson, {"CNATURORI"  , cNaturOri                                  ,Nil})
                 aAdd(aRJson, {"CBCODEST"   , oJson:Itens[nX]:Data[04]:BCODESTINO        ,Nil})
                 aAdd(aRJson, {"CAGENDEST"  , oJson:Itens[nX]:Data[05]:AGENDESTINO       ,Nil})
                 aAdd(aRJson, {"CCTADEST"   , oJson:Itens[nX]:Data[06]:CCTADESTINO       ,Nil})
                 aAdd(aRJson, {"CNATURDES"  , cNaturDes                                  ,Nil})
                 aAdd(aRJson, {"CTIPOTRAN"  , oJson:Itens[nX]:Data[07]:TIPOTRANSF        ,Nil})
                 aAdd(aRJson, {"CDOCTRAN"   , oJson:Itens[nX]:Data[08]:NUMERO            ,Nil})
                 aAdd(aRJson, {"NVALORTRAN" , oJson:Itens[nX]:Data[09]:VALOR             ,Nil})
                 aAdd(aRJson, {"CHIST100"   , oJson:Itens[nX]:Data[10]:HISTORICO         ,Nil})
                 aAdd(aRJson, {"CBENEF100"  , oJson:Itens[nX]:Data[11]:BENEFICIARIO      ,Nil})
                 aAdd(aRJson, {"DATACREDITO", CToD(oJson:Itens[nX]:Data[12]:DATACREDITO) ,Nil})
         
                 aAdd(aDados, {aRJson,;    // 01 = Cabeçalho
                               {},;        // 02 = Item 1 
                               {}})        // 03 = Item 2

            OtherWise
	              aRet := fnR01Req(oItem[nX])
		           lOk  := aRet[01]

		           If ! lOk
		              exit	
		           EndIf   

                 aAdd(aDados, {aRet[02],;    // 01 = Cabeçalho
                               aRet[03],;    // 02 = Item 1 
                               aRet[04]})    // 03 = Item 2
         EndCase
	  Next
   else
     lOk := .F.
  Endif

  If ! lOk
  	  cMensag += "ERRO na estrutura da requisição"

     Return .F.
  EndIf

  If lOk
	  For nX := 1 To Len(aDados)
		   lMsErroAuto := .F.
 	      cLog        := ""
         cDesChv     := ""
         cChave      := ""
	 	   aCab 		   := aDados[nX][01]
		   aItem1		:= aDados[nX][02]
         aItem2      := aDados[nX][03]
         aItens      := {}
           
		   Do Case
           // -- Cliente
           // ----------------------
            Case cIDRot == "MATA030"
                 cTpRotina := "CLIENTE"
                 cDcRotina := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_LOJA"})) > 0
                    cDcRotina += "Loja " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

				     dbSelectArea("SA1")
				     SA1->(dbSetOrder(1))

		           MsExecAuto({|x,y| CRMA980(x,y)}, aCab, nOpcao)

           // -- Vendedor
           // ----------------------
            Case cIDRot == "MATA040"
                 cTpRotina := "VENDEDOR"
                 cDcRotina := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "A3_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A3_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

				     dbSelectArea("SA3")
				     SA3->(dbSetOrder(1))

                 MsExecAuto({|x,y| MATA040(x,y)}, aCab, nOpcao)

           // -- Operador (Banco)
           // ----------------------
            Case cIDRot == "MATA070"
                 cTpRotina := "OPERADOR"
                 cDcRotina := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "A6_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A6_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

				     dbSelectArea("SA6")
				     SA6->(dbSetOrder(1))

                 MsExecAuto({|x,y| MATA070(x,y)}, aCab, nOpcao)

           // -- Forma de Pagamento (Administradoras Financeiras) 
           // ---------------------------------------------------
            Case cIDRot == "LOJA070"
                 cTpRotina := "ADMINISTRADORAS FINANCEIRAS"
                 cDcRotina := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_DESC"})) > 0
                    cDcRotina += "Descricao " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_TIPO"})) > 0
                    cDcRotina += "Tipo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

				     dbSelectArea("SAE")
				     SAE->(dbSetOrder(1))

                 If nOpcao == 4
                    nPos := aScan(aItem1, {|x| x[01] == "MEN_ITEM"})
				
                    If nPos > 0
                       nPos1 := aScan(aCab, {|x| x[01] == "AE_COD"})
                    
                       If nPos1 > 0
                          dbSelectArea("MEN")
				              MEN->(DbSetOrder(1))
				
                          If MEN->(dbSeek(FWxFilial("MEN") + aItem1[nPos][02] + aCab[nPos1][02]))
					              aAdd(aItem1, {"LINPOS"   ,"MEN_ITEM",aItem1[nPos][02]})
				 	              aAdd(aItem1, {"AUTDELETA","N"       ,Nil})
                           else
                             cLog := "Não encontrou a Administradora para alteração."  
	                  	  EndIf
                        else
                          cLog := "Não encontrou a Administradora na requisição para alteração."
                       EndIf
                    EndIf   
                 EndIf

                 If Empty(cLog)
                    aAdd(aItens, aClone(aItem1))
                 
                    MsExecAuto({|a,b,c| LOJA070(a,b,c)}, aCab, aItens, nOpcao)
                 EndIf

           // -- Vendas (Inclusão / Cancelamento)
           // -----------------------------------
		      Case cIDRot == "LOJA701"
			       // --- aCab   = Cabeçalho do orçamento (SLQ)
				    // --- aItem1 = Itens do orçamento (SLR)
				    // --- aItem2 = Formas de Pagamento (SL4)
		   	    // -----------------------------------------
                 cTpRotina := "VENDAS"
                 cLog      := ""
				     aItens    := {}
                 aParcela  := {}

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_NUMCFIS"})) > 0
                    cCupom := AllTrim(aCab[nPos][02])
                 EndIf
                 
                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_SERIE"})) > 0
                    cSerie := AllTrim(aCab[nPos][02])
                 EndIf

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_PDV"})) > 0
                    cPDV := aCab[nPos][02]
                 EndIf

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_OPERADO"})) > 0
                    cOperador := aCab[nPos][02]
                 EndIf

                 cDcRotina := "Cupom " + cCupom + " Serie " + cSerie + " PDV " + cPDV + " Operador " + cOperador

                 If Empty(cOperador)         // -- Validar Operador
                    cLog := "Operador não informado no Cupom: " + AllTrim(cCupom) + " do PDV: " + AllTrim(cPDV)
                  else  
                    dbSelectArea("SA6")
                    SA6->(dbSetOrder(1))

                    If ! SA6->(dbSeek(FWxFilial("SA6") + cOperador))
                       cLog := "Operador não cadastrado - " + AllTrim(cOperador) + " do Cupom: " + AllTrim(cCupom) + " do PDV: " + AllTrim(cPDV)
                     else
                       For nY := 1 To Len(aItem1)
                           aAdd(aItens, {})

                           For nY1 := 1 To Len(aItem1[nY])
                               aAdd(aItens[Len(aItens)], {aItem1[nY][nY1][1],;
                                                          aItem1[nY][nY1][2],;
                                                          aItem1[nY][nY1][3]})
                           Next
                       Next
                 
                       For nY := 1 To Len(aItem2)
                           cAdmCar   := ""
                           cFormaPag := ""

                           aAdd(aParcela, {})
                 
                           For nY1 := 1 To Len(aItem2[nY])
                               If AllTrim(aItem2[nY][nY1][01]) == "L4_ADMINIS"
                                  cAdmCar := aItem2[nY][nY1][02]

                                elseIf AllTrim(aItem2[nY][nY1][01]) == "L4_FORMA"
                                       cFormaPag := AllTrim(aItem2[nY][nY1][02])
                               EndIf            

    				                aAdd(aParcela[Len(aParcela)], {aItem2[nY][nY1][1],;
                                                              aItem2[nY][nY1][2],;
                                                              aItem2[nY][nY1][3]})
                           Next     

                           If cFormaPag $ ("CC/CD")
                              If Empty(cAdmCar)
                                 cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " + AllTrim(cPDV) +;
                                         " Item " + AllTrim(Str(nY)) + ": Pagamento com cartão sem ADMINISTRADORA."
                                 Exit
                              EndIf
                            elseIf Empty(cFormaPag)
                                   cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " + AllTrim(cPDV) +;
                                           " Item " + AllTrim(Str(nY)) + ": Pagamento sem informar a FORMA."
                                 Exit
                           EndIf                             
                       Next
                    EndIf   
                 EndIf

                 If Empty(cLog)
                    If Len(aParcela) == 0
                       cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " + AllTrim(cPDV) +;
                               ": Sem PAGAMENTO informado."
                     else          
                       dbSelectArea("SL1")
                       SL1->(dbSetOrder(2))

                       lLerSL1 := SL1->(dbSeek(FWxFilial("SL1") + PadR(cSerie,TamSX3("L1_SERIE")[1]) +;
                                               PadR(cCupom,TamSX3("L1_DOC")[1]) + PadR(cPDV,TamSX3("L1_PDV")[1])))

                       If nOpcao == 3
                          If lLerSL1
                             cLog := "Venda já cadastrada: Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " + AllTrim(cPDV)
                           else 
                             MSExecAuto({|a,b,c,d,e,f,g,h,i,j| Loja701(a,b,c,d,e,f,g,h,i,j)},.F.,3,"","",{},aCab,aItens,aParcela,.F.,.T.)
                          EndIf

                        elseIf nOpcao == 6
                               If lLerSL1
                                  If SL1->L1_SITUA <> "OK"
                                     cLog := "Venda ainda não processa: Serie - " + AllTrim(cSerie) + " Cupom - " +;
                                             AllTrim(cCupom) + " PDV - " + AllTrim(cPDV)
                                   else
                                     CANCUPOM(SL1->L1_FILIAL, SL1->L1_NUM, SL1->L1_OPERADO, SL1->L1_DOC, SL1->L1_SERIE, @cLog)
                                  EndIf   
                                else
                                  cLog := "Venda não encontrada: Serie - " + AllTrim(cSerie) + " Cupom - " +;
                                          AllTrim(cCupom) + " PDV - " + AllTrim(cPDV)
                               EndIf        
                       EndIf
                    EndIf
                 EndIf   

           // -- Encerramento de Caixa                      
           // ------------------------
            Case cIDRot == "ENCERRA"
                 cTpRotina   := "ENCERRA"
                 lMsErroAuto := .F.
                 aRegSE5     := {}
                 cDcRotina   := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "CBCOORIG"})) > 0
                    cDcRotina += "Banco Origem " + AllTrim(aCab[nPos][02]) + " "
                 EndIf

                 If (nPos := aScan(aCab, {|x| x[01] == "CBCODEST"})) > 0
                    cDcRotina += "Banco Destino " + AllTrim(aCab[nPos][02]) + " "
                 EndIf

                 If (nPos := aScan(aCab, {|x| x[01] == "CTIPOTRAN"})) > 0
                    cDcRotina += "Tipo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf

                 If (nPos := aScan(aCab, {|x| x[01] == "CDOCTRAN"})) > 0
                    cDcRotina += "Documento " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   
                  
                 If Len(aCab) < 14
                    cLog := "ERRO ESTRUTURA - Falta tag na requisição."
                  else  
                    For nY := 1 To 13
                        aAdd(aRegSE5, {aCab[nY][01], aCab[nY][02] ,Nil})
                    Next

                    dDataBase := aCab[14][02]
                    
                    FWSM0Util():setSM0PositionBycFilAnt()       // Método estático que posiciona a SM0 de acordo: cEmpAnt e cFilAnt

                    MsExecAuto({|x,y,z| FINA100(x,y,z)},0,aRegSE5,7)

                    dDataBase := Date()
                 EndIf

           // -- Inutilização de Cupom Fiscal
           // -------------------------------
            Case cIDRot == "INUTILIZAR"
                 cTpRotina := "INUTILIZACAO CUPOM"

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LX_CUPOM"})) > 0
                    cCupom := AllTrim(aCab[nPos][02])
                 EndIf
                 
                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LX_SERIE"})) > 0
                    cSerie := AllTrim(aCab[nPos][02])
                 EndIf

                 cDcRotina := "Cupom " + cCupom + " Serie " + cSerie

                 cQuery := "Select SLX.R_E_C_N_O_ as RECNO from " + RetSqlName("SLX") + " SLX"
                 cQuery += "  where SLX.D_E_L_E_T_ <> '*'"
                 cQuery += "    and SLX.LX_FILIAL  = '" + FWxFilial("SLX") + "'"
                 cQuery += "    and SLX.LX_CUPOM   = '" + cCupom + "'"
                 cQuery += "    and SLX.LX_SERIE   = '" + cSerie + "'"
                 cQuery += "    and SLX.LX_MODDOC  = '" + cModDoc + "'"
                 cQuery := ChangeQuery(cQuery)
                 dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSLX",.F.,.T.)

                 If ! QSLX->(Eof())
                    cLog := "ATENÇÃO - Inutilização já realizada."
                  else 
                    Reclock("SLX",.T.)
                      Replace SLX->LX_FILIAL with FWxFilial("SLX")
                      Replace SLX->LX_TPCANC with "X"

                  	 For nY := 1 To Len(aCab)
                          Replace SLX->(&(aCab[nY][01])) with aCab[nY][02]
                      Next     
                    SLX->(MsUnlock())
                 EndIf

                 QSLX->(dbCloseArea())

		     // -- Documento de Entrada
		     // -----------------------
			   Case cIDRot == "MATA103"
                 cTpRotina := "DOCUMENTO DE ENTRADA"
                 cLog      := ""

                 If nOpcao <> 3 .and. nOpcao <> 5
                    cLog := VarInfo("ERRO","Opção inválida para essa rotina.") 
                  else                           
                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_DOC"})) > 0
                       cDocto := AllTrim(aCab[nPos][02])
                    EndIf
                 
                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_SERIE"})) > 0
                       cSerie := AllTrim(aCab[nPos][02])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_CHVNFE"})) > 0
                       cChvNFe := AllTrim(aCab[nPos][02])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_FORNECE"})) > 0
                       cCodForn := AllTrim(aCab[nPos][02])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_LOJA"})) > 0
                       cLojForn := AllTrim(aCab[nPos][02])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_EMISSAO"})) > 0
                       dEmisNFe := aCab[nPos][02]

                       If Len(aPagtos) == 0 .or.;
                          (nPos := aScan(aPagtos, {|x| x[01] == cDocto .and. x[02] == cSerie .and. x[03] == cCodForn .and. x[04] == cLojForn})) == 0 
                          cLog := "Dados do Pagamento da Nota Fiscal não informada."
                       EndIf
                     else
                       cLog := "Data de Emissão da Nota Fiscal não informada."  
                    EndIf

                    cDcRotina := "NFe Serie " + cSerie + " Numero " + cDocto + " Chave " + cChvNFe + " Emissao " + DToC(dEmisNFe) 

                    If Empty(cLog)
                       aAdd(aCab,{"E2_NATUREZ",Posicione("SA2",1,FWxFilial("SA2") + PadR(cCodForn,TamSX3("A2_COD")[1]) +;
                                               PadR(cLojForn,TamSX3("A2_LOJA")[1]),"A2_NATUREZ"),Nil})
                
			              aRegSD1     := aItem1
                       lMsErroAuto := .F.

                       MsExecAuto({|x,y,z| MATA103(x,y,z)},aCab,aRegSD1,nOpcao)

                       If ! lMsErroAuto .and. nOpcao == 3
                         // -- Inclusão Contas a Pagar
                         // --------------------------
                          If (nPos := aScan(aPagtos, {|x| x[01] == cDocto .and. x[02] == cSerie .and. x[03] == cCodForn .and. x[04] == cLojForn})) > 0
                             Begin Transaction
                               cQuery := "Delete from " + RetSqlName("SE2") 
                               cQuery += "  where D_E_L_E_T_ <> '*'"
                               cQuery += "    and E2_FILIAL  = '" + FWxFilial("SE2") + "'"
                               cQuery += "    and E2_PREFIXO = '" + cSerie + "'"
                               cQuery += "    and E2_NUM     = '" + cDocto + "'"
                               cQuery += "    and E2_FORNECE = '" + cCodForn + "'"
                               cQuery += "    and E2_LOJA    = '" + cLojForn + "'"

                               TCSQLExec(cQuery)

                               aTitulos    := StrTokArr2(aPagtos[nPos][05],";") 
                               lMsErroAuto := .F.
                               nPos        := 1

                               For nY := 1 To Len(aTitulos) Step 2
                                   aRegSE2 := {}

                                   aAdd(aRegSE2,{"E2_PREFIXO", cSerie               , NIL})
                                   aAdd(aRegSE2,{"E2_NUM"    , cDocto               , NIL})
                                   aAdd(aRegSE2,{"E2_PARCELA", IIf(Len(aTitulos) > 2,StrZero(nPos,TamSX3("E2_PARCELA")[1]),""), Nil})
                                   aAdd(aRegSE2,{"E2_TIPO"   , "NF"                 , NIL})
                                   aAdd(aRegSE2,{"E2_FORNECE", cCodForn             , NIL})
                                   aAdd(aRegSE2,{"E2_LOJA"   , cLojForn             , NIL})
                                   aAdd(aRegSE2,{"E2_NATUREZ", Posicione("SA2",1,FWxFilial("SA2") + PadR(cCodForn,TamSX3("A2_COD")[1]) +;
                                                                              PadR(cLojForn,TamSX3("A2_LOJA")[1]),"A2_NATUREZ"), NIL})
                                   aAdd(aRegSE2,{"E2_EMISSAO", dEmisNFe             , NIL})
                                   aAdd(aRegSE2,{"E2_VENCTO" , CToD(aTitulos[nY])   , NIL})
                                   aAdd(aRegSE2,{"E2_VENCREA", CToD(aTitulos[nY])   , NIL})
                                   aAdd(aRegSE2,{"E2_VALOR"  , Val(aTitulos[nY + 1]), NIL})
                                   aAdd(aRegSE2,{"E2_ORIGEM" , "MATA100"            , Nil})

                                   MsExecAuto({|x,y,z| FINA050(x,y,z)},aRegSE2,,3)

                                   nPos++

                                   If lMsErroAuto
                                      DisarmTransaction()
                                      exit
                                   Endif
                               Next   
                             End Transaction
                          EndIf
                         // ----------------------------- 
                       EndIf
                    EndIf
                 EndIf 

  		     // -- Emissão Nfe Subre Cupom
		     // --------------------------
			   Case cIDRot == "LOJR130"
                 cTpRotina := "Nfe x Cupom"
                 cLog      := ""
                 aCupons   := {}

                 If (nPos := aScan(aCab, {|x| x[01] == "F2_SERIE"})) > 0
                    cDcRotina := "Emissão Nfe " + AllTrim(aCab[nPos][02]) + " / "
                 EndIf 

                 If (nPos := aScan(aCab, {|x| x[01] == "F2_DOC"})) > 0
                    cDcRotina +=  AllTrim(aCab[nPos][02]) + " sobre Cupom."
                 EndIf 
                 
                 If (nPos := aScan(aCab, {|x| x[01] == "F2_CLIENTE"})) > 0
                    cCodClie := AllTrim(aCab[nPos][02])
                  else
                    cLog := "Cliente para emissão da Nfe não informado."
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "F2_LOJA"})) > 0
                    cLojClie := AllTrim(aCab[nPos][02])
                  else
                    cLog := "Loja do Cliente para emissão da Nfe não informada."
                 EndIf 

                 If (nPos := aScan(aCab, {|x| x[01] == "F2_DOC"})) > 0
                    cDocto := StrZero(Val(AllTrim(aCab[nPos][02])),TamSX3("F2_DOC")[1])
                  else
                    cLog := "Número da Nfe não informada."
                 EndIf 

                 If (nPos := aScan(aCab, {|x| x[01] == "F2_SERIE"})) > 0
                    cSerie := AllTrim(aCab[nPos][02])
                  else
                    cLog := "Série da Nfe não informada."
                 EndIf 

                 If Len(aItem1) == 0
                    cLog := "Cupons não informados."
                 EndIf 
  
                 If Empty(cLog)
                    If nOpcao == 3
                      // -- Alteração o parâmetro de numeração da Nfe
                      // --------------------------------------------
                       dbSelectArea("SX5")
                       SX5->(dbSetOrder(1))

                       If ! SX5->(dbSeek(FWxFilial("SX5") + "01" + cSerie))
                          cLog := "Série " + cSerie + " informada não cadastrada."
                        else  
                          RecLock("SX5",.F.)
                            Replace SX5->X5_DESCRI  with cDocto 
                            Replace SX5->X5_DESCSPA with cDocto 
                            Replace SX5->X5_DESCENG with cDocto 
                          SX5->(MsUnlock())
                       EndIf
                    EndIf

                   // -- Adiciona os cupons para geração da nota
                   // ------------------------------------------
                    If Empty(cLog)
                       For nY := 1 To Len(aItem1)
                           For nPos := 1 To Len(aItem1[nY])
                               If aItems1[nY][nPos][01] == "L1_DOC"
                                  cCupom := aItems1[nY][nPos][02]

                                elseIf aItems1[nY][nPos][01] == "L1_SERIE"
                                       cSerie := aItems1[nY][nPos][02]
                               EndIf
                           Next
                             
                           aAdd(aCupons,{cCupom,;
                                         cSerie,;
                                         cCodClie,;
                                         cLojClie})
                       Next

                       LojR130(aCupons,IIf(nOpcao == 3,.T.,IIf(nOpcao == 6,.F.,Nill)),cCodClie,cLojClie)   // nOpcao: 3 = Geração ou 6 = Estorno
                    EndIf
                 EndIf  
         EndCase

         If cIDRot == "MATA103" .and. (! Empty(cLog) .or. lMsErroAuto)
            cJsonAux := cLog
            cLog     := "Serie - " + cSerie + Chr(10) + Chr(13)
            cLog     += "N. NFe - " + cDocto + Chr(10) + Chr(13)
            cLog     += "Chave - " + cChvNfe + Chr(10) + Chr(13)
            cLog     += "Fornecedor - " + cCodForn + Chr(10) + Chr(13)
            cLog     += "Loja - " + cLojForn + Chr(10) + Chr(13)
            cLog     += "Emissao - " + DToC(dEmisNFe) + Chr(10) + Chr(13)
            cLog     += IIf(Empty(cJsonAux),"","MENSAGEM " + cJsonAux)
         EndIf   

		   If lMsErroAuto
            If ! lMVC
			      aLog := GetAutoGRLog()

			      For nY := 1 To Len(aLog)
			          cAux := Alltrim(aLog[nY])
			          cAux := StrTran(cAux,"  "," ")
			          cAux := StrTran(cAux,chr(10),"")
			          cAux := StrTran(cAux,chr(13),"")
                   cLog += EncodeUTF8(cAux) + Chr(10) + Chr(13)
			      Next

            EndIf  	
         EndIf

         If ! Empty(cLog)
         	cJSonAux := ""
			   cJSonAux += '{ "status" : 401,'
			   cJSonAux += '  "msg" : "' + EncodeUTF8(cLog) + '" }'
			 else
            cJSonAux := ""
			   cJSonAux += '{ "status" : 201,'
			   cJSonAux += '  "msg" : "sucesso"' 
            
            If ! Empty(cChave)
               cJsonAux += ','
               cJsonAux += '  "' + cDesChv + '" : ' + cChave
            EndIf

            cJsonAux += '}'
		   EndIf		

		   cJson += cJSonAux

		   If nX < Len(aDados)
			   cJson += ","
		   EndIf

        // -- Gravar o Log de Processamento
        // --------------------------------
         Do Case
            Case nOpcao == 3
                 cDcOper := "INCLUSAO"

            Case nOpcao == 4
                 cDcOper := "ALTERACAO"

            Case nOpcao == 5
                 cDcOper := "EXCLUSAO" 

            Case nOpcao == 6
                 cDcOper := "CANCELAMENTO"              

            OtherWise
                 cDcOper := "SEM DEFINICAO"
         EndCase
         
        	cIdLog := GETSX8NUM("SZ1","Z1_ID")

         Reclock("SZ1",.T.)
           Replace SZ1->Z1_FILIAL  with FWxFilial("SZ1")
			  Replace SZ1->Z1_ID      with cIdLog
           Replace SZ1->Z1_FILDEST with cFilAnt
           Replace SZ1->Z1_DATA    with dDataBase
           Replace SZ1->Z1_HORA    with Time()
           Replace SZ1->Z1_ROTINA  with cIDRot
           Replace SZ1->Z1_DESC    with cTpRotina
           Replace SZ1->Z1_DOCTO   with cDcRotina
           Replace SZ1->Z1_OPERACA with nOpcao
           Replace SZ1->Z1_DSCOPER with cDcOper
           Replace SZ1->Z1_MENSAG  with IIf(Empty(cLog),"SUCESSO",DecodeUTF8(cLog))
           Replace SZ1->Z1_STATUS  with IIf(Empty(cLog),"S","E")
         SZ1->(MsUnlock())

			ConfirmSX8()
        // -------------------------------- 	
	  Next
   else
	  cMensag += "Não foi possivel realizar a operação solicitada."
  EndIf

  RestArea(aArea)
Return lOk

//--------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} VWSV0001
  Função CANCUPOM

    Cancelamento da Venda

  @Parâmetro cL1Filial,cL1Num,cL1Operado,cL1Doc
  @Retorno lRet = logico
  @História
   10/04/2022 - Desenvolvimento da rotina.
/*/
//--------------------------------------------------------
Static Function CANCUPOM(cL1Filial,cL1Num,cL1Operado,cL1Doc,cL1Serie,cLog)
  Local lRet         := .F.
  Local aChvCanc     := {}
  Local cBranchId    := ""
  Local cChvSL1      := ""
  Local cNumCanDoc   := ""
  Local cOperador    := ""
  Local cParam       := cL1Filial + "|" + cL1Num + "|" + cL1Operado + "|" + cL1Doc
  Local oRetailSales as Object

  oRetailSales := RetailSalesCancelationAdapter():New()

  oRetailSales:oEaiObjRec := fwEaiObj():new()
  oRetailSales:oEaiObjRec:setRestMethod("GET")
  oRetailSales:oEaiObjRec:Activate()

  If Empty(cParam)
     cLog := "Para cancelar uma venda é necessário informar a Filial, o Número do Orçamento de Venda," +;
             " o Número do Operador de Caixa e Número do Documento de Cancelamento SAT, caso exista " +;
             "('DMG01|0001|C06|12345')."
   else      
     aChvCanc := StrTokArr2(cParam, "|")

     If Len(aChvCanc) < 3
        cLog := "Para cancelar uma venda é necessário informar a Filial, o Número do Orçamento de Venda," +;
                " o Número do Operador de Caixa e Número do Documento de Cancelamento SAT, caso exista " +;
                "('DMG01|0001|C06|12345')."
      else
        cBranchId := aChvCanc[01]
        cChvSL1   := aChvCanc[02]

        If ! Len(aChvCanc) >= 3
           cLog := "Para cancelar uma venda é necessário informar a Filial, o Número do Orçamento de Venda," +;
                " o Número do Operador de Caixa e Número do Documento de Cancelamento SAT, caso exista " +;
                "('DMG01|0001|C06|12345')."
         else
           cOperador := aChvCanc[03]
    
           If Len(aChvCanc) == 4
              cNumCanDoc := aChvCanc[04]
           EndIf

           oRetailSales:oEaiObjRec:setPathParam("InternalId", cBranchId +"|"+ cChvSL1)
           oRetailSales:GetRetailSales()

           oRetailSales:oEaiObjRec:setRestMethod("DELETE")
           oRetailSales:oEaiObjRec:setProp("CompanyId", cEmpAnt)
           oRetailSales:oEaiObjRec:setProp("BranchId", cBranchId)
           oRetailSales:oEaiObjRec:setProp("InternalId", cBranchId +"|"+ cChvSL1)
           oRetailSales:oEaiObjRec:setProp("RetailSalesInternalId", cChvSL1)
           oRetailSales:oEaiObjRec:setProp("OperatorCode", cOperador)
           oRetailSales:oEaiObjRec:setProp("CancelDate", Date())
           oRetailSales:oEaiObjRec:setProp("NfceCancelProtocol", "")
           oRetailSales:oEaiObjRec:setProp("CancellationDocument", cNumCanDoc)

           If oRetailSales:lOk
              oRetailSales:DeleteRetailSales()
          
              If Len(oRetailSales:cError) > 0
                 cLog := EncodeUtf8(oRetailSales:cError)
               else
                 dbSelectArea("MEP")
                 MEP->(dbSetOrder(1))

                 If MEP->(dbSeek(FWxFilial("MEP") + PadR(cL1Serie,TamSX3("MEP_PREFIX")[1]) + PadR(cL1Doc,TamSX3("MEP_NUM")[1])))
                    While ! MEP->(Eof()) .and. MEP->MEP_FILIAL == FWxFilial("MEP") .and. AllTrim(MEP->MEP_PREFIX) == AllTrim(cL1Serie) .and.;
                          AllTrim(MEP->MEP_NUM) == AllTrim(cL1Doc)
                       Reclock("MEP",.F.)
                         dbDelete()
                       MEP->(MsUnlock())

                       MEP->(dbSkip())
                    EndDo      
                 EndIf

                 lRet := .T.
              EndIf
            else
              cLog := EncodeUtf8(oRetailSales:cError)
           EndIf
        EndIf
     EndIf
  EndIf
Return lRet

//--------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} VWSV0001
  Função fnR01Reg
    Retorna o array de inclusão registros

  @Parâmetro oItem, objeto
  @Retorno lOk	, logico
           aRegJson, matriz com os dados da requisição
  @História
   08/07/2021 - Desenvolvimento da rotina.
/*/
//--------------------------------------------------------
Static Function fnR01Req(oItemReq)
  Local lRet    := .T.
  Local aStruc  := {}
  Local aRet    := {}
  Local aRJson  := {}
  Local aRJson1 := {}
  Local aRJson2 := {}
  Local cCampo  := ""
  Local cValor  := "" 
  Local cAlias  := ""
  Local cDocto  := ""
  Local cSerie  := ""
  Local nId     := 0
  Local nPos    := 0
  Local oData

  Private cTpDocto := ""
  Private cCodForn := ""
  Private cLojForn := ""

  If AttIsMemberOf(oItemReq,"tab")
     cAlias := oItemReq:tab
     dbSelectArea(cAlias)
     aStruc := (cAlias)->(dbStruct())
   else
     lRet := .F.
  EndIf	

  If lRet .and. AttIsMemberOf(oItemReq,"data")
     oData := oItemReq:data
   else
     lRet := .F.
  EndIf			

  If lRet 
     If (nPos := aScan(aStruc, {|x| x[01] $ "_FILIAL"})) > 0 
        aAdd(aRJson, {aStruc[nPos][01], FWxFilial(cAlias), Nil})
     EndIf
 					
     For nId := 1 To Len(oData)
	      Do Case
            Case AttIsMemberOf(oData[nId],"SubItem1")
			        aRet := fnR01Dad(oData[nId]:subitem1)
              
		           If aRet[01]
			           aRJson1 := aRet[02]
   		         else
			           Exit  
		           EndIf   

	         Case AttIsMemberOf(oData[nId],"SubItem2")
		           aRet := fnR01Dad(oData[nId]:subitem2)

				     If aRet[01]
				        aRJson2 := aRet[02]
				      else
				        Exit	
			        EndIf

            OtherWise
                 nPos := aScan(aStruc, {|x| AttIsMemberOf(oData[nId], Upper(AllTrim(x[01])))})
         
                 If nPos > 0
                    cCampo := Upper(aStruc[nPos][01])
               Conout("LINHA 838")
               Conout(nPos)
               Conout(cCampo)
               Conout(nId)
               Conout("oData[nId]:" + AllTrim(cCampo)) 
               Conout(&("oData[nId]:" + AllTrim(cCampo)))
                    cValor := &("oData[nId]:" + AllTrim(cCampo))
                    xValor := fnR01MCp(cCampo, cValor, aStruc[nPos][02], aStruc[nPos][03])

                    aAdd(aRJson, {Upper(cCampo),;       // 01 - Nome do campo
                                  xValor,;              // 02 - Conteúdo do campo
                                  Nil})
                 EndIf

                 Do Case
                    Case AttIsMemberOf(oData[nId],"F1_DOC")
                         cDocto := &("oData[nId]:F1_DOC")

                    Case AttIsMemberOf(oData[nId],"F1_SERIE")
                         cSerie := &("oData[nId]:F1_SERIE")

                    Case AttIsMemberOf(oData[nId],"F1_TIPO")
                         cTpDocto := &("oData[nId]:F1_TIPO")

                    Case AttIsMemberOf(oData[nId],"F1_FORNECE")
                         cCodForn := &("oData[nId]:F1_FORNECE")

                    Case AttIsMemberOf(oData[nId],"F1_LOJA")
                         cLojForn := &("oData[nId]:F1_LOJA")

                    Case AttIsMemberOf(oData[nId],"F1_XPAGAMENTOS")
                         If ! Empty(&("oData[nId]:F1_XPAGAMENTOS")) 
                            aAdd(aPagtos, {cDocto,;
                                           cSerie,;
                                           cCodForn,;
                                           cLojForn,;
                                           &("oData[nId]:F1_XPAGAMENTOS")})
                         EndIf                                           
                 EndCase
	       EndCase
     Next
  EndIf	 
Return {lRet, aRJson, aRJson1, aRJSon2}

//------------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} VWSV0001
  Função fnR01Dad
    Retorna o array com o registro para inclusão.

  @Parâmetro oItem, objeto
  @Retorrno lOk	, logico
            aRegJson, matriz com os dados da requisição
  @História
    01/07/2021 - Desenvolvimento da rotina.
/*/
//------------------------------------------------------------------
Static Function fnR01Dad(oSubItReq)
  Local lRet      := .T.
  Local aAux      := {}
  Local aStruc    := {}
  Local aRJson    := {}
  Local cCampo    := ""
  Local cValor    := "" 
  Local cAlias    := ""
  Local cOperacao := ""
  Local cProduto  := ""
  Local cTES      := ""
  Local nX        := 0
  Local nY        := 0
  Local nPos      := 0
  Local oData

  Private aHeader := {}
  Private aCols   := {}

  For nX := 1 To Len(oSubItReq)
      aAux := {}

      If AttIsMemberOf(oSubItReq[nX],"tab")
         cAlias := oSubItReq[nX]:tab
         aStruc := (cAlias)->(dbStruct())
       else
         lRet := .F.
      EndIf	
  
      If lRet .and. AttIsMemberOf(oSubItReq[nX],"data")
         oData := oSubItReq[nX]:data
       else
         lRet := .F.
      EndIf			

      If lRet 
         If (nPos := aScan(aStruc, {|x| x[01] $ "_FILIAL"})) > 0 
             aAdd(aAux, {aStruc[nPos][01],;     // 01 - Nome do campo
                         FWxFilial(cAlias),;    // 02 - Conteúdo do campo
                         Nil})
         EndIf
					
         For nY := 1 To Len(oData)
             If (nPos := aScan(aStruc, {|x| AttIsMemberOf(oData[nY], Upper(AllTrim(x[01])))})) > 0
                cCampo := Lower(aStruc[nPos][01])
                cValor := &("oData[nY]:" + AllTrim(cCampo))
                xValor := fnR01MCp(cCampo, cValor, aStruc[nPos][02], aStruc[nPos][03])    

                aAdd(aAux, {Upper(cCampo),;    // 01 - Nome do campo
                            xValor,;           // 02 - Conteúdo do campo
                            Nil})
             EndIf

             If AttIsMemberOf(oData[nY],"D1_OPER")
                cOperacao := &("oData[nY]:D1_OPER")

              elseIf AttIsMemberOf(oData[nY],"D1_COD") 
                     cProduto := &("oData[nY]:D1_COD")
             EndIf        
         Next

         If cAlias == "SD1"
            cTES := MaTesInt(1,cOperacao,cCodForn,cLojForn,IIf(cTpDocto $ "DB","C","F"),cProduto)   // Achar a TES

            aAdd(aAux, {"D1_TES",;    // 01 - Nome do campo
                        cTES,;        // 02 - Conteúdo do campo
                        Nil})
         EndIf

         If Len(aAux) > 0
            aAdd(aRJson, aAux)
         EndIf   
      EndIf
  Next
Return {lRet, aRJson}

//--------------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} VWSVR001
  Função fnR01MCp
    Conversão do campo para a característica do campo na base
    de dados.

  @Parâmetro oItem, objeto
  @Retorrno cCampo   - Nome do campo
            xValor   - Conteúdo do campo
            cTipDad  - Característica do campo
            nTamanho - Tamando do campo

  @História
    08/07/2021 - Desenvolvimento da rotina.
/*/
//--------------------------------------------------------------
Static Function fnR01MCp(cCampo, xValor, cTipDad, nTamanho)
  Local xConverte := ""
  Local aGetCmp	  := IIf(! Empty(cCampo),Separa(cCampo,"_"),{})

  Default cTipDad := ""

  Do Case
	  // -- Converte para númerico
    // -------------------------
  	 Case (! Empty(cTipDad) .and. cTipDad == "N") .or. (Len(aGetCmp) == 2 .and. TamSX3(cCampo)[03] == "N")
          Do Case
			       Case ValType(xValor) == "C"			
				          xValor    := StrTran(xValor,",",".")				
				          xConverte := Val(xValor)

			       Case ValType(xValor) == "N"
				          xConverte := xValor	
			
             OtherWise
				          xConverte := 0
		      EndCase

	// -- Converte para data
  // ---------------------
	 Case (! Empty(cTipDad) .and. cTipDad == "D") .or. (Len(aGetCmp) == 2 .and. TamSX3(cCampo)[03] == "D")	
		    xConverte := IIf(!Empty(AllTrim(xValor)),CtoD(xValor),CtoD(""))
		
	// -- Converte para String
  // -----------------------		
	 Case (! Empty(cTipDad) .and. cTipDad == "C") .or. (Len(aGetCmp) == 2 .and. TamSX3(cCampo)[03] == "C")	
		    If Empty(cTipDad)
			     xConverte := PadR(xValor, TamSX3(cCampo)[01])
		     else
			     xConverte := PadR(xValor, nTamanho)
		    EndIf
			
	// -- Converte Memo
  // ----------------
	 Case (! Empty(cTipDad) .and. cTipDad == "M") .or. (Len(aGetCmp) == 2 .and. TamSX3(cCampo)[03] == "M")
		    xConverte := xValor	
  EndCase
Return xConverte

//---------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} DREST001
   
   Função fnR01Ler
    Rotina que ler os dados da solicitação da requisição.

  @Author Anderson Almeida (TOTVS Ne)
  @Parâmetro: oJson    = Objecto JSon
              cJsonRet = retorno em JSon da solicitação.
              cMsg     = Mensagem de retorno

  @História
   14/09/2021 - Desenvolvimento da rotina.
/*/
//---------------------------------------------------------
Static Function fnR01Ler(oJson, cJsonRet, cMsg)
  Local aArea      := GetArea()
  Local aStruct    := {}  
  Local aStruSG1   := {} 
  Local aStruSF4   := {} 
  Local cAlias     := ""
  Local cWhere     := ""
  Local cBranch    := ""
  Local cFields    := ""
  Local cFields1   := ""
  Local cFields2   := ""
  Local cCursor    := ""
  Local cQuery     := ""
  Local lRet       := .T.
  Local lEmpytFil  := .F.
  Local nX         := 0
  Local nPos       := 0
  Local nRecnoSB1  := 0
  Local aFieldsSel := {}
  Local cCpoFil	 := ""
  Local cAchaCpo   := ""

  Default cMsg     := ""
  Default cJsonRet := ""

  Private cFilAnt  := ""
  Private cEmpAnt  := ""

  cAlias   := oJson:alias
  cWhere   := oJson:where
  cBranch  := oJson:branch
  cFields  := oJson:listfields
  cFields1 := oJson:listfields1
  cFields2 := oJson:listfields2

  If AttIsMemberOf(oJson, "company")	
     cQuery := "Select M0_CODIGO, M0_CODFIL from SYS_COMPANY"
     cQuery += "  where D_E_L_E_T_ <> '*'"
     cQuery += "    and M0_CGC = '" + oJson:company + "'"
     cQuery := ChangeQuery(cQuery)
     dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSM0",.F.,.T.)

     If QSM0->(Eof())
        cMsg := "CNPJ nao cadastrado."
        lRet := .F.
      else
        cEmpAnt := QSM0->M0_CODIGO
        cFilAnt := AllTrim(QSM0->M0_CODFIL)
     EndIf
     
     QSM0->(dbCloseArea())
   else
     cMsg := "Nao informado o CNPJ na tag 'company'."
	  lRet := .F.
  Endif

  If ! lRet 
     RestArea(aArea)
     Return lRet
  EndIf	
 
  cCpoFil   := PrefixoCpo(cAlias) + "_FILIAL"
  lEmpytFil := Empty(cBranch)

  dbSelectArea("SX3")	
  SX3->(dbSetOrder(1))

  If SX3->(dbSeek(cAlias))
	  aStruct := (cAlias)->(dbStruct())              // Montagem da estrutura

	 // -- Prepara a estrutura para listar somente os campos desejados,
    // -- este campos devem estar separados por virgula, pois serão 
    // -- usados no SELECT.
    // ---------------------------------------------------------------
	  If ! Empty(cFields)
		  aFieldsSel := StrTokArr(cFields,",")
		  aStruct    := aClone(fnR01Est(aStruct, aFieldsSel, @cMsg))                                                                          
		
		  If Empty(aStruct)
		     lRet := .F.                                      
           cMsg := "Lista de Campos Inválida"
         else  
           If cAlias == "SB1" .or. cAlias == "SA2"
              cAchaCpo := Substr(cAlias,2,2)
              nPos     := aScan(aFieldsSel,{|x| Upper(AllTrim(x)) == (cAchaCpo + "_XDATINC")})

              If nPos > 0
				     aAdd(aStruct, {(cAchaCpo + "_XDATINC"),"D",8,0})
              EndIf

              nPos := aScan(aFieldsSel,{|x| Upper(AllTrim(x)) == (cAchaCpo + "_XDATALT")})

              If nPos > 0
				     aAdd(aStruct, {(cAchaCpo + "_XDATALT"),"D",8,0})
              EndIf
           EndIf

           If cAlias == "SB1" 
             // -- Ficha do Produto (Estrutura)
             // -------------------------------
              aFieldsSel := StrTokArr(cFields1,",")
			     aStruSG1   := aClone(IIf(Len(aFieldsSel) == 0,SG1->(dbStruct()),fnR01Est(SG1->(dbStruct()), aFieldsSel, @cMsg)))                                                                          

             // -- Dados TES do Produto
             // -----------------------
              aFieldsSel := StrTokArr(cFields2,",")
			     aStruSF4   := aClone(IIf(Len(aFieldsSel) == 0,SF4->(dbStruct()),fnR01Est(SF4->(dbStruct()), aFieldsSel, @cMsg)))                                                                          
           EndIf                  
		 EndIf
     EndIf    

     If lRet
        dbSelectArea(cAlias)
	 	  (cAlias)->(dbSetOrder(1))

        cCursor  := "QTMP"
        cCursor1 := "QSG1"
        cCursor2 := "QSF4"
		  cQuery	  := "Select "                      
	
		  If Empty(cFields)
		     cQuery += " *, R_E_C_N_O_ as RECNO " + IIf((cAlias == "SB1" .or. cAlias == "SA2"),", T.* ","")   // Lista todos os campos da tabela
		   else
		     cQuery += cFields + ", R_E_C_N_O_ as RECNO "    // Lista somente os campos informados pelo operador.
		  EndIf
	
	  	  cQuery += " from " + RetSqlName(cAlias)

        If cAlias == "SB1"
           cQuery += ", (Select a.B1_COD as PRODUTO, Convert(Varchar,DateAdd(Day,((ASCII(SubString(a.B1_USERLGI,12,1)) - 50) * 100 +"
           cQuery += "         (ASCII(SubString(a.B1_USERLGI,16,1)) - 50)),'19960101'),112) as B1_XDATINC,"
           cQuery += "         Case When SubString(a.B1_USERLGA,03,1) != ' '"
           cQuery += "               Then Convert(VarChar,DateAdd(Day,((ASCII(SubString(a.B1_USERLGA,12,1)) - 50) * 100 +"
           cQuery += "                    (ASCII(SubString(a.B1_USERLGA,16,1)) - 50)),'19960101'),112)"
           cQuery += "               Else ''"
           cQuery += "              End as B1_XDATALT"
           cQuery += "    from " + RetSqlName("SB1") + " a"
           cQuery += "     where a.D_E_L_E_T_ <> '*'"
           cQuery += "       and a.B1_FILIAL = '" + FWxFilial("SB1") + "'"
           cQuery += "       and a.B1_USERLGI != ' ') T"

           cWhere += IIf(Empty(cWhere)," "," and ") + "B1_COD = T.PRODUTO"

         elseIf cAlias == "SA2"  
                cQuery += ", (Select a.A2_COD as CODIGO, a.A2_LOJA as LOJA, Convert(Varchar,DateAdd(Day,((ASCII(SubString(a.A2_USERLGI,12,1)) - 50) * 100 +"
                cQuery += "         (ASCII(SubString(a.A2_USERLGI,16,1)) - 50)),'19960101'),112) as A2_XDATINC,"
                cQuery += "         Case When SubString(a.A2_USERLGA,03,1) != ' '"
                cQuery += "               Then Convert(VarChar,DateAdd(Day,((ASCII(SubString(a.A2_USERLGA,12,1)) - 50) * 100 +"
                cQuery += "                    (ASCII(SubString(a.A2_USERLGA,16,1)) - 50)),'19960101'),112)"
                cQuery += "               Else ''"
                cQuery += "              End as A2_XDATALT"
                cQuery += "    from " + RetSqlName("SA2") + " a"
                cQuery += "     where a.D_E_L_E_T_ <> '*'"
                cQuery += "       and a.A2_FILIAL = '" + FWxFilial("SA2") + "'"
                cQuery += "       and a.A2_USERLGI != ' ') T"

                cWhere += IIf(Empty(cWhere)," "," and ") + "A2_COD = T.CODIGO and A2_LOJA = T.LOJA"
        EndIf

        cQuery += "  where D_E_L_E_T_ <> '*'"
        cQuery += "   and "

		  If lEmpytFil
		     cQuery += cCpoFil + " = '" + FWxFilial(cAlias) + "'"
		   else                                           
			  cBranch := StrTran(cBranch,'"',"'")
		     cQuery	+= cCpoFil + " in (" + cBranch + ")"
		  EndIf

        cQuery += " and " + cWhere
		  cQuery := ChangeQuery(cQuery)
		  dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),cCursor)
	
		  For nX := 1 To Len(aStruct)
			   If aStruct[nX][2] <> "C"
			      TcSetField(cCursor,aStruct[nX][1],aStruct[nX][2],aStruct[nX][3],aStruct[nX][4])
				EndIf
		  Next		

		  If ! (cCursor)->(Eof())
			  cJsonRet := '{'
           cJsonRet += ' "Registros" : ['

			  While ! (cCurSor)->(Eof())
             nRecnoSB1 := IIf(cAlias == "SB1",(cCursor)->RECNO,0)
				 cJsonRet  += '{'	
				 cJsonRet  += '"recno": ' + AllTrim(Str((cCursor)->RECNO)) + ','
				 cJsonRet  += '"fields": ['
             cJsonRet  += fnR01Mnt(aStruct, cCursor) 

             If cAlias == "SB1"
               // -- Pegar a estrutura do produto, quando for o caso
               // --------------------------------------------------
                dbSelectArea("SB1")
                SB1->(dbGoto(nRecnoSB1))

		          cQuery := "Select "
                
                If Empty(cFields1)
				       cQuery += " *, R_E_C_N_O_ as RECNO "
		           else
				       cQuery += cFields1 + ", R_E_C_N_O_ as RECNO " 
			       EndIf

                cQuery += " from " + RetSqlName("SG1")
                cQuery += "  where D_E_L_E_T_ <> '*'"
                cQuery += "    and G1_COD = '" + SB1->B1_COD + "'"
        
                If lEmpytFil
			  	       cQuery += " and G1_FILIAL = '" + FWxFilial("SG1") + "'"
			        else
				       cBranch := StrTran(cBranch,'"',"'")
			          cQuery	+= " and G1_FILIAL in (" + cBranch + ")"
			       EndIf
	
			       cQuery := ChangeQuery(cQuery)
                dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),"QSG1",.F.,.T.)

                If ! QSG1->(Eof())
                   cJsonRet += ','	
                   cJsonRet += '{'	
					    cJsonRet += ' "Ficha": ['

                   For nX := 1 To Len(aStruSG1)
				           If aStruSG1[nX][02] <> "C"
					           TcSetField("QSG1",aStruSG1[nX][01], aStruSG1[nX][02], aStruSG1[nX][03], aStruSG1[nX][04])
				           EndIf
			          Next		

                   While ! QSG1->(Eof())
                     cJsonRet += '{'	
					      cJsonRet += ' "recno": ' + AllTrim(Str(QSG1->RECNO)) + ','
					      cJsonRet += ' "fields": ['
                     cJsonRet += fnR01Mnt(aStruSG1,"QSG1") 

                   	cJsonRet += ']'	
					      cJsonRet += '}'

                     QSG1->(dbSkip())

          				If ! QSG1->(Eof())
						      cJsonRet += ','
					      Endif	
                   EndDo
                   				
                   cJsonRet += ']'
				       cJsonRet += '}'
                EndIf

                QSG1->(dbCloseArea())

               // -- Pegar o fiscal do produto, quando for o caso
               // -----------------------------------------------
                dbSelectArea("SB1")
                SB1->(dbGoto(nRecnoSB1))

		          cQuery := "Select "
                
                If Empty(cFields2)
				       cQuery += " *, R_E_C_N_O_ as RECNO "
		           else
				       cQuery += cFields2 + ", R_E_C_N_O_ as RECNO " 
			       EndIf

                cQuery += " from " + RetSqlName("SF4")
                cQuery += "  where D_E_L_E_T_ <> '*'"
                cQuery += "    and (F4_CODIGO = '" + SB1->B1_TE + "' or F4_CODIGO = '" + SB1->B1_TS + "')"
        
                If lEmpytFil
			  	       cQuery += " and F4_FILIAL = '" + FWxFilial("SF4") + "'"
			        else
				       cBranch := StrTran(cBranch,'"',"'")
			          cQuery	 += " and F4_FILIAL in (" + cBranch + ")"
			       EndIf
	
			       cQuery := ChangeQuery(cQuery)
                dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),"QSF4",.F.,.T.)

                If ! QSF4->(Eof())
                   cJsonRet += ','	
                   cJsonRet += '{'	
					    cJsonRet += ' "Fiscal": ['

                   For nX := 1 To Len(aStruSF4)
				           If aStruSF4[nX][02] <> "C"
					           TcSetField("QSF4",aStruSF4[nX][01], aStruSF4[nX][02], aStruSF4[nX][03], aStruSF4[nX][04])
				           EndIf
			          Next		

                   While ! QSF4->(Eof())
                    	 cJsonRet += '{'	
					       cJsonRet += ' "recno": ' + AllTrim(Str(QSF4->RECNO)) + ','
					       cJsonRet += ' "fields": ['
                      cJsonRet += fnR01Mnt(aStruSF4, "QSF4") 
                   	 cJsonRet += ']'	
					       cJsonRet += '}'

                      QSF4->(dbSkip())

          				 If ! QSF4->(Eof())
						       cJsonRet += ','
					       EndIf	
                   EndDo
                   				
                   cJsonRet += ']'
				       cJsonRet += '}'
                EndIf

                QSF4->(dbCloseArea())
             EndIf

				 cJsonRet += ']'
				 cJsonRet += '}'

				 (cCurSor)->(dbSkip())
					
             If ! (cCurSor)->(Eof())
				    cJsonRet += ','
				 Endif	
			  EndDo
		   else
			  lRet := .f.
			  cMsg := "Nenhum registro encontrado"
		  EndIf

		  (cCursor)->(dbclosearea())

     	  cJsonRet += ']'	
		  cJsonRet += '}'
     EndIf 
   else
     cMsg := "Alias nao encontrado"
  EndIf

  RestArea(aArea)
Return lRet

//--------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} fnR01Est

   Monta dados para retorno da requisição.

  @Author Anderson Almeida (TOTVS Ne)
  @Parâmetro: pEstrutura = estrutura da tabela
              pCampos    = campo solicitados para retornar
              cMsg       = Mensagem de retorno

  @História
   08/07/2021 - Desenvolvimento da rotina.
/*/
//--------------------------------------------------------
Static Function fnR01Est(pEstrutura, pFields, cMsg)
  Local aEstruc  := pEstrutura
  Local aFields  := pFields
  Local aStruRet := {}
  Local nX       := 0
  Local nPos     := 0
  Local nPos1    := 0

 // -- Valida e adiciona no array aStruAux os campos da lista.
 // ----------------------------------------------------------
  For nX := 1 To Len(aFields)
		nPos := aScan(aEstruc, {|x| Alltrim(x[1]) == aFields[nX]})

		If nPos > 0
 		   nPos1 := aScan(aStruRet, {|x| Alltrim(x[1]) == aFields[nX]})

			If nPos1 == 0
				aAdd(aStruRet, {aEstruc[nPos][01],;          // 01 = Nome do campo da tabela
                            aEstruc[nPos][02],;          // 02 = Tipo do campo da tabela
                            aEstruc[nPos][03],;          // 03 = Contém o tamanho do campo
                            aEstruc[nPos][04]})          // 04 = Contém a quantidade de casas decimais que o campo pode armazenar
			EndIf
		 else
		  // -- Busca no "CAMPO" informado se existe o mesmo na tabela
		  // -- Se existir e não tiver incluido ainda no array aStruAux,
        // -- adiciono o mesmo.
        // -----------------------------------------------------------
		   For nPos1 := 1 To Len(aEstruc)
		       If aEstruc[nPos1][01] $ Upper(aFields[nX])
			       nPos := aScan(aStruRet, {|x| Alltrim(x[1]) == aEstruc[nPos1][01]})
							
                If nPos == 0
					    aAdd(aStruRet,{aEstruc[nPos1][01],;
                                  aEstruc[nPos1][02],;
                                  aEstruc[nPos1][03],;
                                  aEstruc[nPos1][04]})
				    EndIf
				 EndIf
			Next				
		EndIf
  Next
Return aStruRet

//--------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} fnR01Mnt

   Monta dados para retorno da requisição.

  @Author Anderson Almeida (TOTVS Ne)
  @Parâmetro: pEstrutura = estrutura da tabela
              pCampos = campo solicitados para retornar

  @História
   08/07/2021 - Desenvolvimento da rotina.
/*/
//--------------------------------------------------------
Static Function fnR01Mnt(pEstrutura, pSQL)
  Local cRet    := ""
  Local cSQL    := pSQL
  Local aEstruc := pEstrutura
  Local nX      := 0

  For nX := 1 To Len(aEstruc)	
		cRet += '{'
		cRet += '"' + Lower(aEstruc[nX][01]) + '" :'

		Do Case 
		   Case aEstruc[nX][02] == "C"
				  cRet += '"' + AllTrim((cSQL)->(FieldGet(FieldPos(aEstruc[nX][01])))) + '"'

			Case aEstruc[nX][02] == "M"
				  cRet += '"' + &(cSQL)->(aEstruc[nX][01]) + '"'

			Case aEstruc[nX][02] == "N"
				  cRet += Str((cSQL)->(FieldGet(FieldPos(aEstruc[nX][01]))))

			Case aEstruc[nX][02] == "D"
				  cRet += '"' + DToC((cSQL)->(FieldGet(FieldPos(aEstruc[nX][01])))) + '"'

			Case aEstruc[nX][02] == "L"
				  cRet += '"' + IIf((cSQL)->(FieldGet(FieldPos(aEstruc[nX][01]))),".T.",".F.") + '"'
		EndCase

		cRet += '}'

		If nX < Len(aEstruc)
		   cRet += ','	
		EndIf	
  Next
Return cRet

//-------------------------------------------------------------------
/*/ Função fnR01SA2
	 Ler código e loja do Fornecedor por CNPJ / CPF.

	@parâmetro pCGC = CNPJ / CPF do Fornecedor
	@retorno aRet[01] , logico
	         aRet[02] , código do fornecedor
			   aRet[03] , loja dp fornecedor
	@version Protheus 12
/*/
//-------------------------------------------------------------------
Static Function fnR01SA2(pCGC)
  Local aRet := {.T.,"",""}

  dbSelectArea("SA2")
  SA2->(dbSetOrder(3))

  If SA2->(dbSeek(FWxFilial("SA2") + pCGC))
	 aRet[02] := SA2->A2_COD
	 aRet[03] := SA2->A2_LOJA					  
   else
     aRet[01] := .F.
	 aRet[02] := "Fornecedor não cadastrado."
  EndIf
Return aRet
