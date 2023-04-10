#Include 'Protheus.ch'
/*/
  @param
  @return Não retorna nada
  @author Totvs Nordeste (Elvis Siqueira)
  @owner Totvs S/A
  @version Protheus 10, Protheus 11,Protheus 12
  @since 10/04/2023
  @sample
  			Ponto de Entrada chamado depois da gravação de todos os dados 
        e da impressão do cupom fiscal na Venda Assistida e após o processamento do Job LjGrvBatch
  @obs
  @project
  @menu 
  @history
  10/04/2023 - Desenvolvimento da Rotina.
/*/

User Function LJ7002()
Local nOpcao    := ParamIxB[1]
Local lGrvBatch := IIF(ParamIxB[3]==2,.T.,.F.)

  If nOpcao <> 2 .AND. !(lGrvBatch)
     Return
  Else 
    LogMsg(FunName(), 1, 1, 1, '', '','Inicio do reprocessamento fiscal: '+FWTimeStamp(2,Date(),Time()))
    ReprossFis() //Funcao para reprocessamento Fiscal
    LogMsg(FunName(), 1, 1, 1, '', '','Fim do reprocessamento fiscal: '+FWTimeStamp(2,Date(),Time()))
  EndIf
  
Return

/*/{Protheus.doc} ReprossFis
  Esta função tem a finalidade de executar automaticamente o MATA930, 
  Reprocessamento dos Livros Fiscais.
  @type  Static Function
  @author Totvs Nordeste (Elvis Siqueira)
  @Link - https://centraldeatendimento.totvs.com/hc/pt-br/articles/360051144013-CROSS-Segmentos-TOTVS-Backoffice-Linha-Protheus-FIS-Rotina-Autom%C3%A1tica-MATA930
/*/
Static Function ReprossFis()
Local aParam := Array(11)
  
  aParam[1]  := DToC(SL1->L1_EMISNF) //Data Inicial
  aParam[2]  := DToC(SL1->L1_EMISNF) //Data Final
  aParam[3]  := 2                    //1-Entrada 2-Saída 3-Ambos
  aParam[4]  := SL1->L1_DOC          //Nota Fiscal Incial
  aParam[5]  := SL1->L1_DOC          //Nota Fiscal Final
  aParam[6]  := SL1->L1_SERIE        //Série Incial
  aParam[7]  := SL1->L1_SERIE        //Série Final
  aParam[8]  := SL1->L1_CLIENTE      //Cli/For Inicial
  aParam[9]  := SL1->L1_CLIENTE      //Cli/For Final
  aParam[10] := SL1->L1_LOJA         //Loja Incial
  aParam[11] := SL1->L1_LOJA         //Loja Final

  MATA930(.T.,aParam)

Return 
