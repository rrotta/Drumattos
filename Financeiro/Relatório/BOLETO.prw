#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "rwmake.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#Include "Directry.ch"

/*/{protheusDoc.marcadores_ocultos} BOLETO
  Função BOLETO
  @param nTela    :=  1 - Usa tela com parametros próprios
                      2 - Usa tela com parametros de terceiros
                      3 - Não usar tela, impressão direita 
         aParam  := Se não usar tela para seleção passar os parametros de pergunta de 1 a 26.
         pTipo   := 1 - Impressão impressora
                    2 - Impressão PDF
         pGerArq := 1 - Gerar todos os boletos em um único arquivo, apenas para geração em PDF
                    2 - Gerar os boletos individual por parcelas em vários arquivos, apenas para geração em PDF
            
  @return Não retorna nada
  @author Totvs Nordeste
  @owner Totvs S/A
  @version Protheus 10, Protheus 11
  @since 27/10/2015 
  @sample
// BOLETO - User Function função impressão de boletos dos Bancarios (Genérico)
  U_BOLETO()
  Return
  @obs Rotina de Impressão de Boletos
  @project 
  @menu \SIGAFIN\Atualização\Específico\Boleto
  @history
  27/10/2015 - Desenvolvimento da Rotina.
/*/
User Function BOLETO(nTela,aParam,pTipo,pGerArq)
  Local aRegs     := {}
  Local aTitulos  := {}
  Local nLastKey  := 0
  Local nId       := 0
  Local nId1      := 0
  Local cTpImpBol := GetMv("MV_XTPBOL")
  Local cParte    := ""
  Local cTamanho  := "M"
  Local cDesc1    := "Este programa tem como objetivo efetuar a impressão do"
  Local cDesc2    := "Boleto de Cobrança com código de barras, conforme os"
  Local cDesc3    := "parâmetros definidos pelo usuário"
  Local cString   := "SE1"
  Local wnrel     := "BOLETO"

  Default nTela   := 1
  
  Private cQualBco := ""
  Private cNossoDg := ""
  Private cStgTipo := "'"
  Private cTpImpre := pTipo    // 1 - Impressora ou 2 - PDF
  Private cGerArq  := pGerArq  // Forma de geração do boleto
  Private bOrigCB  := .F.
  Private cPerg    := "BOLETO"
  Private lEnd     := .F.
  Private aReturn  := {"Banco",;				// [1]= Tipo de Formulário
                       1,;           		// [2]= Número de Vias
                       "Administração",;	// [3]= Destinatário
                    	  2,;						// [4]= Formato 1=Comprimido 2=Normal
                       2,;						// [5]= Mídia 1=Disco 2=Impressora
                       1,;						// [6]= Porta LPT1, LPT2, Etc
                    	  "",;						// [7]= Expressão do Filtro
                    	  1}						// [8]= ordem a ser selecionada
                     	
  Private cTitulo    := "Boleto de Cobrança com Código de Barras"
  Private cStartPath := GetSrvProfString("StartPath","")
  Private nTpImp     := 0
  Private nPosPDF    := 0
  Private aLinDig    := {}

  nTela      := IIf(ValType(nTela) != "N",1,nTela)  
  cStartPath := AllTrim(cStartPath) + "logo_bancos\"

 // --------------
  For nId := 1 To Len(cTpImpBol)
      cParte := Substr(cTpImpBol,nId,1)
      
      If cParte == ","
         While nId1 < 3
           cStgTipo += " "
           
           nId1++  
         EndDo     
         cStgTipo += "','"
         nId1      := 0
       else
         cStgTipo += Substr(cTpImpBol,nId,1)
         nId1++
      EndIf      
  Next

  While nId1 < 3
    cStgTipo += " "
           
    nId1++  
  EndDo     
  
  cStgTipo += "'"
 // -------------- 
 
  fnCriaSx1(aRegs)
  
  If nTela == 1            // Usa tela com parametro 
    If Pergunte(cPerg,.T.)
       MsgRun("Títulos a Receber","Selecionando registros para processamento",{|| fnCallReg(@aTitulos,@nTela)})

       If Len(aTitulos) > 0		
	      // Monta tela de seleção dos registros que deverão gerar o boleto
          fnCallTela(@aTitulos)
       EndIf   
    EndIf
   elseIf nTela <> 1       // Usa tela com parametros de terceiros
          mv_par01 := aParam[01]        // Prefixo Inicial
          mv_par02 := aParam[02]        // Prefixo Final
          mv_par03 := aParam[03]        // Numero Inicial
          mv_par04 := aParam[04]        // Numero Final
          mv_par05 := aParam[05]        // Parcela Inicial
          mv_par06 := aParam[06]        // Parcela Final
          mv_par07 := aParam[07]        // Tipo Inicial
          mv_par08 := aParam[08]        // Tipo Final
          mv_par09 := aParam[09]        // Cliente Inicial
          mv_par10 := aParam[10]        // Cliente Final
          mv_par11 := aParam[11]        // Loja Inicial
          mv_par12 := aParam[12]        // Loja Final
          mv_par13 := aParam[13]        // Emissão Inicial
          mv_par14 := aParam[14]        // Emissão Final
          mv_par15 := aParam[15]        // Vencimento Inicial
          mv_par16 := aParam[16]        // Vencimento Final
          mv_par17 := aParam[17]        // Natureza Inicial
          mv_par18 := aParam[18]        // Natureza Final
          mv_par19 := aParam[19]        // Banco
          mv_par20 := aParam[20]        // Agência
          mv_par21 := aParam[21]        // Conta
          mv_par22 := aParam[22]        // Subconta
          mv_par23 := aParam[23]        // Tipo do processo: 1 - Gerar, 2 - Reimpressão ou 3 - Regerar
          mv_par24 := aParam[24]        // Diretório
          mv_par25 := aParam[25]        // Gerar boleto: 1 - Sim ou 2 - Não
          mv_par26 := aParam[26]        // Tipo do boleto: 1 - Reduzido ou 2 - Completo
          
          MsgRun("Títulos a Receber","Selecionando registros para processamento",{|| fnCallReg(@aTitulos,@nTela)})
          
          If Len(aTitulos) > 0		
            If nTela == 3         // Impressão sem tela com parametros de terceiros
               RptStatus({|lEnd| ImpBol(aTitulos)}, cTitulo)
             else          
              // Monta tela de seleção dos registros que deverão gerar o boleto
               fnCallTela(@aTitulos)
            EndIf   
          EndIf 
  EndIf   
Return

/*---------------------------------------------
--  Função: Pesquisa títulos para impressão  --
--          de boleto.                       --
-----------------------------------------------*/
Static Function fnCallReg(aTitulos,nTela)
  Local cQuery  := ""
 /*  
  If (Empty(mv_par19) .or. Empty(mv_par20)) .and. mv_par23 == 2
     Aviso("ATENÇÃO","Parametros: Banco e Agência não preenchidos.",{"OK"})
     Return
  EndIf
 
 // --- Validar se escolher o boleto reduzido sem cliente
  If mv_par26 == 1 .and. Empty(Alltrim(mv_par09))
     Aviso("ATENÇÃO","Parametros: Boleto reduzido escolhido sem o cliente.",{"OK"})
     Return
   elseIf mv_par26 == 1
          mv_par10 := mv_par09
          mv_par12 := mv_par11
  EndIf
 // -----------------------------------------------------
  */
  cQuery := " Select SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_NATUREZ,"
  cQuery += "        SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_NOMCLI, SE1.E1_EMISSAO, SE1.E1_VENCTO,"
  cQuery += "        SE1.E1_VENCREA, SE1.E1_VALOR, SE1.E1_HIST, SE1.E1_PORTADO, SE1.E1_AGEDEP, SE1.E1_CONTA,"
  cQuery += "        SE1.E1_XSUBCTA, SE1.E1_NUMBCO, R_E_C_N_O_ AS E1_REGSE1"
  cQuery += "  from " + RetSqlName("SE1") + " SE1 "
  cQuery += "    Where SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
  cQuery += "      and SE1.E1_PREFIXO between '" + mv_par01 + "' and '" + mv_par02 + "'"
  cQuery += "      and SE1.E1_NUM     between '" + mv_par03 + "' and '" + mv_par04 + "'"
  cQuery += "      and SE1.E1_PARCELA between '" + mv_par05 + "' and '" + mv_par06 + "'"
  cQuery += "      and SE1.E1_TIPO    between '" + mv_par07 + "' and '" + mv_par08 + "'"
  cQuery += "      and SE1.E1_CLIENTE between '" + mv_par09 + "' and '" + mv_par10 + "'"
  cQuery += "      and SE1.E1_LOJA    between '" + mv_par11 + "' and '" + mv_par12 + "'"
  cQuery += "      and SE1.E1_EMISSAO between '" + DToS(mv_par13) + "' and '" + DToS(mv_par14) + "'"
  cQuery += "      and SE1.E1_VENCTO  between '" + DToS(mv_par15) + "' and '" + DToS(mv_par16) + "'"
  cQuery += "      and SE1.E1_NATUREZ between '" + mv_par17 + "' and '" + mv_par18 + "'"
  cQuery += "      and SE1.E1_SALDO > 0"
  cQuery += "      and SE1.E1_TIPO in (" + cStgTipo + ")"
	
  If mv_par23 == 2
     cQuery += " and SE1.E1_NUMBCO <> ' '"
     cQuery += " and SE1.E1_PORTADO = '" + mv_par19 + "'"
     cQuery += " and SE1.E1_AGEDEP  = '" + mv_par20 + "'"
     cQuery += " and SE1.E1_CONTA   = '" + mv_par21 + "'"
     cQuery += " and SE1.E1_SITUACA = '1'"

   elseIf mv_par23 == 1
          cQuery += " and SE1.E1_NUMBCO  = ' '"
          cQuery += " and SE1.E1_SITUACA = '0'"
        elseIf mv_par23 <> 3
               cQuery += " and SE1.E1_NUMBCO <> ' '"
               cQuery += " and SE1.E1_SITUACA = '1'"
  EndIf

  cQuery += " and SE1.E1_TIPO not in ('" + MVABATIM + "')"
  cQuery += " and SE1.D_E_L_E_T_ <> '*'"
  cQuery += " Order By SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO"

  If Select("FINR01A") > 0
     dbSelectArea("FINR01A")
     FINR01A->(dbCloseAea())
  EndIf
  
  MemoWrit("c:\temp\Qry_VM",cQuery)
  
  TCQuery cQuery New Alias "FINR01A"
  TCSetField("FINR01A", "E1_EMISSAO", "D",08,0)
  TCSetField("FINR01A", "E1_VENCTO" , "D",08,0)
  TCSetField("FINR01A", "E1_VENCREA", "D",08,0)
  TCSetField("FINR01A", "E1_VALOR"  , "N",14,2)
  TCSetField("FINR01A", "E1_REGSE1" , "N",10,0)

  dbSelectArea("FINR01A")
  
  While ! FINR01A->(Eof())
   aAdd(aTitulos, {IIf(nTela == 3,.T.,.F.),;  // 01 = Mark
                   FINR01A->E1_PORTADO,;      // 02 = Portado
                   FINR01A->E1_PREFIXO,;      // 03 = Prefixo do Título
		             FINR01A->E1_NUM,;          // 04 = Número do Título
		             FINR01A->E1_PARCELA,;      // 05 = Parcela do Título
		             FINR01A->E1_TIPO,;         // 06 = Tipo do Título
                   FINR01A->E1_NATUREZ,;      // 07 = Natureza do Título
		             FINR01A->E1_CLIENTE,;      // 08 = Cliente do título
		             FINR01A->E1_LOJA,;         // 09 = Loja do Cliente
		             FINR01A->E1_NOMCLI,;       // 10 = Nome do Cliente
		             Posicione("SA1",1,xFilial("SA1") + FINR01A->E1_CLIENTE + FINR01A->E1_LOJA,"A1_XEMCOB"),;  // 11 = Email de cobrança do cliente
		             FINR01A->E1_EMISSAO,;      // 12 = Data de Emissão do Título
		             FINR01A->E1_VENCTO,;       // 13 = Data de Vencimento do Título
		             FINR01A->E1_VENCREA,;      // 14 = Data de Vencimento Real do Título
		             FINR01A->E1_VALOR,;        // 15 = Valor do Título
		             FINR01A->E1_HIST,;         // 16 = Histótico do Título
		             FINR01A->E1_NUMBCO,;       // 17 = Nosso Número
		             FINR01A->E1_REGSE1,;       // 18 = Número do registro no arquivo
		             FINR01A->E1_AGEDEP,;       // 19 = Agência
		             FINR01A->E1_CONTA,;        // 20 = Conta
		             FINR01A->E1_XSUBCTA})      // 21 = SubConta
    
    FINR01A->(dbSkip())
  EndDo

  If Len(aTitulos) == 0
     aAdd(aTitulos, {.F.,"","","","","","","","","","","","","",0,"",0,"","","",""})
  EndIf

  dbSelectArea("FINR01A")
  FINR01A->(dbCloseArea())
Return

/*=============================================
--  Função: Cria tela de escolha do título   --
--          para impressão.                  --
===============================================*/    
Static Function fnCallTela(aTitulos)
  Local aScreen  := GetScreenRes()
  Local oSize 	:= FwDefSize():New()
  Local bCancel  := {|| RFINR01A(oDlg,@lRetorno,aTitulos) }
  Local bOk      := {|| RFINR01B(oDlg,@lRetorno,aTitulos) }
  Local aAreaAtu := GetArea()
  Local aLabel   := {" ",;
  	                 "Portador",;
  	                 "Prefixo",;
  	                 "Número",;
  	                 "Parcela",;
  	                 "Tipo",;
  	                 "Natureza",;
  	                 "Cliente",;
  	                 "Loja",;
  	                 "Nome Cliente",;
  	                 "EMail",;
  	                 "Emissão",;
  	                 "Vencimento",;
  	                 "Venc.Real",;
  	                 "Valor",;
  	                 "Histórico",;
  	                 "Nosso Número"}
  	                 
  Local aBotao   := {}
  Local lRetorno := .T.
  Local lMark    := .F.
  Local cList1
  Local oDlg
  Local oList1
  Local oMark

  Private oOk	   := LoadBitMap(GetResources(),"LBOK")
  Private oNo    := LoadBitMap(GetResources(),"NADA")
  Private nQtSel := 0
  Private nTtSel := 0
  
 // --- Pegar posição da tela
  oSize:aMargins     := { 0, 0, 0, 0 }        // Espaco ao lado dos objetos 0, entre eles 3
  oSize:aWindSize[3] := (oMainWnd:nClientHeight * 0.99)		
  oSize:lProp        := .F.                   // Proporcional
  oSize:Process()                             // Dispara os calculos

  aAdd(aBotao,{"S4WB011N",{|| U_fnVisReg("SA1",SA1->(aTitulos[oList1:nAt,08] + aTitulos[oList1:nAt,09]),2)},"[F11] - Visualiza Cliente","Cliente"})
  aAdd(aBotao,{"S4WB011N",{|| U_fnVisReg("SE1",SE1->(aTitulos[oList1:nAt,03] + aTitulos[oList1:nAt,04] +; 
                                                     aTitulos[oList1:nAt,05] + aTitulos[oList1:nAt,06] +;
                                                     aTitulos[oList1:nAt,08] + aTitulos[oList1:nAt,09]),2)},"[F12] - Visualiza Título","Título"})
  
  SetKey(VK_F11,{|| IIf(Len(aTitulos) > 0,U_fnVisReg("SA1",SA1->(aTitulos[oList1:nAt,08] + aTitulos[oList1:nAt,09]),2),; 
                                          MsgAlert("Não existe registro selecionado."))})

  SetKey(VK_F12,{|| IIf(Len(aTitulos) > 0,U_fnVisReg("SE1",SE1->(aTitulos[oList1:nAt,03] + aTitulos[oList1:nAt,04] +; 
                                                                 aTitulos[oList1:nAt,05] + aTitulos[oList1:nAt,06] +;
                                                                 aTitulos[oList1:nAt,08] + aTitulos[oList1:nAt,09]),2),;
                                          MsgAlert("Não existe registro selecionado."))})

  Define MsDialog oDlg Title cTitulo From oSize:aWindSize[1],oSize:aWindSize[2] To oSize:aWindSize[3],oSize:aWindSize[4];
           Pixel STYLE nOR( WS_VISIBLE, WS_POPUP ) Of oMainWnd Pixel //"Importação de Tabelas"

    @ 015,005 CHECKBOX oMark VAR lMark PROMPT "Marca Todos" FONT oDlg:oFont PIXEL SIZE 80,09 OF oDlg;
		ON CLICK (aEval(aTitulos, {|x,y| aTitulos[y,1] := lMark}), oList1:Refresh(), fnBOLSel(aTitulos))
    
    @ 030,003 LISTBOX oList1 VAR cList1 Fields HEADER ;
                                               aLabel[01],;
                                               aLabel[02],;
                                               aLabel[03],;
                                               aLabel[04],;
                                               aLabel[05],;
                                               aLabel[06],;
                                               aLabel[07],;
                                               aLabel[08],;
                                               aLabel[09],;
                                               aLabel[10],;
                                               aLabel[11],;
                                               aLabel[12],;
                                               aLabel[13],;
                                               aLabel[14],;
                                               aLabel[15],;
                                               aLabel[16],;
                                               aLabel[17] ;
		Size (oSize:aWindSize[4] - 685),(oSize:aWindSize[3] - 385) NOSCROLL PIXEL
		
    oList1:SetArray(aTitulos)
    oList1:bLine := {|| {If(aTitulos[oList1:nAt,01], oOk, oNo),;
		                 aTitulos[oList1:nAt,02],;
		                 aTitulos[oList1:nAt,03],;
		                 aTitulos[oList1:nAt,04],;
		                 aTitulos[oList1:nAt,05],;
		                 aTitulos[oList1:nAt,06],;
		                 aTitulos[oList1:nAt,07],;
		                 aTitulos[oList1:nAt,08],;
		                 aTitulos[oList1:nAt,09],;
		                 aTitulos[oList1:nAt,10],;
		                 aTitulos[oList1:nAt,11],;
		                 aTitulos[oList1:nAt,12],;
		                 aTitulos[oList1:nAt,13],;
		                 Transform(aTitulos[oList1:nAt,14],"@E 999,999,999.99"),;
		                 Transform(aTitulos[oList1:nAt,15],"@E 999,999,999.99"),;
		                 aTitulos[oList1:nAt,16],;
		                 aTitulos[oList1:nAt,17]}}

    oList1:blDblClick := {|| aTitulos[oList1:nAt,01] := !aTitulos[oList1:nAt,01], oList1:Refresh(), fnBOLSel(aTitulos)}
    oList1:cToolTip   := "Duplo click para marcar/desmarcar o título"
    oList1:Refresh()

    oSayTx1 := TSay():New((oSize:aWindSize[3] - 340),010,{|| "Selecionados:"},oDlg,,,,,,.T.,CLR_BLUE) 
    oSayQtd := TSay():New((oSize:aWindSize[3] - 340),060,{|| Transform(nQtSel,"@E 999,999,999")},oDlg,,,,,,.T.,CLR_BLUE)
 
    oSayTx2 := TSay():New((oSize:aWindSize[3] - 340),100,{|| "Total:"},oDlg,,,,,,.T.,CLR_BLUE) 
    oSayTot := TSay():New((oSize:aWindSize[3] - 340),130,{|| Transform(nTtSel,"@E 999,999,999.99")},oDlg,,,,,,.T.,CLR_BLUE)
    
    oBtImp := TButton():New(013,080,"Impressão",oDlg,{|| RFINR01B(oDlg,@lRetorno,aTitulos,2)},35,13,,,.F.,.T.,.F.,,.F.,,,.F.)
    oBtEma := TButton():New(013,125,"E-mail"   ,oDlg,{|| cGerArq := "2",RFINR01B(oDlg,@lRetorno,aTitulos,6)},35,13,,,.F.,.T.,.F.,,.F.,,,.F.)
    oBtCan := TButton():New(013,170,"Fechar"   ,oDlg,{|| RFINR01A(oDlg,@lRetorno,aTitulos)},35,13,,,.F.,.T.,.F.,,.F.,,,.F.)
  Activate MsDialog oDlg Centered //ON INIT EnchoiceBar(oDlg,bOk,bcancel,,aBotao)
Return(lRetorno)

/*----------------------------------
--  Função: Fechamento da tela    --
--                                --
------------------------------------*/
Static Function RFINR01A(oDlg,lRetorno, aTitulos)
  lRetorno := .F.

  oDlg:End()
Return(lRetorno)

/*----------------------------------------------
--  Função: Conta os registros selecionados.  --
--                                            --
------------------------------------------------*/
Static Function fnBOLSel(aTitulos)
  Local nId := 0
  
  nQtSel := 0
  nTtSel := 0
  
  For nId := 1 to Len(aTitulos)
      If aTitulos[nId][01]
         nTtSel += aTitulos[nId][15]
         nQtSel++
      EndIf   
  Next
  
  ObjectMethod(oSayQtd,"SetText('" + Transform(nQtSel  ,"@E 999,999,999") + "')")         
  ObjectMethod(oSayTot,"SetText('" + Transform(nTtSel  ,"@E 999,999,999.99") + "')")         
Return

/*-----------------------------------------
--  Função: Chamar Impressão de boleto.  --
--                                       --
-------------------------------------------*/
Static Function RFINR01B(oDlg,lRetorno, aTitulos, pTpImp)
  Local nLoop		:= 0
  Local nContador	:= 0

  lRetorno := .T.
  nTpImp   := pTpImp
  
  For nLoop := 1 To Len(aTitulos)
    If aTitulos[nLoop,1]
       nContador++
    EndIf
  Next

  If nContador > 0
     RptStatus( {|lEnd| ImpBol(aTitulos) }, cTitulo)
	else
     lRetorno := .F.
  EndIf

  oDlg:End()
Return(lRetorno)

/*==================================
--  Função: Visualizar título.    --
--                                --
====================================*/
User Function fnVisReg(cAlias, cRecAlias, nOpcEsc)
  Local aAreaAtu    := GetArea()
  Local aAreaAux    := (cAlias)->(GetArea())
  
  Private cCadastro := ""

  If ! Empty(cRecAlias)
     dbSelectArea(cAlias)
     (cAlias)->(dbSetOrder(1))
     (cAlias)->(dbSeek(xFilial(cAlias) + cRecAlias))
	
	 AxVisual(cAlias,(cAlias)->(Recno()),nOpcEsc)
  EndIf

  RestArea(aAreaAux)
  RestArea(aAreaAtu)
Return

/*-------------------------------------
--  Função: Impressão de boleto.     --
--                                   --
---------------------------------------*/
Static Function ImpBol(aTitulos)
  Local aEmpresa := {AllTrim(SM0->M0_NOMECOM),;                                   //[01] Nome da Empresa
                     AllTrim(SM0->M0_ENDENT),;                                    //[02] Endereço
                     AllTrim(SM0->M0_BAIRENT),;                                   //[03] Bairro
                     AllTrim(SM0->M0_CIDENT),;                                    //[04] Cidade
                     SM0->M0_ESTENT,;                                             //[05] Estado
                     "CEP: " + Transform(SM0->M0_CEPENT, "@R 99999-999"),;        //[06] CEP
                     "PABX/FAX: " + SM0->M0_TEL,;                                 //[07] Telefones
                     "CNPJ: " + Transform(SM0->M0_CGC, "@R 99.999.999/9999-99"),; //[08] CGC
                     "I.E.: " + Transform(SM0->M0_INSC, SuperGetMv("MV_IEMASC",.F.,"@R 999.999.999.999"))}	//[09] I.E
	
  Local aCB_RN_NN	:= {}
  Local aDadTit	:= {}
  Local aBanco	:= {}
  Local aSacado	:= {}
  Local aVlBol    := {}

// No máximo 8 elementos com 80 caracteres para cada linha de mensagem
  Local aBolTxt  := {"","","","","","","",""}
  Local nSaldo   := 0
  Local nLoop    := 0
  Local cAgencia := ""
  Local cNumCta  := ""
  Local cChvSA6  := ""
  Local cChvSEE  := ""
  Local cNmPDF   := ""
  Local lGerBor  := .F.
 
  Private oPrint
  Private nNumPag   := 1
  Private lBx       := .F.
  Private cDirGer   := AllTrim(mv_par24) + IIf(Substr(AllTrim(mv_par24),Len(AllTrim(mv_par24)),1) == "\","","\")
  Private cNumBor   := IIf(mv_par25 == 1,Soma1(GetMV("MV_NUMBORR"),6),0)
  Private cBanco    := ""
  Private cCmpLv    := ""
  Private cNN       := ""
  Private cCart     := ""
  Private cNNum     := ""
  Private cConvenio := ""
  Private cLogo     := ""
  Private nDesc     := 0
  Private nJurMul   := 0
  Private nRow      := 0
  Private nCols     := 0
  Private nWith     := 0

 // -- nTpImp = Tipo da impressão:
 //              2 - Spool ou
 //              6 - PDF (envio de e-mail) 
 // --------------------------------------
  If ! nTpImp == 6 .and. ! cTpImpre == "2"
     nPosPDF := 0

     oPrint:= TMSPrinter():New("Boleto Laser")
     oPrint:SetPortrait()
     oPrint:StartPage()
     oPrint:Setup()

   elseIf cTpImpre == "2"                               // Saida em PDF
        If cGerArq == "1"
           nPosPDF := 25
   
          // Nome do PDF: "Bol_" + Codigo Cliente + Loja Cliente + Banco + Prefixo + Titulo
           cNmPDF := "Bol_" + Substr(aSacado[2],1,TamSX3("A1_COD")[1]) + "_" +;
                       Substr(aSacado[2],(TamSX3("A1_COD")[1] + 2),TamSX3("A1_LOJA")[1]) +;
                       "_" + mv_par19 + "_" + AllTrim(aTitulos[01][03]) +;
                       "_" + AllTrim(aTitulos[01][04]) + "_TODAS" 
          // --------------------------------------------------           
  
           oPrint := FwMSPrinter():New(cNmPDF,6,.T.,cDirGer,.T.,.F.,,,,.T.,,.F.)
           oPrint:SetResolution(72)
           oPrint:SetMargin(5,5,5,5)
           oPrint:SetPortrait()								// ou SetLandscape()
        EndIf  
  EndIf
  
// Fazer pergunta de Centimetro ou Polegada

  nTipo := 1 /* Aviso(	"Impressão",;
		"Escolha o método de impressão.",;
		{"&Centimetro","&Polegada"},,;
		"A T E N Ç Ã O" ) */

  SetRegua(Len(aTitulos))

  cNumBor := Replicate("0",6-Len(Alltrim(cNumBor))) + Alltrim(cNumBor)

  While ! MayIUseCode("SE1"+xFilial("SE1")+cNumBor)      // verifica se esta na memoria, sendo usado
	// busca o proximo numero disponivel 
	cNumBor := Soma1(cNumBor)
  EndDo
 
 // Faz loop no array com os títulos a serem impressos
  For nLoop := 1 To Len(aTitulos)
      IncRegua("Titulo: "+aTitulos[nLoop,02]+"/"+aTitulos[nLoop,03]+"/"+aTitulos[nLoop,04])

	 // Se estiver marcado, imprime
      If aTitulos[nLoop,01]
         dbSelectArea("SE1")
         SE1->(dbGoTo(aTitulos[nLoop,18]))

         dbSelectArea("SA1")
         SA1->(dbSetOrder(1))
         SA1->(dbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))
         
         dbSelectArea("SA6")
         SA6->(dbSetOrder(1))
         
         If ! Empty(aTitulos[nLoop,02]) .and. mv_par23 == 2
            cChvSA6 := aTitulos[nLoop,02] + aTitulos[nLoop,19] + aTitulos[nLoop][20]
          else  
            cChvSA6 := mv_par19 + mv_par20 + mv_par21
         EndIf
         
         If ! SA6->(dbSeek(xFilial("SA6") + cChvSA6))
            Aviso("Emissão do Boleto","Banco não localizado no cadastro!",{"&Ok"},,;
                  "Banco: " + SubStr(cChvSA6,1,3) + "/" + SubStr(cChvSA6,4,5) + "/" + SubStr(cChvSA6,9,10))
            Loop
         EndIf
		
		//Posiciona na Configuração do Banco
         dbSelectArea("SEE")
         SEE->(dbGoTop())
         SEE->(dbSetOrder(1))

         If ! Empty(aTitulos[nLoop][02])
            cChvSEE := aTitulos[nLoop,02] + aTitulos[nLoop,19] + aTitulos[nLoop][20] + aTitulos[nLoop][21] 
          else  
            cChvSEE := mv_par19 + mv_par20 + mv_par21 + mv_par22
         EndIf
         
         If ! SEE->(dbSeek(xFilial("SEE") + cChvSEE))
            Aviso("Emissão do Boleto",	"Configuração dos parâmetros do banco não localizado no cadastro!",;
					{"&Ok"},,"Banco: " + Substr(cChvSEE,1,3) + "/" + SubStr(cChvSEE,4,5) + "/" +;
					SubStr(cChvSEE,9,10) + "/" + SubStr(cChvSEE,19,3))
            Loop
          else
            cLogo   := AllTrim(SEE->EE_XLOGO)
            aLinDig := {}
            
            aAdd(aLinDig, AllTrim(SEE->EE_XNNUM))     // Formatação do Nosso Numero
            aAdd(aLinDig, AllTrim(SEE->EE_XDGNN))     // Formatação para calculo no digito do nosso numero
            aAdd(aLinDig, AllTrim(SEE->EE_XMTNN))     // Montagem do Nosso Numero para o boleto
            aAdd(aLinDig, AllTrim(SEE->EE_XCRN1))     // Formatação da primeiro parte
            aAdd(aLinDig, AllTrim(SEE->EE_XCRN2))     // Formatação da segunda parte
            aAdd(aLinDig, AllTrim(SEE->EE_XCRN3))     // Formatação da terceira parte
            aAdd(aLinDig, AllTrim(SEE->EE_XCRN4))     // Formatação da quarta parte
            aAdd(aLinDig, AllTrim(SEE->EE_XCPLV))     // Formatação para Campo livre com digito
         EndIf
			
         dbSelectArea("SE1")

         If SA6->A6_COD == "237"                      // BRADESCO
            cAgencia := IIf(Len(AllTrim(SA6->A6_AGENCIA)) < 4,PadL(AllTrim(SA6->A6_AGENCIA),4,"0"),AllTrim(SA6->A6_AGENCIA))
            cNumCta  := PadL(AllTrim(SA6->A6_NUMCON),7,"0")

          elseIf SA6->A6_COD == "422"                 // SAFRA
                 cAgencia := PadR(SubStr(SA6->A6_AGENCIA,2,3),5,"0")
                 cNumCta  := PadL(AllTrim(SA6->A6_NUMCON),8,"0")
               else
                 cAgencia := IIf(Len(AllTrim(SA6->A6_AGENCIA)) < 4,PadL(AllTrim(SA6->A6_AGENCIA),4,"0"),AllTrim(SA6->A6_AGENCIA))
                 cNumCta  := AllTrim(SA6->A6_NUMCON)
         EndIf        
        
         aBanco := {AllTrim(SA6->A6_COD),;                                                             // [01] Numero do Banco
                    SA6->A6_NREDUZ,;                                                                   // [02] Nome do Banco
                    cAgencia,;                                                                         // [03] Agência
                    cNumCta,;                                                                          // [04] Conta Corrente
                    SubStr(SA6->A6_DVCTA,At("-",SA6->A6_DVCTA)+1,1),;                                  // [05] Dígito da conta corrente
                    AllTrim(SEE->EE_CODCART),;                                                         // [06] Codigo da Carteira
                    SEE->EE_XDVBCO,;                                                                   // [07] Dígito do Banco
                    SA6->A6_DVAGE,;                                                                    // [08] Digito da Agência
                    IIf(AllTrim(SA6->A6_COD) $ ("341/104"),AllTrim(SEE->EE_CODEMP),StrZero(Val(SEE->EE_CODEMP),7)),;// [09] Convêncio com o Banco
                    IIf(SEE->EE_TPCOBRA == "1",;
                      IIf(AllTrim(SA6->A6_COD) $ "104/033",AllTrim(SEE->EE_TIPCART),AllTrim(SEE->EE_CODCART)),"SR")}// [10] Tipo da Carteira

			   If Empty(SA1->A1_ENDCOB)
				    aSacado := {AllTrim(SA1->A1_NOME),;						                 // [1] Razão Social
				                AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA,;                 // [2] Código
				                AllTrim(SA1->A1_END ) + " - " + AllTrim(SA1->A1_BAIRRO),;    // [3] Endereço
				                AllTrim(SA1->A1_MUN ),;                                      // [4] Cidade
				                SA1->A1_EST,;                                                // [5] Estado
				                SA1->A1_CEP,;                                                // [6] CEP
				                SA1->A1_CGC,;                                                // [7] CGC
				                SA1->A1_PESSOA}                                              // [8] PESSOA

			    else
				    aSacado := {AllTrim(SA1->A1_NOME),;                                        // [1] Razão Social
				                AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA,;                   // [2] Código
                            AllTrim(SA1->A1_ENDCOB) + " - " + AllTrim(SA1->A1_BAIRROC),;   // [3] Endereço
                            AllTrim(SA1->A1_MUNC),;                                        // [4] Cidade
                            SA1->A1_ESTC,;                                                 // [5] Estado
                            SA1->A1_CEPC,;                                                 // [6] CEP
                            SA1->A1_CGC,;                                                  // [7] CGC
                           SA1->A1_PESSOA}                                                // [8] PESSOA
			   Endif

		// Define o valor do título considerando Acréscimos e Decréscimos
		   aVlBol  := U_fnSldBol(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_CLIENTE,SE1->E1_LOJA)
         nSaldo  := aVlBol[01]                // Valor do documento
         nJurMul := aVlBol[03]                // Valor de Mora/Multa (Acréscimos)
         nDesc   := aVlBol[04]                // Valor do desconto (Decréscimos)

		// Define o Nosso Número
			If ! Empty(SE1->E1_NUMBCO) .and. mv_par23 == 2
				cNNum	:= Substr(AllTrim(SE1->E1_NUMBCO),1,(len(Alltrim(SE1->E1_NUMBCO)) - 1))
				bRetImp := .T. 
			 else              
              bRetImp := .F.
              cNNum   := AllTrim(SEE->EE_FAXATU)
			
				dbSelectArea("SEE")
				RecLock("SEE",.F.)
				  Replace SEE->EE_FAXATU with Soma1(Alltrim(SEE->EE_FAXATU),11)
				SEE->(MsUnLock())
			EndIf         
			
			dbSelectArea("SE1")

		  // ---- Monta codigo de barras
          aCB_RN_NN := Ret_cBarra(Subs(aBanco[1],1,3),;	         		// [01]-Banco+Fixo 9
                                  aBanco[3],;					    	// [02]-Agencia
                                  aBanco[4],;	    			    	// [03]-Conta
                                  aBanco[5],;						    // [04]-Digito Conta
                                  aBanco[6],;						    // [05]-Carteira
                                  cNNum,;							    // [06]-Nosso Número
                                  nSaldo,;						        // [07]-Valor do Título
                                  SE1->E1_VENCREA /*SE1->E1_VENCTO*/,;  // [08]-Vencimento
                                  aBanco[9],;                           // [09]-Convêncio
                                  SEE->EE_XMODELO,;                     // [10]-Modulo para calculo do digito verificador do Nosso Número
                                  SEE->EE_XPESO)                        // [11]-Peso para calcular o digito do nosso número modulo 11
 
          dbSelectArea("SE1")

          aDadTit := {AllTrim(E1_NUM) + IIf(Empty(E1_PARCELA),"","/" + E1_PARCELA),;  // [01] Número do título
                      E1_EMISSAO,;                                                    // [02] Data da emissão do título
                      dDataBase,;                                                     // [03] Data da emissão do boleto
                      E1_VENCREA  /*E1_VENCTO*/,;                                     // [04] Data do vencimento
                      nSaldo,;                                                        // [05] Valor do título
                      aCB_RN_NN[3],;                                                  // [06] Nosso número (Ver fórmula para calculo)
                      E1_PREFIXO,;                                                    // [07] Prefixo da NF
                      SEE->EE_X_ESPDC,;                                               // [08] Tipo do Titulo
                      E1_HIST,;                                                       // [09] HISTORICO DO TITULO
                      aCB_RN_NN[4],;                                                  // [10] Nosso numero para gravação na "SE1"
                      SEE->EE_XLOCPG}                                                 // [11] Mensagem de Local de Pagamento                                  

			aBolTxt := {"","","","","","","",""}
		
          If SEE->EE_X_MULTA > 0
             aBolTxt[1] := "Multa de R$ " + Alltrim(Transform(((aDadTit[5] * SEE->EE_X_MULTA) / 100),"@E 99,999.99")) + " após o vencimento."
          EndIf
			
          If SEE->EE_X_JURME > 0
             aBolTxt[2] := "Juros de R$ " + AllTrim(Transform(((aDadTit[5] * SEE->EE_X_JURME) / 100),"@E 99,999.99")) + " ao dia."
          EndIf

          If ! Empty(SE1->E1_HIST)
             aBolTxt[3] := AllTrim(SE1->E1_HIST)
          EndIf
          
          If Val(SEE->EE_DIASPRT) > 0
             aBolTxt[4] := "Título sujeito a protesto após " + SEE->EE_DIASPRT + " dias de vencimento."
          EndIf
			
          If ! Empty(Alltrim(SEE->EE_FORMEN1))
             aBolTxt[5] := AllTrim(&(SEE->EE_FORMEN1))
          EndIf
			
          If ! Empty(Alltrim(SEE->EE_FORMEN2))
             aBolTxt[6] := AllTrim(&(SEE->EE_FORMEN2))
          EndIf

          If ! Empty(Alltrim(SEE->EE_FOREXT1))
             aBolTxt[7] := AllTrim(&(SEE->EE_FOREXT1)) 
          EndIf
			
          If ! Empty(Alltrim(SEE->EE_FOREXT2))
		      aBolTxt[8] := AllTrim(&(SEE->EE_FOREXT2))
          EndIf

		  // Sempre Incremento a mensagem de não receber após vencimento
         //  aBolTxt[8]	:= "SR. CAIXA, NÃO RECEBER APÓS O VENCIMENTO"

         // Valida se é impressão em PDF para envio de E-mail ou impressão somente PDF
          If nTpImp == 6 .or. cTpImpre == "2" 
             If cGerArq == "2"
                nPosPDF := 25
 
               // -- Nome do PDF: "Bol_" + Codigo Cliente + Loja Cliente + Banco + Prefixo + Titulo + Parcela
               // -------------------------------------------------------------------------------------------
                cNmPDF := "Bol_" + AllTrim(Substr(aSacado[2],1,TamSX3("A1_COD")[1])) + "_" +;
                          Substr(aSacado[2],(TamSX3("A1_COD")[1] + 2),TamSX3("A1_LOJA")[1]) +;
                          "_" + mv_par19 + "_" + AllTrim(aTitulos[nLoop][03]) +;
                          "_" + AllTrim(aTitulos[nLoop][04]) +;
                          IIf(Empty(aTitulos[nLoop][05]),"","_" + AllTrim(aTitulos[nLoop,5])) + ".PDF"
               // -------------------------------------------------------------------------------------------           
  
                oPrint := FwMSPrinter():New(cNmPDF,6,.T.,cDirGer,.T.,.F.,,,,.T.,,.F.)
                oPrint:SetResolution(72)
                oPrint:SetMargin(5,5,5,5)
          
                oPrint:SetPortrait()
             EndIf
             	
             oPrint:StartPage()
 
             If mv_par26 == 1                              
                fnImprRd(oPrint,aEmpresa,aDadTit,aBanco,aSacado,aBolTxt,aCB_RN_NN,cNNum)     // Impressão boleto reduzido
              else  
                fnImpres(oPrint,aEmpresa,aDadTit,aBanco,aSacado,aBolTxt,aCB_RN_NN,cNNum)     // Impressão boleto completo
             EndIf   

             If cTpImpre == "1"      // Se não for direito PDF
                oPrint:EndPage()     // Finaliza a página
                oPrint:Preview()     // Visualiza antes de imprimir
                FreeObj(oPrint)      // Destruir objeto

              elseIf cGerArq == "2"  // Gravar na pasta para envio por e-mail
                     cFilePrint := cDirGer + cNmPDF

                     File2Printer(cFilePrint,"PDF")
                     oPrint:cPathPDF := cDirGer
                     oPrint:EndPage()
                     oPrint:Preview()
                     FreeObj(oPrint)              
             EndIf   
           else
             oPrint:StartPage()
 
             If mv_par26 == 1
                fnImprRd(oPrint,aEmpresa,aDadTit,aBanco,aSacado,aBolTxt,aCB_RN_NN,cNNum)     // Impressão boleto reduzido
              else  
                fnImpres(oPrint,aEmpresa,aDadTit,aBanco,aSacado,aBolTxt,aCB_RN_NN,cNNum)     // Impressão boleto completo
             EndIf   
          EndIf
		  // -----------------------------------------------
		  	
          dbSelectArea("SE1")
          SE1->(dbGoTo(aTitulos[nLoop,18]))			
          
          Reclock("SE1",.F.)
			   Replace SE1->E1_PORTADOR with mv_par19
			   Replace SE1->E1_AGEDEP   with mv_par20
			   Replace SE1->E1_CONTA    with mv_par21
			   Replace SE1->E1_XSUBCTA  with mv_par22
          SE1->(MsUnlock())
          
         // -- Geração de Bordero
         // --------------------- 
          If mv_par23 <> 2 .and. mv_par25 == 1
             cNumBor := Replicate("0",6-Len(Alltrim(cNumBor))) + Alltrim(cNumBor)

             While ! MayIUseCode("SE1" + xFilial("SE1") + cNumBor)      // verifica se esta na memoria, sendo usado
	            cNumBor := Soma1(cNumBor)                                // busca o proximo numero disponivel
             EndDo

             fnGrvBrd()
  
             PutMv("MV_NUMBORR", cNumBor)
             
             lGerBor := .T.
          EndIf
         // ------------------------  
		EndIf
  Next 

  If lGerBor             
     Aviso("ATENÇÃO","Bordero - " + cNumBor + " gerado com sucesso...",{"OK"})
  EndIf

  If ! nTpImp == 6 .and. ! cTpImpre == "2"
     oPrint:EndPage()
     oPrint:Preview()
   else  
/*     cFilePrint := cDirGer + cNmPDF

     File2Printer(cFilePrint,"PDF")
     oPrint:cPathPDF := cDirGer
     oPrint:EndPage()
     oPrint:Preview()
     FreeObj(oPrint)
*/
     If ! cTpImpre == "2"
        MsAguarde({|| U_fnEnvBol(aTitulos)},"Enviando boleto(s) por e-mail...",SM0->M0_FILIAL)
     EndIf
  EndIf      
Return

/*------------------------------------
--  Função: Impressão dos dados.    --
--                                  --
--------------------------------------*/
Static Function fnImpres(oPrint,aEmpresa,aDadTit,aBanco,aSacado,aBolTxt,aCB_RN_NN,cNNum)
  Local nI       := 0
  Local cBmp     := ""
  Local oFont07  := TFont():New("Arial Narrow",9,07,.T.,.F.,5,.T.,5,.T.,.F.)
  Local oFont07n := TFont():New("Arial Narrow",9,07,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont08  := TFont():New("Arial"       ,9,08,.T.,.F.,5,.T.,5,.T.,.F.)
  Local oFont08n := TFont():New("Arial"       ,9,08,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont11c := TFont():New("Courier New" ,9,11,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont10  := TFont():New("Arial"       ,9,10,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont15n := TFont():New("Arial"       ,9,15,.T.,.F.,5,.T.,5,.T.,.F.)    
  Local oFont20  := TFont():New("Arial"       ,9,20,.T.,.T.,5,.T.,5,.T.,.F.)
  
  cBmp	:= cStartPath + cLogo + ".bmp"

 // ---- Primeiro Bloco - Recibo de Entrega
  nRow1 := 0
 
  oPrint:Line(nRow1 + 0070, 500, nRow1 + (150 - nPosPDF), 500)							// Quadro
  oPrint:Line(nRow1 + 0070, 710, nRow1 + (150 - nPosPDF), 710)							// Quadro

 // ---- O Tamanho da Figura tem que ser 381 X 68 Pixel para imprimir corretamente no boleto
//  oPrint:SayBitMap(nRow1+0034,100,cBmp,380,110)

  oPrint:SayBitMap((0040 - nPosPDF),100,cBmp,380,(110 - nPosPDF))
//  oPrint:SayBitMap((0084 - nPosPDF),100,cBmp,280,(110 - nPosPDF))                 // Logo marca

  oPrint:Say(nRow1 + 0075, 513, aBanco[1] + "-" + aBanco[7], oFont20)	              // Número do Banco + Dígito

  oPrint:Say(nRow1 + 0084, 1900,"Comprovante de Entrega", oFont10)                  
  oPrint:Line(nRow1 + (150 - nPosPDF), 100, nRow1 + (150 - nPosPDF), 2300)          // Quadro

  oPrint:Say(nRow1 + 0150, 0100, "Beneficiário" , oFont08)                        
  oPrint:Say(nRow1 + 0178, 0100, AllTrim(aEmpresa[01]), oFont08n)                   // Nome da Empresa
  oPrint:Say(nRow1 + 0215, 0100, aEmpresa[08], oFont08)                             // CNPJ da Empresa
  oPrint:Say(nRow1 + 0150, 1060, "Agência/Código Beneficiário", oFont08)
	
  Do Case                                                                           // Agencia + Cód.Cedente + Dígito
     Case Empty(aBanco[5])
          oPrint:Say(nRow1 + 0200,1125, aBanco[3] + "/" + aBanco[4], oFont10)

     Case aBanco[1] == "104" .or. aBanco[1] == "033"
          oPrint:Say(nRow1 + 0200,1125, aBanco[3] + "/" + aBanco[9], oFont10)
     
     Case aBanco[1] == "341" 
          oPrint:Say(nRow1 + 0200,1125, aBanco[3] + "/" + AllTrim(aBanco[4]) + "-" + aBanco[5], oFont10)

     Case aBanco[1] == "422" 
          oPrint:Say(nRow1 + 0200,1125, aBanco[3] + "/" + aBanco[4] + aBanco[5], oFont10)

     OtherWise
          oPrint:Say(nRow1 + 0200,1125, aBanco[3] + IIf(Empty(AllTrim(aBanco[8])),"","-") + aBanco[8] +;
                                        " / " + AllTrim(aBanco[4]) + "-" + aBanco[5],oFont10)
  EndCase
	
  oPrint:Say(nRow1 + 0150, 1510, "Nro.Documento", oFont08)
  oPrint:Say(nRow1 + 0200, 1550, aDadTit[1],	oFont10)                          // Prefixo + Numero + Parcela

  oPrint:Say(nRow1 + 0250, 100, "Nome do Pagador", oFont08)
  oPrint:Say(nRow1 + 0300, 100, aSacado[1], oFont10)

  oPrint:Say(nRow1 + 0250, 1060, "Vencimento", oFont08)
  oPrint:Say(nRow1 + 0300, 1125, StrZero(Day(aDadTit[4]),2) + "/" + StrZero(Month(aDadTit[4]),2) +;
		                          "/" + Right(Str(Year(aDadTit[4])),4), oFont10)

  oPrint:Say(nRow1 + 0250, 1510, "Valor do Documento", oFont08)
  oPrint:Say(nRow1 + 0300, 1600, AllTrim(Transform(aDadTit[5],"@E 999,999,999.99")), oFont10)

  oPrint:Say(nRow1 + 0400, 0100, "Recebi(emos) o bloqueto/título",	 oFont10)
  oPrint:Say(nRow1 + 0450, 0100, "com as características acima.", oFont10)
  oPrint:Say(nRow1 + 0350, 1060, "Data", oFont08)
  oPrint:Say(nRow1 + 0350, 1410, "Assinatura", oFont08)
  oPrint:Say(nRow1 + 0450, 1060, "Data", oFont08)
  oPrint:Say(nRow1 + 0450, 1410, "Entregador", oFont08)

  oPrint:Line(nRow1 + (250 - nPosPDF), 0100, nRow1 + (250 - nPosPDF), 1800)
  oPrint:Line(nRow1 + (350 - nPosPDF), 0100, nRow1 + (350 - nPosPDF), 1800)
  oPrint:Line(nRow1 + (450 - nPosPDF), 1050, nRow1 + (450 - nPosPDF), 1800)
  oPrint:Line(nRow1 + (550 - nPosPDF), 0100, nRow1 + (550 - nPosPDF), 2300)

  oPrint:Line(nRow1 + (550 - nPosPDF), 1050, nRow1 + (150 - nPosPDF), 1050)
  oPrint:Line(nRow1 + (550 - nPosPDF), 1400, nRow1 + (350 - nPosPDF), 1400)
  oPrint:Line(nRow1 + (350 - nPosPDF), 1500, nRow1 + (150 - nPosPDF), 1500)
  oPrint:Line(nRow1 + (550 - nPosPDF), 1800, nRow1 + (150 - nPosPDF), 1800)

  oPrint:Say(nRow1 + 0165, 1810, " (  )  Mudou-se", oFont08)
  oPrint:Say(nRow1 + 0205, 1810, " (  )  Ausente", oFont08)
  oPrint:Say(nRow1 + 0245, 1810, " (  )  Não existe nº indicado", oFont08)
  oPrint:Say(nRow1 + 0285, 1810, " (  )  Recusado", oFont08)
  oPrint:Say(nRow1 + 0325, 1810, " (  )  Não procurado", oFont08)
  oPrint:Say(nRow1 + 0365, 1810, " (  )  Endereço insuficiente", oFont08)
  oPrint:Say(nRow1 + 0405, 1810, " (  )  Desconhecido", oFont08)
  oPrint:Say(nRow1 + 0445, 1810, " (  )  Falecido", oFont08)
  oPrint:Say(nRow1 + 0485, 1810, " (  )  Outros(anotar no verso)", oFont08)

 //--------------------------------------------------------------------------------------------------------------//           
 // Segundo Bloco - Recibo do Sacado                                                                             //
 //--------------------------------------------------------------------------------------------------------------//
  nRow2 := 0

 // ---- Pontilhado separador
  For nI := 100 to 2300 step 50
	  oPrint:Line(nRow2 + 0580, nI, nRow2 + 0580, nI + 30)
  Next nI
 // --------------------------
 
  oPrint:Line(nRow2 + (710 - nPosPDF), 100, nRow2 + (710 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (710 - nPosPDF), 500, nRow2 + (630 - nPosPDF), 500)
  oPrint:Line(nRow2 + (710 - nPosPDF), 710, nRow2 + (630 - nPosPDF), 710)

  oPrint:SayBitMap(nRow2 + 0590, 100, cBmp, 380, (110 - nPosPDF))
  oPrint:Say(nRow2 + 0635, 0513, aBanco[1] + "-" + aBanco[7], oFont20)	// Numero do Banco + Dígito
  oPrint:Say(nRow2 + 0644, 1800, "Recibo do Pagador", oFont10)

  oPrint:Line(nRow2 + (810 - nPosPDF), 100, nRow2 + (810 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (910 - nPosPDF), 100, nRow2 + (910 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (980 - nPosPDF), 100, nRow2 + (980 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1050 - nPosPDF), 100, nRow2 + (1050 - nPosPDF), 2300)

  oPrint:Line(nRow2 + (910 - nPosPDF), 0500, nRow2 + (1050 - nPosPDF), 0500)
  oPrint:Line(nRow2 + (980 - nPosPDF), 0750, nRow2 + (1050 - nPosPDF), 0750)
  oPrint:Line(nRow2 + (910 - nPosPDF), 1000, nRow2 + (1050 - nPosPDF), 1000)
  oPrint:Line(nRow2 + (910 - nPosPDF), 1300, nRow2 + (980 - nPosPDF), 1300)
  oPrint:Line(nRow2 + (910 - nPosPDF), 1480, nRow2 + (1050 - nPosPDF), 1480)

  oPrint:Say(nRow2 + 710,100,"Local de Pagamento",oFont08)
  oPrint:Say(nRow2 + 745,300,aDadTit[11]         ,oFont08n)

/*  If aBanco[1] == "104"
     oPrint:Say(nRow2 + 730, 400, "PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE", oFont10)
   elseIf aBanco[1] == 
	  oPrint:Say(nRow2 + 720, 400, "ATÉ O VENCIMENTO, PREFERENCIALMENTE NO " + aBanco[2], oFont10)
	  oPrint:Say(nRow2 + 760, 400, "APÓS O VENCIMENTO, SOMENTE NO " + aBanco[2], oFont10)
  EndIf*/	  

  oPrint:Say(nRow2 + 0710, 1810, "Vencimento", oFont08)
  
  cString	:= StrZero(Day(aDadTit[4]),2) + "/" + StrZero(Month(aDadTit[4]),2) + "/" + Right(Str(Year(aDadTit[4])),4)
  nCol     := 1910 + (374 - (len(cString) * 22))
  
  oPrint:Say(nRow2 + 0750, nCol, cString,	oFont11c)	         // Vencimento

  oPrint:Say(nRow2 + 0810, 100, "Beneficiário"  , oFont08)
  oPrint:Say(nRow2 + 0838, 100, AllTrim(aEmpresa[01]) + " - " + aEmpresa[08], oFont08n)             // Nome + CNPJ
  oPrint:Say(nRow2 + 0870, 100, AllTrim(aEmpresa[02]) + " - " + AllTrim(aEmpresa[03]) + " - " +;
                                AllTrim(aEmpresa[04]) + "/" + aEmpresa[05], oFont08)                // Endereço da empresa

  oPrint:Say(nRow2 + 0810, 1810, "Agência/Código Beneficiário", oFont08)

  Do Case                            // Agencia + Cód.Cedente + Dígito
     Case Empty(aBanco[5])
          cString := aBanco[3] + "/" + aBanco[4]

     Case aBanco[1] == "104" .or. aBanco[1] == "033"
          cString := aBanco[3] + "/" + aBanco[9]

     Case aBanco[1] == "341"
          cString := aBanco[3] + "/" + AllTrim(aBanco[4]) + "-" + aBanco[5]

     Case aBanco[1] == "422"
          cString := aBanco[3] + " / " + aBanco[4] + aBanco[5]

     OtherWise        
          cString := aBanco[3] + IIf(Empty(AllTrim(aBanco[8])),"","-") + aBanco[8] + " / " +;
                     AllTrim(aBanco[4]) + "-" + aBanco[5]
  EndCase

  nCol := 1910 + (373 - (len(cString) * 22))
  
  oPrint:Say(nRow2 + 0850, nCol, cString, oFont11c)	                              // Agência + Código Beneficiário

  oPrint:Say(nRow2 + 0910, 100, "Data do Documento", oFont08)
  oPrint:Say(nRow2 + 0940, 140, StrZero(Day(aDadTit[2]),2) +;
                                "/" + StrZero(Month(aDadTit[2]),2) +;
                                "/" + Right(Str(Year(aDadTit[2])),4), oFont10)	  // Data do Documento

  oPrint:Say(nRow2 + 0910, 505, "Nro.Documento",	oFont08)
  oPrint:Say(nRow2 + 0940, 625, aDadTit[1], oFont10)	                              // Prefixo + Numero + Parcela

  oPrint:Say(nRow2 + 0910, 1005, "Espécie Doc.",	oFont08)
  oPrint:Say(nRow2 + 0940, 1090, aDadTit[8],	oFont10)                             // Tipo do Titulo

  oPrint:Say(nRow2 + 0910, 1305, "Aceite", oFont08)
  oPrint:Say(nRow2 + 0940, 1390, "N",	oFont10)

  oPrint:Say(nRow2 + 0910, 1485, "Data do Processamento", oFont08)
  oPrint:Say(nRow2 + 0940, 1550, StrZero(Day(aDadTit[3]),2) + "/" + StrZero(Month(aDadTit[3]),2) +;
                                 "/" + Right(Str(Year(aDadTit[3])),4), oFont10)	  // Data impressao

  oPrint:Say(nRow2 + 0910, 1810, "Carteira / Nosso Número", oFont08)

  cString := aDadTit[6]
  nCol    := 1910 + (373 - (len(cString) * 22))
  
  oPrint:Say(nRow2 + 0940, nCol, cString,	oFont11c)	                              // Nosso Número

  oPrint:Say(nRow2 + 0980, 100, "Uso do Banco", oFont08)

  oPrint:Say(nRow2 + 0980, 505, "Carteira", oFont08)
  
  If aBanco[1] == "033"
     oPrint:Say(nRow2 + 1010,505,aBanco[10], oFont07)
   else
     oPrint:Say(nRow2 + 1010,565,aBanco[10], oFont10)
  EndIf
  
  oPrint:Say(nRow2 + 0980, 755, IIf(aBanco[1] == "104","Espécie Moeda","Espécie"), oFont08)
  oPrint:Say(nRow2 + 1010, 825, "R$", oFont10)

  oPrint:Say(nRow2 + 0980, 1005, "Qtde Moeda", oFont08)
  oPrint:Say(nRow2 + 0980, 1485, "Valor",	oFont08)

  oPrint:Say(nRow2 + 0980, 1810, "Valor do Documento", oFont08)
  
  cString := Alltrim(Transform(aDadTit[5],"@E 99,999,999.99"))
  nCol    := 1910 + (374 - (len(cString) * 22))
  
  oPrint:Say(nRow2 + 1010, nCol, cString,	oFont11c)	// Valor do Título

  If aBanco[1] == "104"
     oPrint:Say(nRow2 + 1050, 0100,"Instruções (Texto de Responsabilidade do Beneficiário):", oFont08)
   else  
     oPrint:Say(nRow2 + 1050, 0100, "Instruções (Todas informações deste bloqueto são de exclusiva " +;
                                    "responsabilidade do beneficiário)", oFont08)
  EndIf
                             
  If Len(aBolTxt) > 0
     oPrint:Say(nRow2 + 1090, 0100, aBolTxt[1], oFont08n)	// 1a Linha Instrução
     oPrint:Say(nRow2 + 1130, 0100, aBolTxt[2], oFont08n)	// 2a. Linha Instrução
     oPrint:Say(nRow2 + 1170, 0100, aBolTxt[3], oFont08n)	// 3a. Linha Instrução
     oPrint:Say(nRow2 + 1210, 0100, aBolTxt[4], oFont08)	// 4a Linha Instrução
     oPrint:Say(nRow2 + 1250, 0100, aBolTxt[5], oFont08)	// 5a. Linha Instrução
     oPrint:Say(nRow2 + 1290, 0100, aBolTxt[6], oFont08)	// 6a. Linha Instrução
     oPrint:Say(nRow2 + 1330, 0100, aBolTxt[7], oFont08)	// 7a. Linha Instrução
     oPrint:Say(nRow2 + 1370, 0100, aBolTxt[8], oFont08)	// 8a. Linha Instrução
   else
	 oPrint:Say(nRow2 + 1090, 0100, aDadTit[9], oFont08)	// 1a Linha Instrução
	 oPrint:Say(nRow2 + 1370, 0100, aBolTxt[8], oFont08)	// 8a. Linha Instrução
  EndIf

  oPrint:Say(nRow2 + 1050, 1810, "(-)Desconto/Abatimento",	oFont08)
  oPrint:Say(nRow2 + 1120, 1810, "(-)Outras Deduções", oFont08)
  oPrint:Say(nRow2 + 1190, 1810, "(+)Mora/Multa", oFont08)
  oPrint:Say(nRow2 + 1260, 1810, "(+)Outros Acréscimos", oFont08)
  oPrint:Say(nRow2 + 1330, 1810, "(=)Valor Cobrado", oFont08)

  oPrint:Say(nRow2 + 1400, 0100, IIf(aBanco[1] == "104","Pagador","Nome do Pagador"), oFont08)
  oPrint:Say(nRow2 + 1400, 0550, "("+aSacado[2] + ") " + aSacado[1], oFont08n)	// Nome do Cliente + Código

  If Empty(aSacado[7]) 
     oPrint:Say(nRow2 + 1400, 1850, "CPF/CNPJ NAO CADASTRADO",oFont08)
   elseIf aSacado[8] == "J" .and. ! Empty(aSacado[7])
          oPrint:Say(nRow2 + 1400, 1850, "CNPJ: " + Transform(aSacado[7],"@R 99.999.999/9999-99"), oFont08)	// CGC
        elseIf aSacado[8] == "F" .and. ! Empty(aSacado[7])
               oPrint:Say(nRow2 + 1400, 1850, "CPF: " + Transform(aSacado[7],"@R 999.999.999-99"), oFont08)	// CPF
  EndIf

  If Empty(aSacado[3])
     aSacado[3] := "LOGRADOURO NAO CADASTRADO"
  EndIf

  If Empty(aSacado[4])
     aSacado[4] := "MUNICIPIO NAO CADASTRADO"
  EndIf

  If Empty(aSacado[5])
     aSacado[5] := "UF NAO CADASTRADA"
  EndIf

  oPrint:Say(nRow2 + 1443, 0550, aSacado[3], oFont08)	// Endereço	

  If Empty(aSacado[6])
     oPrint:Say(nRow2 + 1483, 0550, "CEP NAO CADASTRADO" + " - " + aSacado[4] + " - " + aSacado[5], oFont08)
   else
     oPrint:Say(nRow2 + 1483, 0550, Transform(aSacado[6],"@R 99999-999") + " - " + aSacado[4] + " - " +;
										 aSacado[5], oFont08)	// CEP + Cidade + Estado
  EndIf										

  oPrint:Say(nRow2 + 1483, 1850, aDadTit[6], oFont08)	   // Carteira + Nosso Número

  oPrint:Say(nRow2 + 1605, 0100, IIf(aBanco[1] == "033","Sacador Avalista","Pagador/Avalista"), oFont08)
  oPrint:Say(nRow2 + 1605, 1850, "Código de Baixa", oFont08)
  
  oPrint:Say(nRow2 + 1645, 1500, "Autenticação Mecânica", oFont08)

  oPrint:Line(nRow2 + (710 - nPosPDF) , 1800, nRow2 + (1400 - nPosPDF), 1800)
  oPrint:Line(nRow2 + (1120 - nPosPDF), 1800, nRow2 + (1120 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1190 - nPosPDF), 1800, nRow2 + (1190 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1260 - nPosPDF), 1800, nRow2 + (1260 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1330 - nPosPDF), 1800, nRow2 + (1330 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1400 - nPosPDF), 0100, nRow2 + (1400 - nPosPDF), 2300)
  oPrint:Line(nRow2 + (1640 - nPosPDF), 0100, nRow2 + (1640 - nPosPDF), 2300)

 //--------------------------------------------------------------------------------------------------------------//
 // Terceiro Bloco - Ficha de Compensação                                                                        //
 //--------------------------------------------------------------------------------------------------------------//
  nRow3 := 0

  For nI := 100 to 2300 step 50
      oPrint:Line(nRow3+1874, nI, nRow3+1874, nI+30) 										// Linha Pontilhada
  Next nI

  oPrint:Line(nRow3 + (2000 - nPosPDF), 100, nRow3 + (2000 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2000 - nPosPDF), 500, nRow3 + (1920 - nPosPDF), 0500)
  oPrint:Line(nRow3 + (2000 - nPosPDF), 710, nRow3 + (1920 - nPosPDF), 0710)

  oPrint:SayBitMap(nRow3 + 1884,100,cBmp,380,(110 - nPosPDF))	    					   // Nome do Banco
  oPrint:Say(nRow3 + 1925, 513, aBanco[01] + "-" + aBanco[07], oFont20)                // Numero do Banco + Dígito
  oPrint:Say(nRow3 + 1934, 755,aCB_RN_NN[02], oFont15n)	                               // Linha Digitavel do Codigo de Barras

  oPrint:Line(nRow3 + (2100 - nPosPDF), 100, nRow3 + (2100 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2200 - nPosPDF), 100, nRow3 + (2200 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2270 - nPosPDF), 100, nRow3 + (2270 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2340 - nPosPDF), 100, nRow3 + (2340 - nPosPDF), 2300)

  oPrint:Line(nRow3 + (2200 - nPosPDF), 0500, nRow3 + (2340 - nPosPDF), 0500)
  oPrint:Line(nRow3 + (2270 - nPosPDF), 0750, nRow3 + (2340 - nPosPDF), 0750)
  oPrint:Line(nRow3 + (2200 - nPosPDF), 1000, nRow3 + (2340 - nPosPDF), 1000)
  oPrint:Line(nRow3 + (2200 - nPosPDF), 1300, nRow3 + (2270 - nPosPDF), 1300)
  oPrint:Line(nRow3 + (2200 - nPosPDF), 1480, nRow3 + (2340 - nPosPDF), 1480)

  oPrint:Say(nRow3 + 2000, 100,"Local de Pagamento",oFont08)
  oPrint:Say(nRow3 + 2030, 300,aDadTit[11]         ,oFont08n)

/*  If aBanco[1] == "104"
     oPrint:Say(nRow3 + 2020, 400, "PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE", oFont10)
   else
     oPrint:Say(nRow3 + 2010, 400, "ATÉ O VENCIMENTO, PREFERENCIALMENTE NO " + aBanco[2], oFont10)
     oPrint:Say(nRow3 + 2050, 400, "APÓS O VENCIMENTO, SOMENTE NO " + aBanco[2], oFont10)
  EndIf*/	  
           
  oPrint:Say(nRow3 + 2000, 1810,"Vencimento", oFont08)
  
  cString := StrZero(Day(aDadTit[4]),2) + "/" + StrZero(Month(aDadTit[4]),2) + "/" + Right(Str(Year(aDadTit[4])),4)
  nCol	   := 1910 + (374 - (len(cString) * 22))
  
  oPrint:Say(nRow3 + 2040, nCol, cString, oFont11c)           // Vencimento
  
  oPrint:Say(nRow3 + 2100, 100, "Beneficiário", oFont08) 
  oPrint:Say(nRow3 + 2128, 100, AllTrim(aEmpresa[01]) + " - " + aEmpresa[08], oFont10)        // Nome + CNPJ
  oPrint:Say(nRow3 + 2160, 100, AllTrim(aEmpresa[02]) + " - " + AllTrim(aEmpresa[03]) + " - " +;
                                AllTrim(aEmpresa[04]) + "/" + aEmpresa[05], oFont08)          // Endereço da empresa

  oPrint:Say(nRow3 + 2100, 1810, "Agência/Código Beneficiário", oFont08)

  Do Case                                                           // Agencia + Cód. Beneficiário + Dígito
     Case Empty(aBanco[5]) 
          cString := aBanco[3] + "/" + aBanco[4]             

     Case aBanco[1] == "104" .or. aBanco[1] == "033"                // Santander e Caixa
          cString := aBanco[3] + "/" + aBanco[9]

     Case aBanco[1] == "341"                                        // ÍTAU
          cString := aBanco[3] + "/" + AllTrim(aBanco[4]) + "-" + aBanco[5]

     Case aBanco[1] == "422"                                        // SAFRA
          cString := aBanco[3] + " / " + aBanco[4] + aBanco[5]
          
     OtherWise                
          cString := aBanco[3] + IIf(Empty(AllTrim(aBanco[8])),"","-") + aBanco[8] + " / " +;
                     aBanco[4] + IIf(aBanco[1] == "422","","-") + aBanco[5]
  EndCase

  nCol	:= 1910 + (373 - (len(cString) * 22))
  
  oPrint:Say(nRow3 + 2140, nCol, cString, oFont11c)                         // Agência + Cod. Beneficiário

  oPrint:Say(nRow3 + 2200,0100, "Data do Documento", oFont08)
  oPrint:Say(nRow3 + 2230,0140, StrZero(Day(aDadTit[2]),2) + "/" + StrZero(Month(aDadTit[2]),2) +;
                                "/" + Right(Str(Year(aDadTit[2])),4), oFont10)	 // Vencimento

  oPrint:Say(nRow3 + 2200,0505, "Nro.Documento", oFont08)
  oPrint:Say(nRow3 + 2230,0605, aDadTit[01], oFont10)	                      // Prefixo + Numero + Parcela

  oPrint:Say(nRow3 + 2200,1005, "Espécie Doc.", oFont08)
  oPrint:Say(nRow3 + 2230,1090, aDadTit[08], oFont10)                       // Tipo do Titulo

  oPrint:Say(nRow3 + 2200,1305, "Aceite", oFont08)
  oPrint:Say(nRow3 + 2230,1390, "N", oFont10)

  oPrint:Say(nRow3 + 2200,1485, "Data do Processamento", oFont08)
  oPrint:Say(nRow3 + 2230,1550, StrZero(Day(aDadTit[03]),2) + "/" + StrZero(Month(aDadTit[03]),2) +;
                                 "/" + Right(Str(Year(aDadTit[03])),4), oFont10)   // Data impressao

  oPrint:Say(nRow3 + 2200, 1810, "Nosso Número", oFont08)

  cString := aDadTit[6]
  nCol	   := 1910 + (373 - (len(cString) * 22))
  
  oPrint:Say(nRow3 + 2230, nCol, cString, oFont11c)	// Nosso Número
  oPrint:Say(nRow3 + 2270, 100, "Uso do Banco", oFont08)
  oPrint:Say(nRow3 + 2270, 505, "Carteira", oFont08)
  
  If aBanco[1] == "033"
     oPrint:Say(nRow3 + 2300,505,aBanco[10],oFont07)
   else
     oPrint:Say(nRow3 + 2300,565,aBanco[10],oFont10)
  EndIf
  
  oPrint:Say(nRow3 + 2270, 755, IIf(aBanco[1] == "104","Espécie Moeda","Espécie"), oFont08)
  oPrint:Say(nRow3 + 2300, 825, "R$", oFont10)

  oPrint:Say(nRow3 + 2270, 1005, "Qtde Moeda", oFont08)
  oPrint:Say(nRow3 + 2270, 1485, "Valor", oFont08)

  oPrint:Say(nRow3 + 2270, 1810, "Valor do Documento", oFont08)
  
  cString := Alltrim(Transform(aDadTit[05],"@E 99,999,999.99"))
  nCol	   := 1910 + (374 - (len(cString) * 22))
  
  oPrint:Say(nRow3 + 2300, nCol, cString, oFont11c)	    // Valor do Documento

  If aBanco[1] == "104"
     oPrint:Say(nRow3 + 2340, 0100,"Instruções (Texto de Responsabilidade do Beneficiário):", oFont08)
   else  
     oPrint:Say(nRow3 + 2340, 0100, "Instruções (Todas informações deste bloqueto são de exclusiva " +;
                                    "responsabilidade do beneficiário)", oFont08)
  EndIf
                               
  If Len(aBolTxt) > 0
     oPrint:Say(nRow3 + 2375, 0100, aBolTxt[1], oFont08n)	// 1a. Linha Instrução
     oPrint:Say(nRow3 + 2415, 0100, aBolTxt[2], oFont08n)	// 2a. Linha Instrução
     oPrint:Say(nRow3 + 2454, 0100, aBolTxt[3], oFont08n)	// 3a. Linha Instrução
     oPrint:Say(nRow3 + 2494, 0100, aBolTxt[4], oFont08)	// 4a. Linha Instrução
     oPrint:Say(nRow3 + 2534, 0100, aBolTxt[5], oFont08)	// 5a. Linha Instrução
     oPrint:Say(nRow3 + 2574, 0100, aBolTxt[6], oFont08)	// 6a. Linha Instrução
     oPrint:Say(nRow3 + 2614, 0100, aBolTxt[7], oFont08)	// 7a. Linha Instrução
     oPrint:Say(nRow3 + 2654, 0100, aBolTxt[8], oFont08)	// 8a. Linha Instrução
   else
	 oPrint:Say(nRow3 + 2375, 0100, aDadTit[9], oFont08)	   // 1a. Linha Instrução
	 oPrint:Say(nRow3 + 2655, 0100, aBolTxt[8], oFont08)	   // 8a. Linha Instrução
  EndIf

  oPrint:Say(nRow3 + 2340, 1810, "(-)Desconto/Abatimento", oFont08)
  oPrint:Say(nRow3 + 2410, 1810, "(-)Outras Deduções", oFont08)
  oPrint:Say(nRow3 + 2480, 1810, "(+)Mora/Multa", oFont08)
  oPrint:Say(nRow3 + 2550, 1810, "(+)Outros Acréscimos", oFont08)
  oPrint:Say(nRow3 + 2620, 1810, "(=)Valor Cobrado",	oFont08)

  oPrint:Say(nRow3 + 2690, 0100, IIf(aBanco[1] == "104","Pagador","Nome do Pagador"), oFont08)
  oPrint:Say(nRow3 + 2690, 0550, "(" + aSacado[2] + ") " + aSacado[1], oFont08n)	// Nome Cliente + Código

  If Empty(aSacado[7]) 
     oPrint:Say(nRow3 + 2690, 1850, "CPF/CNPJ NAO CADASTRADO", oFont08)
   elseIf aSacado[8] == "J" .and. ! Empty(aSacado[7])
          oPrint:Say(nRow3 + 2690, 1850, "CNPJ: " + Transform(aSacado[7],"@R 99.999.999/9999-99"), oFont08)	// CGC
        elseIf aSacado[8] == "F" .and. ! Empty(aSacado[7])
               oPrint:Say(nRow3 + 2690, 1850, "CPF: " + Transform(aSacado[7],"@R 999.999.999-99"), oFont08)	// CPF
  EndIf

  oPrint:Say(nRow3 + 2723, 0550, aSacado[3], oFont08)	// Endereço

  If Empty(aSacado[6])
     oPrint:Say(nRow3 + 2763, 0550, "CEP NAO CADASTRADO - " + aSacado[4] + " - " + aSacado[5], oFont08)
	else
     oPrint:Say(nRow3 + 2763, 0550, Transform(aSacado[6],"@R 99999-999") + " - " + aSacado[4] + " - " + ;
                                    aSacado[5], oFont08)	// CEP + Cidade + Estado
  EndIf

  oPrint:Say(nRow3 + 2763, 1850, aDadTit[6], oFont08)	// Carteira + Nosso Número

  oPrint:Say(nRow3 + 2815, 0100, "Sacador/Avalista", oFont08)
  oPrint:Say(nRow3 + 2815, 1850, "Código de Baixa", oFont08)

  oPrint:Say(nRow3 + 2855,1500,"Autenticação Mecânica - Ficha de Compensação",		oFont08)		// Texto Fixo

  oPrint:Line(nRow3 + (2000 - nPosPDF), 1800, nRow3 + (2690 - nPosPDF), 1800)
  oPrint:Line(nRow3 + (2410 - nPosPDF), 1800, nRow3 + (2410 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2480 - nPosPDF), 1800, nRow3 + (2480 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2550 - nPosPDF), 1800, nRow3 + (2550 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2620 - nPosPDF), 1800, nRow3 + (2620 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2690 - nPosPDF), 0100, nRow3 + (2690 - nPosPDF), 2300)
  oPrint:Line(nRow3 + (2850 - nPosPDF), 0100, nRow3 + (2850 - nPosPDF), 2300)

  If nTpImp == 2
    If nTipo = 2
       MSBAR("INT25",13.0,1.0,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.013,0.7,Nil,Nil,"A",.F.)				// Código de Barras
     else
       MSBAR("INT25",25.1,1.3,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.025,1.5,Nil,Nil,"A",.F.)				// Código de Barras
    EndIf
   else     
    oPrint:FWMSBAR("INT25",65,1,aCB_RN_NN[1],oPrint,.T.,,.T.,0.020,1.0,.T.,"Arial",NIL,.F.,2,2,.F.)
  EndIf

 // Calculo do nosso numero mais o digito verificador, para ser gravado no campo E1_NUMBCO // Humberto / Liberato
    
  If ! bRetImp
     dbSelectArea("SE1")

     RecLock("SE1",.F.)
       Replace SE1->E1_PORTADO with Subs(aBanco[1],1,3) 
       Replace SE1->E1_NUMBCO  with cNossoDg
     SE1->(MsUnlock())
  EndIf
  
 // -- Gravar boleto em PDF
 // -----------------------
/*  If nTpImp == 6 .or. cTpImpre == "2" 
    //             cNmPDF := "Bol_" + AllTrim(Substr(aSacado[2],1,TamSX3("A1_COD")[1])) + "_" +;
      //                    Substr(aSacado[2],(TamSX3("A1_COD")[1] + 2),TamSX3("A1_LOJA")[1]) +;
        //                  "_" + mv_par19 + "_" + AllTrim(aTitulos[nLoop,3]) +;
          //                "_" + AllTrim(aTitulos[nLoop,4]) +;
            //              IIf(Empty(aTitulos[nLoop][05]),"","_" + AllTrim(aTitulos[nLoop,5])) + ".PDF"
               // -------------------------------------------------------------------------------------------           

     cFilePrint := cDirGer + "BOL_" + AllTrim(Substr(aSacado[2],1,TamSX3("A1_COD")[1])) +;
                   SubStr(aSacado[2],(TamSX3("A1_COD")[1] + 1),TamSX3("A1_LOJA")[1]) + "_" + DToS(aDadTit[4]) + ".PDF"
     File2Printer(cFilePrint,"PDF")
     oPrint:cPathPDF := cDirGer 
  EndIf
*/  
  oPrint:EndPage()
Return

/*----------------------------------------------
--  Função: Impressão do boleto Reduzido.     --
--                                            --
------------------------------------------------*/
Static Function fnImprRd(oPrint, aEmpresa, aDadTit, aBanco, aSacado, aBolTxt, aCB_RN_NN, cNNum)
  Local nI         := 0
  Local cStartPath := GetSrvProfString("StartPath","")
  Local cBmp       := ""

 //Parametros de TFont.New()
 //1.Nome da Fonte (Windows)
 //3.Tamanho em Pixels
 //5.Bold (T/F)
  Local oFont06  := TFont():New("Arial Narrow",9,06,.T.,.F.,5,.T.,5,.T.,.F.)
  Local oFont07  := TFont():New("Arial Narrow",9,07,.T.,.F.,5,.T.,5,.T.,.F.)
  Local oFont07n := TFont():New("Arial Narrow",9,07,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont08c := TFont():New("Courier New" ,9,08,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont12n := TFont():New("Arial Narrow",12,14 ,.T.,.T.,5,.T.,5,.T.,.F.)
  Local oFont11  := TFont():New("Arial Narrow",14,11,.T.,.F.,5,.T.,5,.T.,.F.)
 // -----------------------
 
  cStartPath := AllTrim(cStartPath) + "logo_bancos"
 
  If SubStr(cStartPath, Len(cStartPath), 1) <> "\"
     cStartPath += "\"
  EndIf

  cBmp	:= cStartPath + cLogo + ".bmp"
 	
  If nNumPag == 1
     nRow  := 0
     nCols := 0
     nWith := 0
   elseIf nNumPag > 3
		   oPrint:StartPage()   // Inicia uma nova página
		   nNumPag := 1
		   nRow    := 0
          nCols   := 0
          nWith   := 0
        else
          nRow  += 1050
          nCols := 0
          nWith := 0
  EndIf
	
  nNumPag++

 // ---- Canhoto
  oPrint:Line(nRow + 150, 100, nRow + 150, 600)
  oPrint:Line(nRow + 270, 100, nRow + 270, 600)

  oPrint:Line(nRow + 335, 100, nRow + 335, 600)
  oPrint:Line(nRow + 400, 100, nRow + 400, 600)
  oPrint:Line(nRow + 465, 100, nRow + 465, 600)
  oPrint:Line(nRow + 530, 100, nRow + 530, 600)
  oPrint:Line(nRow + 595, 100, nRow + 595, 600)
  oPrint:Line(nRow + 660, 100, nRow + 660, 600)
  oPrint:Line(nRow + 725, 100, nRow + 725, 600)
  oPrint:Line(nRow + 790, 100, nRow + 790, 600)
  oPrint:Line(nRow + 855, 100, nRow + 855, 600)
  oPrint:Line(nRow + 920, 100, nRow + 920, 600)
	
 // ---- Linha Pontilhada
  For nI := 100 To 1030 Step 10
      oPrint:Line(nRow + nI + 50, 700, nRow + nI + 50, 702)
  Next nI
	
 // ---- Boleto (Horizontal)
  oPrint:Line(nRow + 150, 800, nRow + 150, 2300)
  oPrint:Line(nRow + 225, 800, nRow + 225, 2300)
  oPrint:Line(nRow + 300, 800, nRow + 300, 2300)
  oPrint:Line(nRow + 375, 800, nRow + 375, 2300)
  oPrint:Line(nRow + 450, 800, nRow + 450, 2300)
  oPrint:Line(nRow + 750, 800, nRow + 750, 2300)
  oPrint:Line(nRow + 920, 800, nRow + 920, 2300)

 // ---- Traços Direita - Horizontal
  oPrint:Line(nRow + 510, 1900, nRow + 510, 2300)
  oPrint:Line(nRow + 570, 1900, nRow + 570, 2300)
  oPrint:Line(nRow + 630, 1900, nRow + 630, 2300)
  oPrint:Line(nRow + 690, 1900, nRow + 690, 2300)

 // ---- Vertical
  oPrint:Line(nRow + 300,  995, nRow + 450,  995)
  oPrint:Line(nRow + 375, 1130, nRow + 450, 1130)
  oPrint:Line(nRow + 300, 1280, nRow + 450, 1280)
  oPrint:Line(nRow + 300, 1430, nRow + 375, 1430)
  oPrint:Line(nRow + 225, 1580, nRow + 450, 1580)
  oPrint:Line(nRow + 150, 1900, nRow + 750, 1900)
  
 // ---- Traços Banco - Vertical
  oPrint:Line(nRow + 080, 1180, nRow + 150, 1180)
  oPrint:Line(nRow + 080, 1325, nRow + 150, 1325)
	
 // ---- Texto Canhoto
  oPrint:SayBitMap(nRow + 050,160,cBmp,330,90)					         // Logo Canhoto
	
  oPrint:Say(nRow + 155,110,"Beneficiário",oFont07)			
  oPrint:Say(nRow + 180,110, AllTrim(aEmpresa[01]), oFont06)             // Nome 
  oPrint:Say(nRow + 210,110, AllTrim(aEmpresa[02]) + " - " + AllTrim(aEmpresa[03]) + " - " +;
                             AllTrim(aEmpresa[04]) + "/" + aEmpresa[05], oFont06)                // Endereço da empresa
  oPrint:Say(nRow + 240,110, AllTrim(aEmpresa[08]), oFont06)             // CNPJ

  oPrint:Say(nRow + 275,110,"Nro.Documento",oFont07)
  oPrint:Say(nRow + 310,600,aDadTit[1]     ,oFont08c,,,,1)	             // Prefixo + Numero + Parcela
	
  oPrint:Say(nRow + 340,110,"Vencimento",oFont07)
  
  cString := StrZero(Day(aDadTit[4]),2) + "/" + StrZero(Month(aDadTit[4]),2) + "/" + Right(Str(Year(aDadTit[4])),4)
  nCol	   := 150 + (374 - (Len(cString) * 22))
  
  oPrint:Say(nRow + 375,600,cString,oFont08c,,,,1)                      // Vencimento
	
  oPrint:Say(nRow + 405,110,"Agência/Código Beneficiario",oFont07)

  Do Case
     Case aBanco[1] == "104" .or. aBanco[1] == "033"
          cString := AllTrim(aBanco[3]) + "/" + AllTrim(aBanco[9])

     Case aBanco[1] == "341" 
          cString := AllTrim(aBanco[3]) + "/" + AllTrim(aBanco[4]) + "-" + AllTrim(aBanco[5])

     Case aBanco[1] == "422"
           cString := AllTrim(aBanco[3]) + " / " + aBanco[4] + aBanco[5]
     OtherWise                     
          cString := AllTrim(aBanco[3]) + IIf(Empty(AllTrim(aBanco[8])),"","-") + AllTrim(aBanco[8]) + " / " +;
                     AllTrim(aBanco[4]) + "-" + AllTrim(aBanco[5])
  EndCase

  nCol	:= 150 + (374 - (Len(cString) * 22))
  
  oPrint:Say(nRow + 440,600,cString,oFont08c,,,,1)
	
  oPrint:Say(nRow + 470,110,"Nosso Número",oFont07)
  
  cString := AllTrim(aDadTit[6])
  nCol    := 150 + (374 - (Len(cString) * 22))

  oPrint:Say(nRow + 505,600,cString,oFont08c,,,,1)	             // Nosso Número
	
  oPrint:Say(nRow + 535,110,"Valor do Documento",oFont07)
	
  cString := AllTrim(Transform(aDadTit[5],"@E 99,999,999.99"))
  nCol    := 150 + (374 - (Len(cString) * 22))
  oPrint:Say(nRow + 568,600,cString,oFont08c,,,,1)	
	
  oPrint:Say(nRow + 600,110,"(-)Desconto/Abatimento",oFont07)
  
  If nDesc > 0
     cString := Alltrim(Transform(nDesc,"@E 99,999,999.99"))
     nCol    := 1950+(374-(len(cString)*22))
  
     oPrint:Say(nRow + 633,600,cString, oFont08c,,,,1)	
  EndIf
  	
  oPrint:Say(nRow + 665,110,"(-)Outras Deduções",oFont07)
  
  oPrint:Say(nRow + 730,110,"(+)Mora/Multa",oFont07)	
  
  If nJurMul > 0
     cString := Alltrim(Transform(nJurMul,"@E 99,999,999.99"))
     nCol    := 1950+(374-(len(cString)*22))
     
     oPrint:Say(nRow + 763,600,cString,oFont08c,,,,1)	
  EndIf
  
  oPrint:Say(nRow + 795,110,"(+)Outros Acréscimos",oFont07)
  oPrint:Say(nRow + 860,110,"(=)Valor Cobrado",oFont07)
  	
  oPrint:Say(nRow + 925,110,"Pagador:",oFont07)
  oPrint:Say(nRow + 960,150,aSacado[1],oFont08c)               

  If Empty(aSacado[7]) 
     oPrint:Say(nRow + 995,150,"CPF/CNPJ NAO CADASTRADO",oFont08)
     
   elseIf aSacado[8] == "J" .and. ! Empty(aSacado[7])
          oPrint:Say(nRow + 995,150,"CNPJ: " + Transform(aSacado[7],"@R 99.999.999/9999-99"),oFont07)     // CGC
          
        elseIf aSacado[8] == "F" .and. ! Empty(aSacado[7])
               oPrint:Say(nRow + 995,150,"CPF: " + Transform(aSacado[7],"@R 999.999.999-99"),oFont07)  // CPF
  EndIf
	
 // -----------------------
 // ---- Texto do Boleto
 // -----------------------
  oPrint:SayBitMap(nRow + 050,800,cBmp,330,090)                           // Logo Boleto
  
  oPrint:Say(nRow + 095,1212,aBanco[1] + "-" + aBanco[7],oFont12n)        // Numero do Banco + Dígito
  oPrint:Say(nRow + 100,1335,aCB_RN_NN[2],oFont11)                        // Linha Digitavel do Codigo de Barras
	
  oPrint:Say(nRow + 155,810,"Local de Pagamento",oFont07)
  oPrint:Say(nRow + 190,850,aDadTit[11]         ,oFont07)

/*If aBanco[1] == "237"
     oPrint:Say(nRow + 240,850,"Pagável preferencialmente na Rede Bradesco ou Bradesco Expresso",oFont07)
   else  
     oPrint:Say(nRow + 240,850,"PAGAVEL EM QUALQUER BANCO ATÉ O VENCIMENTO",oFont07)
  EndIf*/   
	
  oPrint:Say(nRow + 155,1910,"Vencimento",oFont07)
  
  cString := StrZero(Day(aDadTit[4]),2) + "/" + StrZero(Month(aDadTit[4]),2) + "/" + Right(Str(Year(aDadTit[4])),4)
  nCol    := 1950 + (374 - (Len(cString) * 22))

  oPrint:Say(nRow + 190,nCol,cString,oFont08c)	                                                // Vencimento
	
  oPrint:Say(nRow + 230,810,"Beneficiário",oFont07)
  oPrint:Say(nRow + 235,930, AllTrim(aEmpresa[01]), oFont07n)             // Nome 
  oPrint:Say(nRow + 270,850, AllTrim(aEmpresa[02]) + " - " + AllTrim(aEmpresa[03]) + " - " +;
                             AllTrim(aEmpresa[04]) + "/" + aEmpresa[05], oFont07)                // Endereço da empresa
	
  oPrint:Say(nRow + 230,1585,"CNPJ",oFont07)
  oPrint:Say(nRow + 265,1630,Substr(aEmpresa[8],7,(Len(aEmpresa[8]) - 7)),oFont07)		          // CNPJ
	
  oPrint:Say(nRow + 230,1910,"Agência/Código Beneficiário",oFont07)
	
  Do Case
     Case aBanco[1] == "104" .or. aBanco[1] == "033"
          cString := AllTrim(aBanco[3]) + "/" + AllTrim(aBanco[9])

     Case aBanco[1] == "341" 
          cString := AllTrim(aBanco[3]) + "/" + AllTrim(aBanco[4]) + "-" + AllTrim(aBanco[5])

     Case aBanco[1] == "422"     
          cString := AllTrim(aBanco[3]) + " / " + aBanco[4] + aBanco[5]
 
     OtherWise
          cString := AllTrim(aBanco[3]) + IIf(Empty(AllTrim(aBanco[8])),"","-") + AllTrim(aBanco[8]) + " / " +;
                     AllTrim(aBanco[4]) + "-" + AllTrim(aBanco[5])
  EndCase
	
  nCol	:= 1950 + (374 - (Len(cString) * 22))
  oPrint:Say(nRow + 265,nCol,cString,oFont08c)	// Agência + Cod. Cedente
	
  oPrint:Say(nRow + 305,810,"Data do Documento",oFont07)
  oPrint:Say(nRow + 340,850,StrZero(Day(aDadTit[2]),2) + "/" + StrZero(Month(aDadTit[2]),2) +;
                            "/" + Right(Str(Year(aDadTit[2])),4),oFont07)               	// Vencimento
	
  oPrint:Say(nRow + 305,1000,"Nro.Documento",oFont07)
  oPrint:Say(nRow + 340,1040,aDadTit[1],oFont07)	                                          // Prefixo + Numero + Parcela
	
  oPrint:Say(nRow + 305,1285,"Espécie Doc.",oFont07)
  oPrint:Say(nRow + 340,1325,aDadTit[8],oFont07)                                           // Tipo do Titulo
	
  oPrint:Say(nRow + 305,1435,"Aceite",oFont07)
  oPrint:Say(nRow + 340,1475,"N",oFont07)
	
  oPrint:Say(nRow + 305,1585,"Data do Processamento",oFont07)
  oPrint:Say(nRow + 340,1625,StrZero(Day(aDadTit[3]),2) + "/" + StrZero(Month(aDadTit[3]),2) +;
		                      "/" + Right(Str(Year(aDadTit[3])),4),oFont07)                // Data impressao
	
  oPrint:Say(nRow + 305,1910,"Nosso Número",oFont07)
	
  cString := AllTrim(aDadTit[6])
  nCol    := 1950 + (374 - (Len(cString) * 22))
  
  oPrint:Say(nRow + 340,nCol,cString,oFont08c)	                                         // Nosso Número
	
  oPrint:Say(nRow + 380, 810,"Uso do Banco",oFont07)
  
  oPrint:Say(nRow + 380,1000,"Carteira"    ,oFont07)

  If aBanco[1] == "033"
     oPrint:Say(nRow + 415,1000,aBanco[10],oFont07)
   else  
     oPrint:Say(nRow + 415,1040,aBanco[10],oFont07)
  EndIf
     
  oPrint:Say(nRow + 380,1135,"Espécie"     ,oFont07)
  oPrint:Say(nRow + 415,1175,"R$"          ,oFont07)
  oPrint:Say(nRow + 380,1285,"Quantidade"  ,oFont07)
  oPrint:Say(nRow + 380,1585,"Valor"       ,oFont07)
	
  oPrint:Say(nRow + 380,1910,"Valor do Documento",oFont07)
	
  cString := AllTrim(Transform(aDadTit[5],"@E 99,999,999.99"))
  nCol    := 2350 - 85 - TamTexto(cString)
  
  oPrint:Say(nRow + 415,nCol,cString,oFont08c)	                                        // Valor do Documento

  oPrint:Say(nRow + 455,0810,"Instruções (Todas informações deste bloqueto são de exclusiva " +;
                             "responsabilidade do beneficiário)", oFont07)
                             
  If Len(aBolTxt) > 0
     oPrint:Say(nRow + 500,0820,aBolTxt[1], oFont08c)	// 1a Linha Instrução
     oPrint:Say(nRow + 545,0820,aBolTxt[2], oFont08c)	// 2a. Linha Instrução
     oPrint:Say(nRow + 590,0820,aBolTxt[3], oFont08c)	// 3a. Linha Instrução
     oPrint:Say(nRow + 635,0820,aBolTxt[4], oFont07)	// 4a Linha Instrução
     oPrint:Say(nRow + 680,0820,aBolTxt[5], oFont07)	// 5a. Linha Instrução
     oPrint:Say(nRow + 725,0820,aBolTxt[6], oFont07)	// 6a. Linha Instrução
     oPrint:Say(nRow + 770,0820,aBolTxt[7], oFont07)	// 7a. Linha Instrução
     oPrint:Say(nRow + 815,0820,aBolTxt[8], oFont07)	// 8a. Linha Instrução
   else
	 oPrint:Say(nRow + 500,0820,aDadTit[9], oFont07)	// 1a Linha Instrução
	 oPrint:Say(nRow + 545,0820,aBolTxt[8], oFont07)	// 8a. Linha Instrução
  EndIf

  oPrint:Say(nRow + 455,1905,"(-)Desconto/Abatimento",oFont07)

  If nDesc > 0  
     cString := Alltrim(Transform(nDesc,"@E 99,999,999.99"))
     nCol    := 2350 - 85 - TamTexto(cString)
  
     oPrint:Say(nRow + 460,nCol,cString,oFont08c)                                     
  EndIf
  
  oPrint:Say(nRow + 515,1905,"(-)Outras Deduções",oFont07)
  oPrint:Say(nRow + 575,1905,"(+)Mora/Multa",oFont07)
  
  If nJurMul > 0
     cString := Alltrim(Transform(nJurMul,"@E 99,999,999.99"))
     nCol    := 2350 - 85 - TamTexto(cString)
  
     oPrint:Say(nRow + 580,nCol,cString,oFont08c)
  EndIf
  
  oPrint:Say(nRow + 635,1905,"(+)Outros Acréscimos",oFont07)
  oPrint:Say(nRow + 695,1905,"(=)Valor Cobrado",oFont07)
   
  oPrint:Say(nRow + 755,810,"Pagador:",oFont07)
  oPrint:Say(nRow + 790,850,aSacado[1] + Space(05) + " - " + IIf(Empty(aSacado[7]),"CPF/CNPJ NAO CADASTRADO",;
                                                              IIf(aSacado[8] == "J","CNPJ: " + Transform(aSacado[7],"@R 99.999.999/9999-99"),;
                                                                                    "CPF: " + Transform(aSacado[7],"@R 999.999.999-99"))),oFont07)
  oPrint:Say(nRow + 825,850,aSacado[3],oFont07)	                          // Endereço

  If Empty(aSacado[6])
     oPrint:Say(nRow + 855,850,"CEP NAO CADASTRADO - " + aSacado[4] + " - " + aSacado[5],oFont07)
   else
     oPrint:Say(nRow + 855,850,Transform(aSacado[6],"@R 99999-999") + " - " + aSacado[4] + "/" + aSacado[5],oFont07)	// CEP + Cidade + Estado
  EndIf

  oPrint:Say(nRow + 0890,0810,"Avalista:",oFont07)
  oPrint:Say(nRow + 0930,2065,"Autenticação Mecânica",oFont07)
  oPrint:Say(nRow + 0960,2065,"Ficha de Compensação",oFont07)
 // ----- Código de Barras
 
// MSBAR("INT25",13.0,1.0,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.013,0.7,Nil,Nil,"A",.F.)				// Código de Barras
  
  If nNumPag == 2
    If cTpImpre == "2"    // Envia PDF
       oPrint:FWMSBAR("INT25",7.9,7,aCB_RN_NN[1],oPrint,.T.,,.T.,0.023,1.16,.T.,"Arial",NIL,.F.,2,2,.F.)
     else
       MSBAR("INT25",7.9,7,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.023,1.16,Nil,Nil,"A",.F.)				// Código de Barras
    EndIf
   elseIf nNumPag == 3
         If cTpImpre == "2"    // Envia PDF
            oPrint:FWMSBAR("INT25",16.9,7,aCB_RN_NN[1],oPrint,.T.,,.T.,0.023,1.16,.T.,"Arial",NIL,.F.,2,2,.F.)
          else 
            MSBAR("INT25",16.9,7,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.023,1.16,Nil,Nil,"A",.F.)			// Código de Barras
          // MSBAR("INT25",17.9,7,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.021,1.13,Nil,Nil,"A",.F.)
         EndIf
        elseIf nNumPag == 4
             If cTpImpre == "2"    // Envia PDF
                oPrint:FWMSBAR("INT25",25.7,7,aCB_RN_NN[1],oPrint,.T.,,.T.,0.023,1.16,.T.,"Arial",NIL,.F.,2,2,.F.)
              else 
                MSBAR("INT25",25.7,7,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.023,1.16,Nil,Nil,"A",.F.)	// Código de Barras
             // MSBAR("INT25",27.3,7  ,aCB_RN_NN[1],oPrint,.F.,Nil,Nil,0.021,1.13,Nil,Nil,"A",.F.)
             EndIf
  EndIf
    
  If ! bRetImp
     dbSelectArea("SE1")

     RecLock("SE1",.F.)
       Replace SE1->E1_PORTADO with Subs(aBanco[1],1,3) 
       Replace SE1->E1_NUMBCO  with cNossoDg
     SE1->(MsUnlock())
  EndIf
  
  If nNumPag > 3
     oPrint:EndPage()
  EndIf

 // -- Gravar boleto em PDF
  If nTpImp == 6 
     cFilePrint := cDirGer + "BOL_" + Substr(aSacado[2],1,TamSX3("A1_COD")[1]) +;
                   SubStr(aSacado[2],(TamSX3("A1_COD")[1] + 1),TamSX3("A1_LOJA")[1]) + "_" + DToS(aDadTit[4]) + ".PD_"
     File2Printer(cFilePrint,"PDF")
     oPrint:cPathPDF := cDirGer 
  EndIf
Return

/*----------------------------------------------
--  Função: Calculo do digito pelo Modulo10.  --
--                                            --
------------------------------------------------*/
Static Function Modulo10(cData)
  Local L,D,P := 0
  Local B     := .F.

  L := Len(cData)
  B := .T.
  D := 0

  While L > 0
	 P := Val(SubStr(cData, L, 1))
	 
	 If (B)
		 P := P * 2
	 	 If P > 9
           P := P - 9
		 EndIf
 	 EndIf
	 
	 D := D + P
	 L := L - 1
	 B := !B
  EndDo
  
  D := 10 - (Mod(D,10))
  
  If D == 10
     D := 0
  EndIf
Return(D)

/*----------------------------------------------
--  Função: Calculo do digito pelo Modulo11.  --
--                                            --
------------------------------------------------*/
Static Function Modulo11(cData,nPeso,cOrig)
  Local L, D, P := 0

  L := Len(cdata)
  D := 0
  P := 1

  While L > 0
    P := P + 1
    D := D + (Val(SubStr(cData, L, 1)) * P)

    If P = nPeso
       P := 1
    EndIf
    
    L := L - 1
  EndDo

  If cQualBco == "033" .and. Alltrim(cOrig) == "NN"
     If mod(D,11) < 2
        Return(0)
      elseIf mod(D,11) == 10
             Return(1)
     EndIf        
  EndIf            
     
  D := 11 - (mod(D,11))

  If cQualBco == "104"
    If D > 9
      If bOrigCB     
         D := 1
       else
         D := 0
      EndIf     
     elseIf (D == 0 .Or. D == 10)
            D := 1
    EndIf
   elseIf cQualBco == "237"
 	    If Alltrim(cOrig) == 'NN'
          If D == 11 //Se o resto for 11, o digito verificador será 0
             D := 0
		   EndIf
		
		   If D == 10 //Se o resto for 10, o dígito verificador será P
             D := "P"
		   EndIf
	     else	
          If D == 0 .or. D == 10 .or. D == 11
             D := 1
          EndIf
	    EndIf
	  elseIf cQualBco == "004"
             If D == 1 .or. D == 10 .or. D == 11
                D := 0
             EndIf
           else
             If D == 0 .or. D == 10 .or. D == 11
                D := 1
             EndIf
  EndIf
Return(D)

/*---------------------------------------------------------
--  Função: Montar código de barra.                      --
--          Campo Livre:                                 --
--            Caixa - Conta                              --
--                    Digito da conta                    --
--                    Nosso numero (1:3)                 --
--                    Carteira (1:1)                     --
--                    Nosso numero (4:3)                 --
--                    Carteira (2:1)                     --
--                    Nosso numero (7:9)                 --
--            BRADESCO - Agencia - tamanho 4             --
--                       Carteira - tamanho 2            --
--                       Nosso numero                    --
--                       Conta - tamanho 7 (sem digito)  --
-----------------------------------------------------------*/
Static Function Ret_cBarra(pBanco,pAgencia,pConta,pDacCC,pCart,pNNum,pValor,pVencto,pConvenio,pModDig,pPesoDig)
  Local nId         := 0
  Local nId1        := 0

  Private cBanco      := pBanco
  Private cAgencia    := pAgencia
  Private cConta      := pConta
  Private cDacCC      := pDacCC
  Private cCart       := pCart
  Private nValor      := pValor
  Private dVencto     := pVencto
  Private cConvenio   := pConvenio
  Private cModDig     := pModDig
  Private nPesoDig    := pPesoDig
  Private nDvnn       := 0
  Private nDvcb       := 0
  Private nDv         := 0
  Private nDvCl       := 0
  Private cNNRet      := ""
  Private cNNSE1      := ""
  Private cCB         := ""
  Private cS          := ""
  Private cCmpLv      := ""
  Private cFator      := StrZero(dVencto - CToD("07/10/97"),4)
  Private cValorFinal := StrZero((nValor*100),10) //StrZero(Int(nValor*100),10)

  cNNum    := pNNum
  cQualBco := cBanco
  bOrigCB  := .F.
   
 // ---- Nosso Numero
 // -----------------
  If cVersao == "11"            
     aLinDig[01] := fnResolP11(aLinDig[01])
  EndIf
  
  cNN := &(aLinDig[01])

  If ! Empty(aLinDig[02]) 
     If cVersao == "11"            
        aLinDig[02] := fnResolP11(aLinDig[02])
     EndIf

     cS := &(aLinDig[02])

     If cModDig == "11"
        nDvnn := modulo11(cS,nPesoDig,"NN")
      else            
        nDvnn := modulo10(cS)
     EndIf                    
  EndIf
      
  If cVersao == "11"            
     aLinDig[03] := fnResolP11(aLinDig[03])
  EndIf
  
  cNNRet   := &(aLinDig[03]) 
  cNNSE1   := cNNRet

  If ValType(nDvnn) == "N"
     cNossoDg := StrZero(Val(AllTrim(cNNum) + AllTrim(Str(nDvnn))),TamSX3("E1_NUMBCO")[1])
   else
     cNossoDg := StrZero(Val(AllTrim(cNNum)),(TamSX3("E1_NUMBCO")[1] - 1))
     cNossoDg := cNossoDg + nDvnn
  EndIf   

 // ---- Campo Livre
 // ----------------
  If ! Empty(aLinDig[08])
     If cVersao == "11"            
        aLinDig[08] := fnResolP11(aLinDig[08])
     EndIf
  
     cS     := &(aLinDig[08])
     cCmpLv := &(aLinDig[08])
     nDvCl := modulo11(cS,9,"")
  EndIf

 // ---- Campo 1
 // ------------
  If cVersao == "11"            
     aLinDig[04] := fnResolP11(aLinDig[04])
  EndIf
 
  cS  := &(aLinDig[04])
  nDv := modulo10(cS)
  cRN1 := SubStr(cS,1,5) + "." + SubStr(cS,6,4) + AllTrim(Str(nDv)) + " "

 // ---- Campo 2
 // ------------
  If cVersao == "11"            
     aLinDig[05] := fnResolP11(aLinDig[05])
  EndIf
 
  cS   := &(aLinDig[05])
  nDv  := modulo10(cS)
  cRN2 := cRN1 + SubStr(cS,1,5) + "." + SubStr(cS,6,5) + AllTrim(Str(nDv)) + " "

 // ---- Campo 3
 // ------------
  If cVersao == "11"            
     aLinDig[06] := fnResolP11(aLinDig[06])
  EndIf
 
  cS  := &(aLinDig[06])
  nDv := modulo10(cS)
  cRN3 := cRN2 + SubStr(cS,1,5) + "." + SubStr(cS,6,5) + AllTrim(Str(nDv)) + " "

 // ---- Campo 4
 // ------------
  bOrigCB := .T.

  If cVersao == "11"            
     aLinDig[07] := fnResolP11(aLinDig[07])
  EndIf
  
  cS      := &(aLinDig[07])
  nDvcb   := modulo11(cS,9,"")
  cCB     := SubStr(cS,1,4) + AllTrim(Str(nDvcb)) + SubStr(cS,5,39)
     
  cRN4 := cRN3 + AllTrim(Str(nDvcb)) + " "

 // ---- Campo 5
 // ------------ 
  cRN5 := cRN4 + cFator + StrZero((nValor * 100),14-Len(cFator))
Return({cCB,cRN5,cNNRet,cNNSE1})
   
/*====================================================
--  Função: Converter variavél da linha digitável   --
--          para string. PROTHEUS 11.               --
======================================================*/
Static Function fnResolP11(pString)
  Local nId     := 0
  Local nId1    := 0
  Local cString := pString
  Local cResult := ""
  
  Private cVariavel := "" 
     
  For nId := 1 To Len(cString)
      If Substr(cString,nId,1) == "#"
         cVariavel := ""
         
         nId++
         
         For nId1 := nId To Len(cString)
             If SubStr(cString,nId1,1) == "#"
                nId := nId1 + 1
                Exit
             EndIf
                
             cVariavel += Substr(cString,nId1,1) 
         Next
                
         If cVariavel == "NDVNN" .or. cVariavel == "NDVCL"
            cResult += IIf(ValType(&(cVariavel)) == "C","'" + &(cVariavel) + "'",AllTrim(Str(&(cVariavel))))
          else
            cResult += "'" + &(cVariavel) + "'"
         EndIf
         
         If nId > Len(cString)
            Exit
         EndIf   
      EndIf
      
      cResult += SubStr(cString,nId,1)
  Next 
Return cResult  

/*==================================
--  Função: Gravação do Bordero   --
--                                --
====================================*/
Static Function fnGrvBrd()
  If ! Empty(SE1->E1_NUMBOR)
     dbSelectArea("SEA")
     SEA->(dbSetOrder(1))
     
     If SEA->(dbSeek(xFilial("SEA") + SE1->E1_NUMBOR + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO))
        RecLock("SEA",.F.)
          dbDelete()
        SEA->(MsUnlock())
     EndIf
  EndIf        
     
  RecLock("SEA",.T.)
    Replace SEA->EA_FILIAL  with xFilial("SEA")
    Replace SEA->EA_NUMBOR  with cNumBor
    Replace SEA->EA_DATABOR with dDataBase
    Replace SEA->EA_PORTADO with mv_par19
    Replace SEA->EA_AGEDEP  with mv_par20
    Replace SEA->EA_NUMCON  with mv_par21
    Replace SEA->EA_NUM     with SE1->E1_NUM
    Replace SEA->EA_PARCELA with SE1->E1_PARCELA
    Replace SEA->EA_PREFIXO with SE1->E1_PREFIXO
    Replace SEA->EA_TIPO    with SE1->E1_TIPO
    Replace SEA->EA_CART    with "R"
    Replace SEA->EA_SITUACA with "1"
    Replace SEA->EA_FILORIG with SE1->E1_FILORIG
    Replace SEA->EA_SITUANT with "0"
    Replace SEA->EA_ORIGEM  with ""
  SEA->(MsUnlock())
  
  FKCOMMIT()
				
  RecLock("SE1",.F.)
    Replace SE1->E1_SITUACA with "1"
    Replace SE1->E1_NUMBOR  with cNumBor
    Replace SE1->E1_DATABOR with dDataBase
    Replace SE1->E1_MOVIMEN with dDataBase

  // DDA - Debito Direto Autorizado
    If SE1->E1_OCORREN $ "53/52"
       Replace SE1->E1_OCORREN with "01"
    Endif
  // ------------------------------
  SE1->(MsUnlock())
Return

/*--------------------------------
--  Função: Cria pergunta.      --
--                              --
----------------------------------*/
Static Function fnCriaSx1(aRegs)
  Local aAreaAtu := GetArea()
  Local aAreaSX1 := SX1->(GetArea())
  Local nJ		   := 0
  Local nY       := 0

 // ---- Monta array com as perguntas
  aAdd(aRegs,{cPerg,"01","Prefixo Inicial   ","","","mv_ch1","C",TamSX3("E1_PREFIXO")[1] ,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"02","Prefixo Final     ","","","mv_ch2","C",TamSX3("E1_PREFIXO")[1] ,0,0,"G","","MV_PAR02","","","","ZZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"03","Numero Inicial    ","","","mv_ch3","C",TamSX3("E1_NUM")[1]     ,0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"04","Numero Final      ","","","mv_ch4","C",TamSX3("E1_NUM")[1]     ,0,0,"G","","MV_PAR04","","","","ZZZZZZZZZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"05","Parcela Inicial   ","","","mv_ch5","C",TamSX3("E1_PARCELA")[1] ,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"06","Parcela Final     ","","","mv_ch6","C",TamSX3("E1_PARCELA")[1] ,0,0,"G","","MV_PAR06","","","","ZZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"07","Tipo Inicial      ","","","mv_ch7","C",TamSX3("E1_TIPO")[1]    ,0,0,"G","","MV_PAR07","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"08","Tipo Final        ","","","mv_ch8","C",TamSX3("E1_TIPO")[1]    ,0,0,"G","","MV_PAR08","","","","ZZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"09","Cliente Inicial   ","","","mv_ch9","C",TamSX3("A1_COD")[1]     ,0,0,"G","","MV_PAR09","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
  aAdd(aRegs,{cPerg,"10","Cliente Final     ","","","mv_cha","C",TamSX3("A1_COD")[1]     ,0,0,"G","","MV_PAR10","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
  aAdd(aRegs,{cPerg,"11","Loja Inicial      ","","","mv_chb","C",TamSX3("A1_LOJA")[1]    ,0,0,"G","","MV_PAR11","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"12","Loja Final        ","","","mv_chc","C",TamSX3("A1_LOJA")[1]    ,0,0,"G","","MV_PAR12","","","","ZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"13","Emissao Inicial   ","","","mv_chd","D",08,0,0,"G","","MV_PAR13","","","","01/01/05","","","","",	"","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"14","Emissao Final     ","","","mv_che","D",08,0,0,"G","","MV_PAR14","","","","31/12/05","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"15","Vencimento Inicial","","","mv_chf","D",08,0,0,"G","","MV_PAR15","","","","01/01/05","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"16","Vencimento Final  ","","","mv_chg","D",08,0,0,"G","","MV_PAR16","","","","31/12/05","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"17","Natureza Inicial  ","","","mv_chh","C",10,0,0,"G","","MV_PAR17","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"18","Natureza Final    ","","","mv_chi","C",10,0,0,"G","","MV_PAR18","","","","ZZZZZZZZZZ","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"19","Banco Cobranca    ","","","mv_chj","C",TamSX3("A6_COD")[1]     ,0,0,"G","","MV_PAR19","","","","","","","","","","","","","","","","","","","","","","","","","XSEE","","","",""})
  aAdd(aRegs,{cPerg,"20","Agencia Cobranca  ","","","mv_chk","C",TamSX3("A6_AGENCIA")[1] ,0,0,"G","","MV_PAR20","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"21","Conta Cobranca    ","","","mv_chl","C",TamSX3("EE_CONTA")[1]   ,0,0,"G","","MV_PAR21","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"22","Sub-Conta         ","","","mv_chm","C",TamSX3("EE_SUBCTA")[1]  ,0,0,"G","","MV_PAR22","","","","001","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"23","Tipo Processo     ","","","mv_chn","C",01,0,0,"C","","MV_PAR23","1- Gerar","1- Gerar","1- Gerar","","","2- Reimpressão","2- Reimpressão","2- Reimpressão","","","3- Regerar","3- Regerar","3- Regerar","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"24","Diretorio         ","","","mv_cho","C",40,0,0,"G","","MV_PAR24","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"25","Gerar Bordero     ","","","mv_chp","C",01,0,0,"C","","MV_PAR25","Sim","Sim","Sim","","","Não","Não","Não","","","","","","","","","","","","","","","","","","","","",""})
  aAdd(aRegs,{cPerg,"26","Tipo Boleto       ","","","mv_chq","C",01,0,0,"C","","MV_PAR26","1- Reduzido","1- Reduzido","1- Reduzido","","","2- Completo","2- Completo","2- Completo","","","","","","","","","","","","","","","","","","","","",""})

  dbSelectArea("SX1")
  SX1->(dbSetOrder(1))

  For nY := 1 To Len(aRegs)
    If ! SX1->(dbSeek(padr(cPerg,10)+aRegs[nY,2]))
		RecLock("SX1",.T.)
		  For nJ := 1 To FCount()
			 If nJ <= Len(aRegs[nY])
				FieldPut(nJ,aRegs[nY,nJ])
			 EndIf
		  Next
		SX1->(MsUnlock())
    EndIf
  Next

  RestArea(aAreaSX1)
  RestArea(aAreaAtu)
Return

/*================================
--  Função: Envio de E-Mail.    --
--                              --
==================================*/
User Function fnEnvBol(pTitulos)
  Local nId    := 0
  Local nPos   := 0
  Local aFiles := Directory(cDirGer + "*.PDF","D")
  Local aNmArq := {}
  Local aDados := {}
  Local cGerPDF := ""
  
  Local oHtml,oProcess
 
 // Nome do PDF: "Bol_" + Codigo Cliente + Loja Cliente + Banco + Prefixo + Titulo + Parcela
    
  AEVAL(aFiles, {|file| aAdd(aNmArq, file[F_NAME])})

 // Separar os clientes
  For nId := 1 To Len(pTitulos)
      If pTitulos[nId][01] .and. ! Empty(pTitulos[nId][11])
         nPos := aScan(aDados, {|x| x[1] == pTitulos[nId][08]})
         
         If nPos > 0
            Loop
         EndIf    

         aAdd(aDados, {pTitulos[nId][08],;          // 01 - Código do Cliente
                       pTitulos[nId][10],;          // 02 - Nome do Cliente
                       pTitulos[nId][04],;          // 03 - Número do título
                       pTitulos[nId][05],;          // 04 - Parcela do título
                       pTitulos[nId][14],;          // 05 - Vencimento do título
                       pTitulos[nId][11],;          // 06 - E-Mail do Cliente
                       pTitulos[nId][09]})          // 07 - Loja do Cliente
      EndIf                 
  Next
 // -------------------
  
  aSort(aDados,,,{|x,y| x[01] < y[01]})
  
  For nId := 1 To Len(aDados)
      cGerPDF := "bol_" + aDados[nId][01] + "_" + aDados[nId][07]
      nPos    := aScan(aNmArq, {|x| Upper(Substr(x,1,(TamSX3("A1_COD")[1] + 5 + TamSX3("A1_LOJA")[1]))) == Upper(cGerPDF)})

      If nPos > 0 
         oProcess := TWFProcess():New("000001","Envio de Boleto")
         oProcess:NewTask("Inicio","\workflow\wfboleto.htm")

         oHtml  := oProcess:oHtml
         cEmail := aDados[nId][06] 		   

         oHtml:ValByName("cCliente", aDados[nId][02])
         oHtml:ValByName("cNum"    , aDados[nId][03])
         oHtml:ValByName("cParcela", aDados[nId][04])
         oHtml:ValByName("cVencto" , aDados[nId][05])
         oHtml:ValByName("cEmpresa", SM0->M0_NOME)
  
       // Start do WorkFlow
       //_user := Subs(cUsuario,7,15)
         oProcess:ClientName("Administrador")

         __CopyFile(cDirGer + aNmArq[nPos], "\workflow\boleto_pdf\" + aNmArq[nPos])  // Copiar para pasta de Processado o arquivo já processado

         oProcess:AttachFile("\workflow\boleto_pdf\" + aNmArq[nPos])
         fErase(cDirGer + aNmArq[nPos])                               // Deletar da pasta de Recebido o arquivo processado
             
         oProcess:cTo      := cEmail
         subj              := "Boleto(s)"
         oProcess:cSubject := subj

         oProcess:Start()
  		
         WfSendMail()
      EndIf
  Next          

  MsgInfo("E-Mail enviado com sucesso.","E-Mail")
Return

/*==================================
--  Função: Saldo do boleto.      --
--                                --
====================================*/
User Function fnSldBol(cPrefixo,cNum,cParcela,cCliente,cLoja)
  Local aRet	 := {0,0,0,0}
  Local nVlrAbat := 0
  Local nAcresc	 := 0
  Local nDecres	 := 0
  Local nSaldo	 := 0
  Local nDescto  := 0

 // --- Pega os Default dos parâmetros
 // ----------------------------------
  cPrefixo := Iif(cPrefixo == Nil, SE1->E1_PREFIXO, cPrefixo)
  cNum	  := Iif(cNum == Nil, SE1->E1_NUM, cNum)
  cParcela := Iif(cParcela == Nil, SE1->E1_PARCELA, cParcela)
  cCliente := Iif(cCliente == Nil, SE1->E1_CLIENTE, cCliente)
  cLoja	  := Iif(cLoja == Nil, SE1->E1_LOJA, cLoja)

 // --- Pega o valor dos abatimentos para o título
 // ----------------------------------------------
  nVlrAbat := SomaAbat(cPrefixo,cNum,cParcela,"R",1,,cCliente,cLoja)

 // --- Pega o valor de acréscimos e decrescimos paa o título
 // ---------------------------------------------------------
  nAcresc := SE1->E1_ACRESC
  nDecres := SE1->E1_DECRESC
	
 // --- Calcular o desconto
 // -----------------------
  nDescto := Round(((SE1->E1_SALDO * SE1->E1_DESCFIN) / 100),2)	

// Define o saldo do título
//  nSaldo  := (SE1->E1_SALDO - nVlrAbat - nDecres - nDescto) + nAcresc
  nSaldo  := (SE1->E1_SALDO - nVlrAbat - nDecres) + nAcresc

// Monta Vetor com o retorno
  aRet := {nSaldo,nVlrAbat,nAcresc,(nDecres + nDescto)}
Return(aRet)
