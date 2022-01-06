#Include "Protheus.ch"
#Include "Topconn.ch"

/*/{Protheus.doc} GTCOM016

Retorna os Pedidos de Compra no campo C1_XPEDS no Browse
	 
@author  Cesar Padovani 
@since   11/09/2021
@version 1.0
@type    Funcao
/*/
User Function GTCOM016()

Local cxPeds  := ""
Local cQrySC7 := ""

cQrySC7 := "SELECT DISTINCT C7_NUM FROM "+RetSQLName("SC7")+" WHERE D_E_L_E_T_<>'*' AND C7_FILIAL='"+SC1->C1_FILIAL+"' AND C7_NUMSC='"+SC1->C1_NUM+"' AND C7_ITEMSC='"+SC1->C1_ITEM+"' ORDER BY C7_NUM "
cQrySC7 := ChangeQuery(cQrySC7)

If Select("TRBSC7")<>0
    TRBSC7->(DbCloseArea())
EndIf 

TCQUERY cQrySC7 NEW ALIAS "TRBSC7"
DbSelectArea("TRBSC7")
DbGoTop()
If TRBSC7->(!Eof())
    Do While !Eof()
        If !Empty(cxPeds)
            cxPeds += "/"
        EndIf 
        cxPeds += Alltrim(TRBSC7->C7_NUM)

        DbSelectArea("TRBSC7")
        DbSkip()
    EndDo
EndIf 

Return cxPeds
