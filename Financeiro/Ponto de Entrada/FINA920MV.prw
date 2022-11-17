#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
//----------------------------------------------------------
/*/{PROTHEUS.DOC} FINA920A
Ponto de entrada na rotina de Manutenção de Cadastro de Produto
@OWNER MCP
@VERSION PROTHEUS 12
@SINCE 29/12/21
@Replicar para demais empresas
/*/

User Function FINA920A

Local aArea     	:= GetArea()
Local aParam     	:= PARAMIXB
Local xRet       	:= .T.
Local oObj       	:= ""
Local cIdPonto   	:= ""
Local cIdModel   	:= ""
Local lIsGrid    	:= .F.
Local nLi2          := 1
Local nPos          := 0
Local cAliasTop		:= "TMPSFI"
Local aTitulo       := {}
Local aRepTit       := {}
If aParam <> NIL
	oObj     := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	lIsGrid  := (Len(aParam ) > 3)
	If cIdPonto == "MODELVLDACTIVE"
		If Valtype(MV_PAR01) == "C" .and. Valtype(MV_PAR02) == "C" .and. Valtype(MV_PAR03) == "D" .and. Valtype(MV_PAR04) == "D"
			__cFilIni	:= MV_PAR01  // 1	Da Filial ?
			__cFilFim	:= MV_PAR02  // 2 	Ate Filial ?
			__dDtCredI 	:= MV_PAR03  // 3	Data Crédito De ?
			__dDtCredF 	:= IIf(Empty(MV_PAR04), MV_PAR03, MV_PAR04) //4	Data Credito Até ?
			BeginSql Alias cAliasTop
			SELECT FIF_NSUTEF, FIF_CODFIL, FIF_DTCRED, R_E_C_N_O_ RECFIF
				FROM %table:FIF% FIF
			WHERE FIF.FIF_CODFIL BETWEEN %Exp:__cFilIni% AND %Exp:__cFilFim%
				AND FIF_DTCRED >= %Exp:Dtos(__dDtCredI)%
				AND FIF_DTCRED <= %Exp:Dtos(__dDtCredF)%
				AND FIF.%NotDel%
			ORDER BY FIF_CODFIL, FIF_DTCRED, FIF_NSUTEF
			EndSql
			While (cAliasTop)->(!Eof())
				nRecno  := (cAliasTop)->RECFIF
				cCodNSU := (cAliasTop)->FIF_NSUTEF
				cCodFil := (cAliasTop)->FIF_CODFIL
				dCred   := (cAliasTop)->FIF_DTCRED
				nPos    := aScan( aTitulo, {|x| x[1]+x[2]+x[3] == cCodFil+dCred+cCodNSU})
				If nPos == 0
					aadd(aTitulo, {cCodFil, dCred, cCodNSU, nRecno})
				Else
					aadd(aRepTit, {cCodFil, dCred, cCodNSU, nRecno})
				Endif
				dbSkip()
			End
			(cAliasTop)->(dbCloseArea())
			RestArea(aArea)
			For nLi2:=1 to Len(aRepTit)
				nRecnoFFI := aRepTit[nLi2, 4]
				DbSelectArea("FIF")
				dbGoto(nRecnoFFI)
				cCodFil    := FIF->FIF_CODFIL
				dCred      := FIF->FIF_DTCRED
				cParcela   := FIF->FIF_PARCEL
				nVlLiq     := FIF->FIF_VLLIQ
				cCodNSUOri := FIF->FIF_NSUTEF
				dEmissao   := FIF->FIF_DTTEF
				cCodNSU    := Soma1(FIF->FIF_NSUTEF)
				DbSetOrder(6)
				dbSeek(cCodFil+Dtos(dCred)+cCodNSU)
				While !Eof() .and. cCodFil+Dtos(dCred)+cCodNSU == FIF->(FIF_CODFIL+DTOS(FIF_DTCRED)+FIF_NSUTEF)
					cCodNSU := Soma1(FIF->FIF_NSUTEF)
					dbSkip()
				End
				lAtu := .F.
				DbSelectArea("SE1")
				DbSetOrder(27)
				dbSeek(cCodFil+Dtos(dEmissao)+cParcela+Right(Alltrim(cCodNSUOri),9))
				While !Eof() .and. Alltrim(cCodFil+Dtos(dEmissao)+cParcela+Right(Alltrim(cCodNSUOri),9)) == Alltrim(SE1->(E1_FILIAL+DTOS(E1_EMISSAO)+E1_PARCELA+E1_NSUTEF))
					If QtdComp(nVlLiq) == QtdComp(SE1->E1_VALOR)
						RecLock("SE1", .F.)
						Replace E1_NSUTEF with Right(Alltrim(cCodNSU),9)
						MsUnLock()
						lAtu := .T.
						Exit
					Endif
					dbSkip()
				End
				If lAtu
					DbSelectArea("FIF")
					dbGoto(nRecnoFFI)
					RecLock("FIF", .F.)
					Replace FIF_NSUTEF with cCodNSU
					MsUnLock()
				Endif
			Next
		Endif
	Endif
EndIf
Return xRet
