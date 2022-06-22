#include "Protheus.ch"
 
/*
===============================================================================================================================
Programa----------: F380FIL
===============================================================================================================================
Descrição---------: Ponto de Entrada com o objetivo de complementar os filtro de registros na conciliação bancaria 
===============================================================================================================================
Uso---------------: Filtra no momento da montagem da conciliação bancaria
===============================================================================================================================
Parâmetros--------: Nenhum
===============================================================================================================================
Retorno-----------: cFiltro = instrução do filtro a ser realizado em sintaxe SQL
===============================================================================================================================
*/
User Function F380FIL()
 
Local aArea      := GetArea()
Local cFiltro    := ""

Private cNumerario := Space(TAMSX3("E5_MOEDA")[1])
Private cNatureza  := Space(TAMSX3("E5_NATUREZ")[1])
Private cRecPag    := Space(TAMSX3("E5_RECPAG")[1])
Private cClient    := Space(TAMSX3("E5_CLIFOR")[1])
Private cLojCli    := Space(TAMSX3("E5_LOJA")[1])
Private cFornec    := Space(TAMSX3("E5_CLIFOR")[1])
Private cLojFor    := Space(TAMSX3("E5_LOJA")[1])

xPergunt() 

        If !Empty(cNumerario) //Numerario
            If !Empty(cFiltro)
              cFiltro += " AND E5_MOEDA = '"+cNumerario+"'" 
             Else 
              cFiltro += " E5_MOEDA = '"+cNumerario+"'"   
            EndIf 
        EndIf 
        
        If !Empty(cNatureza) //Natureza
            If !Empty(cFiltro)
              cFiltro += " AND E5_NATUREZ = '"+cNatureza+"'" 
             Else 
              cFiltro += " E5_NATUREZ = '"+cNatureza+"'"   
            EndIf  
        EndIf 

        If !Empty(cRecPag) .And. SUBSTRING(cRecPag,1,1) <> 'A' //Receber ou Pagar
            If !Empty(cFiltro)
              cFiltro += " AND E5_RECPAG = '"+SUBSTRING(cRecPag,1,1)+"'" 
             Else 
              cFiltro += " E5_RECPAG = '"+SUBSTRING(cRecPag,1,1)+"'" 
            EndIf  
        EndIf 

        If !Empty(cClient) .And. !Empty(cLojCli) //Cliente e Loja
            If !Empty(cFiltro)
              cFiltro += " AND E5_CLIFOR = '"+cClient+"' AND E5_LOJA = '"+cLojCli+"'" 
             Else 
              cFiltro += " E5_CLIFOR = '"+cClient+"' AND E5_LOJA = '"+cLojCli+"'"
            EndIf 
        EndIf 

        If !Empty(cFornec) .And. !Empty(cLojFor) //Fornecedor e Loja
            If !Empty(cFiltro)
              cFiltro += " AND E5_CLIFOR = '"+cFornec+"' AND E5_LOJA = '"+cLojFor+"'" 
             Else 
              cFiltro += " E5_CLIFOR = '"+cFornec+"' AND E5_LOJA = '"+cLojFor+"'"
            EndIf 
        EndIf 
    
 RestArea(aArea)
Return cFiltro

/* ============================================== /
  Perguntas para o Filtro
/ =============================================== */
Static Function xPergunt()
 
Local aArea      := GetArea()
Local oDialog    := Nil 
Local aCombo     := {"Ambos","Receber","Pagar"}
//Local aTipo      := {}
//Local cTipo      := aTipo[1]


// Método responsável por criar a janela e montar os paineis.
oDialog := FWDialogModal():New()

// Métodos para configurar o uso da classe.
oDialog:SetBackground( .T. ) 
oDialog:SetTitle( 'Filtro' )
oDialog:SetSize( 180, 150 )
oDialog:EnableFormBar( .T. )
oDialog:SetCloseButton( .F. )
oDialog:SetEscClose( .F. )
oDialog:CreateDialog()
oDialog:CreateFormBar()
oDialog:AddButton('Confirmar' , { || oDialog:DeActivate()}, 'Confirmar' ,,.T.,.F.,.T.,)

// Capturar o objeto do FwDialogModal para alocar outros objetos se necessário.
oPanel := oDialog:GetPanelMain()

	oSay1  := TSay():New(17,5,{|| "Numerario? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 15,40 MSGET cNumerario SIZE 030,009 OF oPanel F3 "06" PIXEL 
	oSay2  := TSay():New(32,5,{|| "Natureza? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 30,40 MSGET cNatureza SIZE 030,009 OF oPanel F3 "06" PIXEL 
  oSay2  := TSay():New(47,5,{|| "Tipo? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
  //@ 45,40 Combobox oCombo Var cRecPag Itens aCombo SIZE 71,10 OF oPanel PIXEL
  @ 45,40 MSCOMBOBOX oCombo VAR cRecPag ITEMS aCombo SIZE 071, 010 OF oPanel COLORS 0, 16777215 PIXEL
  oSay2  := TSay():New(62,5,{|| "Cliente? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 60,40 MSGET cClient SIZE 030,009 OF oPanel F3 "SA1" PIXEL 
  oSay2  := TSay():New(77,5,{|| "Loja Cli.? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 75,40 MSGET cLojCli SIZE 030,009 OF oPanel PIXEL 
  oSay2  := TSay():New(92,5,{|| "Fornecedor? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 90,40 MSGET cFornec SIZE 030,009 OF oPanel F3 "SA2" PIXEL 
  oSay2  := TSay():New(107,5,{|| "Loja For.? "},oPanel,,,,,,.T.,,,50,70,,,,,,.T.)
	@ 105,40 MSGET cLojFor SIZE 030,009 OF oPanel PIXEL 

oDialog:Activate()

RestArea(aArea)

Return
