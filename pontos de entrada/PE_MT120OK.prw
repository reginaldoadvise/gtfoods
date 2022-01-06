#Include "Protheus.ch"

/*/{Protheus.doc} MT120OK

Ponto de entrada na confirmação do pedido de compra
	 
@author  Cesar Padovani 
@since   03/10/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MT120OK()

Local lOk := .T.
Local nY
Local nX

Public _lGrpApr := .F.

DbSelectArea("SC7")
DbSetOrder(1)
DbGoTop()
DbSeek(xFilial("SC7")+ca120num)

If ALTERA .and. Alltrim(SC7->C7_CONAPRO)=="L"
    nPosObs := GDFieldPos("C7_XJUSTIF")

    For nY:=1 To Len(aCols)
        If Empty(aCols[nY][nPosObs])
            lOk := .F.
        EndIf
    Next
EndIf 

If !lOk
    FwAlertWarning("Informe o motivo da alteração no campo Justificativa.","Pedido já aprovado.")
EndIf

// Grava historico das alteracoes
If lOk
    If ALTERA .and. Alltrim(SC7->C7_CONAPRO)=="L"
        _lGrpApr := .T. 
        
        nPosItm := GDFieldPos("C7_ITEM")
        nPosEnt := GDFieldPos("C7_DATPRF")
        nPosObs := GDFieldPos("C7_XJUSTIF")
        nPosAlt := GDFieldPos("C7_XPEDALT")
        nPosPrd := GDFieldPos("C7_PRODUTO")
        nPosQtd := GDFieldPos("C7_QUANT")
        nPosPrc := GDFieldPos("C7_PRECO")

        nContCond := 0
        nContFret := 0
        For nX:=1 To Len(aCols)
            DbSelectArea("SC7")
            DbSetOrder(1)
            DbGoTop()
            DbSeek(xFilial("SC7")+ca120num+aCols[nX][nPosItm])

            lAltCond := Alltrim(cCondicao)<>Alltrim(SC7->C7_COND)
            If nContCond>=1
                lAltCond := .F.
            EndIf 
            lAltFret := Left(cTpFrete,1)<>Alltrim(SC7->C7_TPFRETE)
            If nContFret>=1
                lAltFret := .F.
            EndIf 
            lAltEntr := Alltrim(DTOS(aCols[nX][nPosEnt]))<>Alltrim(DTOS(SC7->C7_DATPRF))

            lAltProd := Alltrim(aCols[nX][nPosPrd])<>Alltrim(SC7->C7_PRODUTO)

            lAltQtd := aCols[nX][nPosQtd]<>SC7->C7_QUANT

            lAltPrc := aCols[nX][nPosPrc]<>SC7->C7_PRECO

            If lAltCond .or. lAltEntr .or. lAltFret .or. lAltProd
                aCols[nX][nPosAlt] := "S"

                cHrAlt := Time()
                DbSelectArea("ZA3")
                RecLock("ZA3",.T.)
                ZA3->ZA3_FILIAL := xFilial("ZA3")
                ZA3->ZA3_DTALT  := dDataBase
                ZA3->ZA3_HRALT  := cHrAlt
                ZA3->ZA3_NUM    := ca120num
                ZA3->ZA3_ITEM   := aCols[nX][nPosItm]
                ZA3->ZA3_OBS    := aCols[nX][nPosObs]
                If lAltCond
                    ZA3->ZA3_CONDDE := SC7->C7_COND 
                    ZA3->ZA3_ADTODE := IIF(Alltrim(Posicione("SE4",1,xFilial("SE4")+SC7->C7_COND,"E4_CTRADT"))=="1","S","N")
                    ZA3->ZA3_CONDAT := cCondicao
                    ZA3->ZA3_ADTOAT := IIF(Alltrim(Posicione("SE4",1,xFilial("SE4")+cCondicao,"E4_CTRADT"))=="1","S","N")
                    If Alltrim(ZA3->ZA3_ADTOAT)=="S"
                        DbSelectArea("FIE")
                        DbSetOrder(1)
                        DbGoTop()
                        If DbSeek(xFilial("FIE")+"P"+ca120num)
                            ZA3->ZA3_PRFADT := FIE->FIE_PREFIX
                            ZA3->ZA3_NUMADT := FIE->FIE_NUM
                            ZA3->ZA3_VALADT := FIE->FIE_VALOR
                        EndIf 
                    EndIf 
                    nContCond++
                EndIf
                If lAltFret
                    ZA3->ZA3_TPFRDE := SC7->C7_TPFRETE
                    ZA3->ZA3_TPFRAT := Left(cTpFrete,1)
                    nContFret++
                EndIf 
                If lAltEntr
                    ZA3->ZA3_ENTRDE := SC7->C7_DATPRF
                    ZA3->ZA3_ENTRAT := aCols[nX][nPosEnt]
                EndIf 
                If lAltProd
                    ZA3->ZA3_PRODDE := SC7->C7_PRODUTO
                    ZA3->ZA3_PRODAT := aCols[nX][nPosPrd]
                EndIf 
                If lAltQtd
                    ZA3->ZA3_QTDEDE := SC7->C7_QUANT
                    ZA3->ZA3_QTDEAT := aCols[nX][nPosQtd]
                EndIf 
                If lAltPrc
                    ZA3->ZA3_PRECDE := SC7->C7_PRECO
                    ZA3->ZA3_PRECAT := aCols[nX][nPosPrc]
                EndIf 
                MsUnLock()
            EndIf 
        Next
    EndIf
EndIf

Return lOk
