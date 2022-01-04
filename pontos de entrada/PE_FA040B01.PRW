// -------------------------------------------------------------------------------------------
// Projeto: GTFoods
// Fonte  : FA040B01
// ---------+---------------------+-----------------------------------------------------------
// Data     | Autor			  	  | Descrição
// ---------+---------------------+ P.E. Executado após a confirmação da exclusão e antes da
// 05/01/19 | Ricardo Mendes  	  | própria exclusão de contabilização do contas a receber
// ---------+---------------------+-----------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

user function FA040B01()

	Local lRet := .T.

	If IsInCallStack("U_F0600104")
		Return lRet
	Endif
	
	If FindFunction("U_G010865B")
		U_G010865B() //Recalcular contrato de frete na exclusão
	EndIf
	
	//Integracao Atua
		IntegAtua()
	//Final Integracao Atua 
	
return lRet

/*/{Protheus.doc} IntegAtua
O ponto de entrada FA040B01 sera executado apos confirmar a exclusao e antes da gravação dos dados complementares.
Se o retorno for .F., não se prosseguirá a deleção do título.
Realiza a exclusão do título na fatura.
@author Paulo Carvalho
@since 27/03/2019
@version 12.0.17
@type function
/*/

Static Function IntegAtua()

Local aArea			:= GetArea()
Local aAreaUQO		:= UQO->(GetArea())
Local aAreaUQP		:= UQP->(GetArea())
Local aAreaSE1		:= SE1->(GetArea())
Local aTCSetField	:= {}

Local cItem			:= "000"
Local cAliasQry		:= ""
Local cQuery		:= ""

Local lExcluiu		:= .F.
Local lExecProg		:= .T.

Local nOrdem		:= IIf(SE1->E1_TIPO=="NCC" .Or. SE1->E1_TIPO=="NDC", 3, 2)

Local nValorTotal	:= 0
	
	If lExecProg
		// Verifica se o título foi gerado por uma fatura
		If !Empty(SE1->E1_XIDFAT)
			// Posiciona na tabela UQO - Cabeçalho de faturas
			DbSelectArea("UQP")
			UQP->(DbSetOrder(nOrdem))	// UQP_FILIAL + UQP_IDFAT + UQP_TITFAT OU UQP_TITULO

			If UQP->(DbSeek(SE1->E1_FILORIG + SE1->E1_XIDFAT + SE1->E1_NUM)) // UQP->(DbSeek(FWxFilial("UQP") + SE1->E1_XIDFAT + SE1->E1_NUM))
				lExcluiu := .T.

				// Altera o status da fatura
				RecLock("UQP", .F.)
					UQP->(DbDelete())	// Deleta a linha referente ao título excluído
				UQP->(MsUnlock())
			EndIf
		EndIf

		// Se houve a exclusão reordena os itens na tabela e refaz o calculo de valor total.
		If lExcluiu
			UQP->(DbSetOrder(1)) // UQP_FILIAL + UQP_IDFAT + UQP_ITEM + UQP_TPFAT + UQP_PFXFAT + UQP_TITFAT + UQP_PARFAT

			If UQP->(DbSeek(SE1->E1_FILORIG + SE1->E1_XIDFAT)) // UQP->(DbSeek(FWxFilial("UQP") + SE1->E1_XIDFAT))
				While !UQP->(Eof()) .And. UQP->UQP_IDFAT == SE1->E1_XIDFAT
					cItem := Soma1(cItem)
					nValorTotal += UQP->UQP_TOTAL

					RecLock("UQP", .F.)
						UQP->UQP_ITEM := cItem
					UQP->(MsUnlock())

					UQP->(DbSkip())
				EndDo
			EndIf

			// Atualiza o total geral da fatura
			DbSelectArea("UQO")
			UQO->(DbSetOrder(1))    // UQO_FILIAL + UQO_ID

			If UQO->(DbSeek(SE1->E1_FILORIG + SE1->E1_XIDFAT)) // UQO->(DbSeek(FWxFilial("UQO") + SE1->E1_XIDFAT))
				RecLock("UQO", .F.)
					UQO->UQO_TOTAL := nValorTotal
				UQO->(MsUnlock())
			EndIf
		EndIf

		// ---------------------------------------------------------------------------------------
		// Verifica se o titulo que está sendo excluído é de uma Liquidação
		// Caso positivo, limpa o campo de fatura da tabela UQO e deixa com status em aberto
		// ---------------------------------------------------------------------------------------
		DbSelectArea("UQO")
		UQO->(DbSetOrder(2)) // UQO_FILIAL + UQO_NUMERO
		If UQO->(DbSeek(SE1->E1_FILORIG + SE1->E1_NUM)) // UQO->(DbSeek(FWXFilial("UQO") + SE1->E1_NUM))

			UQO->(RecLock("UQO",.F.))
				//UQO->UQO_NUMERO := ""//COMENTADO DIA 13/05/2019 por solicitação Marcos/Veloce
				UQO->UQO_STATUS := "1" // Em aberto
			UQO->(MsUnlock())

			// -------------------------------------------
			// Apaga o número da fatura nos títulos
			// -------------------------------------------
			cAliasQry := GetNextAlias()
			cQuery := " SELECT R_E_C_N_O_ RECNOSE1 " 						+ CRLF
			cQuery += " FROM " + RetSQLName("SE1")							+ CRLF
			cQuery += " WHERE E1_FILIAL = '" + xFilial("SE1") + "' "		+ CRLF
			cQuery += " 	AND E1_CLIENTE = '" + UQO->UQO_CLIENT + "' "	+ CRLF
			cQuery += " 	AND E1_LOJA = '" + UQO->UQO_LOJA + "' "			+ CRLF
			cQuery += " 	AND E1_XIDFAT = '" + UQO->UQO_ID + "' "			+ CRLF
			cQuery += " 	AND D_E_L_E_T_ <> '*' "							+ CRLF

			Aadd( aTCSetField, { "RECNOSE1", "N", 17, 0	} )

			// Cria área de trabalho a partir da query definida
			MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

			If !(cAliasQry)->(EoF())
				DbSelectArea("SE1")

				While !(cAliasQry)->(EoF())
					SE1->(DbGoTo( (cAliasQry)->RECNOSE1 ))

					If SE1->(Recno()) == (cAliasQry)->RECNOSE1
						SE1->(RecLock("SE1", .F.))
							SE1->E1_XFAT518 := ""
						SE1->(MsUnlock())
					EndIf

					(cAliasQry)->(DbSkip())
				EndDo
			EndIf

			(cAliasQry)->(DbCloseArea())

		EndIf

	EndIf

	RestArea(aAreaUQP)
	RestArea(aAreaSE1)
	RestArea(aAreaUQO)
	RestArea(aArea)
	
Return
