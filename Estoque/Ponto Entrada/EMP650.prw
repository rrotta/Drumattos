#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �EMP650    � Autor � Ricardo Rotta      � Data �  02/09/14   ���
�������������������������������������������������������������������������͹��
���Descricao � Ponto de Entrada no momento da abertura da OP para gerar   ���
���          � empenho no almoxarifado                                    ���
�������������������������������������������������������������������������͹��
���Uso       �                                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
User Function EMP650()

Local _aArea   := GetArea()
Local _nPosLc  := aScan(aHeader,{|x| AllTrim(x[2])=="D4_LOCAL"})
Local _nPosCd  := aScan(aHeader,{|x| AllTrim(x[2])=="G1_COMP"})
Local _cLocPad := SuperGetMv("MV_XLOCPRD",.F.,"90")
Local _nI := 1
For _nI := 1 To Len(aCols)
	If !IsProdMOD(aCols[_nI,_nPosCd],.T.)
		aCols[_nI][_nPosLc] := _cLocPad
	Endif
Next _nI
Return