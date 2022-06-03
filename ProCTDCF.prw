#include "rwmake.ch"
#include "topconn.ch

 /*/{Protheus.doc} ProCTDCF
	Funçaõ responsável por atualizar os itens contábeis (Clientes e Fornecedores)
	@type  Function
	@author TOTVS Recife (Elvis Siqueira)
	@since 03/06/2022
	@version 1.0
	@param Nil
	@return Nil
	@example
	@see 
/*/

User Function ProCTDCF()       

	If FWAlertYesNo("Deseja realizar atualização dos itens contábeis a partir do cadastro de clientes e fornecedores ?", "Atualizar Itens Contábeis")
		FWMsgRun(, {|oSay| RunProcA(oSay)}, "Aguarde...","Gravando Itens Contábeis...")
		FWAlertSuccess("Processo finalizado com sucesso!", "")
	 else 
	 	FWAlertWarning("Processo abortado pelo usuário.", "Processo abortado!")
	EndIf 

Return 

/* ----------------------------------------------- /
   Função responsável por executar a atualização
/ ------------------------------------------------ */

Static Function RunProcA(oSay)           
    
   Local cQrySA1 := ""
   Local cQrySA2 := ""
	
   cQrySA1 := " Select * "
   cQrySA1 += " From " + RetSqlName("SA1") + " SA1 "
   cQrySA1 += " WHERE SA1.D_E_L_E_T_ <> '*' "

   cQrySA1 := ChangeQuery(cQrySA1)

   IF Select("TMPSA1") > 0 //Encerra tabela temporária de Clientes caso esteja aberta
        TMPSA1->(DbCloseArea())
   EndIf

   dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySA1),"TMPSA1",.T.,.T.)

	While ! TMPSA1->(EoF()) 
		
		DbSelectArea("CTD")                                	
		CTD->(DbSetOrder(1))
		If !(CTD->(DbSeek(FWxFilial("CTD")+"C"+TMPSA1->A1_COD+TMPSA1->A1_LOJA)))	                     
			RecLock("CTD",.T.)
				CTD->CTD_FILIAL	:= FWxFilial("CTD")
				CTD->CTD_ITEM  	:= "C"+TMPSA1->A1_COD+TMPSA1->A1_LOJA
				CTD->CTD_CLASSE	:= "2"
				CTD->CTD_DESC01	:= TMPSA1->A1_NOME
				CTD->CTD_BLOQ	:= "2"
				CTD->CTD_DTEXIS := CTOD("01/01/1980")
				CTD->CTD_ITLP   := "C"+TMPSA1->A1_COD+TMPSA1->A1_LOJA
				CTD->CTD_CLOBRG := "2"
				CTD->CTD_ACCLVL := "1"  
				CTD->CTD_BOOK   := "AUTO"
			CTD->(MsUnLock())	     
		EndIF

	 TMPSA1->(dbSkip())
    EndDo

//Encerra tabela temporária de Clientes
IF Select("TMPSA1") > 0
    TMPSA1->(DbCloseArea())
EndIf


   cQrySA2 := " Select * "
   cQrySA2 += " From " + RetSqlName("SA2") + " SA2 "
   cQrySA2 += " WHERE SA2.D_E_L_E_T_ <> '*' "

   cQrySA2 := ChangeQuery(cQrySA2)

   IF Select("TMPSA2") > 0 //Encerra tabela temporária de Fornecedores caso esteja aberta
        TMPSA2->(DbCloseArea())
   EndIf

   dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQrySA2),"TMPSA2",.T.,.T.)

	While ! TMPSA2->(EoF()) 
		
		DbSelectArea("CTD")                                	
		CTD->(DbSetOrder(1))
		If !(CTD->(DbSeek(FWxFilial("CTD")+"F"+TMPSA2->A2_COD+TMPSA2->A2_LOJA)))	                     
			RecLock("CTD",.T.)
				CTD->CTD_FILIAL	:= FWxFilial("CTD")
				CTD->CTD_ITEM  	:= "F"+TMPSA2->A2_COD+TMPSA2->A2_LOJA
				CTD->CTD_CLASSE	:= "2"
				CTD->CTD_DESC01	:= TMPSA2->A2_NOME
				CTD->CTD_BLOQ	:= "2"
				CTD->CTD_DTEXIS := CTOD("01/01/1980")
				CTD->CTD_ITLP   := "C"+TMPSA2->A2_COD+TMPSA2->A2_LOJA
				CTD->CTD_CLOBRG := "2"
				CTD->CTD_ACCLVL := "1"  
				CTD->CTD_BOOK   := "AUTO"
			CTD->(MsUnLock())	     
		EndIF
		
	 TMPSA2->(dbSkip())
    EndDo

//Encerra tabela temporária de Fornecedores
IF Select("TMPSA2") > 0
    TMPSA2->(DbCloseArea())
EndIf

Return


