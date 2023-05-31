#Include "Protheus.ch"
#Include "FWMVCDEF.ch"
#Include "TOPCONN.ch"

// -----------------------------------------------
/*/ Rotina DAUDI003
  
   Auditar integração PROTHEUS x 3LM:
    - Arquivo enviado pela 3LM para verificar 
      quais a inconsistência de nota de entradas
      incluídas na 3LM que não estão no PROTHEUS.

  @author Anderson Almeida - Totvs Nordeste
  Retorno
  @historia
   20/05/2022 - Desenvolvimento da Rotina.
/*/
// -----------------------------------------------
User Function DAUDI003()
  Local aCampos := {}

  Private aButtons := {{.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,"Confirmar"},;
                       {.T.,"Fechar"},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil}}

 // -- Criar tabela temporária
 // -- Cabeçalho
 // --------------------------
  aAdd(aCampos,{"T1_SEQ"   ,"C",01,0})
  aAdd(aCampos,{"T1_ARQENT","C",80,0})

  oTempTRB1 := FWTemporaryTable():New("TRB1")
  oTempTRB1:SetFields(aCampos)
  oTempTRB1:AddIndex("01",{"T1_SEQ"})
  oTempTRB1:Create()

 // -- Criar tabela temporária
 // -- Grid - Nota Entrada
 // --------------------------
  aCampos := {}

  aAdd(aCampos,{"T2_SEQ"    ,"C",01,0})
  aAdd(aCampos,{"T2_FILIAL" ,"C",TamSX3("F1_FILIAL")[1],0})
  aAdd(aCampos,{"T2_SERIE"  ,"C",TamSX3("F1_SERIE")[1],0})
  aAdd(aCampos,{"T2_DOC"    ,"C",TamSX3("F1_DOC")[1],0})
  aAdd(aCampos,{"T2_FORNECE","C",TamSX3("F1_FORNECE")[1],0})
  aAdd(aCampos,{"T2_LOJA"   ,"C",TamSX3("F1_LOJA")[1],0})
  aAdd(aCampos,{"T2_NREDUZ" ,"C",TamSX3("A2_NREDUZ")[1],0})
  aAdd(aCampos,{"T2_DTDIGIT","D",08,0})
  aAdd(aCampos,{"T2_EMISSAO","D",08,0})
  aAdd(aCampos,{"T2_CHVNFEE","C",TamSX3("F1_CHVNFE")[1],0})
  aAdd(aCampos,{"T2_VALOR"  ,"N",11,2})

  oTempTRB2 := FWTemporaryTable():New("TRB2")
  oTempTRB2:SetFields(aCampos)
  oTempTRB2:AddIndex("01",{"T2_FILIAL","T2_SERIE","T2_DOC","T2_FORNECE","T2_LOJA"})
  oTempTRB2:Create()

 // -- Criar tabela temporária
 // -- Grid - Títulos
 // --------------------------
  aCampos := {}

  aAdd(aCampos,{"T3_PREFIXO","C",TamSX3("E2_PREFIXO")[1],0})
  aAdd(aCampos,{"T3_NUM"    ,"C",TamSX3("E2_NUM")[1],0})
  aAdd(aCampos,{"T3_PARCELA","C",TamSX3("E2_PARCELA")[1],0})
  aAdd(aCampos,{"T3_TIPO"   ,"C",TamSX3("E2_TIPO")[1],0})
  aAdd(aCampos,{"T3_FORNECE","C",TamSX3("E2_FORNECE")[1],0})
  aAdd(aCampos,{"T3_LOJA"   ,"C",TamSX3("E2_LOJA")[1],0})
  aAdd(aCampos,{"T3_EMISSAO","D",08,0})
  aAdd(aCampos,{"T3_VENCTO" ,"D",08,0})
  aAdd(aCampos,{"T3_VALOR"  ,"N",11,2})

  oTempTRB3 := FWTemporaryTable():New("TRB3")
  oTempTRB3:SetFields(aCampos)
  oTempTRB3:AddIndex("01",{"T3_PREFIXO","T3_NUM","T3_PARCELA","T3_FORNECE","T3_LOJA"})
  oTempTRB3:Create()

 // -- Criar tabela temporária
 // -- Grid - Inconsistência
 // --------------------------
  aCampos := {}

  aAdd(aCampos,{"T4_SITUACA","C",30,0})
  aAdd(aCampos,{"T4_FILIAL" ,"C",TamSX3("F1_FILIAL")[1],0})
  aAdd(aCampos,{"T4_DOC"    ,"C",TamSX3("F1_DOC")[1],0})
  aAdd(aCampos,{"T4_FORNECE","C",20,0})
  aAdd(aCampos,{"T4_NREDUZ" ,"C",30,0})
  aAdd(aCampos,{"T4_ENTRADA","D",08,0})
  aAdd(aCampos,{"T4_EMISSAO","D",08,0})
  aAdd(aCampos,{"T4_CHVNFEE","C",TamSX3("F1_CHVNFE")[1],0})
  aAdd(aCampos,{"T4_VALOR"  ,"N",11,2})
  aAdd(aCampos,{"T4_PARCELA","N",02,0})

  oTempTRB4 := FWTemporaryTable():New("TRB4")
  oTempTRB4:SetFields(aCampos)
  oTempTRB4:AddIndex("01",{"T4_FILIAL","T4_DOC","T4_FORNECE"})
  oTempTRB4:Create()

  FWExecView("Arquivo 3LM Nfe Entrada","DAUDI003",MODEL_OPERATION_INSERT,,{|| .T.},,,aButtons)

  oTempTRB1:Delete() 
  oTempTRB2:Delete() 
  oTempTRB3:Delete() 
  oTempTRB4:Delete() 
Return

//-------------------------------------------
/*/ Função ModelDef

  Define as regras de negocio

  @author Anderson Almeida (TOTVS NE)
  @since 
   20/05/2022 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------
Static Function ModelDef() 
  Local oModel  := Nil
  Local oStrCab := fnMTRB1()
  Local oStrSF1 := fnMTRB2()
  Local oStrSE2 := fnMTRB3()
  Local oStrDIV := fnMTRB4()

  oModel := MPFormModel():New("Auditoria-Nfe")  

  oModel:SetDescription("Nfe Entrada")    

  oModel:AddFields("MSTCAB",,oStrCab)
  oModel:AddGrid("DETSF1","MSTCAB",oStrSF1)
  oModel:AddGrid("DETSE2","DETSF1",oStrSE2)
  oModel:AddGrid("DETDIV","MSTCAB",oStrDIV)

  oModel:GetModel("DETSF1"):SetMaxLine(10000)
  oModel:GetModel("DETDIV"):SetMaxLine(10000)

  oModel:AddCalc("SOMAST","MSTCAB","DETDIV","T4_DOC","SEMCAD","COUNT",{|oMld| fnSomaSC(oMld, "SEM CADASTRO")},,"Sem Cadastro",,5,0)
  oModel:AddCalc("SOMAST","MSTCAB","DETDIV","T4_DOC","SEMFIN","COUNT",{|oMld| fnSomaSC(oMld, "SEM FINANCEIRO")},,"Sem Financeiro",,5,0)

  oModel:GetModel("DETSF1"):SetDescription("Nota")  
  oModel:GetModel("DETSE2"):SetDescription("Títulos")  
  oModel:GetModel("DETDIV"):SetDescription("Divergência")  

  oModel:SetPrimaryKey({})

  oModel:SetRelation("DETSF1",{{"T2_SEQ","T1_SEQ"}}, TRB2->(IndexKey(1)))
  oModel:SetRelation("DETSE2",{{"T3_PREFIXO","T2_SERIE"},;
                               {"T3_NUM"    ,"T2_DOC"},;
                               {"T3_FORNECE","T2_FORNECE"},;
                               {"T3_LOJA"   ,"T2_LOJA"}},;
                              TRB3->(IndexKey(1)))
  oModel:SetRelation("DETDIV",{{"T4_SEQ","T1_SEQ"}}, TRB4->(IndexKey(1)))
Return oModel 

//-------------------------------------------
/*/ Função fnMTRB1()

  Estrutura do detalhe dos cabeçalho

  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnMTRB1()
  Local oStruct := FWFormModelStruct():New()
  
  oStruct:AddTable("TRB1",{"T1_SEQ"},"Auditoria")
  oStruct:AddField("Sequencia","Sequencia","T1_SEQ"   ,"C",01,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Arquivo"  ,"Arquivo"  ,"T1_ARQENT","C",80,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-------------------------------------------
/*/ Função fnTRB2()

  Estrutura do detalhe dos grid (Notas)
  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnMTRB2()
  Local oStruct := FWFormModelStruct():New()

  oStruct:AddTable("TRB2",{"T2_FILIAL","T2_SERIE","T2_DOC","T2_FORNECE","T2_LOJA"},"Notas")
  oStruct:AddField("Sequencial","Sequencial","T2_SEQ"    ,"C",01,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Filial"    ,"Filial"    ,"T2_FILIAL" ,"C",TamSX3("F1_FILIAL")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Serie"     ,"Serie"     ,"T2_SERIE"  ,"C",TamSX3("F1_SERIE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Número"    ,"Número"    ,"T2_DOC"    ,"C",TamSX3("F1_DOC")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fornecedor","Fornecedor","T2_FORNECE","C",TamSX3("F1_FORNECE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Loja"      ,"Loja"      ,"T2_LOJA"   ,"C",TamSX3("F1_LOJA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fantasia"  ,"Fantasia"  ,"T2_NREDUZ" ,"C",TamSX3("A2_NREDUZ")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Digitado"  ,"Digitado"  ,"T2_DTDIGIT","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Emissão"   ,"Emissão"   ,"T2_EMISSAO","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Chave Nfe" ,"Chave Nfe" ,"T2_CHVNFE" ,"C",TamSX3("F1_CHVNFE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Valor"     ,"Valor"     ,"T2_VALOR"  ,"N",11,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-------------------------------------------
/*/ Função fnTRB3()

  Estrutura do detalhe dos grid (Títulos)
  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnMTRB3()
  Local oStruct := FWFormModelStruct():New()

  oStruct:AddTable("TRB2",{"T3_PREFIXO","T3_DOC","T3_FORNECE","T3_LOJA"},"Titulos")
  oStruct:AddField("Prefixo"   ,"Prefixo"   ,"T3_PREFIXO","C",TamSX3("E2_PREFIXO")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Número"    ,"Número"    ,"T3_NUM"    ,"C",TamSX3("E2_NUM")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Parcela"   ,"Parcela"   ,"T3_PARCELA","C",TamSX3("E2_PARCELA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Tipo"      ,"Tipo"      ,"T3_TIPO"   ,"C",TamSX3("E2_TIPO")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fornecedor","Fornecedor","T3_FORNECE","C",TamSX3("E2_FORNECE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Loja"      ,"Loja"      ,"T3_LOJA"   ,"C",TamSX3("E2_LOJA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Emissão"   ,"Emissão"   ,"T3_EMISSAO","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Vencimento","Vencimento","T3_VENCTO" ,"D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Valor"     ,"Valor"     ,"T3_VALOR"  ,"N",11,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//---------------------------------------------
/*/ Função fnTRB4()

  Estrutura do detalhe dos grid (Divergência)
  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//---------------------------------------------
Static Function fnMTRB4()
  Local oStruct := FWFormModelStruct():New()

  oStruct:AddTable("TRB4",{"T4_SEQ","T4_FILIAL","T4_DOC","T4_FORNECE"},"Divergência")
  oStruct:AddField("Sequencial","Sequencial","T4_SEQ"    ,"C",01,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Situação"  ,"Situação"  ,"T4_SITUACA","C",30,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Filial"    ,"Filial"    ,"T4_FILIAL" ,"C",TamSX3("F1_FILIAL")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Número"    ,"Número"    ,"T4_DOC"    ,"C",TamSX3("F1_DOC")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fornecedor","Fornecedor","T4_FORNECE","C",20,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fantasia"  ,"Fantasia"  ,"T4_NREDUZ" ,"C",30,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Digitado"  ,"Digitado"  ,"T4_ENTRADA","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Emissão"   ,"Emissão"   ,"T4_EMISSAO","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Chave Nfe" ,"Chave Nfe" ,"T4_CHVNFE" ,"C",TamSX3("F1_CHVNFE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Valor"     ,"Valor"     ,"T4_VALOR"  ,"N",11,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Parcela"   ,"Parcela"   ,"T4_PARCELA","N",02,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-----------------------------------------------------------
/*/ Função fnSomaSC()
  
   Função para contar a quantidade por situação.
  						  
  @Parametro: oModel = Modelo ativo
              cTexto = Texto da situação que quer contar.
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	20/06/2022	
/*/
//-----------------------------------------------------------
Static Function fnSomaSC(oModel, cTexto)
  Local lRet := .T.

  If AllTrim(oModel:GetValue("DETDIV", "T4_SITUACA")) == cTexto
     lRet := .T.
   else
     lRet := .F.
  EndIf
Return lRet

//-------------------------------------------
/*/ Função ViewDef()

   Definição da View

  @author Anderson Almeida (TOTVS NE)
  @since
    24/03/2022 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------
Static Function ViewDef() 
  Local oModel  := ModelDef() 
  Local oStrCab := fnVTB1()
  Local oStrSF1 := fnVTB2()
  Local oStrSE2 := fnVTB3()
  Local oStrDIV := fnVTB4()
  Local oTotDIV := FWCalcStruct(oModel:GetModel("SOMAST"))
  Local oView

  oView := FWFormView():New() 
   
  oView:SetModel(oModel)    
  oView:SetProgressBar(.T.)

  oView:AddUserButton("Impressão","MAGIC_BMP",{|oView| fnImprimir(oView)},"")      // Funcionalidade no menu "Outras Ações"

  oView:AddField("FCAB",oStrCab,"MSTCAB") 
  oView:AddGrid("FSF1",oStrSF1,"DETSF1") 
  oView:AddGrid("FSE2",oStrSE2,"DETSE2") 
  oView:AddGrid("FDIV",oStrDIV,"DETDIV") 
  oView:AddField("FCAL",oTotDiv,"SOMAST") 
  
  oView:SetViewProperty("FCAL","GRIDVSCOLL",{.F.})

  oView:AddOtherObject("FBOT",{|oPanel| fnBotao(oPanel)})

//Function Fa040Legenda(cAlias, nReg)
 // --- Definição da Tela
 // ---------------------
  oView:CreateHorizontalBox("BXCAB",13)

  oView:CreateHorizontalBox("BXHBD",37)
  oView:CreateVerticalBox("BXVF1",60,"BXHBD")
  oView:CreateVerticalBox("BXVE2",40,"BXHBD")

  oView:CreateHorizontalBox("BXSPC",03)
  oView:CreateHorizontalBox("BXDIV",34) 
  oView:CreateHorizontalBox("BXCAL",13)

  oView:EnableTitleView("FSF1","Lançado - Nfe Entrada") 
  oView:EnableTitleView("FSE2","Lançado - Títulos") 
  oView:EnableTitleView("FDIV","Divergência") 
   
  oView:SetOwnerView("FCAB","BXCAB")
  oView:SetOwnerView("FBOT","BXCAB")
  oView:SetOwnerView("FSF1","BXVF1")
  oView:SetOwnerView("FSE2","BXVE2")
  oView:SetOwnerView("FDIV","BXDIV")
  oView:SetOwnerView("FCAL","BXCAL")

  oView:SetViewAction("ASKONCANCELSHOW",{|| .F.})                          // Tirar a mensagem do final "Há Alterações não..."
//  oView:ShowInsertMsg(.F.)

//  oView:SetAfterViewActivate({|oView| fnMntReg(oView)})
Return oView

//-------------------------------------------
/*/ Função fnVTB1

   Estrutura do detalhe do Cabeçalho (View)
  						  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnVTB1()
  Local oViewTB1 := FWFormViewStruct():New() 

 // -- Montagem Estrutura
 //      01 = Nome do Campo
 //      02 = Ordem
 //      03 = Título do campo
 //      04 = Descrição do campo
 //      05 = Array com Help
 //      06 = Tipo do campo
 //      07 = Picture
 //      08 = Bloco de PictTre Var
 //      09 = Consulta F3
 //      10 = Indica se o campo é alterável
 //      11 = Pasta do Campo
 //      12 = Agrupamnento do campo
 //      13 = Lista de valores permitido do campo (Combo)
 //      14 = Tamanho máximo da opção do combo
 //      15 = Inicializador de Browse
 //      16 = Indica se o campo é virtual (.T. ou .F.)
 //      17 = Picture Variavel
 //      18 = Indica pulo de linha após o campo (.T. ou .F.)
 //      19 = Largura do campo no Grid
 // ---------------------------------------------------------
  oViewTB1:AddField("T1_ARQENT","01","Arquivo","Arquivo",Nil,"C","@!",Nil,"DIR",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB1

//-------------------------------------------
/*/ Função fnVTB2

   Estrutura do detalhe do grid (Notas)
  						  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnVTB2()
  Local oViewTB2 := FWFormViewStruct():New()

  oViewTB2:AddField("T2_FILIAL" ,"01","Filial"    ,"Filial"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_SERIE"  ,"02","Serie"     ,"Serie"     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_DOC"    ,"03","Número"    ,"Número"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_FORNECE","04","Fornecedor","Fornecedor",Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_LOJA"   ,"05","Loja"      ,"Loja"      ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_NREDUZ" ,"06","Fantasia"  ,"Fantasia"  ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_DTDIGIT","07","Digitado"  ,"Digitado"  ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_EMISSAO","08","Emissão"   ,"Emissão"   ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_CHVNFE" ,"09","Chave Nfe" ,"Chave Nfe" ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_VALOR"  ,"10","Valor"     ,"Valor"     ,Nil,"N","@E 99,999,999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB2

//-------------------------------------------
/*/ Função fnVSE2

   Estrutura do detalhe do grid (Títulos)
  						  
  @author Anderson Almeida (TOTVS NE)
  @since  17/06/2022
/*/
//-------------------------------------------
Static Function fnVTB3()
  Local oViewTB3 := FWFormViewStruct():New()

  oViewTB3:AddField("T3_PREFIXO","02","Prefixo"   ,"Serie"     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_NUM"    ,"03","No. Título","No. Título",Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_PARCELA","04","Parcela"   ,"Parcela"   ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_TIPO"   ,"05","Tipo"      ,"Tipo"      ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_EMISSAO","06","Emissão"   ,"Emissão"   ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_VENCTO" ,"07","Vencimento","Vencimento",Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_VALOR"  ,"08","Valor"     ,"Valor"     ,Nil,"N","@E 99,999,999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB3

//---------------------------------------------
/*/ Função fnVTB4

   Estrutura do detalhe do grid (Divergência)
  						  
  @author Anderson Almeida (TOTVS NE)
  @since  24/03/2022
/*/
//---------------------------------------------
Static Function fnVTB4()
  Local oViewTB4 := FWFormViewStruct():New()

  oViewTB4:AddField("T4_SITUACA","01","Situação"  ,"Situação"  ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil,120)
  oViewTB4:AddField("T4_FILIAL" ,"02","Filial"    ,"Filial"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_DOC"    ,"03","Número"    ,"Número"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_FORNECE","04","Fornecedor","Fornecedor",Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil,120)
  oViewTB4:AddField("T4_NREDUZ" ,"05","Fantasia"  ,"Fantasia"  ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_ENTRADA","06","Digitado"  ,"Digitado"  ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_EMISSAO","07","Emissão"   ,"Emissão"   ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_CHVNFE" ,"08","Chave Nfe" ,"Chave Nfe" ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil,200)
  oViewTB4:AddField("T4_VALOR"  ,"09","Valor"     ,"Valor"     ,Nil,"N","@E 99,999,999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB4:AddField("T4_PARCELA","10","Parcela"   ,"Parcela"   ,Nil,"N","@E 99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB4

//----------------------------------------------------------
/*/{Protheus.doc} fnBotao()
  
   Define botão
  						  
  @Parametro: oPanel = Objeto aonde vai ser criado o campo
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since   17/06/2022	
/*/
//-----------------------------------------------------------
Static Function fnBotao(oPanel)
  TButton():New(10,270,"Auditar",oPanel,{|| MsAguarde({|| fnAuditar()},"Processando...")},40,13,,,.F.,.T.,.F.,,.F.,,,.F.)
Return

//-----------------------------------------------------------
/*/{Protheus.doc} fnAuditar()
  
   Define botão
  						  
  @Parametro: oPanel = Objeto aonde vai ser criado o campo
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	20/05/2022	
/*/
//-----------------------------------------------------------
Static Function fnAuditar()
  Local oModel  := FWModelActive()
  Local oView   := FWViewActive()
  Local cArqEnt := AllTrim(oModel:GetModel("MSTCAB"):GetValue("T1_ARQENT"))
  Local oGrdSF1 := oModel:GetModel("DETSF1")
  Local oGrdSE2 := oModel:GetModel("DETSE2")
  Local oGrdDIV := oModel:GetModel("DETDIV")
  Local aCpoCSV := {}
  Local aRegSM0 := FWLoadSM0()
  Local nPos    := 0
  Local cCodFil := ""

  oGrdSF1:ClearData(.T.) 
  oGrdSE2:ClearData(.T.) 
  oGrdDIV:ClearData(.T.) 

  If ! File(cArqEnt)
     Help(,,"HELP",,"Arquivo não existe.",1,0)
     Return
  EndIf

  FT_FUSE(cArqEnt)

  ProcRegua(FT_FLASTREC())

  FT_FGOTOP()
  FT_FSKIP()
  
  dbSelectArea("SF1")
  SF1->(dbSetOrder(8))

  oGrdSF1:SetNoInsertLine(.F.)
  oGrdSF1:SetNoDeleteLine(.F.)  
  oGrdSF1:SetNoUpdateLine(.F.) 

  oGrdSE2:SetNoInsertLine(.F.)
  oGrdSE2:SetNoDeleteLine(.F.)  
  oGrdSE2:SetNoUpdateLine(.F.) 

  oGrdDIV:SetNoInsertLine(.F.)
  oGrdDIV:SetNoDeleteLine(.F.)  
  oGrdDIV:SetNoUpdateLine(.F.) 

  While ! FT_FEOF()
    IncProc("Lendo arquivo da 3LM de Entrada de Notas Fiscais...")
 
  	aCpoCSV := StrToKArr(Upper(AllTrim(FT_FREADLN())),";")

   // -- Tratar campos do arquivo de entrada
   // -- Tirar caracteres do campo CGC da Empresa
   // ------------------------------------------- 
    aCpoCSV[02] := StrTran(aCpoCSV[02],".","")
    aCpoCSV[02] := StrTran(aCpoCSV[02],"/","")
    aCpoCSV[02] := AllTrim(StrTran(aCpoCSV[02],"-",""))
   
   // -- Pegar o código da filial
   // ---------------------------
    If (nPos := aScan(aRegSM0,{|x| Alltrim(x[18]) == aCpoCSV[02]})) > 0
       cCodFil := aRegSM0[nPos][02]
    EndIf
   
   // -- Tirar seperador de milhar e trocar o de decimal
   // --------------------------------------------------
    aCpoCSV[06] := StrTran(aCpoCSV[06],".","")
    aCpoCSV[06] := StrTran(aCpoCSV[06],",",".")

   // -- Tratar Chave NFe
   // -------------------
    aCpoCSV[07] := AllTrim(StrTran(aCpoCSV[07],"CHAVE-",""))
   // -------------------

    cQuery := "Select SF1.F1_FILIAL, SF1.F1_SERIE, SF1.F1_DOC, SF1.F1_FORNECE, SF1.F1_LOJA, SF1.F1_CHVNFE,"
    cQuery += "       SF1.F1_DTDIGIT, SF1.F1_EMISSAO, SF1.F1_VALMERC, SA2.A2_NREDUZ, SE2.E2_PREFIXO,"
    cQuery += "       SE2.E2_NUM, SE2.E2_PARCELA, SE2.E2_TIPO, SE2.E2_EMISSAO, SE2.E2_VENCTO,"
    cQuery += "       SE2.E2_VALOR, SE2.R_E_C_N_O_ as SE2RECNO"
    cQuery += "  from " + RetSqlname("SA2") + " SA2, " + RetSqlName("SF1") + " SF1"
    cQuery += "   Full Join " + RetSqlName("SE2") + " SE2" 
    cQuery += "          on SE2.D_E_L_E_T_ <> '*'"
    cQuery += "         and SE2.E2_FILIAL  = '" + cCodFil + "'"
    cQuery += "         and SE2.E2_PREFIXO = SF1.F1_SERIE"
    cQuery += "         and SE2.E2_NUM     = SF1.F1_DOC"
    cQuery += "         and SE2.E2_FORNECE = SF1.F1_FORNECE"
    cQuery += "         and SE2.E2_LOJA    = SF1.F1_LOJA"
    cQuery += "  where SF1.D_E_L_E_T_ <> '*'"
    cQuery += "    and SF1.F1_FILIAL  = '" + cCodFil + "'"
    cQuery += "    and SF1.F1_CHVNFE  = '" + aCpoCSV[07] + "'"
    cQuery += "    and SA2.D_E_L_E_T_ <> '*'"
    cQuery += "    and SA2.A2_FILIAL  = '" + FWxFilial("SA2") + "'"
    cQuery += "    and SA2.A2_COD     = SF1.F1_FORNECE"
    cQuery += "    and SA2.A2_LOJA    = SF1.F1_LOJA"
    cQuery := ChangeQuery(cQuery)
    dbUseArea(.T.,"TopConn",TCGenQry(,,cQuery),"QSF1",.F.,.T.)

    If QSF1->(Eof())
       oGrdDIV:AddLine()

       oGrdDIV:SetValue("T4_SITUACA", "SEM CADASTRO")
       oGrdDIV:SetValue("T4_FILIAL" , cCodFil)
       oGrdDIV:SetValue("T4_DOC"    , aCpoCSV[03])
       oGrdDIV:SetValue("T4_FORNECE", aCpoCSV[09])
       oGrdDIV:SetValue("T4_NREDUZ" , aCpoCSV[08])
       oGrdDIV:SetValue("T4_ENTRADA", CToD(aCpoCSV[04]))
       oGrdDIV:SetValue("T4_EMISSAO", CToD(aCpoCSV[05]))
       oGrdDIV:SetValue("T4_CHVNFE" , aCpoCSV[07])
       oGrdDIV:SetValue("T4_VALOR"  , Val(aCpoCSV[06]))
       oGrdDIV:SetValue("T4_PARCELA", Val(aCpoCSV[12]))
     else  
       If QSF1->SE2RECNO == 0
          oGrdDIV:AddLine()

          oGrdDIV:SetValue("T4_SITUACA", "SEM FINANCEIRO")
          oGrdDIV:SetValue("T4_FILIAL" , cCodFil)
          oGrdDIV:SetValue("T4_DOC"    , aCpoCSV[03])
          oGrdDIV:SetValue("T4_FORNECE", aCpoCSV[09])
          oGrdDIV:SetValue("T4_NREDUZ" , aCpoCSV[08])
          oGrdDIV:SetValue("T4_ENTRADA", CToD(aCpoCSV[04]))
          oGrdDIV:SetValue("T4_EMISSAO", CToD(aCpoCSV[05]))
          oGrdDIV:SetValue("T4_CHVNFE" , aCpoCSV[07])
          oGrdDIV:SetValue("T4_VALOR"  , Val(aCpoCSV[06]))
          oGrdDIV:SetValue("T4_PARCELA", Val(aCpoCSV[12]))
        else
          oGrdSF1:AddLine()

          oGrdSF1:SetValue("T2_FILIAL" , QSF1->F1_FILIAL)
          oGrdSF1:SetValue("T2_SERIE"  , QSF1->F1_SERIE)
          oGrdSF1:SetValue("T2_DOC"    , QSF1->F1_DOC)
          oGrdSF1:SetValue("T2_FORNECE", QSF1->F1_FORNECE)
          oGrdSF1:SetValue("T2_LOJA"   , QSF1->F1_LOJA)
          oGrdSF1:SetValue("T2_NREDUZ" , QSF1->A2_NREDUZ)
          oGrdSF1:SetValue("T2_DTDIGIT", SToD(QSF1->F1_DTDIGIT))
          oGrdSF1:SetValue("T2_EMISSAO", SToD(QSF1->F1_EMISSAO))
          oGrdSF1:SetValue("T2_CHVNFE" , QSF1->F1_CHVNFE)
          oGrdSF1:SetValue("T2_VALOR"  , QSF1->F1_VALMERC)

          While ! QSF1->(Eof())
            oGrdSE2:AddLine()

            oGrdSE2:SetValue("T3_PREFIXO", QSF1->E2_PREFIXO)
            oGrdSE2:SetValue("T3_NUM"    , QSF1->E2_NUM)
            oGrdSE2:SetValue("T3_PARCELA", QSF1->E2_PARCELA)
            oGrdSE2:SetValue("T3_TIPO"   , QSF1->E2_TIPO)
            oGrdSE2:SetValue("T3_EMISSAO", SToD(QSF1->E2_EMISSAO))
            oGrdSE2:SetValue("T3_VENCTO" , SToD(QSF1->E2_VENCTO))
            oGrdSE2:SetValue("T3_VALOR"  , QSF1->E2_VALOR)

            QSF1->(dbSkip())
          EndDo
       EndIf
    EndIf

    QSF1->(dbCloseArea())   

    FT_FSKIP()
  EndDo

  FT_FUSE()

  oGrdSF1:GoLine(1)
  oGrdSE2:GoLine(1)
  oGrdDIV:GoLine(1)

  oGrdSF1:SetNoInsertLine(.T.)
  oGrdSF1:SetNoDeleteLine(.T.)  
  oGrdSF1:SetNoUpdateLine(.T.) 

  oGrdSE2:SetNoInsertLine(.T.)
  oGrdSE2:SetNoDeleteLine(.T.)  
  oGrdSE2:SetNoUpdateLine(.T.) 

  oGrdDIV:SetNoInsertLine(.T.)
  oGrdDIV:SetNoDeleteLine(.T.)  
  oGrdDIV:SetNoUpdateLine(.T.)

  oView:Refresh()
Return

//---------------------------------------
/*/ Função fnImprimir()
  
   Imprimir as divergência encontradas

  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	20/06/2022	
/*/
//---------------------------------------
Static Function fnImprimir(oView)
  Local oReport     
	
	oReport := ReportDef(oView)
	oReport:printDialog()
Return
  
//---------------------------------------------------
/*/ Função ReportDef

  Monta as definições do relatorio de Divergências

  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	20/06/2022	
/*/
//---------------------------------------------------
Static Function ReportDef(oView)
	Local cTitulo  := "Divergências PROTHEUS x 3LM - NFe Entrada"	
	Local oReport
	Local oSection1
	Local oSection2
  Local oTotal
  Local oBreak
	
	oReport := TReport():New("",cTitulo,"",{|oReport| ReportPrint(oReport,oSection1,oSection2,oTotal,oBreak,oView)},;
                              "Divergências PROTHEUS x 3LM - NFe Entrada")
 	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
	oReport:ShowHeader()

	oSection1 := TRSection():New(oReport,"Arquivo",{""})
	oSection1:SetTotalInLine(.F.)
	
	TRCell():New(oSection1,"NOMEARQ","","Arquivo","@!",100,/*lPixel*/,/*{|| code-block de impressao }*/)	 

	oSection2 := TRSection():New(oSection1,"",{""})
	oSection2:SetTotalInLine(.F.)

	TRCell():New(oSection2,"SITUACA",,"Situação"  ,"@!",35,,)
	TRCell():New(oSection2,"FILIAL" ,,"Filial"    ,"@!",15,,)
	TRCell():New(oSection2,"DOCTO"  ,,"Documento" ,"@!",25,,)
	TRCell():New(oSection2,"FORNECE",,"CNPJ Forn.","@!",45,,)
	TRCell():New(oSection2,"NREDUZ" ,,"Fantaisa"  ,"@!",50,,)
	TRCell():New(oSection2,"ENTRADA",,"Entrada"   ,"@!",30,,)
	TRCell():New(oSection2,"EMISSAO",,"Emissão"   ,"@!",30,,)
	TRCell():New(oSection2,"CHVNFE" ,,"Chave Nfe" ,"@!",110,,)
	TRCell():New(oSection2,"VALOR"  ,,"Valor"     ,"@E 99,999,999.99",30,,)
	TRCell():New(oSection2,"PARCELA",,"Qtde Parc.","@E 999",20,,)

	oTotal := TRSection():New(oReport,"TOTAL:",{""},,/*Campos do SX3*/,/*Campos do SIX*/)

	TRCell():New(oTotal,"TOTCAD",,"Sem Cadastro"  ,"@E 999",15,,)
	TRCell():New(oTotal,"TOTFIN",,"Sem Financeiro","@E 999",15,,)
Return (oReport)
  
//---------------------------------------------------
/*/ Função ReportPrint

  Impressão do relatorio de Divergências

  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	20/06/2022	
/*/
//---------------------------------------------------
Static Function ReportPrint(oReport,oSection1,oSection2,oTotal,oBreak,oView)
  Local oModel  := FWModelActive()
  Local oGrdDIV := oModel:GetModel("DETDIV")
  Local oCpoCAL := oModel:GetModel("SOMAST")
  Local nX      := 0

	If oGrdDIV:Length() == 0
		 ApMsgInfo("Não existe divergência para impressão")
		 
     Return
	Endif

//	While ! oReport:Cancel()
		oSection1:Init()

		oSection1:Cell("NOMEARQ"):SetValue(AllTrim(oModel:GetModel("MSTCAB"):GetValue("T1_ARQENT")))
    oSection1:PrintLine()

   	oSection2:Init()

    For nX := 1 To oGrdDIV:Length()
        oGrdDIV:GoLine(nX)
        
				oSection2:Cell("SITUACA"):SetValue(oGrdDIV:GetValue("T4_SITUACA"))
				oSection2:Cell("FILIAL" ):SetValue(oGrdDIV:GetValue("T4_FILIAL"))
				oSection2:Cell("DOCTO"  ):SetValue(oGrdDIV:GetValue("T4_DOC"))
				oSection2:Cell("FORNECE"):SetValue(oGrdDIV:GetValue("T4_FORNECE"))
				oSection2:Cell("NREDUZ" ):SetValue(oGrdDIV:GetValue("T4_NREDUZ"))
				oSection2:Cell("ENTRADA"):SetValue(DToC(oGrdDIV:GetValue("T4_ENTRADA")))
				oSection2:Cell("EMISSAO"):SetValue(DToC(oGrdDIV:GetValue("T4_EMISSAO")))
				oSection2:Cell("CHVNFE" ):SetValue(oGrdDIV:GetValue("T4_CHVNFE"))
				oSection2:Cell("VALOR"  ):SetValue(oGrdDIV:GetValue("T4_VALOR"))
				oSection2:Cell("PARCELA"):SetValue(oGrdDIV:GetValue("T4_PARCELA"))

        oSection2:PrintLine()
    Next
    
    oSection2:Finish()
    oSection1:Finish()

  	oTotal:Init()
  	oTotal:Cell("TOTCAD"):SetValue(oCpoCAL:GetValue("SEMCAD"))
  	oTotal:Cell("TOTFIN"):SetValue(oCpoCAL:GetValue("SEMFIN"))
	  oTotal:PrintLine()
	  oTotal:Finish()
//	EndDo
Return
