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
Local aPergs     := {}
Local cFiltro    := ""
Local cNumerario := Space(TAMSX3("E5_MOEDA")[1])
Local cNatureza  := Space(TAMSX3("E5_NATUREZ")[1])
Local cRecPag    := Space(TAMSX3("E5_RECPAG")[1])
Local cClient    := Space(TAMSX3("E5_CLIFOR")[1])
Local cLojCli    := Space(TAMSX3("E5_LOJA")[1])
Local cFornec    := Space(TAMSX3("E5_CLIFOR")[1])
Local cLojFor    := Space(TAMSX3("E5_LOJA")[1])

    //Adiciona os parametros para a pergunta
	aAdd(aPergs, {1, "Numerario", cNumerario, "", ".T.", "06" , ".T." , 80, .F.})
	aAdd(aPergs, {1, "Natureza" , cNatureza , "", ".T.", "SED", ".T." , 80, .F.})
	aAdd(aPergs, {2, "Tipo"     , cRecPag   , {"R=Receber","P=Pagar"} , 80, ".T.", .F.})
    aAdd(aPergs, {1, "Cliente"  , cClient   , "", ".T.", "SA1" , ".T.", 80, .F.})
	aAdd(aPergs, {1, "Loja Cli.", cLojCli   , "", ".T.", ""    , ".T.", 80, .F.})
    aAdd(aPergs, {1, "Fornecedor"  , cFornec   , "", ".T.", "SA2" , ".T.", 80, .F.})
	aAdd(aPergs, {1, "Loja Fornec.", cLojFor   , "", ".T.", ""    , ".T.", 80, .F.})

    //Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os parâmetros")
		cNumerario := MV_PAR01
		cNatureza  := MV_PAR02
		cRecPag    := MV_PAR03
		cClient    := MV_PAR04
        cLojCli    := MV_PAR05
        cFornec    := MV_PAR06
        cLojFor    := MV_PAR07
	EndIf

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

        If !Empty(cRecPag) //Receber ou Pagar
            If !Empty(cFiltro)
              cFiltro += " AND E5_RECPAG = '"+cRecPag+"'" 
             Else 
              cFiltro += " E5_RECPAG = '"+cRecPag+"'" 
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
