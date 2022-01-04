#Include 'Totvs.ch'

/*/{Protheus.doc} FA070CA2
Ponto de entrada executado após a gravação dos dados no cancelamento da baixa a receber.
Realiza a alteração do status da fatura para liquidada.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/

User Function FA070CA2()
	
	//Integracao Atua
		IntegAtua()
	//final Integracao Atua

Return

/*/{Protheus.doc} IntegAtua
Ponto de entrada executado após a gravação dos dados no cancelamento da baixa a receber.
Realiza a alteração do status da fatura para liquidada.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/

Static Function IntegAtua()

	Local aArea			:= GetArea()
	Local aAreaUQO		:= UQO->(GetArea())
	Local lExecProg		:= .T.

	If lExecProg
		// Verifica se o título foi gerado por uma fatura
		If !Empty(SE1->E1_XIDFAT)
			// Posiciona na tabela UQO - Cabeçalho de faturas
			DbSelectArea("UQO")
			UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID

			If UQO->(DbSeek(SE1->E1_FILORIG + SE1->E1_XIDFAT)) // UQO->(DbSeek(FWxFilial("UQO") + SE1->E1_XIDFAT))
				// Altera o status da fatura
				RecLock("UQO", .F.)
					UQO->UQO_STATUS := "2"				// Fatura Liquidada
					UQO->UQO_BAIXA  := CToD("  /  /  ")
				UQO->(MsUnlock())
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQO)
	RestArea(aArea)

Return
