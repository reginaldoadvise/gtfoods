#Include "Protheus.ch"
  
/*/{Protheus.doc} MT120TEL

Ponto de entrada para adicionar campos no cabecalho do pedido de compra.
	 
@author  Cesar Padovani 
@since   14/11/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MT120TEL()

Local aArea     := GetArea()
Local Dlg_Ped   := PARAMIXB[1] 
Local aPosGet   := PARAMIXB[2]
Local oXNomFor
Public cXNomFor := ""

cXNomFor := Posicione("SA2",1,xFilial("SA2")+ca120forn+ca120loj,"A2_NOME")

@ 062, aPosGet[1,08] - 012 SAY Alltrim(RetTitle("A2_NOME")) OF Dlg_Ped PIXEL SIZE 050,006
@ 061, aPosGet[1,09] + 003 MSGET oXNomFor VAR cXNomFor SIZE 150, 006 OF Dlg_Ped COLORS 0, 16777215 WHEN .F. PIXEL

RestArea(aArea)

Return
