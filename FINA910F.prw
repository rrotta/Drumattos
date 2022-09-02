#Include 'Protheus.ch'
/*/{PROTHEUS.DOC} FINA910F
FUNÇÃO FINA910F - Ponto de entrada na rotina conciliação TEF
@OWNER MCP
@Autor ricardo rotta
@VERSION PROTHEUS 12
@SINCE 23/06/22
@Separação do digito verificar da conta corrente
/*/

User function FINA910F()

Local aRet     := {}
Local cBanco   := Alltrim(Paramixb[1])
Local cAgencia := Alltrim(Paramixb[2])
Local cContaDG := Alltrim(Paramixb[3])
Local nTamCC   := Len(cContaDG)
Local cConta   := Substr(cContaDG, 1, nTamCC-1)

aAdd(aRet,PADR(cBanco,TamSX3("E1_PORTADO")[1]))     // Numero do banco que serah gravado na SE1->E1_PORTADO
aAdd(aRet,PADR(cAgencia,TamSX3("E1_AGEDEP")[1]))    // Numero da agencia que serah gravada no campo SE1->E1_AGENCIAA
aAdd(aRet,PADR(cConta,TamSX3("E1_CONTA")[1]))       // Numero da conta corrente

Return aRet
