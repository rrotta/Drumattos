#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'LOJA781.CH'

Static cSimbMoeda := AllTrim(SuperGetMv("MV_SIMB1"))

//--------------------------------------------------------
/*/{Protheus.doc} LOJA781
Monitor erros integracao ERP(GRAVABATCH)

@author  Carlos.Gorgulho
@since   20/03/2015
@version P11.8

/*/
//--------------------------------------------------------
User Function XLOJA781()

	Local aObj    	:= {}				// Array para dimensionamento de tela do Dialog
	Local aSizeAut	:= {}				// Array para dimensionamento de tela do Dialog
	Local aInfo   	:= {}				// Array para dimensionamento de tela do Dialog
	Local aPObj   	:= {}	  			// Array para dimensionamento de tela do Dialog
	Local aFilial		:= {}				// Array com os WebServices para filtro
	Local aMeto		:= {}				// Array com os metodos para filtro
	Local cMeto		:= ""	 			// Metodo selecionado para filtragem
	Local cFiltro 	:= ""				// Filtro selecionado
	Local cQuery		:= ""				// Query para filtrar os dados do log
	Local cAlias		:= GetNextAlias()	// Alias para a query
	Local dDeDt 		:= CTOD("")	 	// Data incial selecionada para filtragem
	Local dAtDt 		:= CTOD("")	 	// Data final selecionada para filtragem
	Local nCor			:= 239				// Cor do painel
	Local nOpcA		:= 0				// Variavel para confirmacao de gravacao
	Local oDlg 		:= Nil				// Objeto do dialogo   
	Local oCbx1   	:= Nil				// Objeto do combobox dos metodos dos webservices
	Local oCbs	  	:= Nil              // Objeto do combobox 

	Local aFilUsu	:= {}             	// Array filiais acesso usuario
	Local cUsuFil	:= ""               // Sring filiais selecionadas
	Local lAllFil	:= .F.              // Verifica se possui acesso a todas filiais
	Local nX		:= 1                // contador
	Local cDoc		:= Space(TamSX3("L1_DOC")[1]) //Numero documento
	Local cSerie	:= Space(TamSX3("L1_SERIE")[1])  // Serie
	Local cOrcam	:= Space(TamSX3("L1_NUM")[1])    // Numero orcamento     
	Local nValTot	:= 0                              // Valor total
	Local nQtdTot	:= 0                              // Quantidade total
	Local nTimer	:= SuperGetMv( "MV_LJTIMEM",.F., 0)   // Numero timer
	Local oFont1	:= Nil              //Objeto Fonte                   
	Local oFont2	:= Nil				//Objeto Fonte
	Local oTimer	:= Nil     			//Objeto Timer
	Local bRefresh  := {|| Nil }             //Refresh para o Timer
	Local lIntegDef := SuperGetMv( "MV_LJRMBAC",, .F.) .Or. SuperGetMv("MV_INTHTL",, .F.) //Integracao EAI
	Local cPerg		:= iif(!lIntegDef,"LOJA781","LOJA781RM")		// Nome do Pergunte da rotina
	Local cTipo 	  := "1"
	Local cModoEmpr := ""
	Local cModoUnid := ""
	Local cModoFil  := ""
	Local cFilAux	:= ""
	Local lTodos 	:= .T. //Controle filtro

	// Campo verificador se está sendo chamado pelo Robo
	Local lAutomato	:= If(Type("lAutomatoX")<>"L",.F.,lAutomatoX)
	Local lPergunte := .f. 

	Private cCadastro	:= ""	 		// Nome da rotina no Dialog
	Private aRotina	:= {}	  		// Opcoes no menu
	Private cMonStatus	:= Space(75)	// Status selecionado para filtragem      
	Private cFilSel	:= Space(75)	// String Filiais selecionadas

	DEFINE FONT oFont1  NAME "ARIAL"        SIZE 08,17 BOLD   //Largura x Altura
	DEFINE FONT oFont2  NAME "ARIAL"        SIZE 07,14 BOLD   //Largura x Altura
	DEFINE FONT oFont3  NAME "ARIAL"        SIZE 06,13 BOLD   //Largura x Altura     


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Realiza o pergunte: Exportacao ou Importacao ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lAutomato
		lPergunte := Pergunte(cPerg,.T.)
	Else
		lPergunte := .t.
	EndIf

	If lPergunte

		If lIntegDef
			cCadastro := STR0056 //"Monitor de Integrações ERP"
		Else
			cCadastro := STR0001	//"Cadastro Log de Exportação"
		EndIf

		//Defini as opcoes do menu
		AAdd(aRotina,{ STR0002	,"AxPesqui()" , 0, 1})	//"Pesquisar"
		AAdd(aRotina,{ STR0003	,"AxVisual()" , 0, 2})	//"Visualizar"  

		aFilUsu := LJ781Filial() //Valida as filiais que o usuario possui acesso

		If Empty(aFilUsu)
			MsgStop(STR0035) //"Usuario nao possui acesso a nenhuma filial do sistema"
			Return()
		ElseIf !("@" $ aFilUsu[1])
			For nX := 1 To Len(aFilUsu)
				If nX = 1
					cUsuFil := alltrim(aFilUsu[nX])
				Else
					cUsuFil += ","+ alltrim(aFilUsu[nX])
				Endif 
			Next
			cUsuFil := Iif(Empty(cUsuFil), "''", cUsuFil)
		Else
			lAllFil := .T.
		EndIf		

		//Integracao RM verifica tipo da integracao
		If lIntegDef .And. ValType(MV_PAR05) == "N"
			cTipo := CValToChar(MV_PAR05) 
		EndIf

		//Posiciona na tabela
		If cTipo == "1" //Vendas	
			dbSelectArea("SL1")
			SL1->(DbGoTop())   				

			dbSelectArea("SLX")
			SLX->(DbGoTop()) 

			If Empty(cMonStatus)						
				Do Case
					Case MV_PAR04 == 1					 
					cMonStatus := "ER|OK|RX"					
					Case MV_PAR04 == 2
					cMonStatus := "OK"
					Case MV_PAR04 == 3
					cMonStatus := "RX"
					OtherWise
					cMonStatus := "ER"
				EndCase			
			EndIf
		ElseIf cTipo == "2" //Cancelamentos
			dbSelectArea("SLX")
			SLX->(DbGoTop()) 

			Do Case
				Case MV_PAR04 == 1					 
				cMonStatus := "ER|OK|RX"					
				Case MV_PAR04 == 2
				cMonStatus := "OK"
				Case MV_PAR04 == 3
				cMonStatus := "RX"
				OtherWise
				cMonStatus := "ER"
			EndCase		
		ElseIf cTipo == "3" //Reducoes
			dbSelectArea("SFI")
			SFI->(DbGoTop())

			Do Case
				Case MV_PAR04 == 1					 
				cMonStatus := "ER|00|RX"					
				Case MV_PAR04 == 2
				cMonStatus := "00"
				Case MV_PAR04 == 3
				cMonStatus := "RX"
				OtherWise
				cMonStatus := "ER"
			EndCase		
		EndIf

		If Empty(cFilSel)
			cFilSel := MV_PAR03
		EndIf

		cModoEmpr 	:= FWModeAccess(,1)
		cModoUnid 	:= FWModeAccess(,2)
		cModoFil	:= FWModeAccess(,3)

		cFilAux := cFilSel //Inicializa filial
		cFilSel 	:= "" //Limpa filial

		//Armazena Empresa
		If cModoEmpr == "E"
			cFilSel += SubStr(cFilAux, 1, Len(FWCompany()))				
		EndIf

		nTamFil := Len(FWCompany())

		//Armazena Unidade
		If cModoUnid == "E"
			cFilSel += SubStr(cFilAux, nTamFil+1, Len(FWUnitBusiness()))
		EndIf

		nTamFil += Len(FWUnitBusiness())

		//Armazena Filial
		If cModoFil == "E"
			cFilSel += SubStr(cFilAux, nTamFil+1, FWSizeFilial())
		EndIf

		cFilSel := Padr(cFilSel, FWSizeFilial(), "")

		If cTipo == "1" //Vendas		
			If !Empty(MV_PAR03)
				If !Empty(MV_PAR04)
					SL1->(DbSetFilter( { || (L1_SITUA $(cMonStatus)) .AND. (L1_FILIAL $(cFilSel)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02))  }, ;
					' (L1_SITUA $(cMonStatus)) .AND. (L1_FILIAL $(cFilSel)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02)) '))
				Else
					SL1->(DbSetFilter( { || L1_SITUA == 'ER' .AND. (L1_FILIAL $(cFilSel)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02))  }, ;
					' L1_SITUA == "ER" .AND. (L1_FILIAL $(cFilSel)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02)) ' ))   
				EndIf	                         
			Else		
				If !Empty(MV_PAR04)
					SL1->(DbSetFilter( { || (L1_SITUA $(cMonStatus)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02))  }, ;
					' (L1_SITUA $(cMonStatus)) .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02)) ' ))                             
				Else
					SL1->(DbSetFilter( { || L1_SITUA == 'ER'  .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02))  }, ;
					' L1_SITUA == "ER" .AND. (!Empty(L1_NUMCFIS) .OR. !Empty(L1_DOC)) .AND. (DTOS(L1_DTLIM) >= DTOS(MV_PAR01) .AND. DTOS(L1_DTLIM) <= DTOS(MV_PAR02)) ' ))  
				EndIf
			EndIf
		ElseIf cTipo == "2" //Cancelamentos
			If !Empty(MV_PAR03)
				If !Empty(MV_PAR04)
					SLX->(DbSetFilter( { || (LX_SITUA $(cMonStatus) .OR. If(CValToChar(MV_PAR04) $ '1|3', Empty(LX_SITUA), LX_SITUA $(cMonStatus))) .AND.; 
					LX_FILIAL $(cFilSel) .AND. LX_TPCANC $ 'A|C' .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND.; 
					DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND. UniqueKey({'LX_FILIAL', 'LX_CUPOM', 'LX_SERIE', 'LX_PDV'}) },;																		
					'(LX_SITUA $(cMonStatus) .OR. If(CValToChar(MV_PAR04) $ "1|3", Empty(LX_SITUA), LX_SITUA $(cMonStatus)) .AND.' +; 
					'LX_FILIAL $(cFilSel) .AND. LX_TPCANC $ "A|C" .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND.' +; 
					'DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND. UniqueKey({"LX_FILIAL", "LX_CUPOM", "LX_SERIE", "LX_PDV"})' ))																											                              
				Else
					SLX->(DbSetFilter( { || LX_SITUA == 'ER' .AND. (LX_FILIAL $(cFilSel)) .AND. LX_TPCANC $ 'A|C' .AND.; 
					(DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND. DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND.; 
					UniqueKey({'LX_FILIAL', 'LX_CUPOM', 'LX_SERIE', 'LX_PDV'})}, ;
					' LX_SITUA == "ER" .AND. (LX_FILIAL $(cFilSel)) .AND. LX_TPCANC $ "A|C" .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND.' +; 
					'DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND. UniqueKey({"LX_FILIAL", "LX_CUPOM", "LX_SERIE", "LX_PDV"})' ))   
				EndIf	                         
			Else
				If !Empty(MV_PAR04)
					SLX->(DbSetFilter( { || (LX_SITUA $(cMonStatus) .OR. If(CValToChar(MV_PAR04) $ "1|3", Empty(LX_SITUA), LX_SITUA $(cMonStatus))) .AND.; 
					LX_TPCANC $ 'A|C' .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND. DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND.;
					UniqueKey({'LX_FILIAL', 'LX_CUPOM', 'LX_SERIE', 'LX_PDV'}) }, ;
					' (LX_SITUA $(cMonStatus) .OR. If(CValToChar(MV_PAR04) $ "1|3", Empty(LX_SITUA), LX_SITUA $(cMonStatus))) .AND.' +; 
					'LX_TPCANC $ "A|C" .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND. DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND.' +;
					'UniqueKey({"LX_FILIAL", "LX_CUPOM", "LX_SERIE", "LX_PDV"})'))					                             
				Else
					SLX->(DbSetFilter( { || LX_SITUA == 'ER'  .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND. DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND.; 
					UniqueKey({'LX_FILIAL', 'LX_CUPOM', 'LX_SERIE', 'LX_PDV'}) }, ;
					' LX_SITUA == "ER" .AND. LX_TPCANC $ "A|C" .AND. (DTOS(LX_DTMOVTO) >= DTOS(MV_PAR01) .AND.' +; 
					'DTOS(LX_DTMOVTO) <= DTOS(MV_PAR02)) .AND. UniqueKey({"LX_FILIAL", "LX_CUPOM", "LX_SERIE", "LX_PDV"})' ))   
				EndIf
			EndIf
		ElseIf cTipo == "3" //Reducoes							
			If !Empty(MV_PAR03)
				If !Empty(MV_PAR04)
					SFI->(DbSetFilter( { || (FI_SITUA $(cMonStatus)) .AND. (FI_FILIAL $(cFilSel)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02))  }, ;
					'(FI_SITUA $(cMonStatus)) .AND. (FI_FILIAL $(cFilSel)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02)) ' ))																																												                              	
				Else
					SFI->(DbSetFilter( { || FI_SITUA == 'ER' .AND. (FI_FILIAL $(cFilSel)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02))  }, ;
					' FI_SITUA == "ER" .AND. (FI_FILIAL $(cFilSel)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02)) ' ))   
				EndIf	                         
			Else		
				If !Empty(MV_PAR04)
					SFI->(DbSetFilter( { || (FI_SITUA $(cMonStatus)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02))  }, ;
					' (FI_SITUA $(cMonStatus)) .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02)) ' ))					                             
				Else
					SFI->(DbSetFilter( { || FI_SITUA == 'ER'  .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02))  }, ;
					' FI_SITUA == "ER" .AND. (DTOS(FI_DTREDZ) >= DTOS(MV_PAR01) .AND. DTOS(FI_DTREDZ) <= DTOS(MV_PAR02)) ' ))   
				EndIf
			EndIf		
		EndIf	

		cFiltro := ""
		dDeDt := mv_par01
		dAtDt := mv_par02

		nValTot := 0
		nQtdTot := 0

		//Seta os filtros Defaults
		If !Empty(MV_PAR04)
			If cTipo == "1" //Vendas			
				Do Case
					Case MV_PAR04 == 1
					cMonStatus := "ER|OK|RX"
					Case MV_PAR04 == 2
					cMonStatus := "OK"
					Case MV_PAR04 == 3
					cMonStatus := "RX"
					OtherWise
					cMonStatus := "ER"
				EndCase

				dbSelectArea("SL1")
				SL1->(DbGoTop())

				While SL1->(!Eof()) 
					nValTot +=	SL1->L1_VLRTOT	
					nQtdTot ++
					DbSkip()
				End

				SL1->( DbGoTop() )

				If nQtdTot <= 0
					MsgStop(STR0047,STR0048) // "Não existem vendas para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
					Return
				EndIf			
			ElseIf cTipo == "2" //Cancelamentos				
				Do Case
					Case MV_PAR04 == 1					 
					cMonStatus := "ER|OK|RX"					
					Case MV_PAR04 == 2
					cMonStatus := "OK"
					Case MV_PAR04 == 3
					cMonStatus := "RX"
					OtherWise
					cMonStatus := "ER"
				EndCase

				dbSelectArea("SLX")
				SLX->(DbGoTop())

				While SLX->(!Eof()) 
					nValTot +=	SLX->LX_VALOR	
					nQtdTot ++
					DbSkip()
				End

				SLX->( DbGoTop() )

				If nQtdTot <= 0
					MsgStop(STR0057,STR0048) // "Não existem cancelamentos para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
					Return
				EndIf	
			ElseIf cTipo == "3" //Reducoes				
				Do Case
					Case MV_PAR04 == 1					 
					cMonStatus := "ER|00|RX"					
					Case MV_PAR04 == 2
					cMonStatus := "00"
					Case MV_PAR04 == 3
					cMonStatus := "RX"
					OtherWise
					cMonStatus := "ER"
				EndCase

				dbSelectArea("SFI")
				SFI->(DbGoTop())

				While SFI->(!Eof()) 
					nValTot +=	SFI->FI_VALCON	
					nQtdTot ++
					DbSkip()
				End

				SFI->( DbGoTop() )

				If nQtdTot <= 0
					MsgStop(STR0058,STR0048) //"Não existem reduções para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
					Return
				EndIf
			EndIf
		Endif

		If !Empty(MV_PAR03)
			cFilSel 	:= MV_PAR03							
			cModoEmpr 	:= FWModeAccess(,1)
			cModoUnid 	:= FWModeAccess(,2)
			cModoFil	:= FWModeAccess(,3)		
			cFilAux 	:= cFilSel //Inicializa filial
			cFilSel 	:= "" //Limpa filial

			//Armazena Empresa
			If cModoEmpr == "E"
				cFilSel += SubStr(cFilAux, 1, Len(FWCompany()))				
			EndIf

			nTamFil := Len(FWCompany())

			//Armazena Unidade
			If cModoUnid == "E"
				cFilSel += SubStr(cFilAux, nTamFil+1, Len(FWUnitBusiness()))
			EndIf

			nTamFil += Len(FWUnitBusiness())

			//Armazena Filial
			If cModoFil == "E"
				cFilSel += SubStr(cFilAux, nTamFil+1, FWSizeFilial())
			EndIf

			cFilSel := Padr(cFilSel, FWSizeFilial(), "")		
		Endif			

		//Monta interface do monitor de Logs
		aSizeAut  := MsAdvSize()

		aADD( aObj, { 100, 030, .T., .F. })
		aADD( aObj, { 355, 200, .F., .T. })
		aADD( aObj, { 100, 015, .T., .F. })

		aInfo := { aSizeAut[1], aSizeAut[2], aSizeAut[3], aSizeAut[4], 3, 3 }

		aPObj := MsObjSize( aInfo, aObj)

		DEFINE MSDIALOG oDlg TITLE cCadastro From aSizeAut[7],00 To aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

		oPanel:= tPanel():New(aPObj[1,1], aPObj[1,2], "", oDlg,,,,,RGB(nCor,nCor,nCor), (aPObj[1,4]-aPObj[1,2]), (aPObj[1,3]-aPObj[1,1]),.T.,.F.)

		@004,010  SAY STR0006		SIZE 30, 09 OF oPanel PIXEL FONT oFont3		// "STATUS "
		@012,010  MSGET cMonStatus    	SIZE 55, 09 OF oPanel PIXEL When .F. HASBUTTON   
		oSButton := tButton():New(015,089,"?",oDlg,{|| u_LJ781F3SIT(@cMonStatus,@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},009,012,,,,.T.,,,,{|| .T.}) //Filtro Situa	


		@004,080  SAY STR0007		SIZE 35, 25 OF oPanel PIXEL FONT oFont3 		// "FILIAL
		@012,080  MSGET cFilSel    	SIZE 75, 09 OF oPanel PIXEL When .F. HASBUTTON 
		oSButton := tButton():New(015,199,"?",oDlg,{|| u_LJ781F3FIL(@cFilSel,@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot)},009,012,,,,.T.,,,,{|| .T.}) //"Filto Filial	

		If cTipo == "1" //Vendas
			@004,190  SAY STR0046		SIZE 50, 09 OF oPanel PIXEL FONT oFont3 		// "Orcamento : "
			@014,190  SAY STR0024		SIZE 30, 09 OF oPanel PIXEL  		// "Orcamento : "
			@012,225  MSGET cOrcam     	SIZE 40, 09 OF oPanel PIXEL  HASBUTTON          

			@004,290  SAY STR0039		SIZE 50, 09 OF oPanel PIXEL FONT oFont3 		// "Documento : "
			@014,290  SAY STR0040		SIZE 30, 09 OF oPanel PIXEL  		// "Nr. Doc : "
			@012,310  MSGET cDoc     	SIZE 40, 09 OF oPanel PIXEL  HASBUTTON          
			@014,352  SAY STR0041     	SIZE 30, 09 OF oPanel PIXEL  		// "Serie:"
			@012,367  MSGET cSerie     	SIZE 30, 09 OF oPanel PIXEL  HASBUTTON 	

			@004,420  SAY STR0009		SIZE 30, 09 OF oPanel PIXEL FONT oFont3 		// "DATA"
			@014,420  SAY STR0010		SIZE 10, 09 OF oPanel PIXEL  		// "De:"
			@012,430  MSGET dDeDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON          
			@014,478  SAY STR0011     	SIZE 10, 09 OF oPanel PIXEL  		// "Ate:"
			@012,490  MSGET dAtDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON 
		ElseIf cTipo == "2" //Cancelamentos
			@004,195  SAY STR0039		SIZE 50, 09 OF oPanel PIXEL FONT oFont3 		// "Documento : "
			@014,195  SAY STR0040		SIZE 30, 09 OF oPanel PIXEL  		// "Nr. Doc : "
			@012,215  MSGET cDoc     	SIZE 40, 09 OF oPanel PIXEL  HASBUTTON          
			@014,275  SAY STR0041     	SIZE 30, 09 OF oPanel PIXEL  		// "Serie:"
			@012,290  MSGET cSerie     	SIZE 30, 09 OF oPanel PIXEL  HASBUTTON 	

			@004,370  SAY STR0009		SIZE 30, 09 OF oPanel PIXEL FONT oFont3 		// "DATA"
			@014,370  SAY STR0010		SIZE 10, 09 OF oPanel PIXEL  		// "De:"
			@012,380  MSGET dDeDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON          
			@014,428 SAY STR0011     	SIZE 10, 09 OF oPanel PIXEL  		// "Ate:"
			@012,440  MSGET dAtDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON 
		ElseIf cTipo == "3" //Reducoes
			@004,195  SAY STR0039		SIZE 50, 09 OF oPanel PIXEL FONT oFont3 		// "Documento : "
			@014,195  SAY STR0059		SIZE 40, 30 OF oPanel PIXEL  		// "Nr. Reducao:"
			@012,225  MSGET cDoc     	SIZE 40, 09 OF oPanel PIXEL  HASBUTTON          

			@004,310  SAY STR0009		SIZE 30, 09 OF oPanel PIXEL FONT oFont3 		// "DATA"
			@014,310  SAY STR0010		SIZE 10, 09 OF oPanel PIXEL  		// "De:"
			@012,320  MSGET dDeDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON          
			@014,368 SAY STR0011     	SIZE 10, 09 OF oPanel PIXEL  		// "Ate:"
			@012,380  MSGET dAtDt     	SIZE 45, 09 OF oPanel PIXEL HASBUTTON
		EndIf 	

		oSButton := SButton():New(015,550,17,{|x| LJ781Filtra(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},oPanel,.T.,,)    // Filtrar																																								

		If cTipo == "1" //Vendas			
			oBrowse := BrGetDDB():New( aPObj[2,1],aPObj[2,2],(aPObj[1,4]-aPObj[1,2]),aPObj[2,4]-150,,,,oDlg,,,,,{|x| LJ781Detalhe(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},,,,,,,.F.,"SL1",.T.,,.F.,,, )			

			oBrowse:AddColumn( TcColumn():New("",{|| LoadBitmap(GetResources(),u_LJ781Leg(AllTrim(SL1->L1_SITUA))) },,,,,010,.T.,.F.,,,,,))                     
			oBrowse:AddColumn( TCColumn():New(STR0013	,{||AllTrim(SL1->L1_SITUA) },"@!(1)",,,"LEFT",,,.F.,,,,,))	//"Status"	
			oBrowse:AddColumn( TCColumn():New(STR0012	,{||AllTrim(SL1->L1_FILIAL) },"@!",,,"LEFT",,,.F.,,,,,))		//"Filial"
			oBrowse:AddColumn( TCColumn():New(STR0030	,{||AllTrim(FWFilialName(cEmpAnt,SL1->L1_FILIAL,1 ))},"@!(20)",,,"LEFT",,,.F.,,,,,))		//"Nome Filial"	
			oBrowse:AddColumn( TCColumn():New(STR0024	,{||AllTrim(SL1->L1_NUM) },"@!(10)",,,"LEFT",,,.F.,,,,,))		//"Orcamento:"
			oBrowse:AddColumn( TCColumn():New(STR0015	,{||AllTrim(SL1->L1_DOC) },"@!(10)",,,"LEFT",,,.F.,,,,,))		//"Doc.Fiscal:"	
			oBrowse:AddColumn( TCColumn():New(STR0026	,{||AllTrim(SL1->L1_SERIE) },"@!(10)",,,"LEFT",,,.F.,,,,,))	//"Serie:"
			oBrowse:AddColumn( TCColumn():New(STR0009	,{||SL1->L1_DTLIM },,,,"LEFT",,,.F.,,,,,))			//"Data"
			oBrowse:AddColumn( TCColumn():New(STR0008	,{||AllTrim(SL1->L1_HORA) },,,,"LEFT",,,.F.,,,,,))				//"Hora"      
			oBrowse:AddColumn( TCColumn():New(STR0025	,{||Transform(SL1->L1_VLRTOT,PesqPict("SL1","L1_VLRTOT",15))},,,,"RIGHT",,,.F.,,,,,))		//"Vlr.Total:"
			oBrowse:AddColumn( TCColumn():New(STR0018	,{||STRTRAN(SL1->L1_ERGRVBT,CHR(10)," -> ") },"@!",,,"LEFT",,,.F.,,,,,))		//"Detalhe do LOG"

			oPanel1:= tPanel():New(aPObj[3,1], aPObj[3,2], "", oDlg,,,,,RGB(nCor,nCor,nCor), (aPObj[1,4]-aPObj[1,2]), (aPObj[1,3]-aPObj[1,1]),.T.,.F.)

			oSButton := tButton():New(004,007,STR0043,oPanel1,{|| u_LJ781Len()},030,013,,,,.T.,,,,{|| .T.}) //"Legenda"		

			oSButton := tButton():New(004,050,STR0029,oPanel1,{|| LJ781All(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cUsuFil,lAllFil,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},055,013,,,,.T.,,,,{|| .T.}) //"Reprocessar Todos ER"	- 590

			@005,220  SAY STR0044	 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1	// "Quantidade Vendas: "
			@005,260  SAY Transform(nQtdTot,"99999")	 SIZE 40, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1

			@005,330  SAY STR0045	 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1	// "Valor Total Vendas: "
			@005,400  SAY Transform(nValTot,PesqPict("SL1", "L1_VLRTOT" ,,1))	 SIZE 50, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1
		ElseIf cTipo == "2" //Cancelamentos
			oBrowse := BrGetDDB():New( aPObj[2,1],aPObj[2,2],(aPObj[1,4]-aPObj[1,2]),aPObj[2,4]-150,,,,oDlg,,,,,{|x| LJ781Detalhe(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},,,,,,,.F.,"SLX",.T.,,.F.,,, )

			oBrowse:AddColumn( TcColumn():New("",{|| LoadBitmap(GetResources(),u_LJ781Leg(AllTrim(SLX->LX_SITUA))) },,,,,010,.T.,.F.,,,,,))                     
			oBrowse:AddColumn( TCColumn():New(STR0013	,{||AllTrim(SLX->LX_SITUA) },"@!(1)",,,"LEFT",,,.F.,,,,,))	//"Status"	
			oBrowse:AddColumn( TCColumn():New(STR0012	,{||AllTrim(SLX->LX_FILIAL) },"@!",,,"LEFT",,,.F.,,,,,))		//"Filial"
			oBrowse:AddColumn( TCColumn():New(STR0030	,{||AllTrim(FWFilialName(cEmpAnt,SLX->LX_FILIAL,1 ))},"@!(20)",,,"LEFT",,,.F.,,,,,))		//"Nome Filial"				
			oBrowse:AddColumn( TCColumn():New(STR0015	,{||AllTrim(SLX->LX_CUPOM) },"@!(10)",,,"LEFT",,,.F.,,,,,))		//"Doc.Fiscal:"	
			oBrowse:AddColumn( TCColumn():New(STR0026	,{||AllTrim(SLX->LX_SERIE) },"@!(10)",,,"LEFT",,,.F.,,,,,))	//"Serie:"
			oBrowse:AddColumn( TCColumn():New(STR0009	,{||SLX->LX_DTMOVTO },,,,"LEFT",,,.F.,,,,,))			//"Data"
			oBrowse:AddColumn( TCColumn():New(STR0008	,{||AllTrim(SLX->LX_HORA) },,,,"LEFT",,,.F.,,,,,))				//"Hora"
			oBrowse:AddColumn( TCColumn():New(STR0018	,{||STRTRAN(SLX->LX_ERGRVBT,CHR(10)," -> ") },"@!",,,"LEFT",,,.F.,,,,,))		//"Detalhe do LOG"

			oPanel1:= tPanel():New(aPObj[3,1], aPObj[3,2], "", oDlg,,,,,RGB(nCor,nCor,nCor), (aPObj[1,4]-aPObj[1,2]), (aPObj[1,3]-aPObj[1,1]),.T.,.F.)

			oSButton := tButton():New(004,007,STR0043,oPanel1,{|| u_LJ781Len()},030,013,,,,.T.,,,,{|| .T.}) //"Legenda"		

			oSButton := tButton():New(004,050,STR0029,oPanel1,{|| LJ781All(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cUsuFil,lAllFil,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},055,013,,,,.T.,,,,{|| .T.}) //"Reprocessar Todos ER"	- 590

			@005,220  SAY STR0060	 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1	// "Quantidade Cancelamentos: "
			@005,260  SAY Transform(nQtdTot,"99999")	 SIZE 40, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1

			@005,330  SAY STR0061	 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1	// "Valor Total Cancelamentos: "
			@005,400  SAY Transform(nValTot,PesqPict("SLX", "LX_VALOR" ,,1))	 SIZE 50, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1
		ElseIf cTipo == "3" //Reducoes
			oBrowse := BrGetDDB():New( aPObj[2,1],aPObj[2,2],(aPObj[1,4]-aPObj[1,2]),aPObj[2,4]-150,,,,oDlg,,,,,{|x| LJ781Detalhe(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},,,,,,,.F.,"SFI",.T.,,.F.,,, )

			oBrowse:AddColumn( TcColumn():New("",{|| LoadBitmap(GetResources(),u_LJ781Leg(AllTrim(SFI->FI_SITUA))) },,,,,010,.T.,.F.,,,,,))                     
			oBrowse:AddColumn( TCColumn():New(STR0013	,{||AllTrim(SFI->FI_SITUA) },"@!(1)",,,"LEFT",,,.F.,,,,,))	//"Status"	
			oBrowse:AddColumn( TCColumn():New(STR0012	,{||AllTrim(SFI->FI_FILIAL) },"@!",,,"LEFT",,,.F.,,,,,))		//"Filial"
			oBrowse:AddColumn( TCColumn():New(STR0030	,{||AllTrim(FWFilialName(cEmpAnt,SFI->FI_FILIAL,1 ))},"@!(20)",,,"LEFT",,,.F.,,,,,))		//"Nome Filial"										

			oBrowse:AddColumn( TCColumn():New(STR0065	,{||SFI->FI_DTMOVTO },,,,"LEFT",,,.F.,,,,,))			//"Data Movimento"
			oBrowse:AddColumn( TCColumn():New(STR0071	,{||SFI->FI_DTREDZ },,,,"LEFT",,,.F.,,,,,))			//"Data Redução"								
			oBrowse:AddColumn( TCColumn():New(STR0072	,{||Subs(SFI->FI_HRREDZ,1,2) + ":" + Subs(SFI->FI_HRREDZ,3,2) + ":" + Subs(SFI->FI_HRREDZ,5,2)},,,,"LEFT",,,.F.,,,,,))	//"Hora Redução"
			oBrowse:AddColumn( TCColumn():New(STR0025	,{||Transform(SFI->FI_VALCON,PesqPict("SFI","FI_VALCON",15))},,,,"RIGHT",,,.F.,,,,,))		//"Vlr.Total:"
			oBrowse:AddColumn( TCColumn():New(STR0018	,{||STRTRAN(SFI->FI_ERGRVBT,CHR(10)," -> ") },"@!",,,"LEFT",,,.F.,,,,,))		//"Detalhe do LOG"

			oPanel1:= tPanel():New(aPObj[3,1], aPObj[3,2], "", oDlg,,,,,RGB(nCor,nCor,nCor), (aPObj[1,4]-aPObj[1,2]), (aPObj[1,3]-aPObj[1,1]),.T.,.F.)

			oSButton := tButton():New(004,007,STR0043,oPanel1,{|| u_LJ781Len()},030,013,,,,.T.,,,,{|| .T.}) //"Legenda"		

			oSButton := tButton():New(004,050,STR0029,oPanel1,{|| LJ781All(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cUsuFil,lAllFil,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)},055,013,,,,.T.,,,,{|| .T.}) //"Reprocessar Todos ER"	- 590

			@005,220  SAY STR0062	 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1	// "Quantidade Reduções: "
			@005,260  SAY Transform(nQtdTot,"99999")	 SIZE 40, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1

			@005,330  SAY STR0063 SIZE 70, 09 OF oPanel1 PIXEL RIGHT FONT oFont1 //"Valor Total Impostos: "		
			@005,400  SAY Transform(nValTot,PesqPict("SFI", "FI_VALCON" ,,1))	 SIZE 50, 09 OF oPanel1 PIXEL RIGHT COLOR CLR_HRED FONT oFont1
		EndIf

		bRefresh := {|| LJ781Filtra(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo), 	oBrowse:refresh(),	oDlg:Refresh()    }      

		If nTimer > 0
			nTimer := nTimer * 60
			nTimer := nTimer * 1000
			DEFINE TIMER oTimer INTERVAL nTimer ACTION ( Eval( bRefresh )) OF oDlg
			oTimer:Activate()
		EndIf      

		SetKey(VK_F3, {|| .T. })

		If !lAutomato			
			ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| nOpcA := 1, oDlg:End()},{||oDlg:End()},,,,) 
		EndIf	
		DbClearFilter( )  
	EndIf

Return

//--------------------------------------------------------
/*/{Protheus.doc} LJ781MdaCbx
Seleciona as filiais selecionado pelo usuario
para o combobox de filial

@param	oDlg		Objeto do Dialog	
@param	cFilSel		Filial selecionada para a filtragem
@param	oCbx1 		Objeto do combobox dos metodos
@param	aListmeto	Array com todos os metodos encontrados 	

@author  Carlos.Gorgulho
@since   20/03/2015
@version P11.8

/*/
//--------------------------------------------------------
Static Function LJ781MdaCbx(oDlg, cFilSel, oCbx1, aListmeto)

	Local aMeto	  		:= {}			// Array dos metodos de filtragem
	Local nFor	   		:= 0			// Contador do comando For

	Default oDlg		:= Nil
	Default cFilSel		:= ""
	Default oCbx1		:= Nil
	Default aListmeto	:= {}

	aMeto := {STR0004}	//"Todos"

	//Monta array com os metodos para filtro
	For nFor := 1 to Len(aListmeto)

		If Alltrim(aListmeto[nFor][1]) == Alltrim(cFilSel)
			aADD(aMeto, aListmeto[nFor][2])
		Endif

	Next nFor

	//Atualiza a interface
	If oDlg <> Nil
		oCbx1:SetItems(aMeto)  
		oCbx1:Refresh()
		oDlg:Refresh()
	EndIf	

Return

//--------------------------------------------------------
/*/{Protheus.doc} LJ781Filtra
Monta a condicao de filtragem

@param	oDlg		Objeto do Dialog	
@param	oBrowse		Objeto do browse
@param	cMonStatus		Status selecionado para a filtragem
@param	cFilSel		WebService selecionado para a filtragem
@param	cMeto		Metodo selecionado para a filtragem
@param	dDeDt 		Data inicial para a filtragem
@param	dAtDt		Data final para a filtragem

@author  Carlos.Gorgulho
@since   20/03/2014
@version P11.8

/*/
//--------------------------------------------------------    

Static Function LJ781Filtra(oDlg,oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,nValTot,nQtdTot,cTipo)

	Local cFiltro	 := ""  		// Condicao de filtragem
	Local lRet		 := .T. 		// Variavel de retorno

	Default oDlg    := Nil
	Default oBrowse := Nil
	Default cMonStatus := ""
	Default cFilSel := ""
	Default cMeto   := ""
	Default dDeDt   := CtoD("")
	Default dAtDt   := CtoD("")                                                                         
	Default cDoc	:= Space(TamSX3("L1_DOC")[1])
	Default cSerie	:= Space(TamSX3("L1_SERIE")[1])                                              
	Default cOrcam	:= Space(TamSX3("L1_NUM")[1])      
	Default nValTot	:= 0                                                                                                                                      
	Default nQtdTot := 0


	DbClearFilter()

	//Monta as condicoes para o filtro
	If cTipo == "1" //Vendas
		dbSelectArea("SL1")

		If !Empty(cMonStatus)
			cFiltro += " L1_SITUA $(cMonStatus) "	   
		Else
			cFiltro += " L1_SITUA = 'ER' "	 
		Endif

		If MV_PAR04 == 2 //Vendas OK
			cFiltro += " .AND. L1_DOC <> '' "	
		EndIf

		If  !( Empty(dDeDt) ) .And. !( Empty(dAtDt) )
			cFiltro += " .AND. DTOS(L1_DTLIM) >= '"+DTOS(dDeDt)+"' .AND. DTOS(L1_DTLIM) <= '"+DTOS(dAtDt)+"' "
		EndIf   

		If  !( Empty(cDoc) )
			cFiltro += " .AND. L1_DOC = '"+cDoc+"' "
		EndIf   

		If  !( Empty(cSerie) )
			cFiltro += " .AND. L1_SERIE = '"+cSerie+"' "
		EndIf

		If  !(Empty(cOrcam))
			cFiltro += " .AND. L1_NUM = '"+cOrcam+"' "
		EndIf   

		If !(Empty(cFilSel))
			cFiltro += " .AND. (L1_FILIAL $(cFilSel)) "
		Endif

		//Insere o filtro na tabela
		SET FILTER TO &(cFiltro)
		SL1->(DbGotop())

		nValTot := 0
		nQtdTot := 0

		While SL1->(!Eof()) 
			nValTot +=	SL1->L1_VLRTOT	
			nQtdTot ++
			DbSkip()
		End

		//Atualiza a interface
		If oDlg <> Nil
			oBrowse:Refresh()
			oDlg:Refresh()     
		EndIf

		SL1->(DbGotop())

		If nQtdTot <= 0
			MsgStop(STR0047,STR0048) // "Não existem vendas para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
		EndIf
	ElseIf cTipo == "2" //Cancelamentos
		dbSelectArea("SLX")		

		If !Empty(cMonStatus)
			cFiltro := "(LX_SITUA $(cMonStatus) .OR. If(CValToChar(MV_PAR04) $ '1|3', Empty(LX_SITUA), LX_SITUA $(cMonStatus)))" 			   
		Else
			cFiltro := "LX_SITUA == 'ER'"	 
		Endif

		If  !( Empty(dDeDt) ) .And. !( Empty(dAtDt) )
			cFiltro += " .AND. DTOS(LX_DTMOVTO) >= '"+DTOS(dDeDt)+"' .AND. DTOS(LX_DTMOVTO) <= '"+DTOS(dAtDt)+"' "
		EndIf   

		If  !( Empty(cDoc) )
			cFiltro += " .AND. LX_CUPOM = '"+cDoc+"' "
		EndIf   		   

		If  !( Empty(cSerie) )
			cFiltro += " .AND. LX_SERIE = '"+cSerie+"' "
		EndIf

		If !Empty(cFilSel)
			cFiltro += " .AND. (LX_FILIAL $(cFilSel)) "
		Endif

		cFiltro += " .AND. LX_TPCANC $ 'A|C'"
		cFiltro += " .AND. UniqueKey({'LX_FILIAL', 'LX_CUPOM', 'LX_SERIE', 'LX_PDV'})"

		//Insere o filtro na tabela
		SET FILTER TO &(cFiltro)
		SLX->(DbGotop())

		nValTot := 0
		nQtdTot := 0

		While SLX->(!Eof()) 
			nValTot +=	SLX->LX_VALOR	
			nQtdTot ++
			DbSkip()
		End

		//Atualiza a interface
		If oDlg <> Nil
			oBrowse:Refresh()
			oDlg:Refresh()     
		EndIf

		SLX->(DbGotop())

		If nQtdTot <= 0
			MsgStop(STR0057,STR0048) // "Não existem cancelamentos para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
		EndIf
	ElseIf cTipo == "3" //Reducoes
		dbSelectArea("SFI")		

		cDoc := Padr(cDoc, TamSx3("FI_NUMREDZ")[1])

		If !Empty(cMonStatus)
			cFiltro := "(FI_SITUA $(cMonStatus))" 			   
		Else
			cFiltro := "FI_SITUA == 'ER'"	 
		Endif		

		If  !( Empty(dDeDt) ) .And. !( Empty(dAtDt) )
			cFiltro += " .AND. DTOS(FI_DTREDZ) >= '"+DTOS(dDeDt)+"' .AND. DTOS(FI_DTREDZ) <= '"+DTOS(dAtDt)+"' "
		EndIf   

		If  !( Empty(cDoc) )
			cFiltro += " .AND. FI_NUMREDZ = '"+cDoc+"' "
		EndIf   		   

		If !Empty(cFilSel)
			cFiltro += " .AND. (FI_FILIAL $(cFilSel)) "
		Endif

		//Insere o filtro na tabela
		SET FILTER TO &(cFiltro)
		SFI->(DbGotop())

		nValTot := 0
		nQtdTot := 0

		While SFI->(!Eof()) 
			nValTot +=	SFI->FI_VALCON	
			nQtdTot ++
			DbSkip()
		End

		//Atualiza a interface
		If oDlg <> Nil
			oBrowse:Refresh()
			oDlg:Refresh()     
		EndIf

		SFI->(DbGotop())

		If nQtdTot <= 0
			MsgStop(STR0058,STR0048) // "Não existem reduções para exibir. Verifique os parametros de filtro.", "Filtro sem resultado"
		EndIf
	EndIf

Return lRet

//--------------------------------------------------------
/*/{Protheus.doc} LJ781Detalhe
Interface com o detalhe do erro selecionado

@author  Carlos.Gorgulho
@since   20/03/2015
@version P11.8

/*/
//--------------------------------------------------------
Static Function LJ781Detalhe(oDlg,oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,nValTot,nQtdTot,cTipo)

	Local aAreaSL1	:= SL1->( GetArea() )		// Salva a area da tabela SL1
	Local aAreaSLX	:= SLX->( GetArea() )		// Salva a area da tabela SLX
	Local aAreaSFI	:= SFI->( GetArea() )		// Salva a area da tabela SFI
	Local cSitua		:= SL1->L1_SITUA			// Status do log de erro
	Local cCliente	:= SL1->L1_CLIENTE            // Cliente
	Local cLoja		:= SL1->L1_LOJA              //Loja
	Local cFilOrc		:= SL1->L1_FILIAL			// Filial do orcamento
	Local cNF			:= SL1->L1_DOC			// Documento Fiscal
	Local cSerNF		:= SL1->L1_SERIE           // Serie
	Local cData		:= SL1->L1_DTLIM			// Data emissao NF
	Local cHora		:= SL1->L1_HORA			// Hora 
	Local cDetalhe	:= SL1->L1_ERGRVBT			// Mensagem do erro GRVBATCH
	Local cOrc			:= Iif(SuperGetMV("MV_LJSYNT",,"0") == "1", SL1->L1_ORCPOS ,SL1->L1_NUM)			// Numero do Orcamento
	Local cPDV			:= SL1->L1_PDV               // Numero PDV
	Local cOper		:= SL1->L1_OPERADO           //oPERADOR
	Local cVlrTot		:= SL1->L1_VLRTOT            // Valor total
	Local nOpcA		:= 0						// Confirmacao da gravacao
	Local oDlg1		:= Nil						// Objeto do Dialogo
	Local cL1Num		:= SL1->L1_NUM             // Numero do orcamento  
	Local aCanc		:= {}						  //Informacoes cancelamentos
	Local aReducao 	:= {}						  //Informacoes de reducoes
	Local cReducao 	:= ""							// Reducao
	Local cDtMovto 	:= ""							// Data Movimento
	Local oPanel2		:= Nil							//Painel da tela                                               

	// Campo verificador se está sendo chamado pelo Robo
	Local lAutomato	:= If(Type("lAutomatoX")<>"L",.F.,lAutomatoX)

	Default oDlg		:= Nil
	Default oBrowse	:= Nil
	Default cMonStatus 	:= ""
	Default cFilSel 	:= ""
	Default cMeto 	:= ""
	Default dDeDt 	:= ""
	Default dAtDt 	:= ""
	Default cDoc		:= ""
	Default cSerie	:= ""
	Default cOrcam	:= ""
	Default nValTot	:= 0
	Default nQtdTot	:= 0

	If cTipo == "1" //Vendas
		cSitua	:= SL1->L1_SITUA                                                 	

	ElseIf cTipo == "2" //Cancelamentos
		cSitua		:= SLX->LX_SITUA		// Status do log de erro	
		cFilOrc	:= SLX->LX_FILIAL		// Filial do orcamento
		cNF			:= SLX->LX_CUPOM		// Documento Fiscal
		cSerNF		:= SLX->LX_SERIE    	// Serie
		cData		:= SLX->LX_DTMOVTO	// Data emissao NF
		cHora		:= SLX->LX_HORA		// Hora
		cDetalhe	:= SLX->LX_ERGRVBT	// Mensagem do erro GRVBATCH
		cPDV		:= SLX->LX_PDV      	// Numero PDV
		cOper		:= SLX->LX_OPERADO  	//oPERADOR
		cVlrTot	:= SLX->LX_VALOR   	// Valor total		 

		//Armazena informacoes do cancelamento
		aAdd(aCanc, SLX->LX_FILIAL)
		aAdd(aCanc, SLX->LX_PDV)			
		aAdd(aCanc, SLX->LX_CUPOM)
		aAdd(aCanc, SLX->LX_SERIE)

	ElseIf cTipo == "3" //Cancelamentos
		cFilOrc	:= SFI->FI_FILIAL		// Filial do orcamento
		cVlrTot	:= SFI->FI_VALCON   	// Valor total
		cReducao	:= SFI->FI_NUMREDZ	// Reducao
		cDtMovto	:= SFI->FI_DTMOVTO	// Data Movimento
		cData		:= SFI->FI_DTREDZ		// Data Reducao
		cHora		:= Subs(SFI->FI_HRREDZ,1,2) + ":" + Subs(SFI->FI_HRREDZ,3,2) + ":" + Subs(SFI->FI_HRREDZ,5,2)
		cPDV		:= SFI->FI_PDV      	// Numero PDV

		//Armazena informacoes da reducao
		aAdd(aReducao, SFI->FI_FILIAL)
		aAdd(aReducao, SFI->FI_DTMOVTO)			
		aAdd(aReducao, SFI->FI_PDV)
		aAdd(aReducao, SFI->FI_NUMREDZ)
	EndIf

	//Monta interface do detalhe do Logs
	DEFINE MSDIALOG oDlg1 TITLE STR0018 Style DS_MODALFRAME FROM 0,0 TO 510,585 OF oMainWnd PIXEL	   			//"Detalhe do LOG"

	oPanel2:= tPanel():New(40,01,"",oDlg1,,,,,,505,550)

	oDlg1:lEscClose:=.F.

	@008,010 Say STR0013 Size 30, 09 Of oPanel2 Pixel		//"Status"

	If cSitua == "ER"
		@007,030 ComboBox oCombo Var cSitua Items {"ER-"+STR0019,"RX-"+STR0020} Size 60, 09 Of oPanel2 Pixel		//"Erro"#"Reprocessar"	
	Else
		@007,030 ComboBox oCombo Var cSitua Items {"RX-"+STR0020} Size 60, 09 Of oPanel2 Pixel					//"Reprocessar"
	EndIf	     

	If cTipo == "1" //Vendas
		@025,010 TO 055,285 LABEL OF oPanel2 PIXEL
		@035,015 Say STR0014 Size 30,09 Of oPanel2 Pixel																//Filal
		@034,040 MsGet cFilOrc When .F. Size 35,09 Of oPanel2 Pixel 
		@035,105 Say STR0024 Size 30,09 Of oPanel2 Pixel																//"Orcamento"
		@034,140 MsGet cOrc When .F. Size 40,09 Of oPanel2 Pixel
		@035,203 Say STR0025 + cSimbMoeda Size 30,09 Of oPanel2 Pixel														//"Vlr.Total"
		@034,235 MsGet cVlrTot Picture "@E 999,999.99" When .F. Size 40,09 Of oPanel2 Pixel

		@065,010 TO 095,285 LABEL OF oPanel2 PIXEL
		@075,015 Say STR0022 Size 30,09 Of oPanel2 Pixel																//"Cliente"
		@074,040 MsGet cCliente When .F. Size 50,09 Of oPanel2 Pixel 
		@075,120 Say STR0023 Size 30,09 Of oPanel2 Pixel																//"Loja"
		@074,140 MsGet cLoja When .F. Size 20,09 Of oPanel2 Pixel

		@105,010 TO 140,285 LABEL OF oPanel2 PIXEL
		@121,015 Say STR0015 Size 50,09 Of oPanel2 Pixel																//"NF"
		@120,050 MsGet cNF When .F. Size 60,09 Of oPanel2 Pixel 
		@121,120 Say STR0026 Size 30,09 Of oPanel2 Pixel																//"SERIE"
		@120,140 MsGet cSerNF When .F. Size 25,09 Of oPanel2 Pixel

		@150,010 TO 185,285 LABEL OF oPanel2 PIXEL																
		@165,015 Say STR0016 Size 30,09 Of oPanel2 Pixel																//"PDV"
		@164,035 MsGet cPDV When .F. Size 30,09 Of oPanel2 Pixel
		@165,110 Say STR0017 Size 30,09 Of oPanel2 Pixel																//"Operador:"
		@164,140 MsGet cOper When .F. Size 30,09 Of oPanel2 Pixel

		If !Empty(cDetalhe)
			oTMultiget2 := tMultiget():new(195,010, {| u | If( PCount() > 0, cDetalhe := u, cDetalhe ) }, oPanel2, 275,040, , , , , , .T. )
		EndIf
	ElseIf cTipo == "2" //Cancelamentos
		@025,010 TO 055,285 LABEL OF oPanel2 PIXEL
		@035,015 Say STR0014 Size 30,09 Of oPanel2 Pixel																//Filal
		@034,040 MsGet cFilOrc When .F. Size 35,09 Of oPanel2 Pixel 	
		@035,103 Say STR0025 + cSimbMoeda Size 30,09 Of oPanel2 Pixel																//"Vlr.Total"
		@034,140 MsGet cVlrTot Picture "@E 999,999.99" When .F. Size 40,09 Of oPanel2 Pixel

		@065,010 TO 130,285 LABEL OF oPanel2 PIXEL
		@091,015 Say STR0015 Size 50,09 Of oPanel2 Pixel																//"NF"
		@090,050 MsGet cNF When .F. Size 60,09 Of oPanel2 Pixel 
		@091,120 Say STR0026 Size 30,09 Of oPanel2 Pixel																//"SERIE"
		@090,140 MsGet cSerNF When .F. Size 25,09 Of oPanel2 Pixel

		@135,010 TO 185,285 LABEL OF oPanel2 PIXEL																
		@151,015 Say STR0016 Size 30,09 Of oPanel2 Pixel																//"PDV"
		@150,035 MsGet cPDV When .F. Size 30,09 Of oPanel2 Pixel
		@151,110 Say STR0017 Size 30,09 Of oPanel2 Pixel																//"Operador:"
		@150,140 MsGet cOper When .F. Size 30,09 Of oPanel2 Pixel

		If !Empty(cDetalhe)
			oTMultiget2 := tMultiget():new(195,010, {| u | If( PCount() > 0, cDetalhe := u, cDetalhe ) }, oPanel2, 275,040, , , , , , .T. )
		EndIf
	ElseIf cTipo == "3" //Reducoes
		@025,010 TO 055,285 LABEL OF oPanel2 PIXEL
		@035,015 Say STR0014 Size 30,09 Of oPanel2 Pixel																//Filal
		@034,040 MsGet cFilOrc When .F. Size 35,09 Of oPanel2 Pixel 	
		@035,105 Say STR0064 Size 50,09 Of oPanel2 Pixel																//Redução																
		@034,140 MsGet cReducao When .F. Size 60,09 Of oPanel2 Pixel
		@034,225 Say STR0016 Size 30,09 Of oPanel2 Pixel																//"PDV"
		@035,250 MsGet cPDV When .F. Size 30,09 Of oPanel2 Pixel	


		@105,010 TO 140,285 LABEL OF oPanel2 PIXEL			
		@121,015 Say STR0073 Size 80,20 Of oPanel2 Pixel																//Data Movto
		@120,050 MsGet cDtMovto When .F. Size 50,09 Of oPanel2 Pixel
		@121,105 Say STR0071 Size 50,20 Of oPanel2 Pixel																//Data Redução																	
		@120,145 MsGet cData When .F. Size 50,09 Of oPanel2 Pixel
		@121,200 Say STR0072 Size 50,20 Of oPanel2 Pixel																//Hora	Redução
		@120,235 MsGet cHora When .F. Size 50,09 Of oPanel2 Pixel	

		If !Empty(cDetalhe)
			oTMultiget2 := tMultiget():new(155,010, {| u | If( PCount() > 0, cDetalhe := u, cDetalhe ) }, oPanel2, 275,080, , , , , , .T. )
		EndIf																		
	EndIf
	If !lAutomato
		ACTIVATE MSDIALOG oDlg1 CENTER ON INIT EnchoiceBar(oDlg1,{|| nOpcA := 1, IIF(Lj781Atu(oDlg1,cSitua,cCliente,cLoja,nOpcA,cL1Num,cFilOrc,cTipo,aCanc,aReducao),oDlg1:End(),NIL)},{||oDlg1:End()},,,,)
	EndIf
	If oDlg <> Nil	 		  		
		oBrowse:Refresh()
		oDlg:Refresh()	
	EndIf

	RestArea(aAreaSL1)
	RestArea(aAreaSLX)
	RestArea(aAreaSFI)

Return       

//--------------------------------------------------------
/*/{Protheus.doc} Lj781Atu

Atualiza registro para reprocessar 

@param	oDlg1		Objeto do Dialog	
@param	cMonStatus		Status selecionado para a filtragem
@param	cSeq		Codigo sequencial do log de erro
@param	cRef		Codigo de referencia a tabela intermediaria
@param	nOpcA 		Confirmacao da gravacao

@author  Carlos.Gorgulho
@since   20/03/2014
@version P11.8

/*/
//--------------------------------------------------------
Static Function Lj781Atu(oDlg1,cSitua,cCliente,cLoja,nOpcA,cL1Num,cFilOrc,cTipo,aCanc,aReducao)

	Local cOrig		 := SL1->L1_SITUA		// Status antes da gravacao
	Local lRet		 := .T.			   		// Retorno da funcao

	Default oDlg1    := Nil
	Default cSitua   := ""
	Default cCliente := ""
	Default cLoja    := ""
	Default nOpcA    := 0                                            
	Default cL1Num	 := ""   
	Default cFilOrc	 := FWxFilial("SL1")
	Default cTipo		:= "1"
	Default aCanc		:= {}

	If cTipo == "1" //Vendas
		cOrig := SL1->L1_SITUA
	ElseIf cTipo == "2" //Cancelamentos
		cFilOrc := FWxFilial("SLX")
		cOrig := SLX->LX_SITUA
	EndIf

	//Altera os registros
	If nOpcA == 1 .AND. SubStr(cSitua,1,1) <> cOrig

		//Atualiza registro para reprocessar
		If cTipo == "1" //Vendas
			dbSelectArea("SL1")
			SL1->(dbSetOrder(1))
			If SL1->(dbSeek(cFilOrc+ cL1Num))	  	
				If !(SL1->L1_SITUA $ "OK|AG|RX|RY")
					RecLock("SL1",.F.)		
					SL1->L1_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
					SL1->L1_ERGRVBT	:= ""
					SL1->(MsUnLock())   
				Else 
					MsgInfo(STR0037) //"Reprocessamento permitido somente para vendas com status ER-Erro"
					lRet := .F.
				EndIf
			Else	
				lRet := .F.	
			EndIf
		ElseIf cTipo == "2" //Cancelamentos
			dbSelectArea("SLX")
			SLX->(dbSetOrder(1))

			If SLX->(dbSeek(aCanc[1]+aCanc[2]+aCanc[3]+aCanc[4]))	  				
				If !(SLX->LX_SITUA $ "OK|AG|RX|RY") .And. !Empty(SLX->LX_SITUA)						
					While SLX->(!Eof()) .And. SLX->LX_FILIAL == aCanc[1] .And. SLX->LX_PDV == aCanc[2] .And.;
					SLX->LX_CUPOM == aCanc[3] .And. SLX->LX_SERIE == aCanc[4]

						If SLX->LX_TPCANC $ "A|C"
							RecLock("SLX",.F.)		
							SLX->LX_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
							SLX->LX_ERGRVBT	:= ""
							SLX->(MsUnLock())
						EndIf

						SLX->(dbSkip())
					EndDo   
				Else 
					MsgInfo(STR0037) //"Reprocessamento permitido somente para vendas com status ER-Erro"
					lRet := .F.
				EndIf
			Else	
				lRet := .F.	
			EndIf
		ElseIf cTipo == "3" //Reducoes
			dbSelectArea("SFI")
			SFI->(dbSetOrder(1))

			If SFI->(dbSeek(aReducao[1]+DtoS(aReducao[2])+aReducao[3]+aReducao[4]))	  				
				If !(SFI->FI_SITUA $ "OK|AG|RX|RY|00")																									
					RecLock("SFI",.F.)		
					SFI->FI_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
					SFI->FI_ERGRVBT	:= ""
					SFI->(MsUnLock())													
				Else 
					MsgInfo(STR0037) //"Reprocessamento permitido somente para vendas com status ER-Erro"
					lRet := .F.
				EndIf
			Else	
				lRet := .F.	
			EndIf
		EndIf

	EndIf

	//Atualiza a interface
	If oDlg1 <> Nil
		oDlg1:Refresh()
	EndIf    

Return lRet  

//--------------------------------------------------------
/*/{Protheus.doc} Lj781ALL
Reprocessar todos com status ER

@param	oDlg1		Objeto do Dialog	
@param	cMonStatus		Status selecionado para a filtragem
@param	cSeq		Codigo sequencial do log de erro
@param	cRef		Codigo de referencia a tabela intermediaria
@param	nOpcA 		Confirmacao da gravacao

@author  Carlos.Gorgulho
@since   20/03/2014
@version P11.8

/*/
//--------------------------------------------------------

Static Function Lj781All(oDlg,oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cUsuFil,lAllFil,cDoc,cSerie,cOrcam,nValTot,nQtdTot,cTipo)

	Local lRet		:= .T. 		// Variavel de retorno

	Default oDlg    := Nil
	Default oBrowse := Nil
	Default cMonStatus := ""
	Default cFilSel := ""
	Default cMeto   := ""
	Default dDeDt   := CtoD("")
	Default dAtDt   := CtoD("")
	Default cUsuFil	:= ""
	Default lAllFil := .F.                                                                           
	Default cDoc	:= Space(TamSX3("L1_DOC")[1])
	Default cSerie	:= Space(TamSX3("L1_SERIE")[1])
	Default cOrcam	:= Space(TamSX3("L1_NUM")[1])           

	//Atualiza registro para reprocessar
	If cTipo == "1" //Venda
		While SL1->(!Eof()) 
			If !(SL1->L1_SITUA $ "OK|AG|RX|RY") 
				RecLock("SL1",.F.)		
				SL1->L1_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
				SL1->L1_ERGRVBT	:= ""
				SL1->(MsUnLock())     
			EndIf

			SL1->(DbSkip())
		EndDo
	ElseIf cTipo == "2" //Cancelamentos
		While SLX->(!Eof()) 
			If !(SLX->LX_SITUA $ "OK|AG|RX|RY") .And. !Empty(SLX->LX_SITUA) .And. SLX->LX_TPCANC $ "A|C"
				RecLock("SLX",.F.)		
				SLX->LX_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
				SLX->LX_ERGRVBT	:= ""
				SLX->(MsUnLock())     
			EndIf

			SLX->(DbSkip())
		End
	ElseIf cTipo == "3" //Reducoes	
		While SFI->(!Eof()) 
			If !(SFI->FI_SITUA $ "OK|AG|RX|RY|00")
				RecLock("SFI",.F.)		
				SFI->FI_SITUA 	:= "RX"  //ER=Erro RX=Reprocessar
				SFI->FI_ERGRVBT	:= ""
				SFI->(MsUnLock())     
			EndIf

			SFI->(DbSkip())
		End
	EndIf

	//Atualiza a interface
	If oDlg <> Nil
		oDlg:Refresh()
	EndIf    

	LJ781Filtra(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)

Return lRet

//--------------------------------------------------------
/*/{Protheus.doc} LJ781Filial
Valida as filiais que o usuario possui acessos 

@author	TOTVS
@since		28/09/15
@version	P11.8
@obs		Indicadores Gerenciais
/*/
//--------------------------------------------------------
Static Function LJ781Filial()

	Local aUsrFil	:= {}	// Retorna vetor com informações do usuário
	Local aGrupo    := ""	// Grupos que o usuario pertence
	Local nX        := 0	// Variável de laço For
	Local nxFil     := 0	// Variável de laço For
	Local nInc      := 0	// Variável de laço For
	Local aFilUsr   := {}	// Array de retorno com as filiáis de acesso do usuário

	PswOrder(1)
	If PswSeek( __cUserID, .T. )
		aUsrFil := PswRet()[2,6] 					// Retorna vetor com informações do usuário   

		If Empty(aUsrFil) .And. PswRet()[2,11]  	// Verifica se prioriza os acessos do grupo do usuario
			aGrupo := PswRet()[1,10]   				// Grupos que o usuario pertence
			For nX := 1 To  Len(aGrupo)  			// Busca as filiais dos grupos q o usuario tem acesso
				PswSeek( aGrupo[nX], .F. ) 
				For nxFil := 1 To Len(PswRet()[1,11]) 
					AADD(aUsrFil, PswRet()[1,11][nXFil])
				Next
			Next
		Endif   

		// Adiciona as filiais que o usuario tem permissão            
		If Len( aUsrFil ) >= 0
			If !EMPTY(mv_par03) 
				If "@" $ aUsrFil[1]
					For nInc := 1 To Len( aUsrFil )
						AADD(aFilUsr,  Right( aUsrFil[nInc],LEN(aUsrFil[nInc])-2 ) )
					Next	
				Else
					For nInc := 1 To Len( aUsrFil )    
						AADD(aFilUsr, Right( aUsrFil[nInc],LEN(aUsrFil[nInc])-2 ))
					Next
				Endif
			Else
				For nInc := 1 To Len( aUsrFil )
					AADD(aFilUsr, Right( aUsrFil[nInc],LEN(aUsrFil[nInc])-2 ) )
				Next	
			Endif	
		Endif
	Endif

Return aFilUsr                                                                            

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} LJ781Leg
Função para definição da legenda da venda

@author    Vendas.Varejo
@version   11.8
@since     29/09/2015

@param cMonStatus 	Status da venda (L1_SITUA)
@return cRet		String do bitmap da legenda

/*/
//------------------------------------------------------------------------------------------
User Function LJ781Leg(cMonStatus)

	Local cRet := ""    // Variavel de retorno

	DEFAULT cMonStatus := ""

	If cMonStatus $ "OK|00" //OK
		cRet := "BR_VERDE"
	ElseIf cMonStatus == "ER" //Erro
		cRet := "BR_VERMELHO"	
	ElseIf cMonStatus == "RX" //Erro
		cRet := "BR_AZUL"	
	EndIf

Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} LJ781Len
Função para exibicao da legenda

@author    Vendas.Varejo
@version   11.8
@since     29/09/2015

/*/
//------------------------------------------------------------------------------------------

User Function LJ781Len()

	Local aCores := {	{"BR_VERDE"		,OemToAnsi(STR0067)},;	//"OK-Concluido"
	{"BR_VERMELHO"	,OemToAnsi(STR0068)},;	//"ER-Erro"
	{"BR_AZUL" 		,OemToAnsi(STR0069)}}	//"RX-Reprocessar"

	BrwLegenda(STR0070,STR0038,aCores) //"Legenda","Status das vendas: "

Return()

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} LJ781F3SIT
Função para exibir os status das vendas a partir de um F3

@author    Vendas.Varejo
@version   11.8
@since     01/10/2015

/*/
//------------------------------------------------------------------------------------------

User Function LJ781F3SIT(cDado,oDlg,oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,nValTot,nQtdTot,cTipo)

	Local aArea     	:= GetArea()         //Area
	Local K_OK      	:= 0                  // opc ok
	Local oDlg1                               // Objeto Dialog
	Local nOpca     	:= 0                  // opcao
	Local nPosStatus	:= 0                  // posicao array status
	Local bOK       	:= { || nOpca := K_OK, oDlg1:End() }    // confirma
	Local bCancel   	:= { || oDlg1:End() }                    // cancela
	Local oCritica                                                // objeto
	Local cQuery                                                  // string query
	Local aCritica	 	:= {}                                    // array status
	Local nInd                                                   // contador
	Local cAlias		:= GetNextAlias()	// Alias para a query
	Local cMonStatusAnt	:= cMonStatus			//Status do L1_SITUA anterior

	// Campo verificador se está sendo chamado pelo Robo
	Local lAutomato	:= If(Type("lAutomatoX")<>"L",.F.,lAutomatoX)

	Default cDado		:= ""                                                                                                                                                                       
	Default oDlg        := nil
	Default oBrowse     := nil                                                                             
	Default cMonStatus		:= ""
	Default cFilSel		:= ""
	Default cMeto		:= ""
	Default dDeDt		:= ""
	Default dAtDt     	:= ""
	Default cDoc		:= ""
	Default cSerie   	:= ""                                                                               
	Default cOrcam 		:= ""

	cDado    := AllTrim(cDado)

	//Monta query para filtrar os dados
	If cTipo == "1" //Vendas
		cQuery := "SELECT "
		cQuery += "		L1_SITUA,"
		cQuery += "		CASE L1_SITUA WHEN 'ER' Then 'Erro' WHEN 'RX' Then 'Reprocessar' ELSE 'Concluido' END AS DESC_SITUA"
		cQuery += "	FROM " + RetSQLName("SL1") + " SL1 "
		cQuery += "WHERE "  
		cQuery += "	SL1.D_E_L_E_T_ <> '*'	" 

		If MV_PAR04 == 2 //Vendas OK
			cQuery += "	AND SL1.L1_DOC <> ''	" 
		EndIf

		cQuery += " GROUP BY L1_SITUA  	"  

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)

		While ! (cAlias)->(Eof())

			nPosStatus	:= aScan(aCritica,{|x| x[1] == (cAlias)->L1_SITUA})

			If (nPosStatus == 0)
				aadd(aCritica,{(cAlias)->L1_SITUA,(cAlias)->DESC_SITUA,If((cAlias)->L1_SITUA$cDado,.T.,.F.)})
			EndIf

			(cAlias)->(DbSkip())

		EndDo

		(cAlias)->(DbCloseArea())
	ElseIf cTipo == "2" //Cancelamentos
		cQuery := "SELECT "
		cQuery += "		LX_SITUA,"
		cQuery += "		CASE LX_SITUA WHEN 'ER' Then 'Erro' WHEN 'RX' Then 'Reprocessar' ELSE 'Concluido' END AS DESC_SITUA"
		cQuery += "	FROM " + RetSQLName("SLX") + " SLX "
		cQuery += "WHERE "  
		cQuery += "	SLX.LX_TPCANC IN ('A','C')	"   
		cQuery += "	AND	SLX.D_E_L_E_T_ <> '*'	"      
		cQuery += " GROUP BY LX_SITUA  	"  

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)

		While ! (cAlias)->(Eof())

			nPosStatus	:= aScan(aCritica,{|x| x[1] == (cAlias)->LX_SITUA})

			If (nPosStatus == 0)
				aadd(aCritica,{(cAlias)->LX_SITUA,(cAlias)->DESC_SITUA,If((cAlias)->LX_SITUA$cDado,.T.,.F.)})
			EndIf

			(cAlias)->(DbSkip())

		EndDo

		(cAlias)->(DbCloseArea())
	ElseIf cTipo == "3" //Reducoes
		cQuery := "SELECT "
		cQuery += "		FI_SITUA,"
		cQuery += "		CASE FI_SITUA WHEN 'ER' Then 'Erro' WHEN 'RX' Then 'Reprocessar' ELSE 'Concluido' END AS DESC_SITUA"
		cQuery += "	FROM " + RetSQLName("SFI") + " SFI "
		cQuery += "WHERE "  	   
		cQuery += "	SFI.D_E_L_E_T_ <> '*'	"      
		cQuery += " GROUP BY FI_SITUA  	"  

		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)

		While ! (cAlias)->(Eof())

			nPosStatus	:= aScan(aCritica,{|x| x[1] == (cAlias)->FI_SITUA})

			If (nPosStatus == 0)
				aadd(aCritica,{(cAlias)->FI_SITUA,(cAlias)->DESC_SITUA,If((cAlias)->FI_SITUA$cDado,.T.,.F.)})
			EndIf

			(cAlias)->(DbSkip())

		EndDo

		(cAlias)->(DbCloseArea())
	EndIf

	RestArea(aArea)

	DEFINE MSDIALOG oDlg1 TITLE STR0013 FROM 10,10 TO 28,65 OF GetWndDefault() //"Status: "

	oCritica := TcBrowse():New( 020, 012, 195, 110,,,, oDlg1,,,,,,,,,,,, .F.,, .T.,, .F., )

	oCritica:AddColumn(TcColumn():New(" ",{ || IF(aCritica[oCritica:nAt,3],LoadBitmap( GetResources(), "LBOK" ),LoadBitmap( GetResources(), "LBNO" )) },;
	"@!",nil,nil,nil,012,.T.,.T.,nil,nil,nil,.T.,nil))     

	oCritica:AddColumn(TcColumn():New(STR0013 ,{ || OemToAnsi(aCritica[oCritica:nAt,1]) },;
	"@!",nil,nil,nil,020,.F.,.F.,nil,nil,nil,.F.,nil))  //"Codigo"   

	oCritica:AddColumn(TcColumn():New(STR0042 ,{ || OemToAnsi(aCritica[oCritica:nAt,2]) },;
	"@!",nil,nil,nil,200,.F.,.F.,nil,nil,nil,.F.,nil))  //"Descricao"   

	oCritica:SetArray(aCritica)         
	oCritica:bLDblClick := { || aCritica[oCritica:nAt,3] := IF(aCritica[oCritica:nAt,3],.F.,.T.) }
	If !lAutomato
		ACTIVATE MSDIALOG oDlg1 ON INIT EnChoiceBar(oDlg1,bOK,bCancel,.F.,{})
	Else
		nOpca := K_OK
	EndIf
	If nOpca == K_OK

		cDado := ""
		For nInd := 1 To Len(aCritica)
			If aCritica[nInd,3]
				cDado += aCritica[nInd,1]+","
			Endif 
		Next
		cDado := Substr(cDado,1,Len(cDado)-1)
	Endif

	cMonStatus := cDado

	If oDlg <> Nil
		oBrowse:refresh()
		oDlg:Refresh()
		LJ781Filtra(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)
	EndIf

Return(cDado)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} LJ781F3FIL
Função para exibir as filiais que o usuario possui acesso a partir de um F3

@author    Vendas.Varejo
@version   11.8
@since     02/10/2015

/*/
//------------------------------------------------------------------------------------------

User Function LJ781F3FIL(cDado,oDlg,oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,nValTot,nQtdTot,cTipo)

	Local aArea     	:= GetArea()   // area selecionada
	Local K_OK      	:= 0            // apcao ok
	Local oDlg2                          // objeto dialog
	Local nOpca     	:= 0             // opcao
	Local nPosStatus	:= 0             // posicao array filial
	Local nX			:= 0               // contador
	Local bOK       	:= { || nOpca := K_OK, oDlg2:End() } // ok
	Local bCancel   	:= { || oDlg2:End() }               // cancela
	Local oCritica                                           // obejto seleciona filial
	Local cQuery                                              // string query
	Local cUsuFil		:= ""                                  // string usuario filial
	Local lAllFil		:= .F.                                 // todas filiais
	Local aCritica	 	:= {}                                  // array selecao
	Local aFilial		:= {}                                  // array filiais
	Local aFilUsu		:= {}                                  // array filial usuario acesso
	Local aCloneFil		:= {}                                  // array auxiliar filial
	Local nInd                                                  // contador
	Local cAlias		:= GetNextAlias()	// Alias para a query

	// Campo verificador se está sendo chamado pelo Robo
	Local lAutomato	:= If(Type("lAutomatoX")<>"L",.F.,lAutomatoX)

	Default cDado		:= ""                                                                                                                                                                       
	Default oDlg        := nil
	Default oBrowse     := nil                                                                             
	Default cMonStatus		:= ""
	Default cFilSel		:= ""
	Default cMeto		:= ""
	Default dDeDt		:= ""
	Default dAtDt     	:= ""
	Default cDoc		:= ""
	Default cSerie   	:= ""                                                                               
	Default cOrcam		:= ""

	cDado    := AllTrim(cDado)

	aFilial := FWAllFilial()

	aFilUsu := LJ781Filial() //Valida as filiais que o usuario possui acesso

	If Empty(aFilUsu)
		MsgStop(STR0035) //"Usuario nao possui acesso a nenhuma filial do sistema" 
		Return()
	ElseIf !("@" $ aFilUsu[1])
		For nX := 1 To Len(aFilUsu)
			If nX = 1
				cUsuFil := alltrim(aFilUsu[nX])
			Else
				cUsuFil += ","+ alltrim(aFilUsu[nX])
			Endif 
		Next
		cUsuFil := Iif(Empty(cUsuFil), "''", cUsuFil)
	Else
		lAllFil := .T.
	EndIf

	If lAllFil
		aCloneFil := aClone(aFilial) 
	Else	
		aCloneFil := aClone(aFilUsu) 
	EndiF

	For nX := 1 To Len(aCloneFil)

		nPosStatus	:= aScan(aCritica,aCloneFil[nX])

		If (nPosStatus == 0)
			aadd(aCritica,{aCloneFil[nX],FWFilialName(cEmpAnt,aCloneFil[nX],1),If(aCloneFil[nX]$cDado,.T.,.F.)})
		EndIf

	Next

	RestArea(aArea)

	DEFINE MSDIALOG oDlg2 TITLE STR0012 FROM 10,10 TO 28,65 OF GetWndDefault() //"Filial "

	oCritica := TcBrowse():New( 008, 012, 195, 110,,,, oDlg2,,,,,,,,,,,, .F.,, .T.,, .F., )

	oCritica:AddColumn(TcColumn():New(" ",{ || IF(aCritica[oCritica:nAt,3],LoadBitmap( GetResources(), "LBOK" ),LoadBitmap( GetResources(), "LBNO" )) },;
	"@!",nil,nil,nil,012,.T.,.T.,nil,nil,nil,.T.,nil))     

	oCritica:AddColumn(TcColumn():New(STR0012 ,{ || OemToAnsi(aCritica[oCritica:nAt,1]) },;
	"@!",nil,nil,nil,020,.F.,.F.,nil,nil,nil,.F.,nil))  //"Codigo"   

	oCritica:AddColumn(TcColumn():New(STR0042 ,{ || OemToAnsi(aCritica[oCritica:nAt,2]) },;
	"@!",nil,nil,nil,200,.F.,.F.,nil,nil,nil,.F.,nil))  //"Descricao"   

	oCritica:SetArray(aCritica)         
	oCritica:bLDblClick := { || aCritica[oCritica:nAt,3] := IF(aCritica[oCritica:nAt,3],.F.,.T.) }

	If !lAutomato
		ACTIVATE MSDIALOG oDlg2 ON INIT EnChoiceBar(oDlg2,bOK,bCancel,.F.,{})
	Else
		nOpca := K_OK
	EndIf
	If nOpca == K_OK

		cDado := ""
		For nInd := 1 To Len(aCritica)
			If aCritica[nInd,3]
				cDado += aCritica[nInd,1]+","
			Endif 
		Next
		cDado := Substr(cDado,1,Len(cDado)-1)
	Endif

	cFilSel := cDado

	If oDlg <> Nil
		oBrowse:refresh()
		oDlg:Refresh()
		LJ781Filtra(@oDlg,@oBrowse,cMonStatus,cFilSel,cMeto,dDeDt,dAtDt,cDoc,cSerie,cOrcam,@nValTot,@nQtdTot,cTipo)
	EndIf

Return(cDado)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} VerIntDic
Função para validar o pergunte no dicinario a fim de evitar erros por incompatibilidade
 
@author    Vendas.Varejo
@version   12.1.7
@since     04/01/2017
@return	.T. -> Dicionario OK / .F. -> Dicionario com problemas

/*/
//------------------------------------------------------------------------------------------
Static Function VerIntDic(cPerg)
	Local lRet			:= .T.
	Local nTamGrupo	:= 0

	//Somente na versao 12.1.7
	SX1->(DBSetOrder(1)) //X1_GRUPO + X1_ORDEM
	nTamGrupo := Len(SX1->X1_GRUPO)

	If SX1->(DBSeek( PadR(cPerg,nTamGrupo) + "04" ))
		If AllTrim(SX1->X1_TIPO) == "C"
			lRet := .F.
			LjGrvLog( "Monitor Integração", "PERGUNTE " + cPerg + " SEQUENCIA 04 COM TIPO DE CAMPO INCORRETO (NUMERICO)")
			MsgInfo(STR0074 + cPerg + STR0075 + CHR(10)+CHR(13) +; //"Incompatibilidade no dicionario de dados SX1 pergunte '"##"' sequencia '04'"
			STR0076) //"Favor alterar o tipo de caracter para numerico."
		EndIf
	EndIf

Return lRet
