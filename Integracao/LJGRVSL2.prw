#Include "PROTHEUS.CH"
#Include "TOTVS.ch"

// ---------------------------------------------------------
/*/{protheusDoc.marcadores_ocultos} LJGrvBatch

  Ponto de entrada no Grava Batch antes de atualizar o 
  saldo do produto.
    - Incluído para gerar Ordem de Produção e apontar

  @Retorno Confirmação
  @Author Anderson Almeida (TOTVS NE)
  Retorno
  @História 
    11/12/2021 - Desenvolvimento da Rotina.
/*/
// ---------------------------------------------------------
User Function LJGRVSL2()
  Local aArea   := GetArea()
  Local aRegSC2 := {}            // Registro da Ordem de Produção
  Local aRegSD3 := {}            // Registro de Apontamento da Ordem de Produção
  Local aLog    := {}
  Local cQuery  := ""

  Private lMsErroAuto    := .F.
  Private lAutoErrNoFile := .T.
  Private lMsHelpAuto	   := .T.

 // -- Verificar se o produto é um PA e tem Estrutura
 // -------------------------------------------------
  cQuery := "Select SB1.B1_TIPO from " + RetSqlName("SB1") + " SB1"
  cQuery += "  where SB1.D_E_L_E_T_ <> '*'"
  cQuery += "    and SB1.B1_FILIAL  = '" + FWxFilial("SB1") + "'"
  cQuery += "    and SB1.B1_COD     = '" + SL2->L2_PRODUTO + "'"
  cQuery += "    and SB1.B1_TIPO    = 'PA'"
  cQuery += "    and exists (Select Top 1 SG1.G1_COMP from " + RetSqlName("SG1") + " SG1"
  cQuery += "                   where SG1.D_E_L_E_T_ <> '*'"
  cQuery += "                     and SG1.G1_FILIAL  = '" + FWxFilial("SG1") + "'"
  cQuery += "                     and SG1.G1_COD     = SB1.B1_COD)"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TopConn",TcGenQry(,,cQuery),"QSB1")

  If QSB1->(Eof())
     QSB1->(dbCloseArea())

     Return .T.
  EndIf

  QSB1->(dbCloseArea())
     
 // -- Gravação da Ordem de Produção 
 //---------------------------------			
  aAdd(aRegSC2, {"C2_FILIAL" , FWxFilial("SC2") , NIL})
  aAdd(aRegSC2, {"C2_ITEM"   , "01"             , NIL}) 
  aAdd(aRegSC2, {"C2_SEQUEN" , "001"            , NIL})
  aAdd(aRegSC2, {"C2_PRODUTO", SL2->L2_PRODUTO  , NIL})
  aAdd(aRegSC2, {"C2_LOCAL"  , "03"             , NIL})
  aAdd(aRegSC2, {"C2_QUANT"  , SL2->L2_QUANT    , NIL})
  aAdd(aRegSC2, {"C2_DATPRI" , dDataBase        , NIL})
  aAdd(aRegSC2, {"C2_DATPRF" , dDataBase        , NIL})
  aAdd(aRegSC2, {"AUTEXPLODE", "S"              , NIL})

  MsExecAuto({|x,y| MATA650(x,y)},aRegSC2,3)      // Incluir OP
 
  If lMsErroAuto
     aLog := GetAutoGRLog()

     ConOut("LJGRVSL2: Erro na inclusao da OP")
     Conout(VarInfo("ORDEM PRODUCAO: ",aLog))
   else
    // -- Encerrar a OP gerada
    // -- Opção: 3 - Inclusão
    //           5 - Estorno
    //           7 - Encerramento
    // --------------------------  
     aAdd(aRegSD3, {"D3_OP", (SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN),NIL})
     aAdd(aRegSD3, {"D3_TM", "010"				                                ,NIL})

     MsExecAuto({|x,y| MATA250(x,y)}, aRegSD3,3)      // Apontamento da OP
    
     If lMsErroAuto
        aLog := GetAutoGRLog()
   
        Conout("LJGRVSL2: Erro no Apontamento da OP: " + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
        Conout(VarInfo("APONTAMENTO OP: ",aLog))
     EndIf 
  EndIf

  RestArea(aArea)
Return .T.
