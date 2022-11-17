#include "PROTHEUS.ch"
#Include "TOTVS.ch"
#Include "TOPCONN.ch"
#Include "Directry.ch"

/*/{Protheus.doc} 
Função UPDSL1
@author Totvs Nordeste
@sample
   Função para: 
     1 - Realizar UPDATE no campo L1_SITUA
     2 - Deletar registro da "SL1" duplicados, status de 'ER'
     3 - Deletar arquivos de controle preso na integração PROTHEUS x 3LM

@history
11/07/2022 - Desenvolvimento da Rotina.
/*/

User Function UPDSL1(aParam)
  Local cEmp      := aParam[1] 
  Local cFil      := aParam[2]
  Local cQry      := ""
  Local nX        := 0
  Local nRecnoSL1 := 0
  Local nRecnoSL2 := 0
  Local nRecnoSL4 := 0
  Local cBarras   := IIf(isSRVunix(),"/","\")
  Local cRootPath := AllTrim(GetSrvProfString("RootPath",cBarras))
  Local aFiles    := Directory(cRootPath + cBarras + "3lm_json" + cBarras + "\*.ctr","D")
  Local aNomeArq  := {}

   If (IsBlind()) //PREPARAÇÃO DE AMBIENTE EM CASO DE ESTADO DE JOB
      RpcClearEnv()
      RpcSetType(3) 
      RPCSetEnv(cEmp,cFil,,,"FIN",,,,,,)
   EndIf
   
   //Mensagem de ínicio de Execução no Console
   ConOut("/*-------------------------------------------------------")
   ConOut("Iniciou o processo de atualizacao da tabela SL1")
   ConOut("                                                         ")

      cQry := " Select SL1.L1_FILIAL, SL1.L1_NUM, SL1.L1_DOC, SL1.L1_SERIE, SL1.L1_EMISNF, SL1.L1_SITUA"
      cQry += " From " + RetSqlName("SL1") + " SL1"
      cQry += " WHERE SL1.D_E_L_E_T_ <> '*' "
      cQry += " AND L1_SITUA = 'ER' "
      cQry += " AND L1_ERGRVBT <> '' "
      cQry := ChangeQuery(cQry)
      IF Select("TMPSL1") > 0
       TMPSA1->(DbCloseArea())
      EndIf
      dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMPSL1",.T.,.T.)

      TMPSL1->(dbGoTop())
      While !TMPSL1->(EoF())
         ConOut("Filial: "+TMPSL1->L1_FILIAL+;
                " / Orcamento: "+TMPSL1->L1_NUM+;
                " / Cupom: "+TMPSL1->L1_DOC+;
                " / Serie: "+TMPSL1->L1_SERIE+;
                " / Emis. NF: "+DToC(SToD(TMPSL1->L1_EMISNF))+;
                " / Situacao: "+TMPSL1->L1_SITUA)
       TMPSL1->(dbSkip())
      EndDo

   // -- Deletar registros com situação de 'ER' e já processado, duplicidade
  // -----------------------------------------------------------------------
   cQry := "Select SL1.R_E_C_N_O_ as RECNOSL1, SL2.R_E_C_N_O_ as RECNOSL2, SL4.R_E_C_N_O_ as RECNOSL4"
   cQry += "  from " + RetSqlName("SL1") + " SL1, " + RetSqlName("SL2") + " SL2, " + RetSqlName("SL4") + " SL4"
   cQry += "   where SL1.D_E_L_E_T_ <> '*'"
   cQry += "     and SL1.L1_SITUA    = 'ER'"
   cQry += "     and SL1.L1_ERGRVBT <> ''"
	cQry += "     and exists (Select a.R_E_C_N_O_ as Recno"  
   cQry += "                    from " + RetSqlName("SL1") + " a" 
   cQry += "                     where a.D_E_L_E_T_ <> '*'"
   cQry += "                       and a.L1_SITUA   <> 'ER'"
   cQry += "   				        and a.L1_FILIAL  = SL1.L1_FILIAL"
	cQry += "    				        and a.L1_DOC     = SL1.L1_DOC"
	cQry += "          				  and a.L1_SERIE   = SL1.L1_SERIE"
	cQry += "         				  and a.L1_PDV     = SL1.L1_PDV"
	cQry += "   				        and a.L1_KEYNFCE = SL1.L1_KEYNFCE)"
   cQry += "     and SL2.D_E_L_E_T_ <> '*'"
   cQry += "     and SL2.L2_FILIAL  = SL1.L1_FILIAL"
   cQry += "     and SL2.L2_NUM     = SL1.L1_NUM"
   cQry += "     and SL4.D_E_L_E_T_ <> '*'"
   cQry += "     and SL4.L4_FILIAL  = SL1.L1_FILIAL"
   cQry += "     and SL4.L4_NUM     = SL1.L1_NUM"
   cQry := ChangeQuery(cQry)
   dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSL1",.T.,.T.)
   
   dbSelectArea("SL1")
   SL1->(dbSetOrder(1))

   dbSelectArea("SL2")
   SL2->(dbSetOrder(1))

   dbSelectArea("SL4")
   SL4->(dbSetOrder(1))

   While ! QSL1->(Eof())
     If nRecnoSL1 <> QSL1->RECNOSL1
        SL1->(dbGoto(QSL1->RECNOSL1))

        Reclock("SL1",.F.)
          dbDelete()
        SL1->(MsUnlock())

        nRecnoSL1 := QSL1->RECNOSL1
     EndIf

     If nRecnoSL2 <> QSL1->RECNOSL2
        SL2->(dbGoto(QSL1->RECNOSL2))

        Reclock("SL2",.F.)
          dbDelete()
        SL2->(MsUnlock())

        nRecnoSL2 := QSL1->RECNOSL2
     EndIf

     If nRecnoSL4 <> QSL1->RECNOSL4
        SL4->(dbGoto(QSL1->RECNOSL4))

        Reclock("SL4",.F.)
          dbDelete()
        SL4->(MsUnlock())

        nRecnoSL4 := QSL1->RECNOSL4
     EndIf

     QSL1->(dbSkip())
   EndDo

   QSL1->(dbCloseArea())

  // -- Verificar se existe arquivo de Controle preso 
  // ------------------------------------------------
   AEVAL(aFiles, {|file| aAdd(aNomeArq, file[F_NAME])})

   For nX := 1 To Len(aNomeArq)
       FErase(cRootPath + cBarras + "3lm_json" + cBarras + aNomeArq[nX])       // Deletar arquivo de controle
   Next  
  // ------------------------------------------------

   TCLink()
      cQry := " UPDATE " + RetSqlName("SL1") 
      cQry += " SET L1_SITUA = 'RX', L1_ERGRVBT = NULL "
      cQry += " WHERE " 
      cQry += " D_E_L_E_T_ <> '*' "
      cQry += " AND L1_SITUA = 'ER' "
      cQry += " AND L1_ERGRVBT <> '' "
      
      //Executando Update
      nStatus := TCSqlExec(cQry)
      
      If (nStatus < 0)
         ConOut("Houve um erro na tentativa do Update." + CRLF + TCSQLError())
      endif
   TCUnlink()
  
  //Mensagem de fim de Execução no Console
  ConOut("                                                         ")
  ConOut("Finalizou o processo de atualizacao da tabela SL1")
  ConOut("/*-------------------------------------------------------")

  If (IsBlind()) //ENCERRAMENTO DE AMBIENTE EM CASO DE ESTADO DE JOB
      RpcClearEnv()
  Endif    

Return
