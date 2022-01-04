#Include "TOTVS.ch"
#Include "PRT0553.ch"

Static lVeloce		:=	SuperGetMV('PLG_WFVELO',,.F.)
Static NomePrt		:=	"PRT0553"
Static VersaoJedi	:= 	"V1.16"

/*/{Protheus.doc} PRT0553
Fonte de centralização dos pontos de entrada.
@author Juliano Fernandes
@since 15/04/2019
@type function
/*/
User Function PRT0553()

	Local aArea		:= GetArea()

	Local cFuncPE	:= ""

	Local uReturn	:= Nil

	cFuncPE := Upper( ProcName(1) )			// Recebe o nome do ponto de entrada
	cFuncPE := StrTran( cFuncPE, "U_", "" )	// Remove o "U_"
	cFuncPE := "f" + cFuncPE + "()"			// Ajusta para o nome da Static Function correspondente

	// -----------------------------------------------------------------
	// Realiza a chamada da função correspondente ao ponto de entrada,
	// recebe o retorno esperado e repassa para o ponto de entrada
	// -----------------------------------------------------------------
	If !(Empty( cFuncPE ))
		uReturn := &( cFuncPE )
	EndIf

	RestArea(aArea)

Return(uReturn)

/*/{Protheus.doc} fMT120GRV
Ponto de entrada utilizado para Continuar ou não a inclusão, alteração ou exclusão.
Localização:
Function A120Pedido - Rotina de Inclusão, Alteração, Exclusão e Consulta dos Pedidos de
Compras e Autorizações de Entrega.
Finalidade:
O ponto de entrada MT120GRV utilizado para continuar ou não a Inclusão, alteração ou
exclusão do Pedido de Compra ou Autorização de Entrega.
@author Douglas Gregorio
@since 11/04/2019
@version 1.0
@return lRet, Continuar ou não a inclusão, alteração ou exclusão
@type function
/*/
Static Function fMT120GRV()

	Local cMsg		:=	""

	Local lAtivo	:= .F.
	//Local lContinua	:= .T.
	Local lRet 		:= .T.

	If !lVeloce
		If !Inclui .And. Altera
			// -------------------------------------------------------------
			// Verifica se o Workflow de Pedidos de Compra está ativado
			// Verifica se processo foi iniciado não permitir alteração
			// -------------------------------------------------------------
			lAtivo := StaticCall(PRT0551, f551WFPC, .F.)

			If lAtivo
				// ----------------------------------------------------------------------------
				// Verificar se pedido está pendente/aprovado
				// ----------------------------------------------------------------------------
				lRet := fValidApr()

			EndIf
		EndIf

		If !lRet
			If StaticCall(PRT0551, fExistProc)
				If SC7->C7_CONAPRO $ "L|R"
					cMsg := PRT553001 + If(Altera, PRT553002, PRT553003) + "."+ CRLF //"Pedido já passou por processo de aprovação e não poderá ser " # "alterado" # "excluído"
					cMsg += PRT553004 //"Alterações não serão salvas."
				Else
					cMsg := PRT553005 + If(Altera, PRT553002, PRT553003) + "."+ CRLF //"Pedido encontra-se em processo de aprovação e não poderá ser " # "alterado" # "excluido"
					cMsg += PRT553004 //"Alterações não serão salvas."
				EndIf
				Aviso( PRT553006 , cMsg, {PRT553007}, 2) //'Workflow de Pedido de Compra' # "OK"
			EndIf
		EndIf
	EndIf
Return lRet

/*/{Protheus.doc} fValidApr
Função para validar se pode realizar a alteração do pedido de compra
@type Function
@author Douglas Gregorio
@since 15/04/19
@return return, return_type, return_description
/*/
Static Function fValidApr()

	Local lRet		:= .T.

	//Verifica se está rejeitado ou pendente
	//Se rejeitado não permite alterar
	//Se aprovado não permite alterar
	If SC7->C7_CONAPRO $ "L|R"
		lRet := .F.
	Else
		//Verificar se está no 1o nivel, e ainda não foi aprovado
		cAliasQry := GetNextAlias()

		BeginSQL Alias cAliasQry
			SELECT 		SCR.CR_STATUS, SCR.R_E_C_N_O_ nRecSCR
			FROM 		%Table:SCR% SCR
			WHERE 		SCR.CR_FILIAL	= %xFilial:SCR%			AND
						SCR.CR_NUM		= %Exp:SC7->C7_NUM% 	AND
						SCR.CR_TIPO		= %Exp:'PC'% 			AND
						//SCR.CR_NIVEL	= %Exp:'01'%			AND
						//SCR.CR_STATUS	= %Exp:'02'% 			AND
						SCR.%NotDel%
			ORDER BY	SCR.CR_NUM, SCR.CR_NIVEL, SCR.R_E_C_N_O_
		EndSQL

		//Ainda permite alteração,
		If !(cAliasQry)->(Eof())
			lRet := .F.
		EndIf
		(cAliasQry)->(DbCloseArea())
	EndIf

Return lRet

/*/{Protheus.doc} fMT094END
Ponto de entrada utilizado para acionar o processo de workflow apos a gravacao da
liberacao de documentos, quando feito fora da rotina de workflow.
O ponto de entrada MT094END trás as seguintes informações: Número do Documento, Tipo do Documento,
Operação que está sendo executada (Aprovação, Transferência e/ou Superior) e filial do documento
com controle de alçadas, para serem usadas conforme necessidade do usuário. O mesmo não possui
retorno e tem por finalidade somente mostrar as informações.
Este Ponto de Entrada é executado antes da conclusão do tipo de operação que está em andamento
(Liberar o Documento, Transferência do Documento, Transferência para Superior)

Lista de opções do parâmetro PARAMIXB[3]:
1-Aprovar, 2-Estornar, 3-Aprovar pelo Superior, 4-Transferir para Superior, 5-Rejeitar, 6-Bloquear
@author Juliano Fernandes
@since 03/04/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fMT094END()
	Local aAreaSC7	:= {}
	Local cTipo     := ""
	Local cAprov	:= ""
	Local cPedido	:= ""

	Local lContinua := .F.

	Local nOpc      := 0

	Local oProcess	:= Nil

	// -----------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// -----------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		// -------------------------------------------------------------------
		// Se a chamada está sendo feita pela função fExAuto094 que está
		// no programa PRT0551, deve ignorar este ponto de entrada.
		// -------------------------------------------------------------------
		If IsInCallStack("fExAuto094")
			lContinua := .F.
		EndIf
	EndIf

	If lContinua
		// -----------------------------
		// PARAMIXB[2]:
		// "PC"
		// "AE"
		// "CP"
		// -----------------------------
		cTipo := PARAMIXB[2] ; cTipo  := AllTrim(cTipo)

		// -----------------------------
		// PARAMIXB[3]:
		// 1-Aprovar
		// 2-Estornar
		// 3-Aprovar pelo Superior
		// 4-Transferir para Superior
		// 5-Rejeitar
		// 6-Bloquear
		// -----------------------------
		nOpc := PARAMIXB[3]

		If cTipo == "PC"

			aAreaSC7 := SC7->(GetArea())

			cPedido := PadR(SCR->CR_NUM, TamSX3("C7_NUM" )[1])

			DbSelectArea("SC7")
			SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
			If SC7->(DbSeek( xFilial("SC7") + cPedido))

				While !SC7->(EoF()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cPedido

					SC7->(Reclock("SC7", .F.))
						If nOpc == 1 .Or. nOpc == 5
							SC7->C7_XENVWF  := 'S'
						ElseIf nOpc == 2
							SC7->C7_XENVWF  := 'N'
						EndIf
					SC7->(MsUnlock())

					SC7->(DbSkip())
				EndDo

			EndIf

			RestArea(aAreaSC7)

			If !Empty(SCR->CR_XIDWF)

				// ---------------------------------------------
				// Instancia o processo criado anteriormente
				// ---------------------------------------------
				oProcess := TWFProcess():New("APR_PC", PRT553008, SCR->CR_XIDWF) //"Criacao do Processo - Aprovacao de Pedidos"

				If nOpc == 1 // Aprovado
					cAprov := "S"
				ElseIf nOpc == 5 // Rejeitado
					cAprov := "N"
				EndIf

				If !Empty(cAprov)
					oProcess:oHtml:ValByName('Aprovacao', cAprov)
					oProcess:oHtml:ValByName('cObsApr'  , AllTrim(SCR->CR_OBS))

					U_f551Ret(oProcess)
				EndIf
			EndIf
		EndIf
	EndIf

Return (Nil)

/*/{Protheus.doc} fA120PSCR
Inclui Campos na Tabela SCR.
LOCALIZAÇÃO:
Function A120POSIC - Função responsável pela consulta das aprovações de documentos contida na tabela SCR.
EM QUE PONTO:
No inicio da função A120POSIC tem o objetivo de incluir campos da tabela SCR na MsGetDados da conulta de
aprovações, deve ser retornado os campos da tabela SCR em uma string separados por uma / .
@author Juliano Fernandes
@since 09/04/2019
@version 1.0
@return cNewFields, Campos da tabela SCR a adicionar na tela de consulta das aprovações de documentos
@type function
/*/
Static Function fA120PSCR()

	Local cNewFields	:= ""

	Local lContinua 	:= .F.

	// -------------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// e adiciona o botão para a chamada da função
	// -------------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		cNewFields := "CR_XIDWF/CR_XERROWF"
	EndIf

Return(cNewFields)

/*/{Protheus.doc} fMT120BRW
Ponto de entrada utilizado para adicionar botoes na aRotina do Pedido de compra.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fMT120BRW()

	Local lContinua := .F.

	// -------------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// e adiciona o botão para a chamada da função
	// -------------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		Aadd(aRotina,{PRT553009, "U_PRT0551(.F.)", 0, 4, 0, Nil}) //"Workflow"
		Aadd(aRotina,{PRT553023, "U_PRT0551(.T.)", 0, 5, 0, Nil}) //"Reenvio de Workflow"
	EndIf

Return(Nil)

/*/{Protheus.doc} fMT120GOK
Ponto de entrada utilizado para acionar o processo de workflow após a gravação do pedido de compra.
LOCALIZAÇÃO:
Function A120PEDIDO - Função do Pedido de Compras e Autorização de Entrega responsavel pela inclusão,
alteração, exclusão e cópia dos PCs.
EM QUE PONTO:
Após a execução da função de gravação A120GRAVA e antes da contabilização do Pedido de compras / AE.
Pode ser utilizado para qualquer tratamento que o usuario necessite realizar no PC antes da contabilização do mesmo.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fMT120GOK()

	Local aAreaSA5		:= {}
	Local aAreaSC7		:= {}

	//Local cWFPCAuto		:= ""
	Local cNumPC		:= PARAMIXB[1]
	Local cNumPed		:= "" //Usado no Seek para gravar o grupo de aprovação
	Local cStatusPed	:= ""

	Local lInclui		:= PARAMIXB[2]
	Local lAltera		:= PARAMIXB[3]
	Local lExclui		:= PARAMIXB[4]
	Local lContinua		:= .T.

	// -----------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// -----------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		If (lInclui .Or. lAltera) .And. !lExclui

			If lVeloce
				aAreaSC7 := SC7->(GetArea())
				aAreaSA5 := SA5->(GetArea())

				DbSelectArea("SC7")
				SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
				If SC7->(DbSeek( xFilial("SC7") + SC7->C7_NUM))

					cNumPed := SC7->C7_NUM

					cStatusPed := StaticCall(PRT0551, fGetStPed, SC7->C7_NUM)

					If cStatusPed == "B" // Bloqueado
						While !SC7->(EoF()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cNumPed

							SC7->(Reclock("SC7", .F.))
								SC7->C7_XGRPAPR := cPCGrpApr
								SC7->C7_XENVWF  := 'N'
							SC7->(MsUnlock())

							DbSelectArea("SA5")
							SA5->(DbSetOrder(1)) //A5_FILIAL + A5_FORNECE + A5_LOJA + A5_PRODUTO + A5_FABR + A5_FALOJA
							If SA5->(DbSeek( xFilial("SA5") + SC7->C7_FORNECE + SC7->C7_LOJA + SC7->C7_PRODUTO ))
								SA5->(Reclock("SA5", .F.))
									SA5->A5_CCUSTO := SC7->C7_CC
								SA5->(MsUnlock())
							EndIf

							SC7->(DbSkip())
						EndDo
					EndIf

				EndIf

				RestArea(aAreaSA5)
				RestArea(aAreaSC7)

			Else

				aAreaSC7 := SC7->(GetArea())

				DbSelectArea("SC7")
				SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
				If SC7->(DbSeek( xFilial("SC7") + SC7->C7_NUM))

					cNumPed := SC7->C7_NUM

					cStatusPed := StaticCall(PRT0551, fGetStPed, SC7->C7_NUM)

					If cStatusPed == "B" // Bloqueado
						While !SC7->(EoF()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cNumPed

							SC7->(Reclock("SC7", .F.))
								SC7->C7_XGRPAPR := cPCGrpApr
								SC7->C7_XENVWF  := 'N'
							SC7->(MsUnlock())
							
							SC7->(DbSkip())
						EndDo
					EndIf

				EndIf

				RestArea(aAreaSC7)

				MsgRun(PRT553010, PRT553011,{|| StaticCall(PRT0551, f551Send, cNumPC)}) //"Montando processo de workflow" # "Aguarde..."
			EndIf
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fMT120ALT
LOCALIZAÇÃO:
Function A120PEDIDO - Função do Pedido de Compras e Autorização de Entrega responsavel pela
inclusão, alteração, exclusão e cópia dos PCs.
EM QUE PONTO:
No inico da Função, antes de executar as operações de inclusão, alteração exclusão e cópia,
deve ser utilizado para validar o registro posicionado do PC e retornar .T. se deve continuar
e executar as operações de inclusão, alteração, exclusão e cópia ou retornar .F. para interromper
o processo.
@author Juliano Fernandes
@since 18/04/2019
@version 1.0
@return lContinua, Indica se deve ou não seguir com a opção selecionada no Pedido de Compra
@type function
/*/
Static Function fMT120ALT()

	Local cTitulo		:= ""
	Local cMensagem		:= ""
	Local cStatusPed	:= ""
	//Local lBloqueado	:= .F.
	Local lContinua 	:= .F.

	Local nOpc			:= PARAMIXB[1]

	// -----------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// -----------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		If nOpc == 4 .Or. nOpc == 5
			If StaticCall(PRT0551, fExistProc)
				cStatusPed := StaticCall(PRT0551, fGetStPed, SC7->C7_NUM)

				cTitulo   := NomePrt + PRT553012 + VersaoJedi //' - Workflow de Pedido de Compra - '

				If cStatusPed == "B"

					lContinua := .F.

					If nOpc == 4
						cMensagem := PRT553013 //"Pedido de Compra em processo de aprovação, não é permitida a alteração do mesmo."
					Else
						//cMensagem := PRT553014 //"Pedido de Compra em processo de aprovação, não é permitida a exclusão do mesmo."
					EndIf
				ElseIf cStatusPed == "R"
					If !lVeloce

						lContinua := .F.

						If nOpc == 4
							cMensagem := PRT553015 //"Pedido de Compra rejeitado pelo grupo de aprovação, não é permitida a alteração do mesmo."
						Else
							//cMensagem := PRT553016 //"Pedido de Compra rejeitado pelo grupo de aprovação, não é permitida a exclusão do mesmo."
						EndIf
					EndIf
				ElseIf cStatusPed == "P"

					lContinua := .F.

					If nOpc == 4
						cMensagem := PRT553017 //"Pedido de Compra já liberado pelo grupo de aprovação, não é permitida a alteração do mesmo."
					Else
						//cMensagem := PRT553018 //"Pedido de Compra já liberado pelo grupo de aprovação, não é permitida a exclusão do mesmo."
					EndIf
				Else
					lContinua := .F.

					cMensagem := PRT553019 + CRLF //'Workflow de Pedido de Compra já enviado para este pedido.'
					cMensagem += PRT553020 //"Não será possível continuar."
				EndIf

				If !lContinua .And. !Empty(cMensagem)
					Aviso( cTitulo, cMensagem, {PRT553007}, 2 ) //"OK"
				EndIf

			EndIf
		EndIf
	Else
		lContinua := .T.
	EndIf

Return(lContinua)

/*/{Protheus.doc} fMT097EST
LOCALIZAÇÃO :
Function A097ESTORNA - Função da Dialog que estorna a liberação dos documentos com alçada.
EM QUE PONTO :
O ponto se encontra no inicio da função A097ESTORNA, não passa parametros e não envia retorno,
usado conforme necessidades do usuario para diversos fins.
@author Douglas Gregorio
@since 02/05/19
@version 1.0
/*/
Static Function fMT097EST()
	Local aIDWF		:= {}
	Local cAliasQry := ""
	Local nCount	:= 0
	Local oProcKill	:= {}

	cAliasQry := GetNextAlias()

	// --------------------------------------------------------------------------
	// Mata o processo, pois o mesmo foi estornado pelo Protheus
	// --------------------------------------------------------------------------
	BeginSQL Alias cAliasQry
		SELECT		SCR.CR_XIDWF
		FROM 		%Table:SCR% SCR
		WHERE 		SCR.CR_FILIAL	=  %xFilial:SCR%		AND
					SCR.CR_TIPO		=  %Exp:'PC'% 			AND
					SCR.CR_NUM		=  %Exp:SCR->CR_NUM% 	AND
					SCR.%NotDel%
		ORDER BY	SCR.R_E_C_N_O_
	EndSQL

	(cAliasQry)->(DbEval({|| IIf(!Empty(CR_XIDWF), Aadd(aIDWF, CR_XIDWF), Nil)},, {|| !Eof()}))
	(cAliasQry)->(DbCloseArea())

	For nCount := 1 To Len(aIDWF)
		// ---------------------------------------------
		// Instancia o processo criado anteriormente
		// ---------------------------------------------
		oProcKill := TWFProcess():New("APR_PC", , aIDWF[nCount])

		// ---------------------------------------------------------
		// Tratamento da rastreabilidade do workflow
		// ---------------------------------------------------------
		RastreiaWF(oProcKill:fProcessID + '.' + oProcKill:fTaskID, oProcKill:fProcCode, '30002')

		// ---------------------------------------------
		// Finaliza o processo
		// ---------------------------------------------
		oProcKill:Finish()

		// ---------------------------------------------
		// Libera o objeto
		// ---------------------------------------------
		oProcKill:Free()
		oProcKill := Nil
	Next nCount

Return Nil


/*/{Protheus.doc} fMT97EXPOS
LOCALIZAÇÃO :
Está localizado  na função "A097Estorna".Quando: Este ponto de Entrada é executado após a gravação dos dados no estorno da liberação do Pedido.
Finalidade:  Execuções customizadas após a gravação dos dados no estorno da liberação do Pedido.
Programa Fonte
MATA097.PRX
@author Douglas Gregorio
@since 03/05/19
@version 1.0
/*/
Static Function fMT97EXPOS()

	//Local cWFPCAuto	:= ""
	Local cNumPC	:= PadR(SCR->CR_NUM, TamSX3("C7_NUM" )[1])

	Local lInclui	:= .F.
	Local lAltera	:= .T.
	Local lExclui	:= .F.
	Local lContinua	:= .F.

	// -----------------------------------------------------------
	// Verifica se o Workflow de Pedidos de Compra está ativado
	// -----------------------------------------------------------
	lContinua := StaticCall(PRT0551, f551WFPC, .F.)

	If lContinua
		// ----------------------------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
		// Verifica parâmetros, campos, arquivos de template...
		// ----------------------------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
	EndIf

	If lContinua
		If (lInclui .Or. lAltera) .And. !lExclui
			MsgRun(PRT553010, PRT553011,{|| StaticCall(PRT0551, f551Send, cNumPC)}) //'Montando processo de workflow' # 'Aguarde...'
		EndIf
	EndIf

Return Nil

/*/{Protheus.doc} MT120TEL
LOCALIZAÇÃO: Function A120PEDIDO - Função do Pedido de Compras responsável pela inclusão, alteração, exclusão e cópia dos PCs.
EM QUE PONTO: Se encontra dentro da rotina que monta a dialog do pedido de compras antes  da montagem dos folders e da chamada da getdados.
@type function
@author Icaro Laudade
@since 28/06/2019
/*/
Static Function fMT120TEL()
	Local aAreaSC7		:=	{}
	//Local aDadosCpos	:=	{}
	Local aPosGet    	:=	{}
	Local bValid		:=	{|| }
	//Local cStatusPed	:=	""
	Local cFunName		:=	FunName()
	Local lContinua		:=	.T.
	Local lReadOnly		:=	.F.
	Local nLinSay4		:=	0//aPosGet[1][1] + 40
	Local nLinGet4		:=	0//aPosGet[1][1] + 39
	Local oNewDialog	:=	Nil
	Local oSayGrpApr	:=	Nil
	Local oGetGrpApr	:=	Nil

	//O If lVeloce foi comentado por Icaro dia 23/11/2020
	//If lVeloce
		// -----------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra está ativado
		// -----------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551WFPC, .F.)

		If lContinua
			// ----------------------------------------------------------------------------
			// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
			// Verifica parâmetros, campos, arquivos de template...
			// ----------------------------------------------------------------------------
			lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
		EndIf

		If lContinua
			_SetNamedPrvt("cPCGrpApr", Space(TamSX3("C7_XGRPAPR")[1]), cFunName)

			bValid		:=	{|| fVldGrpApr() }

			oNewDialog 	:= PARAMIXB[1]
			aPosGet		:= PARAMIXB[2]

			nLinSay4	:= aPosGet[1][1] + 28
			nLinGet4	:= aPosGet[1][1] + 27

			Aadd(aPosGet[3], aPosGet[2,5] + 127) // Posição coluna Say Grupo de Aprovadores
			Aadd(aPosGet[3], aPosGet[2,5] + 168) // Posição coluna Get Grupo de Aprovadores

			If (!INCLUI .And. !IsInCallStack("A120Copia")) .Or. cFunName == "MATA101N"
				aAreaSC7 := SC7->(GetArea())

				DbSelectArea("SC7")
				SC7->(DbSetOrder(1)) //C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN
				If SC7->(DbSeek(xFilial("SC7") + SC7->C7_NUM))
					cPCGrpApr := SC7->C7_XGRPAPR

				EndIf

				RestArea(aAreaSC7)

				lReadOnly := .T.
			EndIf

			oSayGrpApr	:= TSay():New(nLinSay4,aPosGet[3,6],{|| RetTitle("C7_XGRPAPR")},oNewDialog,,,,,,.T.,,,035,007)
			oGetGrpApr 	:= TGet():New(nLinGet4,aPosGet[3,7],{|u| IIf(Pcount() > 0, cPCGrpApr := u, cPCGrpApr)},oNewDialog,050,008,PesqPict("SC7","C7_XGRPAPR"),bValid,,,,,,.T.,,,,,,,/*lReadOnly*/,,"SAL",,,,,.T.)

			If lReadOnly
				oGetGrpApr:Disable()
			EndIf
/*
			// ------------------------------------------------------------------------------------------------------------
			// Comentado em 29/01/2020 por Juliano Fernandes
			// Após reunião com a Veloce em 28/01/2020 ficou definido que após a reprovação de um Pedido de Compra
			// via Workflow, o mesmo deve passar novamente (por toda a fila) pelo processo de aprovação.
			//
			// A regra anterior era que apenas passaria pelo processo de aprovação se fosse feita alteração de quantidade,
			// preço ou ter inserido nova linha no pedido de compra.
			// ------------------------------------------------------------------------------------------------------------
			If ALTERA
				cStatusPed := StaticCall(PRT0551, fGetStPed, SC7->C7_NUM)

				// ---------------------------------------------------------------------
				// Armazena dados do Pedido de Compra antes de sua alteração
				// que serão utilizados no ponto de entrada MT120APV
				// ---------------------------------------------------------------------
				_SetNamedPrvt("aMT120APV", Array(2), cFunName)

				aMT120APV[1] := cStatusPed		// Status do Pedido de Compra
				aMT120APV[2] := AClone(aCols)	// ACols com as alterações efetuadas pelo usuário
			EndIf */
		EndIf
	//EndIf

Return

/*/{Protheus.doc} fVldGrpApr
Valida se o codigo do grupo de aprovador existe ou não
@author Icaro Laudade
@since 01/07/2019
@return lRet, Indica se o grupo de aprovadores existe ou não
@type function
/*/
Static Function fVldGrpApr()
	Local aAreaSAL	:=	SAL->(GetArea())
	Local lRet		:=	.T.

	If !Empty(cPCGrpApr)
		DbSelectArea("SAL")
		SAL->(DbSetOrder(1)) // AL_FILIAL + AL_COD + AL_ITEM
		If !(SAL->(DbSeek(xFilial("SAL") + cPCGrpApr )))
			lRet := .F.
		EndIf
	Else
		lRet := .F.
	EndIf
	RestArea(aAreaSAL)

Return lRet

/*/{Protheus.doc} fMT120APV
Descrição:
O ponto de Entrada: MT120APV é responsável pela gravação do Pedido de Compras e Autorização de Entrega.

LOCALIZAÇÃO:
É executado em 2 pontos distintos sendo:

1a) No Pedido de Compras, na função: A120GRAVA
       Neste ponto, nenhum parâmetro é passado para o Ponto de Entrada.

2a) Na Análise da Cotação, na função: MaAvalCOT
      Neste ponto, serão passados os parâmetros:

      ParamIXB[1]
      1a Posição: Fornecedor Vencedor
      2a Posição: Loja Fornecedor Vencedor
      3a Posição: Código da Condição de Pagamento
      4a Posição: Filial de Entrega

      ParamIXB[2] = Acols com campos e conteúdo da SC8


EM QUE PONTO: Após a gravação dos itens do pedido de compras, dentro da condição que gera o Bloqueio do PC na tabela SCR e pode ser utilizado para:

1. Manipular o grupo de aprovação que será gravado na tabela SCR conforme as necessidades do usuário (vide exemplo 1).
2. e/ou Manipular o saldo do pedido, conforme as necessidades do usuário, na alteração do pedido.
    Atenção: neste caso, deve-se restringir a execução da rotina através da variável 'ALTERA' (vide exemplo 2).
Eventos
***** Atenção: ao executar o Ponto de Entrada, o mesmo enviará ou não parâmetros de acordo com o local onde a chamada foi originada *****
@author Icaro Laudade
@since 02/07/2019
@version 1.0
@return cGrupo, Grupo de aprovação
@type function
/*/
Static Function fMT120APV()

//	Local aColsAnt		:= {}

	Local cGrupoApr		:= Nil	// Se o retorno não for caracter o grupo não será alterado
//	Local cStatusPed	:= ""
//	Local cItem			:= ""
//	Local cProduto		:= ""

	Local lContinua 	:= .T.
//	Local lAltPedCom	:= .F.

//	Local nI			:= 0
//	Local nJ			:= 0
//	Local nPsC7Item		:= 0
//	Local nPsC7Prod		:= 0
//	Local nPsC7Qtde		:= 0
//	Local nPsC7Preco	:= 0
//	Local nPsC7Delet	:= 0
//	Local nPos			:= 0
//	Local nQuantidade	:= 0
//	Local nPrecoUnit	:= 0

	// Para atualizar o saldo usar a variavel n120TotLib nesse ponto de entrada
	//O If lVeloce foi Comentado por ICARO dia 23/11/2020
	//If lVeloce

		// -----------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra está ativado
		// -----------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551WFPC, .F.)

		If lContinua
			// ----------------------------------------------------------------------------
			// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
			// Verifica parâmetros, campos, arquivos de template...
			// ----------------------------------------------------------------------------
			lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
		EndIf

		If lContinua

			If IsInCallStack("MATA161") //Analisa Cotação - Para o caso de ser uma Cotação

				cGrupoApr := SC7->C7_XGRPAPR
			ElseIf IsInCallStack("MATA120") //Se for chamado do pedido de compras e o Workflow estiver funcionando corretamente

				cGrupoApr := cPCGrpApr

/*				// ------------------------------------------------------------------------------------------------------------
				// Comentado em 29/01/2020 por Juliano Fernandes
				// Após reunião com a Veloce em 28/01/2020 ficou definido que após a reprovação de um Pedido de Compra
				// via Workflow, o mesmo deve passar novamente (por toda a fila) pelo processo de aprovação.
				//
				// A regra anterior era que apenas passaria pelo processo de aprovação se fosse feita alteração de quantidade,
				// preço ou ter inserido nova linha no pedido de compra.
				// ------------------------------------------------------------------------------------------------------------

				// ---------------------------------------------------------------------------------------------------------------------------------------
				// Na alteração de um pedido reprovado pelo processo de workflow se mudar as informações de quantidade, preço unitário ou incluir
				// uma nova linha de item no pedido então tem que voltar o processo de workflow, caso contrário apenas devemos liberar o pedido de
				// compra, pois a permissão de alteração na tela de pedido de compra será realizada através de permissão no grupo de acesso do usuário.
				// ----------------------------------------------------------------------------------------------------------------------------------------
				If ALTERA
					If Type("aMT120APV") == "A" .And. Len(aMT120APV) == 2
						cStatusPed	:= aMT120APV[1]
						aColsAnt	:= aMT120APV[2]

						If cStatusPed == "R"
							// -------------------------------------------------------------
							// Verifica se alguma quantidade ou preço foi alterado
							// -------------------------------------------------------------
							nPsC7Item	:= GDFieldPos("C7_ITEM"	  ,aHeader)
							nPsC7Prod	:= GDFieldPos("C7_PRODUTO",aHeader)
							nPsC7Qtde	:= GDFieldPos("C7_QUANT"  ,aHeader)
							nPsC7Preco	:= GDFieldPos("C7_PRECO"  ,aHeader)
							nPsC7Delet	:= Len(aHeader) + 1

							For nI := 1 To Len(aColsAnt)
								cItem		:= aColsAnt[nI,nPsC7Item ]
								cProduto	:= aColsAnt[nI,nPsC7Prod ]
								nQuantidade	:= aColsAnt[nI,nPsC7Qtde ]
								nPrecoUnit	:= aColsAnt[nI,nPsC7Preco]

								If (nPos := AScan(aCols, {|x| x[nPsC7Item] == cItem .And. x[nPsC7Prod] == cProduto .And. !x[nPsC7Delet]})) > 0
									If aCols[nPos,nPsC7Qtde] != nQuantidade .Or. aCols[nPos,nPsC7Preco] != nPrecoUnit
										lAltPedCom := .T.
										Exit
									EndIf
								Else
									lAltPedCom := .T.
									Exit
								EndIf
							Next nI

							// -------------------------------------------
							// Verifica se alguma linha foi incluída
							// -------------------------------------------
							If !lAltPedCom
								If Len(aColsAnt) < Len(aCols)
									lAltPedCom := .T.
								EndIf
							EndIf

							// ----------------------------------------------------------------------------
							// Se não houve alterações no pedido conforme as regras da Veloce, então
							// limpa a variável de retorno do grupo aprovador para que o pedido de
							// compra seja liberado e não passe pelo processo de aprovação.
							// ----------------------------------------------------------------------------
							If !lAltPedCom
								cGrupoApr := ""

								// ------------------------------------------------------------
								// Ajuste em 13/01/2020 - Atualiza o Status do Pedido
								// de Compra para Pendente (Legenda verde)
								// ------------------------------------------------------------
								SC7->(Reclock("SC7",.F.))
									SC7->C7_CONAPRO := "L"
								SC7->(MsUnlock())
							EndIf
						ElseIf cStatusPed == "P"
							cGrupoApr := ""
						EndIf
					EndIf
				EndIf */
			EndIf

		EndIf
	//EndIf

Return cGrupoApr

/*/{Protheus.doc} fMT160GRPC
Ponto de entrada disponibilizado para gravação de valores e campos específicos do Pedido de Compra (SC7).
Executado durante a geração do pedido de compra na análise da cotação.
O ponto é chamado enquanto o arquivo SC7 encontra-se bloqueado.
@author Icaro Laudade
@since 11/07/2019
@return Nil, Nulo
@type function
/*/
Static Function fMT160GRPC()
	Local aAreaSAL	:=	SAL->(GetArea())
	Local cPedido	:=	""
	Local cPedCot	:=	""
	Local lContinua	:=	.T.

	If lVeloce

		// -----------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra está ativado
		// -----------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551WFPC, .F.)

		If lContinua
			// ----------------------------------------------------------------------------
			// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
			// Verifica parâmetros, campos, arquivos de template...
			// ----------------------------------------------------------------------------
			lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
		EndIf

		If lContinua

			//Deve ser usado o GetMV uma vez que ele busca na SX6 a já fica atualizado com o putMV
			//NÃO deve ser usado o SuperGetMv uma vez que ele busca em uma area de memória e não irá ficar
			//atualizado com o novo valor do PutMV até a finalização de TODO o processo de cotação
			cPedCot := GetMV("PLG_PEDCOT")

			If SC7->C7_NUM == cPedCot
				SC7->C7_XGRPAPR := 	MV_PAR01
				SC7->C7_XENVWF := "N"
			Else
				fAsrPerg("XGRPAPR")

				While .T.

					MsgAlert(PRT553021 + SC7->C7_NUM, PRT553022) //"Digite o grupo de aprovação para o Pedido " # "Atenção"

					If Pergunte( "XGRPAPR", .T. )
						cPedido := SC7->C7_NUM
						PUTMV("PLG_PEDCOT", cPedido)

						SC7->C7_XGRPAPR := 	MV_PAR01
						SC7->C7_XENVWF := "N"
						Exit

					EndIf
				EndDo
			EndIf
		EndIf

	EndIf

	RestArea(aAreaSAL)
Return Nil

/*/{Protheus.doc} fAsrPerg
Responsável pela criação das perguntas
@author Icaro Laudade
@since 28/12/2018
@return Nil, Nulo
@param cPer, characters, Nome da pergunta
@type function
/*/
Static Function fAsrPerg(cPer)
	Local aArea := GetArea()

	//³Limpa o conte£do de pergunta existente³
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1))
	If SX1->(DbSeek(PADR(cPer,10)))
		While Alltrim(SX1->X1_GRUPO) == Alltrim(cPer)
			SX1->(RecLock("SX1",.F.))
				SX1->X1_CNT01 := ""
			SX1->(MsUnlock())
			SX1->(DbSkip())
		EndDo
	EndIf
	SX1->(DbCloseArea())

	u_PRT0557(cPer,"01","Grupo de aprovação?", "¿Grupo de aprobación?", "Approval group?", "MV_PAR01", "C", TAMSX3("AL_COD")[1],0,0,"G","U_VldGrupo()","SAL","","","MV_PAR01","","","","","","","","","","","","",""," "," "," ",{"Grupo de aprovação?"},{"Order From?"},{"¿Grupo de aprobación?"})
	RestArea(aArea)

Return Nil


/*/{Protheus.doc} VldGrupo
Responsável por validar o grupo de aprovação
@author Icaro Laudade
@since 11/07/2019
@return lRet, se o grupo é valido ou não
@type function
/*/
User Function VldGrupo()
	Local lRet := .T.

	If !Empty(MV_PAR01)
		DbSelectArea("SAL")
		SAL->(DbSetOrder(1)) //AL_FILIAL+AL_COD+AL_ITEM
		If !SAL->(DbSeek( xFilial("SAL") + MV_PAR01 ))
			lRet := .F.
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} fMT097GRV
Ponto de entrada antes da gravação dos processos de compras, pois, quando reprovado o pedido de compra
era feita a atualização do limite do aprovador estourando a capacidade do campo
@author Douglas Gregorio
@since 25/07/2019
@return Nil, Nulo
@type function
/*/
Static Function fMT097GRV()
	Local aArea		:= GetArea()
	Local aAreaSAK	:= SAK->(GetArea())
	Local aAreaSAL	:= SAL->(GetArea())
	Local aAreaSCR	:= SCR->(GetArea())
	Local aAreaSCS	:= SCR->(GetArea())
	Local aDocto	:= ParamIxb[1]
	Local cGrupo	:= ""
	Local cDocto	:= aDocto[1]
	Local cTipoDoc	:= aDocto[2]
	//Local nValDcto	:= aDocto[3]
	//Local cDocSF1	:= ParamIxb[4]
	Local cFilSCR	:= IIf(cTipoDoc $ 'IC|CT|IR|RV',CnFilCtr(cDocto),xFilial("SCR"))
	//Local dDataRef	:= ParamIxb[2]
	//Local lEstCred	:= .T.
	Local lRet		:= .T.
	//Local lResiduo	:= ParamIxb[5]
	Local nOper		:= ParamIxb[3]

	If lVeloce
		//Documentos com Alçada
		dbSelectArea("SCR")
		SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
		SCR->(dbGoTop())
		SCR->(MsSeek(cFilSCR+cTipoDoc+cDocto))
		cGrupo := SCR->CR_GRUPO

		If !SCR->(Eof()) .And. cTipoDoc=="PC" .And. nOper == 3 .And. SCR->CR_STATUS == '03'
			While !Eof() .And. SCR->CR_FILIAL+SCR->CR_TIPO+SCR->CR_NUM == cFilSCR+cTipoDoc+PadR(cDocto, TamSX3("CR_NUM " )[1])

				//Aprovadores
				dbSelectArea("SAK")
				SAK->(dbSetOrder(1))//AK_FILIAL+AK_COD
				SAK->(MsSeek(xFilial("SAK")+SCR->CR_LIBAPRO)) // CR_LIBAPRO - Cod. Aprov

				//Grupos de Aprovacao
				dbSelectArea("SAL")
				SAL->(dbSetOrder(3)) //AL_FILIAL+AL_COD+AL_APROV
				SAL->(dbSeek(xFilial("SAL") + cGrupo + SAK->AK_COD))
				If SAL->AL_LIBAPR == "A"

					//Saldos dos Aprovadores
					dbSelectArea("SCS")
					SCS->(dbSetOrder(2)) // CS_FILIAL+CS_APROV+DTOS(CS_DATA)
					If SCS->(MsSeek(xFilial("SCS")+SAK->AK_COD+DTOS(MaAlcDtRef(SCR->CR_LIBAPRO,SCR->CR_DATALIB,SCR->CR_TIPOLIM))))
						If (SCS->CS_SALDO + SCR->CR_VALLIB) >= SAK->AK_LIMITE
							RecLock("SCS",.F.)
								SCS->CS_SALDO := SCS->CS_SALDO - SCR->CR_VALLIB
							MsUnlock()
						EndIf
					EndIf
				EndIf
				SCR->(dbSkip())
			EndDo
		EndIf
	EndIf

	RestArea(aAreaSCS)
	RestArea(aAreaSCR)
	RestArea(aAreaSAL)
	RestArea(aAreaSAK)
	RestArea(aArea)
Return lRet


/*/{Protheus.doc} fMTA120E
LOCALIZAÇÃO : Function A120PEDIDO - Função do Pedido de Compras e Autorização de Entrega responsável pela inclusão, alteração, exclusão e cópia dos PCs.

EM QUE PONTO : Após a montagem da dialog do pedido de compras. É acionado quando o usuário clicar nos botões OK (Ctrl O) ou CANCELAR (Ctrl X) na exclusão de um PC ou AE.
Deve ser utilizado para validar se o PC ou AE será excluído ('retorno .T.') ou não ('retorno .F.') , após a confirmação do sistema.
@author Icaro Laudade
@since 02/08/2019
@return lExclui, Indica se o pedido pode ser excluido ou não
@type function
/*/
Static Function fMTA120E()
	Local nBtnPress := PARAMIXB[1]
	Local lExclui	:=	.T.

	If nBtnPress == 1
		If StaticCall(PRT0551, fExistProc)
			cStatusPed := StaticCall(PRT0551, fGetStPed, SC7->C7_NUM)

			cTitulo   := NomePrt + PRT553012 + VersaoJedi //' - Workflow de Pedido de Compra - '

			If cStatusPed == "B"

				lExclui := .F.
				cMensagem := PRT553014 //"Pedido de Compra em processo de aprovação, não é permitida a exclusão do mesmo."

			ElseIf cStatusPed == "R"

				If !lVeloce
					lExclui := .F.
					cMensagem := PRT553016 //"Pedido de Compra rejeitado pelo grupo de aprovação, não é permitida a exclusão do mesmo."
				EndIf

			ElseIf cStatusPed == "P"
				lExclui := .F.
				cMensagem := PRT553018 //"Pedido de Compra já liberado pelo grupo de aprovação, não é permitida a exclusão do mesmo."

			Else
				lExclui := .F.
				cMensagem := PRT553019 + CRLF //'Workflow de Pedido de Compra já enviado para este pedido.'
				cMensagem += PRT553020 //"Não será possível continuar."
			EndIf

			If !lExclui
				Aviso( cTitulo, cMensagem, {PRT553007}, 2 ) //"OK"
			EndIf
		EndIf

	EndIf

Return lExclui

/*/{Protheus.doc} fMT120PCOK
Ponto de entrada que valida a inclusão do pedido de compra (MATA120) antes da validação do módulo SIGAPCO (Validação de bloqueio).
@author Juliano Fernandes
@since 14/08/2019
@version 1.0
@return lOk, Variável que indica se a validação está correta (.T.) ou não (.F.).
@type function
/*/
Static Function fMT120PCOK()

	Local lOk 			:= .T.
	Local lArgentina	:= .F.
	Local lContinua		:= .T.

	If lVeloce
		// -----------------------------------------------------------
		// Verifica se o Workflow de Pedidos de Compra está ativado
		// -----------------------------------------------------------
		lContinua := StaticCall(PRT0551, f551WFPC, .F.)

		If lContinua
			// ----------------------------------------------------------------------------
			// Verifica se o Workflow de Pedidos de Compra estão configurado corretamente
			// Verifica parâmetros, campos, arquivos de template...
			// ----------------------------------------------------------------------------
			lContinua := StaticCall(PRT0551, f551VldWFPC, .T.)
		EndIf

		If lContinua
			lArgentina := IIf(SM0->M0_CODIGO == "02", .T., .F.)

			If lArgentina .And. Empty(cPCGrpApr)
				lOk := .F.
				MsgAlert(PRT553021 + cA120Num, PRT553022) //"Digite o grupo de aprovação para o Pedido " # "Atenção"
			EndIf
		EndIf
	EndIf

Return(lOk)
