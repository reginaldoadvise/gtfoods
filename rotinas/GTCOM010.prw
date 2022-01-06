#Include "Protheus.ch"
#Include "Topconn.ch"

/*/{Protheus.doc} GTCOM010

Retorna o nome do Comprador no campo C1_NOMCOMP
	 
@author  Cesar Padovani 
@since   11/09/2021
@version 1.0
@type    Funcao
/*/
User Function GTCOM010()

Local cxNmComp := ""
Local cQrySC7  := ""

// Posiciona no Produto
DbSelectArea("SB1")
DbSetOrder(1)
DbGoTop()
DbSeek(xFilial("SB1")+SC1->C1_PRODUTO)

// Verifica o Comprador do Grupo
DbSelectArea("PAO")
DbSetOrder(3)
DbGoTop()
If DbSeek(xFilial("PAO")+SB1->B1_GRUPO)
    cxNmComp := PAO->PAO_NOMCOM 
EndIf 

/*
// Verifica se a SC possui cotacao e retorna o comprador da cotacao
cQrySC8 := "SELECT DISTINCT C8_XCOMPR FROM "+RetSQLName("SC8")+" WHERE D_E_L_E_T_<>'*' AND C8_FILIAL='"+SC1->C1_FILIAL+"' AND C8_NUMSC='"+SC1->C1_NUM+"' AND C8_ITEMSC='"+SC1->C1_ITEM+"' "
cQrySC8 := ChangeQuery(cQrySC8)
If Select("TRBSC8")<>0
    TRBSC8->(DbCloseArea())
EndIf 

TCQUERY cQrySC8 NEW ALIAS "TRBSC8"
DbSelectArea("TRBSC8")
DbGoTop()
If !Empty(TRBSC8->C8_XCOMPR)
    DbSelectArea("SY1")
    DbSetOrder(1)
    DbSeek(xFilial("SY1")+TRBSC8->C8_XCOMPR)

    cxNmComp := SY1->Y1_NOME
EndIf
*/

// Verifica se a SC possui pedido e retorna o comprador do pedido
cQrySC7 := "SELECT DISTINCT C7_USER FROM "+RetSQLName("SC7")+" WHERE D_E_L_E_T_<>'*' AND C7_FILIAL='"+SC1->C1_FILIAL+"' AND C7_NUMSC='"+SC1->C1_NUM+"' AND C7_ITEMSC='"+SC1->C1_ITEM+"' "
cQrySC7:= ChangeQuery(cQrySC7)
If Select("TRBSC7")<>0
    TRBSC7->(DbCloseArea())
EndIf 

TCQUERY cQrySC7 NEW ALIAS "TRBSC7"
DbSelectArea("TRBSC7")
DbGoTop()
If !Empty(TRBSC7->C7_USER)
    DbSelectArea("SY1")
    DbSetOrder(1)
    DbSeek(xFilial("SY1")+TRBSC7->C7_USER)

    cxNmComp := SY1->Y1_NOME
EndIf

Return cxNmComp
