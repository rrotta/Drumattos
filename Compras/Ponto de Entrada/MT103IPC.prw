#include "Protheus.ch"
/*************************************************************************************|
|Ponto de Entrada: MT103IPC()                                                         |
|-------------------------------------------------------------------------------------|
|Localiza��o: ao lan�ar um documento de entrada a partir de um pedido de compras ir�  |
| carregar a descri��o do produto                                                     |
|-------------------------------------------------------------------------------------|
|*************************************************************************************/
User Function MT103IPC
   
	Local _nItem := PARAMIXB[1]
	Local _nPosCod := AsCan(aHeader,{|x|Alltrim(x[2])=="D1_COD"})
	Local _nPosDes := AsCan(aHeader,{|x|Alltrim(x[2])=="D1_XDESC"})
   
		If _nPosCod > 0 .And. _nItem > 0
			aCols[_nItem,_nPosDes] := SB1->B1_DESC
		Endif
Return
