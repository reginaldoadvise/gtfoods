#Include "Protheus.ch"

/*/{Protheus.doc} FA330EXC
Ponto de entrada utilizado para cancelamento de faturas a receber ao Excluir ou Estornar a compensação de títulos a Receber.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/
User Function FA330EXC()

	//Integracao Atua
		IntegAtua()
	//Final Integracao atua

Return

/*/{Protheus.doc} IntegAtua
Ponto de entrada utilizado para cancelamento de faturas a receber ao Excluir ou Estornar a compensação de títulos a Receber.
@author Tiago Malta
@since 16/10/2021
@version 12.0.27
@type function
/*/

Static Function IntegAtua()

	Local cStatusUQO	:= ""
	Local lExecProg		:= .T.

	If lExecProg
		DbSelectArea("UQO")
		UQO->(DbSetOrder(2)) //UQO->UQO_FILIAL + UQO->UQO_NUMERO
		If UQO->(DbSeek(SE1->E1_FILORIG + SE1->E1_NUM)) // UQO->(DbSeek(FWXFilial("UQO") + SE1->E1_NUM ))

			If SE1->E1_SALDO == 0
				//Baixado totalmente
				cStatusUQO := "4"
			ElseIf  SE1->E1_VALOR != SE1->E1_SALDO
				//Baixado parcialmente
				cStatusUQO := "3"
			Else
				//Em aberto
				cStatusUQO := "2"
			EndIf

			UQO->(Reclock("UQO", .F.))
				UQO->UQO_STATUS := cStatusUQO
			UQO->(MsUnlock())
		EndIf
	EndIf

Return
