#include "protheus.ch"
#include "totvs.ch

/*/{Protheus.doc} CUSTOMERVENDOR
Ponto de Entrada em MVC no cadastro do Fornecedor
@author Totvs S.A.
@since 16/10/2019
@version 1.0
/*/
User Function CUSTOMERVENDOR()
	Local aParam 	:= PARAMIXB
	Local xRet 		:= .T.
	Local oObj 		:= ""
	Local cIdPonto 	:= ""
	Local cIdModel 	:= ""

	If aParam <> NIL
		oObj 	:= aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]

		//Ap�s a grava��o total do modelo e dentro da transa��o.
		If cIdPonto =="MODELCOMMITTTS"
			xRet	:=	Nil
			//Inclus�o da Item Cont�bil
			sfSetCTD(oObj)
		EndIf
	EndIf
Return(xRet)  

//==================================================================================================
Static Function sfSetCTD(mvModel)
	Local liRec		:=	.F.
	Local oModelSA2 := mvModel:GetModel( 'SA2MASTER' )
	Local aAreaSA2	:= SA2->(GetArea())
	Local aAreaCTD	:= CTD->(GetArea())

	If mvModel:GetOperation() == 3 .Or. mvModel:GetOperation() == 4

		DbSelectArea("CTD")
		CTD->(DbSetOrder(1))

		If !(CTD->(DbSeek(FWxFilial("CTD")+"F"+oModelSA2:GetValue('A2_COD')+oModelSA2:GetValue('A2_LOJA'))))

			liRec	:=	RecLock("CTD",.T.)
			CTD->CTD_FILIAL := FWxFilial("CTD") 
			CTD->CTD_ITEM	:= "F"+oModelSA2:GetValue('A2_COD')+oModelSA2:GetValue('A2_LOJA')
			CTD->CTD_CLASSE := "2"          
			CTD->CTD_DESC01 := oModelSA2:GetValue('A2_NOME')
			CTD->CTD_BLOQ	:= "2"    
			CTD->CTD_DTEXIS := CTOD("01/01/1980")
			CTD->CTD_ITLP 	:= "F"+oModelSA2:GetValue('A2_COD')+oModelSA2:GetValue('A2_LOJA')
			CTD->(MsUnLock())  

			/*
			If liRec

				DbSelectArea("SA2")
				SA2->(DbSetOrder(1))
				If SA2->(DBSeek(FWxFilial("SA2")+oModelSA2:GetValue('A2_COD')+oModelSA2:GetValue('A2_LOJA')))		
					RecLock("SA2",.F.)
					SA2->A2_XITEMCC := "F"+oModelSA2:GetValue('A2_COD')+oModelSA2:GetValue('A2_LOJA')
					SA2->(MsUnLock())
			
				EndIf
			EndIf
			*/

		EndIF
	EndIf	

	RestArea(aAreaSA2)
	RestArea(aAreaCTD)

Return () 
