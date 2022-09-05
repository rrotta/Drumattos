#include "Protheus.CH"
//----------------------------------------------------------
/*/{PROTHEUS.DOC} F110QRCP
FUNÇÃO F110QRCP - Ponto de entrada na rotina baixas automatica CR
@OWNER MCP
@Autor ricardo rotta
@VERSION PROTHEUS 12
@SINCE 14/01/22
@Inclusão de novos filtros
/*/
//---------------------------------------------------------------------------------------------------

User Function F110QRCP

/*
WHERE E1_FILIAL  = '01' 
AND E1_VENCREA Between '20220517' AND '20220517' 
AND E1_CLIENTE Between '      ' AND 'ZZZZZZ' 
AND E1_EMISSAO <= '20220517' 
AND E1_SALDO > 0 
AND E1_TIPO NOT IN ('RA ','NCC','AB-','CF-','CS-','FC-','FE-','FU-','I2-','IM-','IN-','IR-','IS-','PI-','FC-','FE-','PR ') 
AND E1_NUMSOL = ' '  
AND D_E_L_E_T_ = ' '  
ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO
*/

Local cQuery := ParamIxb[1]

Return(cQuery)
