#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'Protheus.ch'
#INCLUDE 'FWMVCDef.ch'

/*/{Protheus.doc} MT010INC

MT010INC - Ponto de Entrada para complementar a inclusão no cadastro do Produto.

LOCALIZAÇÃO : Function A010Inclui - Função de Inclusão do Produto, após sua inclusão.
EM QUE PONTO: Após incluir o Produto, este Ponto de Entrada nem confirma nem cancela a operação, 
			  deve ser utilizado para gravar arquivos/campos do usuário, complementando a inclusão.

@type function
@author TOTVS NORDESTE
@since 20/12/2021

@history 
/*/

User Function MT010INC() 

Local aRet    := {}
Local aDados  := {}
Local aFilNao := StrToKArr(SuperGetMv("DT_XFILIAL",.F.,""),";")
Local cQry    := ""
Local cFilNao := ""
Local cGrpEmp := ""
Local cFil    := ""
Local nId 

Private oModel := Nil
Private lMsErroAuto := .F.
Private aRotina := {}

	If INCLUI
		For nId := 1 To Len(aFilNao)
      		cFilNao += "'" + aFilNao[nId] + "',"
  		Next
  
  		cFilNao := Substr(cFilNao,1,(Len(cFilNao) - 1))

		DBSelectArea("SB1")
		aRet := SB1->(dbStruct())

		oModel := FwLoadModel ("MATA010")

		For nId := 1 To Len(aRet)
			
			If GetSx3Cache(aRet[nId][1],"X3_CONTEXT") $ ("R, ");    //Se o campo for Real
				.And. X3Uso(GetSX3Cache(aRet[nId][1], "X3_USADO")); //Se o campo for Usado
				.And. !Empty(&("SB1->" + Alltrim(aRet[nId][1])));   //Se o conteúdo não está em branco
				.And. aRet[nId][1] <> "B1_FILIAL"                   //Não preenche a Filial 

				aAdd(aDados, {aRet[nId][1], &("SB1->" + Alltrim(aRet[nId][1])) ,Nil} )
			
			EndIf 	

		Next nId

		cQry := " SELECT * FROM SYS_COMPANY " 
		cQry += " WHERE D_E_L_E_T_ <> '*' AND M0_CODFIL NOT IN ("+cFilNao+") "  
		cQry += "  Order By M0_CODFIL " 
		cQry := ChangeQuery(cQry)
			IF Select("TMP_M0") <> 0
				TMP_M0->(DbCloseArea())
			EndIf
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMP_M0",.T.,.T.)

		While ! TMP_M0->(EoF())

			cGrpEmp := Alltrim(TMP_M0->M0_CODIGO)
			cFil    := Alltrim(TMP_M0->M0_CODFIL)

			If cEmpAnt <> cGrpEmp .Or. cFilAnt <> cFil
				RpcClearEnv()
  		     	RpcSetType(3) 
  		     	RpcSetEnv(cGrpEmp,cFil,,,"EST")

				lMsErroAuto := .F.
				
				FWMsgRun(, FWMVCRotAuto( oModel,"SB1",MODEL_OPERATION_INSERT,{{"SB1MASTER", aDados}}),;
								 "Aguarde...", "Gravando produto na filial: "+ cFil + " - " + ;
								  Alltrim(FWSM0Util():GetSM0Data(cGrpEmp,cFil,{"M0_NOMECOM"})[1][2]))

				//Se houve erro no ExecAuto, mostra Erro!
				If lMsErroAuto
					FWAlertError("O erro ocorreu para a Filial: " + cFil + " - " + ;
								  Alltrim(FWSM0Util():GetSM0Data(cGrpEmp,cFil,{"M0_NOMECOM"})[1][2]);
					              ,"Ocorreu erro na inclusão!")
					MostraErro()
				EndIf
			EndIf 
		 
		 TMP_M0->(dbSkip()) 
		
		ENDDO

	EndIf 

TMP_M0->(DbCloseArea())

Return 
