#Include "TOTVS.ch"

/*/{Protheus.doc} M460NUM
O ponto de entrada é executado após a seleção da série na rotina de documento de saída.
Seu objetivo é permitir a troca da série e do número do documento através de customização local.
O número do documento de saída pode ser alterado através da variável Private cNumero e a série pela variável cSerie.
Observações:
1) O ponto de entrada é executado fora da transação do programa de preparação do documento de saída.
2) O ponto de entrada tem um comportamento diferente quando o parâmetro MV_TPNRNFS estiver configurado como 3.
Nesta situação o valor informado na variável cNumero não condiz com o próximo número que será gerado e caso o desenvolvedor
queira que o sistema obtenha o próximo número, deve-se atribuir a variável cNumero uma string vazia.
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
O ponto de entrada é executado após a seleção da série na rotina de documento de saída.
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
    // ParamIxb[n,3] - Sequência da liberação na SC9  //
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
