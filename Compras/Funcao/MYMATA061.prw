#Include "totvs.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

/*/{Protheus.doc} MATA061

============================
ExecAuto MATA061
============================

@type function
@author TOTVS NORDESTE
@since 06/05/2021

@history 
/*/

User Function MYMATA061(cFornec,cLoja,cProdFor,cDescFor,cEan) 

Local aErro   := {}
Local cQry    := ""
Local nOpc    := 0
Local oModel  := Nil

Public cProd   := ""
Public cDesc   := ""

    cQry := " SELECT " + CRLF
    cQry += "     B1_COD, B1_DESC " + CRLF
    cQry += " FROM " + CRLF
    cQry += "     "+RetSQLName('SB1')+" SB1 " + CRLF
    cQry += "     WHERE " + CRLF
    cQry += "           SB1.B1_FILIAL       = '" + FWxFilial("SB1") + "'" + CRLF
    cQry += "           AND SB1.B1_CODBAR   = '" + cEan + "'" + CRLF
    cQry += "           AND SB1.D_E_L_E_T_ <> '*' " + CRLF
    
    cQry := ChangeQuery(cQry)

            IF Select("TMPSB1") <> 0
              TMPSB1->(DbCloseArea())
            EndIf

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMPSB1",.T.,.T.)

    If !Empty(TMPSB1->B1_COD)
            
     cProd := TMPSB1->B1_COD
     cDesc := TMPSB1->B1_DESC
    
        If !Empty(cProd)
            dbSelectArea("SA5")
            SA5->(dbSetOrder(2))
            If ! SA5->(Dbseek(FWxFilial("SA5") + cProd + cFornec + cLoja ))

                nOpc  := 3

                oModel := FWLoadModel('MATA061')

                oModel:SetOperation(nOpc)
                oModel:Activate()

                //Cabeçalho
                oModel:SetValue('MdFieldSA5','A5_PRODUTO',cProd)
                oModel:SetValue('MdFieldSA5','A5_NOMPROD',cDesc)

                //Grid
                oModel:SetValue('MdGridSA5','A5_FORNECE',cFornec)
                oModel:SetValue('MdGridSA5','A5_LOJA'   ,cLoja)
                oModel:SetValue('MdGridSA5','A5_CODPRF' ,cProdFor)
                oModel:SetValue('MdGridSA5','A5_CODBAR' ,cEan)
                
                If oModel:VldData()
                    oModel:CommitData()
                Else 
                    aErro := MostraErro()
                    VarInfo(aErro)
                Endif

                oModel:DeActivate()
                oModel:Destroy()
            
            ElseIf SA5->(Dbseek(FWxFilial("SA5") + cProd))
                    If ! SA5->(Dbseek(FWxFilial("SA5") + cProd + cFornec + cLoja ))
                    
                    nOpc  := 4 

                        oModel := FWLoadModel('MATA061')

                        oModel:SetOperation(nOpc)
                        oModel:Activate()

                        //Cabeçalho
                        oModel:SetValue('MdFieldSA5','A5_PRODUTO',cProd)
                        oModel:SetValue('MdFieldSA5','A5_NOMPROD',cDesc)

                        //Nova linha na Grid
                        oModel:GetModel("MdGridSA5"):AddLine()
                        
                        oModel:SetValue('MdGridSA5','A5_FORNECE',cFornec)
                        oModel:SetValue('MdGridSA5','A5_LOJA'   ,cLoja)
                        oModel:SetValue('MdGridSA5','A5_CODPRF' ,cProdFor)
                        oModel:SetValue('MdGridSA5','A5_CODBAR' ,cEan)
                        
                        If oModel:VldData()
                            oModel:CommitData()
                        Else 
                            aErro := MostraErro()
                            VarInfo(aErro)
                        Endif

                        oModel:DeActivate()
                        oModel:Destroy()

                    EndIf 
            EndIf 
        EndIf  

    EndIf     

    IF Select("TMPSB1") <> 0
        TMPSB1->(DbCloseArea())
    EndIf

Return cProd
