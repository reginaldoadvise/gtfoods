#Include "Protheus.ch"
#Include "Topconn.ch"

/*/{Protheus.doc} GTCOM012

Atualiza o nome do fornecedor no cabecalho do pedido de compra
	 
@author  Cesar Padovani 
@since   11/09/2021
@version 1.0
@type    Funcao
/*/
User Function GTCOM012()

If Type("cXNomFor")<>"U"
    cXNomFor := Posicione("SA2",1,xFilial("SA2")+ca120forn+ca120loj,"A2_NOME")
EndIf

Return .T.
