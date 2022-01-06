#Include "Protheus.ch"

/*/{Protheus.doc} MT114CAB

Ponto de entrada para adicionar campos no cabecalho do cadastro de grupos de aprovacao.
	 
@author  Cesar Padovani 
@since   03/10/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MT114CAB()

cCabCampos := "AL_COD|AL_DESC|AL_DOCAE|AL_DOCCO|AL_DOCCP|AL_DOCMD|AL_DOCNF|AL_DOCPC|AL_DOCIP|AL_DOCSA|AL_DOCSC|AL_DOCST|AL_DOCCT|AL_DOCGA"
If SAL->(FieldPos("AL_AGRCNNG")) > 0
    cCabCampos += "|AL_AGRCNNG"
Endif

cCabCampos += "|AL_XALTPED|AL_XADIPED"

Return cCabCampos
