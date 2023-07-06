#Include 'Protheus.ch'
/*/{PROTHEUS.DOC} FINA910F
FUNÇÃO FINA910F - Ponto de entrada na rotina conciliação TEF
@OWNER FIN
@Autor Elvis Siqueira
@VERSION PROTHEUS 12
@SINCE 05/07/2023
@Separação do digito verificar da conta corrente
/*/

User function FINA910F()
Local aArea    := GetArea()
Local aRet     := {}
Local cBanco   := PADR(Alltrim(Paramixb[1]),TamSX3("E1_PORTADO")[1])  // Numero do banco que sera gravado na SE1->E1_PORTADO
Local cAgencia := PADR(Alltrim(Paramixb[2]),TamSX3("E1_AGEDEP")[1])   // Numero da agencia que sera gravada no campo SE1->E1_AGENCIAA
Local cConta   := PADR(Alltrim(Paramixb[3]),TamSX3("E1_CONTA")[1])    // Numero da conta corrente que sera gravada no campo SE1->E1_CONTA
Local nTamCC   := Len(cConta)
Local cContaDG := PADR(Substr(cConta, 1, nTamCC-1),TamSX3("E1_CONTA")[1])

DBSelectArea("SA6")
SA6->(DBSetOrder(1))
Do Case 
    Case SA6->(MsSeek(FWxFilial("SA6")+cBanco+cAgencia+cConta))
        aAdd(aRet,cBanco   ) 
        aAdd(aRet,cAgencia ) 
        aAdd(aRet,cConta   ) 
    Case SA6->(MsSeek(FWxFilial("SA6")+cBanco+cAgencia+cContaDG)) 
        aAdd(aRet,cBanco   )
        aAdd(aRet,cAgencia )
        aAdd(aRet,cContaDG )
    OTHERWISE
        aAdd(aRet,cBanco   ) 
        aAdd(aRet,cAgencia ) 
        aAdd(aRet,cConta   )
EndCase

RestArea(aArea)

Return aRet
