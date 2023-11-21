#include "PROTHEUS.ch"
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

//  WsMethod Get  Description "Consulta tabela Protheus" WSSYNTAX "/api/retail/v1/DREST001"
//  WsMethod Post Description "Inclusao no PROTHEUS" WSSYNTAX "/api/retail/v1/DREST001"

  WsMethod Get         Description "Consulta tabela Protheus" WSSYNTAX "/api/retail/v1/DREST001" PATH "/api/retail/v1/DREST001"
  WsMethod Get Auditor Description "Consulta Protheus Auditoria" WSSYNTAX "/api/retail/v1/DREST001/Auditor" PATH "/api/retail/v1/DREST001/Auditor"
  WsMethod Post        Description "Inclusao no PROTHEUS" WSSYNTAX "/api/retail/v1/DREST001" PATH "/api/retail/v1/DREST001"

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

//--------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} DREST001

  Get - Ler informação do PROTHEUS para gerar
        JSon de registro de venda.
  						  
  @version P12.1.27
  @since 01/09/2022	
/*/
//--------------------------------------------------
WsMethod Get Auditor WsReceive RECEIVE WsService DREST001
  Local lRet     := .F.
  Local oJson	  := THashMap():New()
  Local cMsg     := ""
  Local cJsonRet := ""
  Local cBody    := ""
  Local cQuery   := ""

  ::SetContentType("application/json")

  cBody  := Self:GetContent()
  lRet   := FWJsonDeserialize(cBody,@oJson)

  If lRet
     If AttIsMemberOf(oJson, "company")	
        cQuery := "Select M0_CODIGO, M0_CODFIL from SYS_COMPANY"
        cQuery += "  where D_E_L_E_T_ <> '*'"
        cQuery += "    and M0_CGC = '" + oJson:company + "'"
        cQuery := ChangeQuery(cQuery)
        dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSM0",.F.,.T.)

        If QSM0->(Eof())
           cMsg := "CNPJ não cadastrado."
           lRet := .F.

           QSM0->(dbCloseArea())
         else
           cEmpAnt := QSM0->M0_CODIGO
           cFilAnt := AllTrim(QSM0->M0_CODFIL)
           
           QSM0->(dbCloseArea())
     
           cQuery := "Select Distinct SL1.L1_SERIE, SL1.L1_DOC, SL1.L1_KEYNFCE, SL1.L1_VLRTOT,"
           cQuery += "       SE1.E1_PREFIXO, SE1.E1_NUM, TSF3.F3_SERIE, TSF3.F3_NFISCAL"
           cQuery += "  from " + RetSqlName("SL1") + " SL1" 
           cQuery += "   Full Outer Join " + RetSqlName("SE1") + " SE1"  
           cQuery += " 	              on SE1.D_E_L_E_T_ <> '*'"
           cQuery += "				    and SE1.E1_FILIAL  = '" + cFilAnt + "'"
			  cQuery += "               and SE1.E1_PREFIXO = SL1.L1_SERIE"
			  cQuery += "               and SE1.E1_NUM     = SL1.L1_DOC"
	        cQuery += "   Full Outer Join (Select Distinct SF3.F3_NFISCAL, SF3.F3_SERIE, SF3.F3_CHVNFE"
           cQuery += "                       from " + RetSqlName("SF3") + " SF3"
           cQuery += "                        where SF3.D_E_L_E_T_ <> '*'"
           cQuery += "                          and SF3.F3_FILIAL  = '" + cFilAnt + "'"
           cQuery += "                          and SF3.F3_EMISSAO between '" + oJson:Emissao_Inicio + "'"
           cQuery += "                                                 and '" + oJson:Emissao_Final + "') TSF3"						  
	        cQuery += "                on TSF3.F3_CHVNFE = SL1.L1_KEYNFCE"
           cQuery += "   where SL1.D_E_L_E_T_ <> '*'"
           cQuery += "     and SL1.L1_FILIAL  = '" + cFilAnt + "'"
           cQuery += "     and SL1.L1_EMISNF between '" +  oJson:Emissao_Inicio + "' and '" + oJson:Emissao_Final + "'"
   		  cQuery := ChangeQuery(cQuery)
		     dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),"TAUD")
        
           If TAUD->(Eof())
              cMsg := "Não existem registros cadastrados."
              lRet := .F.
			   else
              cJsonRet := '{'
              cJsonRet += ' "Registros" : ['

			     While ! TAUD->(Eof())
  				     cJsonRet += '{'	
				     cJsonRet += '"fields": ['
                 cJsonRet += '  { "L1_SERIE" : "' + AllTrim(TAUD->L1_SERIE) + '" },'
                 cJsonRet += '  { "L1_DOC" : "' + AllTrim(TAUD->L1_DOC) + '" },'
                 cJsonRet += '  { "L1_KEYNFCE" : "' + TAUD->L1_KEYNFCE + '" },'
                 cJsonRet += '  { "L1_VLRTOT" : "' + AllTrim(Str(TAUD->L1_VLRTOT,16,2)) + '" },'
                 cJsonRet += '  { "E1_PREFIXO" : "' + AllTrim(TAUD->E1_PREFIXO) + '" },'
                 cJsonRet += '  { "E1_NUM" : "' + AllTrim(TAUD->E1_NUM) + '" },'
                 cJsonRet += '  { "F3_SERIE" : "' + AllTrim(TAUD->F3_SERIE) + '"},'
                 cJsonRet += '  { "F3_NFISCAL" : "' + AllTrim(TAUD->F3_NFISCAL) + '" }'
                 cJsonRet += ' ]'	
			        cJsonRet += '}'

                 TAUD->(dbSkip())

          		  If ! TAUD->(Eof())
						  cJsonRet += ','
					  Endif	
              EndDo
                   				
              cJsonRet += ']'
			     cJsonRet += '}'
           EndIf

           TAUD->(dbCloseArea())
        EndIf
      else
        cMsg := "CNPJ não informado."
        lRet := .F.
     EndIf       
   else	
	  cMsg := "JSon Error"	
  EndIf

  If ! lRet
     SetRestFault(400, NoAcento(cMsg))
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
  Local oJson	    := THashMap():New()
  Local cMensag    := ""
  Local cJsonRet   := ""
  Local cJson      := ""
  Local lRet       := .T.

  Private cBody          := ""
  Private lMsErroAuto    := .F.
  Private lAutoErrNoFile := .T.
  Private lMsHelpAuto    := .T.

  ::SetContentType("application/json")

  cBody := Self:GetContent()
  lRet  := FWJsonDeserialize(cBody, @oJson)

  If lRet   
     lRet := fnR01Grv(oJson, @cJson, @cMensag)
   
     cJsonRet := '{ "Ret": ['
	  cJsonRet += IIf(! Empty(cMensag),NoAcento(cMensag),cJson)
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
  @Parâmetro: oJson	  , objeto
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
  Local lLerSF1   := .F.
  Local lDescPro  := .F.
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
  Local aAuditor  := {}
  Local nX        := 0
  Local nY	      := 0
  Local nY1	      := 0
  Local nPos      := 0
  Local nPos1     := 0
  Local nOpcao    := 0
  Local nRecnoSL1 := 0
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
  Local cKeyNFCe  := ""
  Local cBarras   := If(isSRVunix(),"/","\")
  Local cRootPath := AllTrim(GetSrvProfString("RootPath",cBarras))
  Local cFile     := ""
  Local cFileCtr  := ""
  Local cArqJson  := ""
  Local cDadosReq := ""
  Local cCRLF		:= Chr(13) + Chr(10)
  Local dEmisNFe  := SToD("")
  Local dVencSE2  := SToD("")
  Local dAtual    := dDataBase 
  Local oItem     := Nil
  Local nHand     := Nil
  Local nHandCtr  := Nil

//  Local oError
  Local cError      := ""
  Local oError      := ErrorBlock( { |e| cError := e:Description} )
//  Local bErrorBlock := ErrorBlock({|oError| cError := oError:Description, Break(oError)})

  Private aDados    := {}
  Private aPagtos   := {}
  Private aSX3SLQ   := {}
  Private aSX3SLR   := {}
  Private aSX3SL4   := {}
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

     Return .T.
  EndIf       

  If AttIsMemberOf(oJson, "id") 	
     cIDRot := oJson:id
   else
     cMensag := "ID Rotina não enviado"

     Return .T.
  EndIf	

 // -- Verificar se a requisição está sendo processada
 // --------------------------------------------------
  cFileCtr := cRootPath + cBarras + "3lm_json" + cBarras + "JSON_" + cFilAnt + "_" + cIDRot + ".ctr"

  If File(cFileCtr)
  	  cMensag += '{ "status" : 401,'
	  cMensag += '  "msg" : "Requisicao nao pode ser processado porque ja esta em processamento por outra instancia."'
     cMensag += '}'

     Return .T.
  EndIf

  nHandCtr := fCreate(cFileCtr)       // Criação de arquivo de Controle
 // --------------------------------------------------- 
      
  If AttIsMemberOf(oJson, "opcao") 	
	  nOpcao := oJson:opcao
  EndIf

  If AttIsMemberOf(oJson,"itens") 
	  oItem  := oJson:itens  
	  aDados := {}
     
     dbSelectArea("SLQ")
     aSX3SLQ := ("SLQ")->(dbStruct())
     
     dbSelectArea("SLR")
     aSX3SLR := ("SLR")->(dbStruct())

     dbSelectArea("SL4")
     aSX3SL4 := ("SL4")->(dbStruct())

     cArqJson := "JSON_" + cFilAnt + "_" + FWTimeStamp(1) + ".txt"
     cFile    := cRootPath + cBarras + "3lm_json" + cBarras + cArqJson
     nHand    := FCreate(cFile,,,.F.)           // Cria Arquivo texto para gravação de JSon

     fWrite(nHand,cBody)
     FClose(nHand)
     
    // -- Marcar tempo de inicio
    // ------------------------- 
     Conout("**** INICIO - VERSAO 1.0") 
     Conout(cFilAnt)    
     Conout(Time())
    // ------------------------- 
     
     For nX := 1 To len(oItem) 
         Do Case
            Case cIDRot == "MATA116"
                 aRJson := {}

                 aAdd(aRJson, {""          , CToD(oItem[nX]:Data[01]:DATAINICIO), Nil})    // 01 - Data Inicial
                 aAdd(aRJson, {""          , CToD(oItem[nX]:Data[02]:DATAFINAL) , Nil})    // 02 - Data Final
                 aAdd(aRJson, {""          , nOpcao                             , Nil})    // 03 - 2 = Inclusão ou 1 = Exclusão
                 aAdd(aRJson, {""          , oItem[nX]:Data[03]:FORNECEDOR      , Nil})    // 04 - Fornecedor do documento de Origem
	              aAdd(aRJson, {""          , oItem[nX]:Data[04]:LOJA            , Nil})    // 05 - Loja de origem
                 aAdd(aRJson, {""          , Val(oItem[nX]:Data[05]:TIPO_CTE)   , Nil})    // 06 - Tipo nota origem: 1=Normal;2=Devol/Benef
	              aAdd(aRJson, {""          , 1                                  , Nil})    // 07 - 1 = Aglutina; 2 = Não aglutina
                 aAdd(aRJson, {"F1_EST"    , oItem[nX]:Data[06]:UF_ORIGEM       , Nil})    // 08 - Estado origem
                 aAdd(aRJson, {""          , oItem[nX]:Data[07]:VALOR_CTE       , Nil})    // 09 - Valor do conhecimento
                 aAdd(aRJson, {"F1_FORMUL" , Val(oItem[nX]:Data[08]:FORMULARIO) , Nil})    // 10 - Utiliza Formulario proprio ? 1-Nao,2-Sim
                 aAdd(aRJson, {"F1_DOC"    , oItem[nX]:Data[09]:NUMERO_DOC      , Nil})    // 11 - Numero da NF de Conhecimento de Frete
                 aAdd(aRJson, {"F1_SERIE"  , oItem[nX]:Data[10]:SERIE           , Nil})    // 12 - Serie da NF de Conhecimento de Frete
                 aAdd(aRJson, {"F1_FORNECE", oItem[nX]:Data[11]:CTE_FORNECEDOR  , Nil})    // 13 - Fornecedor da Nota
                 aAdd(aRJson, {"F1_LOJA"   , oItem[nX]:Data[12]:CTE_LOJA        , Nil})    // 14 - Loja do Fornecedor da Nota    
                 aAdd(aRJson, {""          , SuperGetMV("DR_TESAPI",.F.,"019")  , Nil})    // 15 - TES
                 aAdd(aRJson, {"F1_BASERET", 0                                  , Nil})    // 16 - Base de Retenção
                 aAdd(aRJson, {"F1_ICMRET" , 0                                  , Nil})    // 17 - ICMS Retido
                 aAdd(aRJson, {"F1_COND"   , oItem[nX]:Data[13]:CONDICAO_PAGTO  , Nil})    // 18 - Condição de pagamento
                 aAdd(aRJson, {"F1_EMISSAO", CToD(oItem[nX]:Data[14]:EMISSAO)   , Nil})    // 19 - Data de emissão da nota
                 aAdd(aRJson, {"F1_ESPECIE", oItem[nX]:Data[15]:ESPECIE         , Nil})    // 20 - Espécie da Nota

                 dVencSE2 := CToD(oItem[nX]:Data[16]:VENCIMENTO)

                 aRet := {}

                 For nY := 1 To Len(oItem[nX]:Data[17]:SubItem1)
                     aAdd(aRet, {PadR(oItem[nX]:Data[17]:SubItem1[nY]:Data[01]:SERIE,TamSX3("F1_SERIE")[1]),;
                                 PadR(oItem[nX]:Data[17]:SubItem1[nY]:Data[02]:DOCUMENTO,TamSX3("F1_DOC")[1]),;
                                 PadR(oItem[nX]:Data[17]:SubItem1[nY]:Data[03]:NF_FORNECEDOR,TamSX3("F1_FORNECE")[1]),;
                                 PadR(oItem[nX]:Data[17]:SubItem1[nY]:Data[04]:NF_LOJA,TamSX3("F1_LOJA")[1])})   
                 Next

                 aAdd(aDados, {aRJson,;    // 01 = Cabeçalho
                               aRet,;      // 02 = Item 1 
                               {}})        // 03 = Item 2
                               
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

     FErase(cFileCtr)

     Return .F.
  EndIf

  If lOk
     dbSelectArea("SA1")
	  SA1->(dbSetOrder(1))

     dbSelectArea("SA3")
     SA3->(dbSetOrder(1))

     dbSelectArea("SA6")
     SA6->(dbSetOrder(1))

     dbSelectArea("SAE")
     SAE->(dbSetOrder(1))

     dbSelectArea("MEN")
     MEN->(DbSetOrder(1))

     dbSelectArea("SF1")
     SF1->(dbSetOrder(1))

     dbSelectArea("SE2")
     SE2->(dbSetOrder(6))

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
                 cDadosReq := VarInfo("Dados: ",aCab)

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_LOJA"})) > 0
                    cDcRotina += "Loja " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A1_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

		           MsExecAuto({|x,y| CRMA980(x,y)}, aCab, nOpcao)

           // -- Vendedor
           // ----------------------
            Case cIDRot == "MATA040"
                 cTpRotina := "VENDEDOR"
                 cDcRotina := ""
                 cDadosReq := VarInfo("Dados: ",aCab)

                 If (nPos := aScan(aCab, {|x| x[01] == "A3_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A3_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 MsExecAuto({|x,y| MATA040(x,y)}, aCab, nOpcao)

           // -- Operador (Banco)
           // ----------------------
            Case cIDRot == "MATA070"
                 cTpRotina := "OPERADOR"
                 cDcRotina := ""
                 cDadosReq := VarInfo("Dados: ",aCab)

                 If (nPos := aScan(aCab, {|x| x[01] == "A6_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "A6_NOME"})) > 0
                    cDcRotina += "Nome " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 MsExecAuto({|x,y| MATA070(x,y)}, aCab, nOpcao)

           // -- Forma de Pagamento (Administradoras Financeiras) 
           // ---------------------------------------------------
            Case cIDRot == "LOJA070"
                 cTpRotina := "ADMINISTRADORAS FINANCEIRAS"
                 cDcRotina := ""
                 cDadosReq := ""

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_COD"})) > 0
                    cDcRotina += "Codigo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_DESC"})) > 0
                    cDcRotina += "Descricao " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If (nPos := aScan(aCab, {|x| x[01] == "AE_TIPO"})) > 0
                    cDcRotina += "Tipo " + AllTrim(aCab[nPos][02]) + " "
                 EndIf   

                 If nOpcao == 4
                    nPos := aScan(aItem1, {|x| x[01] == "MEN_ITEM"})
				
                    If nPos > 0
                       nPos1 := aScan(aCab, {|x| x[01] == "AE_COD"})
                    
                       If nPos1 > 0
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

                    cDadosReq := VarInfo("Cabecalho: ",aCab) + cCRLF + VarInfo("Itens: ",aItens)
                 
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
                 cDadosReq := ""
				     aItens    := {}
                 aParcela  := {}
                 aAuditor  := {}

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_NUMCFIS"})) > 0
                    cCupom := AllTrim(aCab[nPos][02])
                 EndIf
                 
                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_DOC"})) > 0
                    cDoc := AllTrim(aCab[nPos][02])
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

                 If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "LQ_KEYNFCE"})) > 0
                    cKeyNFCe := aCab[nPos][02]
                 EndIf

                 cDcRotina := "Cupom: " + cCupom + " Serie: " + cSerie + " PDV: " + cPDV + " Operador: " + cOperador

                 If Empty(cOperador)         // -- Validar Operador
                    cLog := "Operador não informado no Cupom: " + AllTrim(cCupom) + " do PDV: " + AllTrim(cPDV)
                  else  
                    If ! SA6->(dbSeek(FWxFilial("SA6") + cOperador))
                       cLog := "Operador não cadastrado - " + AllTrim(cOperador) + " do Cupom: " + AllTrim(cCupom) + " do PDV: " + AllTrim(cPDV)
                     else
                       For nY := 1 To Len(aItem1)
                           lDescPro := .F.
 
                           aAdd(aItens, {})

                           For nY1 := 1 To Len(aItem1[nY])
                               If nOpcao == 3
                                  If aItem1[nY][nY1][01] == "LR_PRODUTO"
                                     aAdd(aAuditor, {aItem1[nY][nY1][2],"",""})

                                    elseIf aItem1[nY][nY1][01] == "LR_ITEM"
                                           aAuditor[Len(aAuditor)][02] := aItem1[nY][nY1][2] 

                                         elseIf aItem1[nY][nY1][1] == "LR_CF"
                                                aAuditor[Len(aAuditor)][03] := aItem1[nY][nY1][2] 
                                  EndIf

                                  If aItem1[nY][nY1][01] == "LR_DESCPRO"
                                     lDescPro := .T.
                                  EndIf
                               EndIf   

                               aAdd(aItens[Len(aItens)], {aItem1[nY][nY1][1],;
                                                          aItem1[nY][nY1][2],;
                                                          aItem1[nY][nY1][3]})
                           Next

                           If ! lDescPro
                              Exit
                           EndIf   
                       Next

                       If ! lDescPro .and. nOpcao == 3
                          cLog := "Cupom: " + cCupom + " Chave: " + cKeyNFCe + " sem a tag 'LR_DESCPRO', por favor verifique."
                        else
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
                                    cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " +;
                                            AllTrim(cPDV) + " Item " + AllTrim(Str(nY)) +;
                                            ": Pagamento com cartão sem ADMINISTRADORA."
                                    Exit
                                 EndIf
                               elseIf Empty(cFormaPag)
                                      cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " +;
                                              AllTrim(cPDV) + " Item " + AllTrim(Str(nY)) + ": Pagamento sem informar a FORMA."
                                      Exit
                              EndIf                             
                          Next
                       EndIf
                    EndIf   
                 EndIf

                 If Empty(cLog)
                    If Len(aParcela) == 0
                       cLog := "Venda Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) + " PDV - " + AllTrim(cPDV) +;
                               ": Sem PAGAMENTO informado."
                     else
                       nRecnoSL1 := 0

                       cQuery := "Select SL1.L1_SITUA, SL1.R_E_C_N_O_ as RECNOSL1, SLQ.R_E_C_N_O_ as RECNOSLQ"
                       cQuery += "  from " + RetSqlName("SL1") + " SL1"
                       cQuery += "   Full Outer Join " + RetSqlName("SLQ")  + " SLQ"
                       cQuery += "           on SLQ.D_E_L_E_T_ <> '*'"
                       cQuery += "          and SLQ.LQ_FILIAL = '" + FWxFilial("SLQ") + "'"
                       cQuery += "          and SLQ.LQ_KEYNFCE = '" + cKeyNFCe + "'"
                       cQuery += "  where SL1.D_E_L_E_T_ <> '*'"
                       cQuery += "    and SL1.L1_FILIAL  = '" + FWxFilial("SL1") + "'"
                       cQuery += "    and SL1.L1_KEYNFCE = '" + cKeyNFCe + "'"
                       cQuery := ChangeQuery(cQuery)
                       dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSL1",.F.,.T.)

                       If ! QSL1->(Eof())
                          nRecnoSL1 := QSL1->RECNOSL1
                          lLerSL1   := .T.
                        else
                          lLerSL1 := .F.  
                       EndIf

                       QSL1->(dbCloseArea())

                       If nOpcao == 3
                          If lLerSL1
                             cLog := "Venda já cadastrada: Serie - " + AllTrim(cSerie) + " Cupom - " + AllTrim(cCupom) +;
                                     " PDV - " + AllTrim(cPDV)
                           else 
                             cDadosReq := VarInfo("Cabecalho: ",aCab) + cCRLF + VarInfo("Itens: ",aItens)

                             MSExecAuto({|a,b,c,d,e,f,g,h,i,j| Loja701(a,b,c,d,e,f,g,h,i,j)},.F.,3,"","",{},aCab,aItens,aParcela,.F.,.T.)

                             If ! lMsErroAuto
                                If AllTrim(SL1->L1_KEYNFCE) <> AllTrim(cKeyNFCe)
                                   cLog := "Problema na gravação do registro, Chave NFCe " + cKeyNFCe
                                 else
                                   If Empty(AllTrim(SL1->L1_SERIE)) .or. Empty(SL1->L1_DOC) .or. Empty(SL1->L1_SITUA)
                                      Reclock("SL1",.F.)
                                        Replace SL1->L1_SERIE with cSerie
                                        Replace SL1->L1_DOC   with cDoc
                                        Replace SL1->L1_SITUA with "RX"
                                      SL1->(MsUnlock())
                                   EndIf

                                   cQuery := "Select SL1.L1_DOC, SL1.L1_SERIE, SL1.L1_SITUA, SL1.R_E_C_N_O_ as L1RECNO,"
                                   cQuery += "       SL2.L2_ITEM, SL2.R_E_C_N_O_ as L2RECNO"
                                   cQuery += "  from " + RetSqlName("SL1") + " SL1"
                                   cQuery += "   Full Outer Join " + RetSqlName("SL2")  + " SL2"
                                   cQuery += "           on SL2.D_E_L_E_T_ <> '*'"
                                   cQuery += "          and SL2.L2_FILIAL = '" + FWxFilial("SL2") + "'"
                                   cQuery += "          and SL2.L2_NUM    = SL1.L1_NUM"
                                   cQuery += "          and SL2.L2_CF     = ''"
                                   cQuery += "   where SL1.D_E_L_E_T_ <> '*'"
                                   cQuery += "     and SL1.L1_FILIAL  = '" + FWxFilial("SL1") + "'"
                                   cQuery += "     and SL1.L1_NUM     = '" + SL1->L1_NUM + "'"
                             //      cQuery += "     and (SL1.L1_SERIE = '' or SL1.L1_DOC = '')"
                                   cQuery := ChangeQuery(cQuery)
                                   dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"QSL1",.F.,.T.)

                                   While ! QSL1->(Eof())
                                      If QSL1->L2RECNO > 0
                                        If (nPos := aScan(aAuditor, {|x| AllTrim(x[02]) == AllTrim(QSL1->L2_ITEM)})) > 0
                                           SL2->(dbGoto(QSL1->L2RECNO))

                                           Reclock("SL2",.F.)
                                             Replace SL2->L2_CF with aAuditor[nPos][03]
                                           SL2->(MsUnlock())
                                        EndIf
                                      EndIf
                                         
                                      QSL1->(dbSkip())
                                   EndDo

                                   QSL1->(dbCloseArea())
                                EndIf
                             EndIf
                          EndIf

                        elseIf nOpcao == 6
                               If lLerSL1
                                  SL1->(dbGoto(nRecnoSL1))

                                  If SL1->L1_SITUA <> "OK"
                                     cLog := "Venda ainda não processada: Serie - " + AllTrim(cSerie) + " Cupom - " +;
                                             AllTrim(cCupom) + " PDV - " + AllTrim(cPDV)
                                   else
                                     cDadosReq := "Cancelamneto CUPOM: " + AllTrim(SL1->L1_FILIAL) + " / " +;
                                                  AllTrim(SL1->L1_NUM) + " / " + AllTrim(SL1->L1_OPERADO) +;
                                                  " / " + AllTrim(SL1->L1_DOC) + " / " + SL1->L1_SERIE

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
                 cDadosReq   := ""

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
                    cDadosReq := VarInfo("Dados: ",aRegSE5)
                    
                    FWSM0Util():setSM0PositionBycFilAnt()       // Método estático que posiciona a SM0 de acordo: cEmpAnt e cFilAnt

                    MsExecAuto({|x,y,z| FINA100(x,y,z)},0,aRegSE5,7)

                    dDataBase := Date()
                 EndIf

           // -- Inutilização de Cupom Fiscal
           // -------------------------------
            Case cIDRot == "INUTILIZAR"
                 cTpRotina := "INUTILIZACAO CUPOM"
                 cDadosReq := ""

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
                    cDadosReq := VarInfo("Inutilização: ",aCab)

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
                 cDadosReq := ""

                 If nOpcao <> 3 .and. nOpcao <> 5
                    cLog := "ERRO: Opção inválida para essa rotina." 
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

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_DTDIGIT"})) > 0
                       dDataBase := aCab[nPos][02]
                    EndIf   

                    cDcRotina := "NFe Serie " + cSerie + " Numero " + cDocto + " Chave " + cChvNFe + " Emissao " + DToC(dEmisNFe) 

                    If Empty(cLog)
                       aAdd(aCab,{"E2_NATUREZ",Posicione("SA2",1,FWxFilial("SA2") + PadR(cCodForn,TamSX3("A2_COD")[1]) +;
                                               PadR(cLojForn,TamSX3("A2_LOJA")[1]),"A2_NATUREZ"),Nil})
                
			              aRegSD1     := aItem1
                       lMsErroAuto := .F.
                       cDadosReq := VarInfo("Cabecalho: ",aCab) + cCRLF + VarInfo("Itens: ",aRegSD1)

                       MsExecAuto({|x,y,z| MATA103(x,y,z)},aCab,aRegSD1,nOpcao)
                      
                       If ! lMsErroAuto .and. nOpcao == 3
                          If AllTrim(SF1->F1_CHVNFE) <> AllTrim(cChvNFe)
                             cLog := "Problema na gravação do registro, Chave NFCe " + cChvNFe
                           else
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
                                      EndIf
                                  Next   
                                End Transaction
                             EndIf
                            // -----------------------------
                          EndIf   
                       EndIf
                    EndIf

                    dDataBase := dAtual
                 EndIf 

  		     // -- Emissão Nfe Sobre Cupom
		     // --------------------------
			   Case cIDRot == "LOJR130"
                 cTpRotina := "Nfe x Cupom"
                 cLog      := ""
                 cDadosReq := ""
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

  		     // -- CT-e Conhecimento Frete
		     // --------------------------
			   Case cIDRot == "MATA116"
                 cTpRotina := "CT-e Nota Conhecimento de Frete"
                 cLog      := ""
                 cDadosReq := ""

                 If nOpcao <> 1 .and. nOpcao <> 2
                    cLog := "ERRO: Opção inválida para essa rotina." 
                  else                           
                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_DOC"})) > 0
                       cDocto := PadR(AllTrim(aCab[nPos][02]),TamSX3("F1_DOC")[1])
                    EndIf
                 
                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_SERIE"})) > 0
                       cSerie := PadR(AllTrim(aCab[nPos][02]),TamSX3("F1_SERIE")[1])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_FORNECE"})) > 0
                       cCodForn := PadR(AllTrim(aCab[nPos][02]),TamSX3("F1_FORNECE")[1])
                    EndIf

                    If (nPos := aScan(aCab, {|x| AllTrim(x[01]) == "F1_LOJA"})) > 0
                       cLojForn := PadR(AllTrim(aCab[nPos][02]),TamSX3("F1_LOJA")[1])
                    EndIf

                    cDcRotina := "NFe Serie " + cSerie + " Numero " + cDocto + " Fornecedor " + cCodForn + " Loja " + cLojForn
                    lLerSF1   := SF1->(dbSeek(FWxFilial("SF1") + cDocto + cSerie + cCodForn + cLojForn))

                    If lLerSF1 .and. nOpcao == 2 
                       cLog := "JAEXISTECTE: " + cDcRotina + ", já cadastrada."

                     elseIf ! lLerSF1 .and. nOpcao == 1  
                            cLog := "NAOEXISTECTE: " + cDcRotina + ", não cadastrada."
                          else    
                            For nY := 1 To Len(aItem1)
                                aAdd(aItens, {aItem1[nY]})
                            Next    

                            cDadosReq := VarInfo("Cabecalho: ",aCab) + cCRLF + VarInfo("Itens: ",aItens)
                            
                            MATA116(aCab,aItens,,,aItem2)
                           
                            If ! lMsErroAuto
                               If nOpcao == 2
                                  If ! SF1->(dbSeek(FWxFilial("SF1") + cDocto + cSerie + cCodForn + cLojForn))
                                     cLog := "Problema na gravação do registro, Documento " + cDocto + " Serie " + cSerie
                                   else
                                     If SE2->(dbSeek(FWxFilial("SE2") + cCodForn + cLojForn + cSerie + cDocto))
                                        Reclock("SE2",.F.)
                                          Replace SE2->E2_VENCTO  with dVencSE2
                                          Replace SE2->E2_VENCREA with dVencSE2
                                          Replace SE2->E2_VENCORI with dVencSE2
                                        SE2->(MsUnlock())
                                     EndIf
                                  EndIf   
                               EndIf   
                            EndIf
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
  				       cLog += _NoTags(cAux) + Chr(10) + Chr(13)
			      Next

            EndIf  	
         EndIf

         If ! Empty(cLog)
         	cJSonAux := ""
			   cJSonAux += '{ "status" : 401,'
			   cJSonAux += '  "msg" : "' + NoAcento(cLog) + '" }'
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
            Case nOpcao == 3 .or. nOpcao == 2
                 cDcOper := "INCLUSAO"

            Case nOpcao == 4
                 cDcOper := "ALTERACAO"

            Case nOpcao == 5 .or. nOpcao == 1
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
           Replace SZ1->Z1_DATA    with Date()
           Replace SZ1->Z1_HORA    with Time()
           Replace SZ1->Z1_ROTINA  with cIDRot
           Replace SZ1->Z1_DESC    with cTpRotina
           Replace SZ1->Z1_DOCTO   with cDcRotina
           Replace SZ1->Z1_OPERACA with nOpcao
           Replace SZ1->Z1_DSCOPER with cDcOper
           Replace SZ1->Z1_MENSAG  with IIf(Empty(cLog),"SUCESSO",IIf(lMsErroAuto .and. ! lMVC,NoAcento(cLog),cLog))
           Replace SZ1->Z1_STATUS  with IIf(Empty(cLog),"S","E")
           Replace SZ1->Z1_ARQJSON with cArqJson
           Replace SZ1->Z1_DADOS   with cDadosReq
         SZ1->(MsUnlock())

			ConfirmSX8()
        // -------------------------------- 	
	  Next
   else
	  cMensag += "Não foi possivel realizar a operação solicitada."
  EndIf

  FClose(nHandCtr)
  FErase(cFileCtr)       // Deletar arquivo de controle

 // -- Marcar tempo de terminio
 // ---------------------------
  Conout(cFilAnt)
  Conout(cIDRot)
  Conout(Time()) 
  Conout("**** FIM")
 // ---------------------------
  RestArea(aArea)
Return lOk

//--------------------------------------------------------
/*/  Função CANCUPOM

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
                 cLog := NoAcento(oRetailSales:cError)
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
              cLog := NoAcento(oRetailSales:cError)
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

     If cAlias == "SLQ"
        aStruc := aClone(aSX3SLQ)
      else
        dbSelectArea(cAlias)
        aStruc := (cAlias)->(dbStruct())
     EndIf
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
         Do Case
            Case cAlias == "SLR" 
                 aStruc := aClone(aSX3SLR)
        
            Case cAlias == "SL4"
                 aStruc := aClone(aSX3SL4)

            OtherWise
                 cAlias := oSubItReq[nX]:tab
                 aStruc := (cAlias)->(dbStruct())
         EndCase        
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

                If AllTrim(aStruc[nPos][01]) == "L4_DATATEF"
                   xValor := DToS(CToD(cValor))
                 else  
                   xValor := fnR01MCp(cCampo, cValor, aStruc[nPos][02], aStruc[nPos][03])    
                EndIf

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
//  Local nPos       := 0
  Local nRecnoSB1  := 0
  Local aFieldsSel := {}
  Local cCpoFil	 := ""
//  Local cAchaCpo   := ""

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
/*           If cAlias == "SB1" .or. cAlias == "SA2"
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
*/
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
/*
        If cAlias == "SB1"
//           cQuery += ", (Select a.B1_COD as PRODUTO, Convert(Varchar,DateAdd(Day,((ASCII(SubString(a.B1_USERLGI,12,1)) - 50) * 100 +"
//           cQuery += "         (ASCII(SubString(a.B1_USERLGI,16,1)) - 50)),'19960101'),112) as B1_XDATINC,"
//           cQuery += "         Case When SubString(a.B1_USERLGA,03,1) != ' '"
//           cQuery += "               Then Convert(VarChar,DateAdd(Day,((ASCII(SubString(a.B1_USERLGA,12,1)) - 50) * 100 +"
//           cQuery += "                    (ASCII(SubString(a.B1_USERLGA,16,1)) - 50)),'19960101'),112)"
//           cQuery += "               Else ''"
//           cQuery += "              End as B1_XDATALT"
           cQuery += ", (Select a.B1_COD as PRODUTO, a.B1_XDATINC, a.B1_XDATALT"
           cQuery += "    from " + RetSqlName("SB1") + " a"
           cQuery += "     where a.D_E_L_E_T_ <> '*'"
           cQuery += "       and a.B1_FILIAL = '" + FWxFilial("SB1") + "'"
           cQuery += "       and a.B1_USERLGI != ' ') T"

           cWhere += IIf(Empty(cWhere)," "," and ") + "B1_COD = T.PRODUTO"

         elseIf cAlias == "SA2"  
//                cQuery += ", (Select a.A2_COD as CODIGO, a.A2_LOJA as LOJA, Convert(Varchar,DateAdd(Day,((ASCII(SubString(a.A2_USERLGI,12,1)) - 50) * 100 +"
//                cQuery += "         (ASCII(SubString(a.A2_USERLGI,16,1)) - 50)),'19960101'),112) as A2_XDATINC,"
//                cQuery += "         Case When SubString(a.A2_USERLGA,03,1) != ' '"
//                cQuery += "               Then Convert(VarChar,DateAdd(Day,((ASCII(SubString(a.A2_USERLGA,12,1)) - 50) * 100 +"
//                cQuery += "                    (ASCII(SubString(a.A2_USERLGA,16,1)) - 50)),'19960101'),112)"
//                cQuery += "               Else ''"
//                cQuery += "              End as A2_XDATALT"
                cQuery += ", (Select a.A2_COD as CODIGO, a.A2_LOJA as LOJA, a.A2_XDATINC, a.A2_XDATALT"
                cQuery += "    from " + RetSqlName("SA2") + " a"
                cQuery += "     where a.D_E_L_E_T_ <> '*'"
                cQuery += "       and a.A2_FILIAL = '" + FWxFilial("SA2") + "'"
                cQuery += "       and a.A2_USERLGI != ' ') T"

                cWhere += IIf(Empty(cWhere)," "," and ") + "A2_COD = T.CODIGO and A2_LOJA = T.LOJA"
        EndIf
*/
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
