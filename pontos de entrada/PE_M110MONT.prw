#Include "Protheus.ch"
#Include "Topconn.ch"

/*/{Protheus.doc} M110MONT

Ponto de entrada para manipular o aCols da Solicitacao de Compras
	 
@author  Cesar Padovani 
@since   02/11/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function M110MONT()

Local cxPeds  := ""
Local cQrySC7 := ""
Local nPosIT  := GDFieldPos("C1_ITEM")
Local nPosPc  := GDFieldPos("C1_XPEDS")
Local nW      := 0

For nW:=1 To Len(aCols)
    cxPeds := ""
    cQrySC7 := "SELECT DISTINCT C7_NUM FROM "+RetSQLName("SC7")+" WHERE D_E_L_E_T_<>'*' AND C7_FILIAL='"+xFilial("SC1")+"' AND C7_NUMSC='"+ca110num+"' AND C7_ITEMSC='"+aCols[nW][nPosIT]+"' ORDER BY C7_NUM "
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
    aCols[nW][nPosPc] := cxPeds
Next 

Return 

