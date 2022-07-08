#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} 
Função UPDSL1
@author Totvs Nordeste
@sample
UPDSL1 - Função para realizar UPDATE no campo L1_SITUA
@history
07/07/2022 - Desenvolvimento da Rotina.
/*/

User Function UPDSL1(aParam)

Local cQry   := ""

   TCLink()
      cQry := " UPDATE " + RetSqlName("SL1") 
      cQry += " SET L1_SITUA = 'RX', L1_ERGRVBT = NULL "
      cQry += " WHERE " 
      cQry += " D_E_L_E_T_ <> '*' "
      cQry += " AND L1_SITUA = 'ER' "
      cQry += " AND L1_ERGRVBT <> NULL "
      
      //Executando Update
      nStatus := TCSqlExec(cQry)
      
      If (nStatus < 0)
         ConOut("Houve um erro na tentativa do Update." + CRLF + TCSQLError())
      endif
   TCUnlink()


Return
