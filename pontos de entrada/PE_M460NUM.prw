#Include "TOTVS.ch"

/*/{Protheus.doc} M460NUM
O ponto de entrada � executado ap�s a sele��o da s�rie na rotina de documento de sa�da.
Seu objetivo � permitir a troca da s�rie e do n�mero do documento atrav�s de customiza��o local.
O n�mero do documento de sa�da pode ser alterado atrav�s da vari�vel Private cNumero e a s�rie pela vari�vel cSerie.
Observa��es:
1) O ponto de entrada � executado fora da transa��o do programa de prepara��o do documento de sa�da.
2) O ponto de entrada tem um comportamento diferente quando o par�metro MV_TPNRNFS estiver configurado como 3.
Nesta situa��o o valor informado na vari�vel cNumero n�o condiz com o pr�ximo n�mero que ser� gerado e caso o desenvolvedor
queira que o sistema obtenha o pr�ximo n�mero, deve-se atribuir a vari�vel cNumero uma string vazia.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/

User Function M460NUM()

Local cAxPed := ParamIxb[1,1]

	//Integracao Atua
		IntegAtua(cAxPed)
	//final Integracao Atua
	
Return

/*/{Protheus.doc} IntegAtua
O ponto de entrada � executado ap�s a sele��o da s�rie na rotina de documento de sa�da.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/

Static Function IntegAtua(cAxPed)

	Local aArea			:=	GetArea()
	Local aAreaUQD		:=	UQD->(GetArea())
	Local aNota			:=	{}
	Local cTmpAlias	 	:=	GetNextAlias()
	Local cNovaSerie 	:=	""
	Local cNovoNum		:= 	""
	Local lExecProg	 	:=	.T.//lFaturaPed
	Local cQuery		:= ""

	////////////////////////////////////////////////////
	// ParamIxb[n,1] - Pedido da SC9                  //
	// ParamIxb[n,2] - Item do Pedido na SC9		  //
    // ParamIxb[n,3] - Sequ�ncia da libera��o na SC9  //
    ////////////////////////////////////////////////////
	If lExecProg	//Programa exclusivo Brasil
		cQuery := " SELECT DISTINCT SC6.C6_PEDCLI "						+ CRLF
		cQuery += " FROM " + RetSQLName("SC6") + " SC6 "				+ CRLF
		cQuery += " WHERE SC6.C6_FILIAL = '" + XFilial("SC6") + "' "	+ CRLF
		cQuery += "   AND SC6.C6_NUM = '" + cAxPed  + "' "		+ CRLF
		cQuery += "   AND SC6.D_E_L_E_T_ <> '*' "						+ CRLF

		MpSysOpenQuery( cQuery, cTmpAlias )

		While !(cTmpAlias)->(Eof())

			aNota := Separa((cTmpAlias)->C6_PEDCLI, "-" ,.T.)

			If !Empty(aNota)

				cNovoNum := PadR(aNota[1], TamSX3("F2_DOC")[1])//AllTrim( StrTran((cTmpAlias)->C6_PEDCLI, "-", "") )

				If Len(aNota) > 1
					cNovaSerie := PadR(aNota[2], TamSX3("F2_SERIE")[1])
				EndIf

			EndIf

			If !Empty(cNovoNum)
				cNumero := cNovoNum
			EndIf

			If !Empty(cNovaSerie)
				cSerie := cNovaSerie

				If IsIncallStack("U_PRT0544") .And. Type("n544RecUQD") != "U"
					DbSelectArea("UQD")
					UQD->(DbSetOrder(3)) //UQD_FILIAL + UQD_NUMERO
					UQD->(DbGoTo(n544RecUQD))//UQD->(DbSeek(xFilial("UQD") + (cTmpAlias)->C6_PEDCLI ))
					If UQD->(Recno()) == n544RecUQD
						UQD->(RecLock("UQD", .F.))
							UQD->UQD_SERIE := cSerie
						UQD->(MsUnlock())
					EndIf
				EndIf
			EndIf

			(cTmpAlias)->(DbSkip())
		EndDo

		(cTmpAlias)->(DbCloseArea())
	EndIf

	RestArea(aAreaUQD)
	RestArea(aArea)

Return Nil
