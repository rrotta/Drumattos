#include "rwmake.ch"
#include "topconn.ch
                 
/*/{Protheus.doc} MATA030
Ponto de Entrada em MVC do cadastro de Cliente
@author Totvs S.A.
@since 16/10/2019
@version 1.0
@OBS Para utilizar os pontos de entrada da rotina MATA030 no padr�o MVC, altere para .T. o par�metro MV_MVCSA1.

O ID do modelo da dados da rotina MATA030 � CRMA980, assim sendo, a assinatura da fun��o de usu�rio deve ser User Function CRMA980().

/*/
User Function CRMA980()
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
	Local oModelSA1 := mvModel:GetModel( 'SA1MASTER' )
	Local aAreaSA1	:= SA1->(GetArea())
	Local aAreaCTD	:= CTD->(GetArea())

	If mvModel:GetOperation() == 3 .Or. mvModel:GetOperation() == 4

		DbSelectArea("CTD")
		CTD->(DbSetOrder(1))

		If !(CTD->(DbSeek(xFilial("CTD")+"C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA'))))

			liRec	:=	RecLock("CTD",.T.)
			CTD->CTD_FILIAL := xFilial("CTD") 
			CTD->CTD_ITEM	:= "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
			CTD->CTD_CLASSE := "2"          
			CTD->CTD_DESC01 := oModelSA1:GetValue('A1_NOME')
			CTD->CTD_BLOQ	:= "2"    
			CTD->CTD_DTEXIS := CTOD("01/01/1980")
			CTD->CTD_ITLP 	:= "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
			CTD->(MsUnLock())  

			If liRec

				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))
				If SA1->(DBSeek(xFilial("SA1")+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')))		
					RecLock("SA1",.F.)
					SA1->A1_XITEMCC := "C"+oModelSA1:GetValue('A1_COD')+oModelSA1:GetValue('A1_LOJA')
					
					SA1->(MsUnLock())
			
				EndIf
			EndIf


		EndIF
	EndIf	

	RestArea(aAreaSA1)
	RestArea(aAreaCTD)

Return () 

