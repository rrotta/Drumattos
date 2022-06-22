#Include "TOTVS.CH"

/*/{Protheus.doc} A140IPRD

A140IPRD - Customiza��o da Identifica��o do Produto 
Parametros:
	Nome       | Tipo               | Descri��o
	cCodigo    | Caracter           | C�digo do fornecedor/cliente.
	cLoja      | Array of Record    | C�digo da loja do fornecedor/cliente.
	cPrdXML    | Array of Record    | C�digo do produto contido no arquivo xml.
	oDetItem   | Array of Record    | Objeto contendo a Tag principal: InfNFE
	cAlias     | Array of Record    | C�digo da tabela "SA5" ou "SA7"

@type function
@author TOTVS NORDESTE
@since 06/05/2021

@history 
/*/

User Function A140IPRD() 

Local cFornec  := PARAMIXB[1]
Local cLoja    := PARAMIXB[2]
Local cNewPRD  := PARAMIXB[3]
Local oDetItem := PARAMIXB[4]
Local cEan     := ""
Local cProdFor := ""
Local cDescFor := ""

	cProdFor := oDetItem:_PROD:_CPROD:TEXT
	cDescFor := oDetItem:_PROD:_XPROD:TEXT
	cEan     := oDetItem:_PROD:_CEAN:TEXT
		
		U_MYMATA061(cFornec,cLoja,cProdFor,cDescFor,cEan)
	
	If !Empty(cProd)
		cNewPRD := cProd
	EndIf

Return cNewPRD
