#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} 
Função UPDSL1
@author Totvs Nordeste
@sample
UPDSL1 - Função para realizar UPDATE no campo L1_SITUA
@history
11/07/2022 - Desenvolvimento da Rotina.
/*/

User Function UPDSL1(aParam)

Local cEmp   := aParam[1] 
Local cFil   := aParam[2]
Local cQry   := ""

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
