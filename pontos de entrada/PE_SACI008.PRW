#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} SACI008
//TODO 	PONTO DE ENTRADA APOS GRAVAR TODOS OS DADOS DA BAIXA A RECEBER.
@author paulo.junior1
@since 18/07/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function SACI008()

	Local aArea := GetArea()
	
	If FindFunction("U_G0112411")
		U_G0112411(SE1->E1_XENVEL,SE1->E1_NUM,SE1->E1_PREFIXO,1) //Grava Envelope na SE5 caso houver na SE1
	Endif	
	
	If FindFunction("U_G0108641")
		U_G0108641(,,SE1->E1_XCTRFRT,SE1->E1_NUM,SE1->E1_PREFIXO,1) //Grava Contrato de Frete na SE5 caso houver na SE1	
	Endif	
	
	//Integracao Atua
		IntegAtua()
	//Final Integracao Atua
	
	RestArea(aArea)
	
Return Nil

/*/{Protheus.doc} IntegAtua
Ponto de entrada executado após a gravação dos dados da baixa a receber.
Realiza a alteração do status da fatura para baixada.
@author Paulo Carvalho
@since 27/03/2019
@version 12.0.17
@type function
/*/

Static Function IntegAtua()

	Local aArea			:= GetArea()
	Local aAreaUQO		:= GetArea()
	Local lExecProg		:= .T.

	If lExecProg
		// Verifica se o título foi gerado por uma fatura
		If !Empty(SE1->E1_XIDFAT) .And. SE1->E1_PREFIXO == "FAT"
			// Posiciona na tabela UQO - Cabeçalho de faturas
			DbSelectArea("UQO")
			UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID

			If UQO->(DbSeek(SE1->E1_FILORIG + SE1->E1_XIDFAT)) // UQO->(DbSeek(FWxFilial("UQO") + SE1->E1_XIDFAT))
				// Altera o status da fatura
				RecLock("UQO", .F.)
					UQO->UQO_STATUS := IIf(SE1->E1_SALDO == 0, "4", "3") // Fatura Baixada
					UQO->UQO_BAIXA  := SE5->E5_DATA
				UQO->(MsUnlock())
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQO)
	RestArea(aArea)

Return
