#Include 'Protheus.ch'
#Include "Totvs.ch"
#Include "TBICONN.ch"
#Include 'FWMVCDef.ch'

//----------------------------------------------------------
/*/{PROTHEUS.DOC} ITEM
Ponto de entrada na rotina de Manutenção de Cadastro de Produto
@OWNER MCP
@VERSION PROTHEUS 12
@SINCE 26/05/2023
/*/
User Function ITEM()

Local aParam   := PARAMIXB
Local xRet     := .T.
Local oObj     := Nil
Local aArea    := GetArea()
Local cIdPonto := ""
Local cIdModel := ""
Local lIsGrid  := .F.
Local nOpc

If (aParam <> NIL)
    oObj := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]
    lIsGrid  := (Len(aParam) > 3)
	nOpc := oObj:GetOperation() 
	
	If cIdPonto == "MODELCOMMITNTTS"   	
		If oObj != Nil
			If nOpc == 3 .Or. nOpc == 4
               Reclock("SB1",.F.)
			     If nOpc == 3
				    Replace SB1->B1_XDATINC with dDataBase

				  elseIf nOpc == 4
   				         Replace SB1->B1_XDATALT with dDataBase
				 EndIf 
			   SB1->(MsUnlock())
			EndIf 	
		EndIf
	EndIf 
EndIf 

RestArea(aArea)
Return xRet
