#Include "Protheus.ch"
#Include "FWMVCDEF.ch"
#Include "TOPCONN.ch"

// ---------------------------------------------------
/*/ Rotina DAUDI003
  
   Auditar integração PROTHEUS x 3LM:
    - Verificar se todas as vendas foram processadas
    e estão no Financeiro.

  @author Anderson Almeida - Totvs Nordeste
  Retorno
  @historia
   12/01/2023 - Desenvolvimento da Rotina.
/*/
// ---------------------------------------------------
User Function DAUDI004()
  Local aCampos := {}

  Private lChkSom  := .F.
  Private nTotVen  := 0
  Private nTotFin  := 0
  Private nTotDif  := 0
  Private cQuery   := ""
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
  aAdd(aCampos,{"T1_DTINIC","D",08,0})
  aAdd(aCampos,{"T1_DTFIM" ,"D",08,0})

  oTempTRB1 := FWTemporaryTable():New("TRB1")
  oTempTRB1:SetFields(aCampos)
  oTempTRB1:AddIndex("01",{"T1_SEQ"})
  oTempTRB1:Create()

 // -- Criar tabela temporária
 // -- Grid - Nota Entrada
 // --------------------------
  aCampos := {}

  aAdd(aCampos,{"T2_SEQ"   ,"C",01,0})
  aAdd(aCampos,{"T2_CODFIL","C",TamSX3("F1_FILIAL")[1],0})
  aAdd(aCampos,{"T2_FILIAL","C",40,0})

  oTempTRB2 := FWTemporaryTable():New("TRB2")
  oTempTRB2:SetFields(aCampos)
  oTempTRB2:AddIndex("01",{"T2_CODFIL"})
  oTempTRB2:Create()

 // -- Criar tabela temporária
 // -- Grid - Títulos
 // --------------------------
  aCampos := {}

  aAdd(aCampos,{"T3_SEQ"    ,"C",01,0})
  aAdd(aCampos,{"T3_STATUS ","C",15,0})
  aAdd(aCampos,{"T3_FILIAL" ,"C",TamSX3("L1_FILIAL")[1],0})
  aAdd(aCampos,{"T3_KEYNFCE","C",TamSX3("L1_KEYNFCE")[1],0})
  aAdd(aCampos,{"T3_SERIE"  ,"C",TamSX3("L1_SERIE")[1],0})
  aAdd(aCampos,{"T3_DOC"    ,"C",TamSX3("L1_DOC")[1],0})
  aAdd(aCampos,{"T3_EMISSAO","D",08,0})
  aAdd(aCampos,{"T3_VALOR"  ,"N",11,2})
  aAdd(aCampos,{"T3_PDV"    ,"C",TamSX3("L1_PDV")[1],0})
  aAdd(aCampos,{"T3_NUM"    ,"C",TamSX3("L1_NUM")[1],0})
  aAdd(aCampos,{"T3_SITUA"  ,"C",TamSX3("L1_SITUA")[1],0})
  aAdd(aCampos,{"T3_RECNO"  ,"N",10,0})

  oTempTRB3 := FWTemporaryTable():New("TRB3")
  oTempTRB3:SetFields(aCampos)
  oTempTRB3:AddIndex("01",{"T3_FILIAL","T3_KEYNFCE"})
  oTempTRB3:Create()

  FWExecView("Venda x Fiscal x Financeiro","DAUDI004",MODEL_OPERATION_INSERT,,{|| .T.},,,aButtons)

  oTempTRB1:Delete() 
  oTempTRB2:Delete() 
  oTempTRB3:Delete() 
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
  Local oStrFil := fnMTRB2()
  Local oStrReg := fnMTRB3()

  oModel := MPFormModel():New("VendaxFinanceiro")  

  oModel:SetDescription("Venda x Fiscal x Financeiro")    

  oModel:AddFields("MSTCAB",,oStrCab)
  oModel:AddGrid("DETFIL","MSTCAB",oStrFil)
  oModel:AddGrid("DETREG","MSTCAB",oStrReg)

  oModel:GetModel("DETFIL"):SetNoInsertLine(.T.) 
  oModel:GetModel("DETFIL"):SetNoDeleteLine(.T.)

  oModel:GetModel("DETREG"):SetNoInsertLine(.T.) 
  oModel:GetModel("DETREG"):SetNoUpdateLine(.T.) 
  oModel:GetModel("DETREG"):SetNoDeleteLine(.T.)

  oModel:SetPrimaryKey({})

  oModel:SetRelation("DETFIL",{{"T2_SEQ","T1_SEQ"}}, TRB2->(IndexKey(1)))
  oModel:SetRelation("DETREG",{{"T3_SEQ","T1_SEQ"}}, TRB3->(IndexKey(1)))
Return oModel 

//-------------------------------------------
/*/ Função fnMTRB1()

  Estrutura do detalhe dos cabeçalho

  @author Anderson Almeida (TOTVS NE)
  @since  12/01/2023
/*/
//-------------------------------------------
Static Function fnMTRB1()
  Local oStruct := FWFormModelStruct():New()
  
  oStruct:AddTable("TRB1",{"T1_SEQ"},"Filtrar")
  oStruct:AddField("Sequencia","Sequencia","T1_SEQ"   ,"C",01,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Inicio"   ,"Inicio"   ,"T1_DTINIC","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Fim"      ,"Fim"      ,"T1_DTFIM" ,"D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-------------------------------------------
/*/ Função fnTRB2()

  Estrutura do detalhe dos grid (Notas)
  
  @author Anderson Almeida (TOTVS NE)
  @since  12/01/2023
/*/
//-------------------------------------------
Static Function fnMTRB2()
  Local oStruct := FWFormModelStruct():New()

  oStruct:AddTable("TRB2",{"T2_SEQ","T2_CODFIL"},"Filiais")
  oStruct:AddField("Sequencial","Sequencial","T2_SEQ"    ,"C",01,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Filial"    ,"Filial"    ,"T2_CODFIL" ,"C",TamSX3("L1_FILIAL")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Nome"      ,"Nome"      ,"T2_FILIAL" ,"C",40,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)

  oStruct:AddField("SELECT"," ","SELECT","L",1,0,,,{},.F.,FWBuildFeature(STRUCT_FEATURE_INIPAD, ".F."))
Return oStruct

//-------------------------------------------
/*/ Função fnTRB3()

  Estrutura do detalhe dos grid (Títulos)
  
  @author Anderson Almeida (TOTVS NE)
  @since  12/01/2023
/*/
//-------------------------------------------
Static Function fnMTRB3()
  Local oStruct := FWFormModelStruct():New()

  oStruct:AddTable("TRB3",{"T3_SEQ","T3_KEYNFCE"},"Vendas")
  oStruct:AddField(""         ,""         ,"T3_STATUS" ,"C",15,0,Nil,Nil,{},.F.,,.F.,.F.,.T.)
  oStruct:AddField("Filial"   ,"Filial"   ,"T3_FILIAL" ,"C",TamSX3("L1_FILIAL")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Key NFCe" ,"Key NFCe" ,"T3_KEYNFCE","C",TamSX3("L1_KEYNFCE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Serie"    ,"Serie"    ,"T3_SERIE"  ,"C",TamSX3("L1_SERIE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Documento","Documento","T3_DOC"    ,"C",TamSX3("L1_DOC")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Emissão"  ,"Emissão"  ,"T3_EMISSAO","D",08,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Valor"    ,"Valor"    ,"T3_VALOR"  ,"N",11,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("PDV"      ,"PDV"      ,"T3_PDV"    ,"C",TamSX3("L1_PDV")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Número"   ,"Número"   ,"T3_NUM"    ,"C",TamSX3("L1_NUM")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Situação" ,"Situação" ,"T3_SITUA"  ,"C",TamSX3("L1_SITUA")[1],2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("RECNO"    ,"RECNO"    ,"T3_RECNO"  ,"N",10,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-------------------------------------------
/*/ Função ViewDef()

   Definição da View

  @author Anderson Almeida (TOTVS NE)
  @since
    12/01/2023 - Desenvolvimento da Rotina.
/*/
//-------------------------------------------
Static Function ViewDef() 
  Local oModel  := ModelDef() 
  Local oStrCab := fnVTB1()
  Local oStrFil := fnVTB2()
  Local oStrReg := fnVTB3()
  Local oView

  oView := FWFormView():New() 
   
  oView:SetModel(oModel)    

  oView:AddField("FCAB",oStrCab,"MSTCAB") 
  oView:AddGrid("FFIL",oStrFil,"DETFIL") 
  oView:AddGrid("FREG",oStrReg,"DETREG") 

  oView:SetViewProperty("FREG","ENABLENEWGRID")
  oView:SetViewProperty("FREG","GRIDFILTER", {.T.}) 
  oView:SetViewProperty("FREG","GRIDSEEK"  , {.T.})

  oView:AddUserButton("Legenda","btLeg",{|| fnLegenda()},"Legenda",,)

  oView:AddOtherObject("FBOT",{|oPanel| fnBotao(oPanel)})

 // --- Definição da Tela
 // ---------------------
  oView:CreateHorizontalBox("BXLI1",85)
  
  oView:CreateVerticalBox("BXVF1",40,"BXLI1")
  oView:CreateHorizontalBox("BXDAT",15,"BXVF1")
  oView:CreateHorizontalBox("BXFIL",85,"BXVF1") 

  oView:CreateVerticalBox("BXVF2",60,"BXLI1")

  oView:CreateHorizontalBox("BXLI2",15)
   
  oView:SetOwnerView("FCAB","BXDAT")
  oView:SetOwnerView("FFIL","BXFIL")

  oView:SetOwnerView("FREG","BXVF2")

  oView:SetOwnerView("FBOT","BXLI2")

  oView:SetViewAction("ASKONCANCELSHOW",{|| .F.})                          // Tirar a mensagem do final "Há Alterações não..."
  oView:ShowInsertMsg(.F.)

  oView:SetAfterViewActivate({|oView| fnMntFil(oView)})
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

  oViewTB1:AddField("T1_DTINIC","01","Inicio","Inicio",Nil,"D","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB1:AddField("T1_DTFIM" ,"02","Fim"   ,"Fim"   ,Nil,"D","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
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

  oViewTB2:AddField("SELECT"   ,"01"," "     ,"Selecionar",,"CHECK") 
  oViewTB2:AddField("T2_CODFIL","02","Filial","Filial"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_FILIAL","03","Nome"  ,"Nome"      ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
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

  oViewTB3:AddField("T3_STATUS" ,"00",""        ,""          ,{"Legenda"},"C","@BMP",Nil,Nil,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_FILIAL" ,"02","Filial"  ,"Filial"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_KEYNFCE","03","Key NFCe","Key NFCe"  ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_SITUA"  ,"04","Situação","Sequencial",Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_SERIE"  ,"05","Serie"   ,"Serie"     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_DOC"    ,"06","Número"  ,"Número"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_EMISSAO","07","Emissão" ,"Emissão"   ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_VALOR"  ,"08","Valor"   ,"Valor"     ,Nil,"N","@E 99,999,999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_PDV"    ,"09","PDV"     ,"PDV"       ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB3:AddField("T3_NUM"    ,"10","Chave"   ,"Chave"     ,Nil,"D","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB3

//-------------------------------------------------------------------
/*/ Função: fnLegenda()

  Define a legenda da tela
  						  
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	16/01/2023	
/*/
//-------------------------------------------------------------------
Static Function fnLegenda() 
  Local aLegenda := {}

  aAdd(aLegenda, {"BR_VERDE"   ,"Integrado"})
  aAdd(aLegenda, {"BR_VERMELHO","Não integrado"})

  BrwLegenda("Carga","Legenda",aLegenda) 
Return

//-------------------------------------------------------------------
/*/ Função: fnMntFil()

  Define a legenda da tela
  						  
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since	16/01/2023	
/*/
//-------------------------------------------------------------------
Static Function fnMntFil(oView)
  Local oModel  := FWModelActive()
  Local oGrdFil := oModel:GetModel("DETFIL")

  oGrdFil:SetNoInsertLine(.F.)

  cQuery := "Select SM0.M0_CODFIL, SM0.M0_FILIAL from SYS_COMPANY SM0"
  cQuery += "  where R_E_C_D_E_L_ = 0"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TopConn",TCGenQry(,,cQuery),"QSM0",.F.,.T.)

  While ! QSM0->(Eof())
    oGrdFil:AddLine()

    oGrdFil:SetValue("T2_CODFIL", Substr(QSM0->M0_CODFIL,1,6))
    oGrdFil:SetValue("T2_FILIAL", Substr(QSM0->M0_FILIAL,1,40))

    QSM0->(dbSkip())
  EndDo

  QSM0->(dbCloseArea())

  oGrdFil:SetNoInsertLine(.T.)

  oGrdFil:GoLine(1)

  oView:Refresh()
Return

//----------------------------------------------------------
/*/{Protheus.doc} fnBotao()
  
   Define botão
  						  
  @Parametro: oPanel = Objeto aonde vai ser criado o campo
  @author Anderson Almeida (TOTVS NE)
  @version P12.1.17
  @since   16/01/2023	
/*/
//-----------------------------------------------------------
Static Function fnBotao(oPanel)
  Local oFont := TFont():New("Arial",,-13,,.F.)

	oChkSom := TCheckBox():New(15,05,"Divergentes",{|u|If(PCount()>0,lChkSom := u,lChkSom)},oPanel,180,210,,,oFont,,,,,.T.,,,)

  oSayVen := TSay():New(02,270,{|| "Venda"},oPanel,,,,,,.T.)
  oGetVen := TGet():New(10,270,{|u| If(PCount()>0,nTotVen := u,nTotVen)},oPanel,050,010,"@E 99,999,999.99",,;
                        CLR_BLACK,CLR_GRAY,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nTotVen",,)

  oSayFin := TSay():New(02,370,{|| "Financeiro"},oPanel,,,,,,.T.)
  oGetFin := TGet():New(10,370,{|u| If(PCount()>0,nTotFin := u,nTotFin)},oPanel,050,010,"@E 99,999,999.99",,;
                        CLR_BLACK,CLR_GRAY,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nTotFin",,)

  oSayDif := TSay():New(02,470,{|| "Diferença"},oPanel,,,,,,.T.)
  oGetDif := TGet():New(10,470,{|u| If(PCount()>0,nTotDif := u,nTotDif)},oPanel,050,010,"@E 99,999,999.99",,;
                        CLR_BLACK,CLR_GRAY,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nTotDif",,)

  TButton():New(10,220,"Pesquisar"  ,oPanel,{|| MsAguarde({|| fnPesquisar()},"Processando...")},40,13,,,.F.,.T.,.F.,,.F.,,,.F.)
  TButton():New(10,625,"Reprocessar",oPanel,{|| MsAguarde({|| fnReproces()},"Processando...")},40,13,,,.F.,.T.,.F.,,.F.,,,.F.)
Return

//------------------------------------------------------
/*/{Protheus.doc} fnPesquisar()
  
   Verificar se a venda foi integrada com o financeiro

  @author Anderson Almeida (TOTVS NE)
  @since	16/01/2023	
/*/
//------------------------------------------------------
Static Function fnPesquisar()
  Local oModel  := FWModelActive()
  Local oView   := FWViewActive()
  Local oGrdCab := oModel:GetModel("MSTCAB")
  Local oGrdFil := oModel:GetModel("DETFIL")
  Local oGrdReg := oModel:GetModel("DETREG")
  Local nX      := 0
  Local cStrFil := ""

  oGrdReg:ClearData(.T.) 
  oGrdReg:SetNoInsertLine(.F.)
  oGrdReg:SetNoUpdateLine(.F.)  

  If Empty(DToS(oGrdCab:GetValue("T1_DTINIC")))
     Help(,,"HELP",,"Informe a Data Inicio.",1,0)

     Return
  EndIf

  If Empty(DToS(oGrdCab:GetValue("T1_DTFIM")))
     Help(,,"HELP",,"Informe a Data Fim.",1,0)
     
     Return
  EndIf

  For nX := 1 To oGrdFil:Length()
      oGrdFil:GoLine(nX)

      If oGrdFil:GetValue("SELECT")
         cStrFil += "'" + oGrdFil:GetValue("T2_CODFIL") + "',"
      EndIf
  Next

  oGrdFil:GoLine(1)

  If Empty(cStrFil)
     Help(,,"HELP",,"Selecione uma ou mais Filiais.",1,0)
     
     Return
  EndIf

  cStrFil := Substr(cStrFil,1,(Len(cStrFil) - 1))

  cQuery := "Select SL1.L1_FILIAL, SL1.L1_KEYNFCE, SL1.L1_SITUA, SL1.L1_SERIE, SL1.L1_DOC, SL1.R_E_C_N_O_ RECNO,"
  cQuery += "       SL1.L1_EMISNF, SL1.L1_VALBRUT, SL1.L1_PDV, SL1.L1_NUM, SF2.F2_CHVNFE"
  cQuery += "  from " + RetSqlName("SL1") + " SL1"
  cQuery += "  Full Outer Join " + RetSqlName("SF2") + " SF2"
  cQuery += "        on SF2.D_E_L_E_T_ <> '*'"
  cQuery += "       and SF2.F2_FILIAL = SL1.L1_FILIAL"
  cQuery += "       and SF2.F2_CHVNFE = SL1.L1_KEYNFCE"
  cQuery += "   where SL1.L1_FILIAL in (" + cStrFil + ")"
  cQuery += "     and SL1.L1_EMISNF between '" + DToS(oGrdCab:GetValue("T1_DTINIC")) + "' and '" + DToS(oGrdCab:GetValue("T1_DTFIM")) + "'"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TopConn",TCGenQry(,,cQuery),"QREG",.F.,.T.)

  nTotVen := 0
  nTotFin := 0
  nTotDif := 0

  If QREG->(Eof())
     Help(,,"HELP",,"Não existe registros para esse filtro.",1,0)

     QREG->(dbCloseArea())
     
     Return
  EndIf

  While ! QREG->(Eof())
    If lChkSom
       If ! Empty(QREG->F2_CHVNFE)
          QREG->(dbSkip())

          Loop
       EndIf
    EndIF

    oGrdReg:AddLine()

    oGrdReg:SetValue("T3_STATUS" , IIf(Empty(QREG->F2_CHVNFE),"BR_VERMELHO","BR_VERDE"))
    oGrdReg:SetValue("T3_FILIAL" , QREG->L1_FILIAL)
    oGrdReg:SetValue("T3_KEYNFCE", QREG->L1_KEYNFCE)
    oGrdReg:SetValue("T3_SITUA"  , QREG->L1_SITUA)
    oGrdReg:SetValue("T3_SERIE"  , QREG->L1_SERIE)
    oGrdReg:SetValue("T3_DOC"    , QREG->L1_DOC)
    oGrdReg:SetValue("T3_EMISSAO", SToD(QREG->L1_EMISNF))
    oGrdReg:SetValue("T3_VALOR"  , QREG->L1_VALBRUT)
    oGrdReg:SetValue("T3_PDV"    , QREG->L1_PDV)
    oGrdReg:SetValue("T3_NUM"    , QREG->L1_NUM)
    oGrdReg:SetValue("T3_RECNO"  , QREG->RECNO)

    nTotVen += QREG->L1_VALBRUT
    nTotFin += IIf(! Empty(QREG->F2_CHVNFE),QREG->L1_VALBRUT,0)

    QREG->(dbSkip())
  EndDo

  QREG->(dbCloseArea())

  nTotDif := nTotVen - nTotFin

  oGrdReg:GoLine(1)

  oGrdReg:SetNoInsertLine(.T.)
  oGrdReg:SetNoUpdateLine(.T.)

  oView:Refresh()
Return

//------------------------------------------------------
/*/{Protheus.doc} fnReproces()
  
   Alterar o status das vendas com erro para 'RX', há
   ser reprocessada pelo rotina GravBatch.

  @author Anderson Almeida (TOTVS NE)
  @since	16/01/2023	
/*/
//------------------------------------------------------
Static Function fnReproces()
  Local oModel  := FWModelActive()
  Local oGrdReg := oModel:GetModel("DETREG")
  Local oView   := FWViewActive()
  Local nX      := 0

  dbSelectArea("SL1")
  SL1->(dbSetOrder(1))

  For nX := 1 To oGrdReg:Length()
      oGrdReg:GoLine(nX)

      If oGrdReg:GetValue("T3_SITUA") <> "OK"
         SL1->(dbGoto(oGrdReg:GetValue("T3_RECNO")))

         Reclock("SL1",.F.)
           Replace SL1->L1_SITUA with "RX"
         SL1->(MsUnlock())
      EndIf
  Next

  oGrdReg:GoLine(1)
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
