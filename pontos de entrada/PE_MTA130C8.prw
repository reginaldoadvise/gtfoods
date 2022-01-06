#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} MTA130C8

Ponto de entrada na gravacao da SC8
	 
@author  Cesar Padovani 
@since   02/11/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MTA130C8() 

// Verifica o codigo do comprador do usuario corrente
DbSelectArea("SY1")
DbSetOrder(3)
DbGoTop()
If DbSeek(xFilial("SY1")+__cUserID )
    RecLock("SC8",.F.)
    SC8->C8_XCOMPR := SY1->Y1_COD
    MsUnLock()
EndIf 

Return
