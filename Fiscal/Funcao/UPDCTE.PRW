#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} User Function UPDSA1
    (long_description)
    @type  Function
    @author user
    @since 15/07/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function UPDCTE
	Local aArea := GetArea()
	Local aAreaSF1 := SF1->(GetArea())
    Local aAreaSF3 := SF3->(GetArea())
    Local aAreaSFT := SFT->(GetArea())
	Local aCTE := U_LERCSV()
	Local nTam := LEN(aCTE)
	Local nIx := 0

	For nIx := 2 To nTam
		BEGINSQL ALIAS 'TSF1'
            SELECT SF1.R_E_C_N_O_
            FROM %Table:SF1% AS SF1
            WHERE SF1.F1_CHVNFE = %exp:ALLTRIM(aCTE[nix][1])%
            AND SF1.F1_CHVNFE NOT LIKE ''
            AND SF1.%NotDel%
		ENDSQL

        If !Empty(TSF1->R_E_C_N_O_)
			SF1->(DbGoto(TSF1->R_E_C_N_O_))
            Reclock("SF1",.F.)
			Replace SF1->F1_ESPECIE With "CTE"
			MsUnLock()
        EndIf
        TSF1->(DbCloseArea())
	Next

    For nIx := 2 To nTam
		BEGINSQL ALIAS 'TSF3'
            SELECT SF3.R_E_C_N_O_
            FROM %Table:SF3% AS SF3
            WHERE SF3.F3_CHVNFE = %exp:ALLTRIM(aCTE[nix])%
            AND SF3.F3_CHVNFE NOT LIKE ''
            AND SF3.%NotDel%
		ENDSQL

        If !Empty(TSF3->R_E_C_N_O_)
			SF3->(DbGoto(TSF3->R_E_C_N_O_))
            Reclock("SF3",.F.)
			Replace SF3->F3_ESPECIE With "CTE"
			MsUnLock()
        EndIf
        TSF3->(DbCloseArea())
	Next

    For nIx := 2 To nTam
		BEGINSQL ALIAS 'TSFT'
            SELECT SFT.R_E_C_N_O_
            FROM %Table:SFT% AS SFT
            WHERE SFT.FT_CHVNFE = %exp:ALLTRIM(aCTE[nix])%
            AND SFT.FT_CHVNFE NOT LIKE ''
            AND SFT.%NotDel%
		ENDSQL

        If !Empty(TSFT->R_E_C_N_O_)
			SFT->(DbGoto(TSFT->R_E_C_N_O_))
            Reclock("SFT",.F.)
			Replace SFT->FT_ESPECIE With "CTE"
			MsUnLock()
        EndIf
        TSFT->(DbCloseArea())
	Next

    SFT->(RestArea(aAreaSFT))
    SF3->(RestArea(aAreaSF3))
    SF1->(RestArea(aAreaSF1))
	RestArea(aArea)
Return
