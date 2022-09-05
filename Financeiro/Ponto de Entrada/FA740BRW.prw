#Include 'Protheus.ch'

User Function FA740BRW()

Local aBotao := {}

//aAdd( aBotao, { "Boleto Bradesco" , "U_BOL237()" , 0 , 9}) //"boleto"
//aAdd( aBotao, { "Boleto ITAU " , "U_BOL341()" , 0 , 8}) //"boleto"
//aAdd( aBotao, { "Boleto Santander" , "U_BOL33()" , 0 , 10}) //"boleto"
//aAdd( aBotao, { "Boleto Caixa " , "U_BOL104()" , 0 , 11}) //"boleto"
aAdd( aBotao, { "Boleto " , "U_BOLETO()" , 0 , 9}) //"boleto"

Return (aBotao)
