#include 'protheus.ch' 
#include 'parmtype.ch'

/*/{Protheus.doc} FA040FIN
//TODO PE SERA CHAMADO NO PROGRAMA DE INCLUSAO DE CONTAS A RECEBER, APOS O FIM DO BEGIN TRANSACTION.
@author paulo.junior1
@since 22/07/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function FA040FIN()

	Local aArea := GetArea()

	If IsInCallStack("U_F0600104")
		Return Nil
	Endif
	
	if FindFunction("U_G0112411")
		U_G0112411(SE1->E1_XENVEL,SE1->E1_NUM,SE1->E1_PREFIXO,1) //Grava envelope no Titulo SE5 caso houver SE1.
	Endif
	
	If FindFunction("U_G0108650")//Gravação de Saldo de Contrato de Frete, após inclusão do titulo.
		U_G0108650()
	EndIf
	
	//Integracao Atua
		u_GRVCTVEL()   //grava conta contabil
	//final Integracao Atua
	
	RestArea(aArea)
Return Nil


/*/{Protheus.doc} GRVCTVEL
O ponto de entrada GRVCTVEL será executado encerramento da rotina de gravação de contas a receber
@author Marcos Santos
@since 04/12/2019
@type function
/*/
User Function GRVCTVEL()

Local aAreaSED	:= SED->(GetArea())
Local cConta    := ""

	If Empty(SE1->E1_CONTA) .Or. AllTrim(SE1->E1_TIPO) = 'RA'

		DbSelectArea('CT5')
		CT5->(DbSetOrder(1))


		If SE1->E1_TIPO = 'RA'
			If DbSeek(xFilial("CT5")+"501001")
				DbSelectArea('SED')
				SED->(DbSetOrder(1))
				SED->(DbSeek(xFilial("SED") +SE1->E1_NATUREZ))

				cConta := &(CT5->CT5_CREDIT)
			endif
		Else
			If DbSeek(xFilial("CT5")+"500001")
				DbSelectArea('SED')
				SED->(DbSetOrder(1))
				SED->(DbSeek(xFilial("SED") +SE1->E1_NATUREZ))

				cConta := &(CT5->CT5_CREDIT)
			endif
		Endif

		If !Empty(cConta)
			Reclock("SE1",.F.)
			SE1->E1_CONTA := cConta
			SE1->(MsUnlock())
		Endif
	Endif

	RestArea(aAreaSED)

Return
