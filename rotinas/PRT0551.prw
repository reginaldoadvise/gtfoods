#Include "TOTVS.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"
#Include "FWMVCDef.ch"
#Include "PRT0551.ch"

Static NomePrt		:= "PRT0551"
Static VersaoJedi	:= "V1.16"

Static cOperID		:= ""
Static cBarra		:= IIf(GetRemoteType() == 2,"/","\")

Static cWF0551		:= "WF0551.html"
Static cWF0551Link	:= "WF0551Link.html"
Static cWF0551Msg	:= "WF0551Msg.html"
Static cWF0551Rep	:= "WF0551Rep.html"

/*/{Protheus.doc} PRT0551
Função responsável pela montagem e envio do processo de workflow para a aprovação de Pedidos de compra.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@param lReenvio, logico, Indica se é um reenvio de Workflow
@return Nil, Não há retorno
@type function
/*/
User Function PRT0551(lReenvio)

	Local cArq		:= ""

	Local cNumPC	:= SC7->C7_NUM

	//Verificar se já foi enviado, para não criar nova tarefa
	If fExistProc()
		If lReenvio
			MsgRun(PRT551007, PRT551008, {|| f551Reenv(cNumPC)}) //'Montando processo de workflow' # 'Aguarde...'
		Else
			Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551002, {PRT551003}, 2) // ' - Workflow de Pedido de Compra - ' # 'Workflow de Pedido de Compra já enviado para este pedido.' # 'OK'
		EndIf
	Else
		If lReenvio
			Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551145, {PRT551003}, 2) // ' - Workflow de Pedido de Compra - ' # 'Workflow de Pedido de Compra não foi enviado para este pedido.' # 'OK'
		Else
			cArq := fGetDirTem() + cWF0551

			If File(cArq)
				If SC7->C7_CONAPRO $ "L"
					Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551019 + SC7->C7_NUM + PRT551140, {PRT551003}, 2) //"O Pedido de compra No. " # " já foi aprovado."
				Else
					If !Empty(SC7->C7_XGRPAPR)

						If Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551004, {PRT551005, PRT551006}, 2) == 1 //' - Workflow de Pedido de Compra - ' # 'Deseja enviar o processo de workflow para o pedido de compra selecionado?' # Sim # Não
							MsgRun(PRT551007, PRT551008, {|| f551Send(cNumPC)}) //'Montando processo de workflow' # 'Aguarde...'
						EndIf
					Else
						Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551141 + SC7->C7_NUM + ".", {PRT551003}, 2) //"Grupo de aprovação não informado no pedido "
					EndIf
				EndIf
			Else
				Help('', 1, PRT551009,, PRT551010, 1, 0) //'PRT0551' # 'Não foi encontrado o arquivo de template para envio do processo de workflow!'
			EndIf
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} f551Send
Função responsável pela montagem e envio do processo de workflow para a aprovação de Pedidos de compra.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return aUrl, Diretório do arquivo de workflow gerado
@param cNumPC, caracter, Código do Pedido de Compra
@param lSchedule, logico, Indica se o processamento está sendo executado via Schedule (Veloce)
@type function
/*/
Static Function f551Send(cNumPC, lSchedule)

	Local aAreas		:= {}
	Local aAreaSC7		:= {} //Usado ao gravar o campo C7_ENVWF
	Local aDoctos		:= {}
	Local aTimeOut		:= {}
	Local aSchedWF		:= {}
	Local aProdPC		:= {}
	//Local aObs			:= {}

	Local cSimbMoed		:= SuperGetMV('MV_SIMB' + Alltrim(Str(SC7->C7_MOEDA)), .F., 'R$') + ' '
	Local cSimbMoAIB	:= ""
	Local cMailId		:= ""
	Local cUrl			:= ""
	Local cPastaHTM		:= ""
	Local cMailApr		:= ""
	Local cAliasQry		:= ""
	Local cHttpSrv		:= AllTrim(SuperGetMV('PLG_WFPCIP',,''))
	Local cArq			:= ""
	Local cTimeOutAv	:= AllTrim(SuperGetMV('PLG_WFPCTA',,""))
	Local cTimeOutRe	:= AllTrim(SuperGetMV('PLG_WFPCTR',,""))
	Local cObsItem		:= ""
	Local cDirRaiz		:= ""
	Local cEmail		:= ""
	Local cObsApr		:= ""

	Local dEmissao  	:= dDataBase

	Local lVeloce 		:= SuperGetMV('PLG_WFVELO',,.F.)

	Local nValLiq   	:= 0
	Local nValIPI   	:= 0
	Local nValTot   	:= 0
	Local nCount    	:= 0

	Local oProcess  	:= Nil

	Default cNumPC  	:= SC7->C7_NUM
	Default lSchedule	:= .F.

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SA2->(GetArea()))
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SC7->(GetArea()))

	cArq := fGetDirTem()
	cArq += cWF0551

	// -------------------------------------------
	// Valida a existencia do arquivo de template
	// -------------------------------------------
	If !File(cArq)
		If lSchedule
			ConOut(PRT551010) //'Não foi encontrado o arquivo de template para envio do processo de workflow'
		Else
			Help('', 1, PRT551009,, PRT551010, 1, 0) //'PRT0551' # 'Não foi encontrado o arquivo de template para envio do processo de workflow'
		EndIf
	Else
		SC7->(DbSetOrder(1))
		If SC7->(DbSeek(xFilial('SC7') + cNumPC))

			// ----------------------------------------
			// Verifica o controle de alcadas, somente
			// para Pedidos de Compra:
			// ---------------------------------------
			cAliasQry := GetNextAlias()

			BeginSQL Alias cAliasQry
				SELECT 		SCR.R_E_C_N_O_ nRecSCR
				FROM 		%Table:SCR% SCR
				WHERE 		SCR.CR_FILIAL	= %xFilial:SCR%					AND
							SCR.CR_TIPO		= %Exp:'PC'% 					AND
							SCR.CR_NUM		= %Exp:SC7->C7_NUM% 			AND
							SCR.CR_STATUS	= %Exp:'02'% 					AND
							SCR.%NotDel%
				ORDER BY	SCR.R_E_C_N_O_
			EndSQL

			(cAliasQry)->(DbEval({|| AAdd(aDoctos, nRecSCR)},, {|| !Eof()}))
			(cAliasQry)->(DbCloseArea())

			For nCount := 1 To Len(aDoctos)

				SCR->(DbGoTo(aDoctos[nCount]))

				PswOrder(1)
				If PswSeek(SCR->CR_USER) .And. !Empty(PswRet()[1,14])
					cMailApr := AllTrim(PswRet()[1,14])

					// ---------------------------------------------------------
					// Criacao do objeto TWFProcess, responsavel
					// pela inicializacao do processo de Workflow
					// ---------------------------------------------------------
					oProcess := TWFProcess():New('APR_PC')

					// ---------------------------------------------------------
					// Criacao de uma tarefa de workflow. Podem
					// existir varias tarefas. Para cada tarefa,
					// deve-se informar um nome e o HTML envolvido
					// ---------------------------------------------------------
					oProcess:NewTask('PLGWFPC01', cArq)

					// ----------------------------------------------------------------
					// Monta layout HTML conforme o País (variável pública cPaisLoc)
					// ----------------------------------------------------------------
					fLayoutHtml(@oProcess, cWF0551)

					// ---------------------------------------------------------
					// Determinacao da funcao que realiza o processamento
					// do retorno do workflow
					// ---------------------------------------------------------
					oProcess:bReturn := 'U_f551Ret()'

					// --------------------------------------------------------------------------
					// Tratamento do timeout. Este tratamento tem o objetivo
					// de determinar o tempo maximo para processamento do retorno
					// f551TOAv - Envia aviso por falta de resposta
					// f551TORe - Rejeita o Pedido de compra por inatividade
					// --------------------------------------------------------------------------
					// oProcess:bTimeOut := { { <cFuncao>, <nDias>, <nHoras>, <nMinutos> }, { ... } }
					aTimeOut := {}

					If !Empty(cTimeOutAv)
						Aadd( aTimeOut, &("{ 'U_f551TOAv()'," + cTimeOutAv + "}") )
					EndIf

					If !Empty(cTimeOutRe)
						Aadd( aTimeOut, &("{ 'U_f551TORe()'," + cTimeOutRe + "}") )
					EndIf

					oProcess:bTimeOut := aTimeOut

					// ---------------------------------------------------------
					// Realiza o preenchimento do HTML:
					// ---------------------------------------------------------
					SC7->(DbSetOrder(1))
					SC7->(DbSeek(xFilial('SC7') + cNumPC))

					If !lSchedule //Execução através de botão
						aAreaSC7 := SC7->(GetArea())

						While !SC7->(EoF()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cNumPC
							SC7->(Reclock("SC7", .F.))
								SC7->C7_XENVWF := 'S'
							SC7->(MsUnlock())

							SC7->(DbSkip())
						EndDo

						RestArea(aAreaSC7)
					EndIf

					SA2->(DbSetOrder(1))
					SA2->(DbSeek(xFilial('SA2') + SC7->(C7_FORNECE + C7_LOJA)))

					SE4->(DbSetOrder(1))
					SE4->(DbSeek(xFilial('SE4') + SC7->C7_COND))

					dEmissao := SC7->C7_EMISSAO

					//-- CABECALHO DO FORMULARIO
					oProcess:oHtml:ValByName('cNumPed'		, SC7->C7_NUM)
					oProcess:oHtml:ValByName('dEmissao'		, SC7->C7_EMISSAO)
					oProcess:oHtml:ValByName('cCodFor'		, SC7->(C7_FORNECE + '/' + C7_LOJA))
					oProcess:oHtml:ValByName('cNomFor' 		, SA2->A2_NOME)
					oProcess:oHtml:ValByName('cComprador'	, UsrRetName(SC7->C7_USER))
					oProcess:oHtml:ValByName('cCondPagto'	, '(' + AllTrim(SC7->C7_COND) + ') ' + SE4->E4_DESCRI)
					oProcess:oHtml:ValByName('cCodAprov'	, SCR->CR_USER)

					//-- DADOS DO SOLICITANTE
					If !Empty(SC7->C7_NUMSC)
						SC1->(DbSetOrder(1))
						If SC1->(DbSeek(xFilial('SC1')+SC7->C7_NUMSC))
							//Alterado dia 23/07/2019 para buscar pelo nome do solicitante
							cEmail := fRetEmail(SC1->C1_SOLICIT)

							oProcess:oHtml:ValByName('cSolicitante', SC1->C1_SOLICIT )
							If !Empty(cEmail)//PswSeek(SC1->C1_USER) .And. !Empty(PswRet()[1,14])
								oProcess:oHtml:ValByName('cEmailSolic'	, AllTrim(PswRet()[1,14]))
							EndIf
							oProcess:oHtml:ValByName('dDtSolic'	, DToC(SC1->C1_EMISSAO))
						Else
							oProcess:oHtml:ValByName('cSolicitante'	, BSCEncode(PRT551142)) // 'Não Informado'
							oProcess:oHtml:ValByName('cEmailSolic'	, '-')
							oProcess:oHtml:ValByName('dDtSolic'	, '-')
						EndIf
					Else
						oProcess:oHtml:ValByName('cSolicitante'	, BSCEncode(PRT551142)) // 'Não Informado'
						oProcess:oHtml:ValByName('cEmailSolic'	, '-')
						oProcess:oHtml:ValByName('dDtSolic'	, '-')
					EndIf

					//-- ITENS DO FORMULARIO
					nValLiq := 0
					nValIPI := 0
					nValTot := 0

					cObsApr := ""

					While !SC7->(Eof()) .And. SC7->(C7_FILIAL + C7_NUM) == xFilial('SC7') + cNumPC

						AAdd(oProcess:oHtml:ValByName('PED.cItem')		, SC7->C7_ITEM)
						AAdd(oProcess:oHtml:ValByName('PED.cCodPro')	, SC7->C7_PRODUTO)
						AAdd(oProcess:oHtml:ValByName('PED.cDesPro')	, SC7->C7_DESCRI)

						//Comentado por ICARO dia 24/11/2020 essas informaçoes estavam sendo impressas erradas em caso de não ser veloce
						//If lVeloce
							AAdd(oProcess:oHtml:ValByName('PED.cCCusto')	, SC7->C7_CC)
							AAdd(oProcess:oHtml:ValByName('PED.cCtaContab')	, SC7->C7_CONTA)
						//EndIf

						AAdd(oProcess:oHtml:ValByName('PED.nQtde')		, Transform(SC7->C7_QUANT, PesqPict('SC7', 'C7_QUANT')))
						AAdd(oProcess:oHtml:ValByName('PED.nValUnit')	, cSimbMoed + Transform(SC7->C7_PRECO, PesqPict('SC7', 'C7_PRECO')))
						AAdd(oProcess:oHtml:ValByName('PED.nValTot')	, cSimbMoed + Transform(SC7->C7_TOTAL, PesqPict('SC7', 'C7_TOTAL')))
						AAdd(oProcess:oHtml:ValByName('PED.dDtEntr')	, SC7->C7_DATPRF)

						AIB->(DbSetOrder(2))
						If AIB->(DbSeek(xFilial('AIB')+SC7->(C7_FORNECE+C7_LOJA+C7_CODTAB+C7_PRODUTO)))
							cSimbMoAIB := SuperGetMV('MV_SIMB' + Alltrim(Str(AIB->AIB_MOEDA)), .F., 'R$') + ' '
							AAdd(oProcess:oHtml:ValByName('PED.nPrcTab')	, BSCEncode(cSimbMoAIB) + Transform(AIB->AIB_PRCCOM, PesqPict('AIB', 'AIB_PRCCOM')))
						Else
							cSimbMoAIB := " "
							AAdd(oProcess:oHtml:ValByName('PED.nPrcTab')	, BSCEncode(cSimbMoAIB) + Transform(0, PesqPict('AIB', 'AIB_PRCCOM')))
						EndIf

						// Observações dos itens:
						cObsItem := AllTrim(SC7->C7_OBS)

						If !Empty(cObsItem)
							aAdd(oProcess:oHtml:ValByName('OBS.cItem'), SC7->C7_ITEM)
						Else
							aAdd(oProcess:oHtml:ValByName('OBS.cItem'), "")
						EndIf

						AAdd(oProcess:oHtml:ValByName('OBS.cObsItem'), cObsItem)

						//-- Totais
						nValLiq += SC7->C7_TOTAL
						nValIPI += SC7->C7_VALIPI
						nValTot += SC7->(C7_TOTAL + C7_VALIPI)

						If AScan(aProdPC, SC7->C7_PRODUTO) == 0
							Aadd(aProdPC, SC7->C7_PRODUTO)
						EndIf

/*						If Empty(cObsApr)
							cObsApr := AllTrim(SC7->C7_XOBSAPR)
						EndIf
*/
						SC7->(DbSkip())
					End

					//-- TOTAIS
					oProcess:oHtml:ValByName('nValLiq', BSCEncode(cSimbMoed) + Transform(nValLiq, PesqPict('SC7', 'C7_TOTAL' )))
					oProcess:oHtml:ValByName('nValIPI', BSCEncode(cSimbMoed) + Transform(nValIPI, PesqPict('SC7', 'C7_VALIPI')))
					oProcess:oHtml:ValByName('nValTot', BSCEncode(cSimbMoed) + Transform(nValTot, PesqPict('SC7', 'C7_TOTAL' )))

					//-- OBSERVACOES DO APROVADOR
					oProcess:oHtml:ValByName('cObsApr', cObsApr)

					// ---------------------------------------------------------
					// Realiza a gravacao do processo de workflow.
					// Este processo sera gravado no servidor para
					// que seja acessado posteriormente via link
					// enviado no e-mail de notificacao do processo
					// ---------------------------------------------------------
					cPastaHTM    := 'PROCESSOS'
					oProcess:cTo := cPastaHTM

					// ---------------------------------------------------------
					// Tratamento da rastreabilidade do workflow
					// ---------------------------------------------------------
					RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '30001')

					If lVeloce
						cDirRaiz := 'messenger' + cBarra + 'emp' + cEmpAnt + cBarra + cPastaHTM
						fAdcVeloce(@oProcess, cNumPC, aProdPC, cDirRaiz)
					Else
						
						// ------------------------------------------
						// ALTERAÇÃO REALIZADO POR ICARO DIA 24/11 
						// Oculta a table
						// ------------------------------------------
						oProcess:oHtml:ValByName("cStyleU12P", "style='display:none'")
						oProcess:oHtml:ValByName("cStyleOUTF", "style='display:none'")
						oProcess:oHtml:ValByName("cStyleANEXO", "style='display:none'")
						//oProcess:oHtml:ValByName("cStyleCOTA", "style='display:none'")
						oProcess:oHtml:ValByName("cStyleFILA", "style='display:none'")
					EndIf

					// ---------------------------------------------------------
					// Inicia o processo de workflow e
					// guarda o Id do processo para montagem
					// do e-mail de link:
					// ---------------------------------------------------------
					cMailId := oProcess:Start()

					// ---------------------------------------------------------------
					//  Grava o ID do Workflow na tabela SCR (Documentos com alçada)
					//  Juliano Fernandes - 03/04/2019
					// ---------------------------------------------------------------
					SCR->(Reclock("SCR",.F.))
						SCR->CR_XIDWF := oProcess:fProcessID + "." + oProcess:fTaskID
					SCR->(MsUnlock())

					oProcess:Free()
					oProcess := Nil

					cUrl := 'http://' + cHttpSrv + If(Right(cHttpSrv, 1) <> '/', '/', '') + 'messenger/emp' + cEmpAnt + '/' + cPastaHTM + '/' + cMailId + '.htm'

					If !lSchedule
						f551WFLink( {{cNumPC, SA2->A2_NOME, cUrl}}, cMailApr )
					Else
						Aadd(aSchedWF, { cMailApr, cUrl })
					EndIf
				EndIf
			Next nCount
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(aSchedWF)

/*/{Protheus.doc} f551Ret
Função responsável pelo tratamento do retorno do processo de workflow de aprovação de Pedidos de compra.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@param oProcess, objeto, Processo do workflow
@type function
/*/
User Function f551Ret(oProcess)

	Local aArea			:= GetArea()
	Local aAreaSC7		:= {}
	Local aAreaSCR		:= SCR->(GetArea())
	Local aIDWF			:= {}
	Local aRetSaldo		:= {}
	Local aEMailApv		:= {}

	Local cNumPC		:= ""
	Local cNumSCR		:= ""
	Local cObserv		:= ""
	Local cCodAprov		:= ""
	Local cAliasQry		:= ""
	Local cTitle		:= ""
	Local cMsg			:= ""
	Local cMotivo		:= ""
	Local cMailCompr	:= ""
	Local cObsApr		:= ""
	Local cFornec		:= ""

	Local lAprovado		:= .F.
	Local lContinua		:= .T.
	Local lLiberou		:= .F.
	Local lSendMsg		:= .F.
	Local lMT094End		:= IsInCallStack("U_MT094END")
	Local lf551TORe		:= IsInCallStack("U_f551TORe")
	Local lVeloce 		:= SuperGetMV('PLG_WFVELO',,.F.)

	Local nTotal		:= 0
	Local nCount		:= 0

	Local oProcKill		:= Nil

	// -----------------------------------------------
	// Obtem os dados do formulario HTML para
	// tratamento do retorno:
	// -----------------------------------------------
	cNumPC     := oProcess:oHtml:RetByName('cNumPed')
	cNumSCR    := PadR(oProcess:oHtml:RetByName('cNumPed'),Len(SCR->CR_NUM))
	cObserv    := oProcess:oHtml:RetByName('cObsApr')
	cCodAprov  := oProcess:oHtml:RetByName('cCodAprov')
	lAprovado  := oProcess:oHtml:RetByName('Aprovacao') == 'S'

	// -----------------------------------------------
	// Posiciona no Documento de Alcada
	// -----------------------------------------------
	SCR->(DbSetOrder(2)) //-- CR_FILIAL+CR_TIPO+CR_NUM+CR_USER
	If SCR->(DbSeek(xFilial('SCR') + 'PC' + cNumSCR + cCodAprov))

		// -----------------------------------------------
		// Posiciona nas tabelas auxiliares
		// -----------------------------------------------
		SAK->( DbSetOrder(2) )
		SAK->( DbSeek(xFilial("SAK")+cCodAprov))

		SC7->( DbSetOrder(1) )
		If SC7->( DbSeek(xFilial("SC7")+cNumPC))
			cFornec := AllTrim(SC7->C7_FORNECE) + "/"
			cFornec += AllTrim(SC7->C7_LOJA) + " - "
			cFornec += AllTrim(Posicione("SA2",1,xFilial("SA2") + SC7->(C7_FORNECE + C7_LOJA), "A2_NOME"))

			cObsApr := AllTrim(SC7->C7_XOBSAPR)

			If !Empty(cObsApr)
				cObsApr += CRLF
			EndIf

			cObsApr += '['+ PRT551011 + AllTrim(UsrFullName(SCR->CR_USER)) + ']' + CRLF //OBSERVACOES REALIZADAS PELO APROVADOR:
			cObsApr += AllTrim(cObserv)
			cObsApr += CRLF

			aAreaSC7 := SC7->(GetArea())

			While !SC7->(Eof()) .And. SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7")+cNumPC

				SC7->(RecLock('SC7', .F.))
				SC7->C7_XOBSAPR := cObsApr
				SC7->(MsUnLock())

				SC7->(DbSkip())

			End

			RestArea(aAreaSC7)
		EndIf

		SAL->( DbSetOrder(3) ) // AL_FILIAL+AL_COD+AL_APROV
		SAL->( DbSeek(xFilial("SAL")+SC7->C7_APROV+SAK->AK_COD) )

		DHL->( DbSetOrder(1) ) // DHL_FILIAL+DHL_COD
		DHL->( DbSeek(xFilial("DHL")+SAL->AL_PERFIL) )

		If !lMT094End
			// -----------------------------------------------
			// Avalia o Status do Documento a ser liberado
			// -----------------------------------------------
			If lContinua .And. !Empty(SCR->CR_DATALIB) .And. SCR->CR_STATUS $ '03|05'
				Conout(PRT551012 + cNumPC + PRT551013) //'[PEDIDO: ' # ']Este pedido ja foi liberado anteriormente. Somente os pedidos que estao aguardando liberacao poderao ser liberados.'
				lContinua := .F.

			ElseIf lContinua .And. SCR->CR_STATUS $ '01'
				Conout(PRT551012 + cNumPC + PRT551014) //'[PEDIDO: ' # ']Esta operação não poderá ser realizada pois este registro se encontra bloqueado pelo sistema (aguardando outros niveis)'
				lContinua := .F.

			EndIf
		EndIf

		If lContinua
			If !lMT094End
				// ---------------------------------------------------------
				// Inicializa a gravacao dos lancamentos do SIGAPCO
				// ---------------------------------------------------------
				PcoIniLan("000055")

				// ---------------------------------------------------------
				// Avalia liberacao do DOcumento pelo PCO
				// ---------------------------------------------------------
				If !ValidPcoLan()
					Conout(PRT551012 + cNumPC + PRT551015) //'[PEDIDO ' # ']Bloqueio de Liberacao pelo PCO.'
					lContinua := .F.
				EndIf

				// ---------------------------------------------------------
				// Analisa o Saldo do Aprovador
				// ---------------------------------------------------------
				If lContinua .And. SAL->AL_LIBAPR == 'A'
					aRetSaldo  := MaSalAlc(SAK->AK_COD, dDataBase)
					nTotal     := xMoeda(SCR->CR_TOTAL,SCR->CR_MOEDA,aRetSaldo[2],SCR->CR_EMISSAO,,SCR->CR_TXMOEDA)
					If (aRetSaldo[1] - nTotal) < 0
						Conout(PRT551012 + cNumPC + PRT551016) //'[PEDIDO ' # ']Saldo na data insuficiente para efetuar a liberacao do pedido. Verifique o saldo disponivel para aprovacao na data e o valor total do pedido.'
						lContinua := .F.
					EndIf
				EndIf
			EndIf

			If lContinua
				BeginTran()
					// ---------------------------------------------------------
					// Executa a liberacao ou rejeicao
					// do Pedido de Compra.
					// --------------------------------------------------------
					If !lMT094End
//						lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SC7->C7_APROV,,,,,cObserv},dDataBase,IIf(lAprovado,4,7/* 6 */),,,,,,,cChaveSC7)
						lLiberou := fExAuto094(IIf(lAprovado,4,7), AllTrim((cObserv)))
					Else
						lLiberou := fPedidoLib(cNumPC)
					EndIf

					If Empty(SCR->CR_DATALIB) //-- Verifica se Aprovou se liberou o Documento
						Conout(PRT551012 + cNumPC + PRT551017 ) //'[PEDIDO ' # ']Nao foi possivel realizar a liberacao do Documento via WorkFlow. Tente realizar a liberacao manual.'
						lContinua := .F.
					EndIf

					If lContinua
						If lLiberou //-- Verifica se todos os niveis ja foram aprovados
							If !lMT094End
								// ---------------------------------------------------------
								// Grava os lancamentos nas contas orcamentarias SIGAPCO
								// ---------------------------------------------------------
								PcoDetLan("000055","02","MATA097")

								While SC7->(!Eof()) .And. SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+PadR(SCR->CR_NUM,Len(SC7->C7_NUM))
									SC7->(Reclock("SC7",.F.))
									SC7->C7_CONAPRO := "L" //-- Atualiza o status (Liberado) no Pedido de Compra
									SC7->(MsUnlock())

									// ---------------------------------------------------------
									// Grava os lancamentos nas contas orcamentarias SIGAPCO
									// ---------------------------------------------------------
									PcoDetLan("000055","01","MATA097")
									SC7->( DbSkip() )
								End
							EndIf

							SC7->(DbSetOrder(1))
							SC7->(DbSeek(xFilial("SC7")+cNumPC))

							// ---------------------------------------------------------
							// Tratamento da rastreabilidade do workflow
							// ---------------------------------------------------------
							RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '30002')

							// ---------------------------------------------------------
							// Envia e-mail ao comprador notificando a liberacao
							// do pedido de compra
							// ---------------------------------------------------------

							//-- Obtem o e-mail do Comprador:
							lSendMsg := .T.
							cTitle   := PRT551018 //'Aprovação de Pedido de Compra - Aprovado'
							cMsg     := PRT551019 + cNumPC + PRT551020 //'O Pedido de compra No. ' # ' foi aprovado com sucesso!'
							cMotivo  := ''

							PswOrder(1)
							If PswSeek(SC7->C7_USER) .And. !Empty(PswRet()[1,14])
								cMailCompr := AllTrim(PswRet()[1,14])
							EndIf

						Else
							If SCR->CR_STATUS == "06" //-- Se Rejeitado
								Conout(PRT551012 + cNumPC + PRT551021) //[PEDIDO  # ]O pedido em questao foi rejeitado!

								// ---------------------------------------------------------
								// Envia e-mail ao comprador notificando a reprovação
								// do pedido de compra
								// ---------------------------------------------------------
								lSendMsg := .T.
								cTitle   := PRT551022 //'Aprovação de Pedido de Compra - Rejeitado'
								cMsg     := PRT551019 + cNumPC + PRT551023 //'O Pedido de compra No. ' # ' foi Rejeitado.'
								cMotivo  := AllTrim(cObserv)

								//-- Obtem o e-mail do Comprador:
								SC7->(DbSetOrder(1))
								SC7->(DbSeek(xFilial("SC7")+cNumPC))

								PswOrder(1)
								If PswSeek(SC7->C7_USER) .And. !Empty(PswRet()[1,14])
									cMailCompr := AllTrim(PswRet()[1,14])
								EndIf

								If lVeloce
									// ----------------------------------------------
									// Array com o email dos usuários anteriores
									// da fila que aprovaram o pedido de compra
									// ----------------------------------------------
									aEMailApv := fGetEMailApv(cNumPC)
								EndIf

							Else
								// ---------------------------------------------------------
								// Envia WorkFlow para aprovacao do proximo Nivel
								// ---------------------------------------------------------
								SC7->( DbSetOrder(1) )
								SC7->( DbSeek(xFilial("SC7")+cNumPC))
								f551Send(cNumPC)

								// ---------------------------------------------------------
								// Tratamento da rastreabilidade do workflow
								// ---------------------------------------------------------
								RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '30002')

							EndIf
						EndIf

						// -----------------------------------------------------------------------------
						// Se o tipo de liberação for em Nivel (AL_TPLIBER == "N") então verifica
						// se existem mais usuários no nivel atual e mata o processo de Workflow
						// deles para que não possam mais aprovar / rejeitar
						// Juliano Fernandes - 03/04/2019
						// -----------------------------------------------------------------------------
						If SAL->AL_TPLIBER == "N"
							cAliasQry := GetNextAlias()

							If !lMT094End .And. !lf551TORe // Aprovação ou rejeição por Workflow
								// --------------------------------------------------------------------------
								// Mata o processo de outros usuários do mesmo nível
								// --------------------------------------------------------------------------
								BeginSQL Alias cAliasQry
									SELECT		SCR.CR_XIDWF
									FROM 		%Table:SCR% SCR
									WHERE 		SCR.CR_FILIAL	=  %xFilial:SCR%		AND
												SCR.CR_TIPO		=  %Exp:'PC'% 			AND
												SCR.CR_NUM		=  %Exp:SC7->C7_NUM% 	AND
												SCR.CR_NIVEL	=  %Exp:SAL->AL_NIVEL% 	AND
												SCR.CR_USER		<> %Exp:SAL->AL_USER% 	AND
												SCR.%NotDel%
									ORDER BY	SCR.R_E_C_N_O_
								EndSQL
							Else  // Aprovação ou rejeição pelo Protheus ou função de Timeout f551TORe
								// --------------------------------------------------------------------------
								// Mata o processo de todo o nível, pois o mesmo foi aprovado pelo Protheus
								// --------------------------------------------------------------------------
								BeginSQL Alias cAliasQry
									SELECT		SCR.CR_XIDWF
									FROM 		%Table:SCR% SCR
									WHERE 		SCR.CR_FILIAL	=  %xFilial:SCR%		AND
												SCR.CR_TIPO		=  %Exp:'PC'% 			AND
												SCR.CR_NUM		=  %Exp:SC7->C7_NUM% 	AND
												SCR.CR_NIVEL	=  %Exp:SAL->AL_NIVEL% 	AND
												SCR.%NotDel%
									ORDER BY	SCR.R_E_C_N_O_
								EndSQL
							EndIf

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

								// Douglas Gregorio
								// ---------------------------------------------------
								// Buscar o ID da SCR na WF6 para obter o WF6_IDENT1
								// ---------------------------------------------------
								//cIdentWF6 := fBscIdent(oProcKill:fProcessID)

								// ---------------------------------------------
								// Chamar função que deleta a tarefa do WF
								// ---------------------------------------------
								//If !Empty(cIdentWF6)
								//	xRet := WFSchDelete( cIdentWF6 )
								//EndIf

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
						EndIf
					EndIf
				EndTran()
			EndIf

			If !lMT094End
				// ------------------------------------------------
				// Finaliza a gravacao dos lancamentos do SIGAPCO
				// ------------------------------------------------
				PcoFinLan("000055")
			EndIf

			If lSendMsg
				If lVeloce
					If lAprovado
						// ------------------------------------------------------------
						// Notifica apenas o usuário que incluiu o pedido de compra
						// ------------------------------------------------------------
						f551Msg(cTitle, cMsg, cMotivo, cMailCompr)
					Else
						// ------------------------------------------------------------------------------
						// Verifica se o email o usuário que incluiu o pedido de compra (cMailCompr)
						// está entre os aprovadores (aEmailApv). Se não encontrar, então inclui do
						// array aEmailApv para que o mesmo também possa ser notificado.
						// ------------------------------------------------------------------------------
						If AScan(aEMailApv, {|x| AllTrim(x) == AllTrim(cMailCompr)}) == 0
							Aadd(aEMailApv, cMailCompr)
						EndIf

						// ------------------------------------------------------------------------------
						// Envia email para os usuários que fizeram a aprovação do pedido anteriormente.
						// Somente caso o pedido de compra seja rejeitado.
						// ------------------------------------------------------------------------------
						AEval(aEMailApv, {|cMailApv| f551Reprov(cTitle, cMailApv, cNumPC, cFornec)})
					EndIf

					fExcAnexos(cNumPC)
				Else
					f551Msg(cTitle, cMsg, cMotivo, cMailCompr)
				EndIf
			EndIf

		EndIf
	EndIf

	// ---------------------
	// Finaliza o Processo
	// ---------------------
	oProcess:Finish()

	// ---------------------------------------------
	// Libera o objeto
	// ---------------------------------------------
	oProcess:Free()
	oProcess := Nil

	RestArea(aAreaSC7)
	RestArea(aAreaSCR)
	RestArea(aArea)

Return(Nil)

/*/{Protheus.doc} ValidPcoLan
Validacoes de bloqueio orcamentario (A094PcoLan).
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return lRet, Indica se é válido ou não
@type function
/*/
Static Function ValidPcoLan()

	Local aArea		:= GetArea()
	Local aAreaSC7	:= SC7->(GetArea())
	Local lRet		:= .T.

	DbSelectArea("SC7")
	SC7->(DbSetOrder(1))
	SC7->(DbSeek(xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))))

	If lRet := PcoVldLan('000055','02','MATA097')
		While lRet .And. !SC7->(Eof()) .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))
			lRet := PcoVldLan("000055","01","MATA097")
			SC7->(DbSelectArea("SC7"))
			SC7->(DbSkip())
		EndDo
	EndIf

	If !lRet
		PcoFreeBlq("000055")
	EndIf

	RestArea(aAreaSC7)
	RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} f551Msg
Envia mensagem de e-mail ao final do processo.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@param cTitle, caracter, Título do e-mail
@param cMsg, caracter, Mensagem do e-mail
@param cMotivo, caracter, Motivo da rejeição
@param cMail, caracter, Endereço do e-mail destinatário
@type function
/*/
Static Function f551Msg(cTitle, cMsg, cMotivo, cMail)

	Local cArqMsg := fGetDirTem() + cWF0551Msg

	Local oPrcMsg := Nil

	// ---------------------------------------------------------
	// Envia e-mail ao comprador notificando a liberacao
	// do pedido de compra
	// ---------------------------------------------------------
	oPrcMsg := TWFProcess():New('APR_PC')

	oPrcMsg:NewTask('PLGWFPC03', cArqMsg)

	// ----------------------------------------------------------------
	// Monta layout HTML conforme o País (variável pública cPaisLoc)
	// ----------------------------------------------------------------
	fLayoutHtml(@oPrcMsg, cWF0551Msg)

	If !Empty(cMotivo)
		cMotivo := PRT551024 + BSCEncode(cMotivo) //"Motivo: "
	EndIf

	// ---------------------------------------------------------
	// Atualiza variaveis do formulario
	// ---------------------------------------------------------
	oPrcMsg:oHtml:ValByName('cTitle' , BSCEncode(cTitle))
	oPrcMsg:oHtml:ValByName('cMsg'	 , BSCEncode(cMsg))
	oPrcMsg:oHtml:ValByName('cMotivo', BSCEncode(cMotivo))

	// ---------------------------------------------------------
	// Determina o destinatario do e-mail
	// ---------------------------------------------------------
	oPrcMsg:cTo := cMail

	// ---------------------------------------------------------
	// Assunto do e-mail:
	// ---------------------------------------------------------
	oPrcMsg:cSubject := cTitle

	// ---------------------------------------------------------
	// Envia e-mail
	// ---------------------------------------------------------
	oPrcMsg:Start()

	// ---------------------------------------------------------
	// Finaliza o processo
	// ---------------------------------------------------------
	oPrcMsg:Finish()

	// ---------------------------------------------------------
	// Libera o objeto
	// ---------------------------------------------------------
	oPrcMsg:Free()
	oPrcMsg := Nil

Return(Nil)

/*/{Protheus.doc} f551Reprov
Envia mensagem de e-mail em caso de reprovação ao final do processo.
Específico Veloce.
@author Juliano Fernandes
@since 13/02/2020
@version 1.0
@return Nil, Não há retorno
@param cTitle, caracter, Título do e-mail
@param cMail, caracter, Endereço do e-mail destinatário
@param cNumPed, caracter, Número do pedido de compra
@type function
/*/
Static Function f551Reprov(cTitle, cMail, cNumPed, cFornec)

	Local cArqMsgRep := fGetDirTem() + cWF0551Rep

	Local oPrcMsgRep := Nil

	oPrcMsgRep := TWFProcess():New('APR_PC')

	oPrcMsgRep:NewTask('PLGWFPC03', cArqMsgRep)

	// ----------------------------------------------------------------
	// Monta layout HTML conforme o País (variável pública cPaisLoc)
	// ----------------------------------------------------------------
	fLayoutHtml(@oPrcMsgRep, cWF0551Rep)

	oPrcMsgRep:oHtml:ValByName('cTitle' , BSCEncode(cTitle) )
	oPrcMsgRep:oHtml:ValByName('cNumPed', BSCEncode(cNumPed))
	oPrcMsgRep:oHtml:ValByName('cFornec', BSCEncode(cFornec))

	// ---------------------------------------------------------
	// Monta a fila de aprovação
	// ---------------------------------------------------------
	fFilaAprov(@oPrcMsgRep, cNumPed)

	// ---------------------------------------------------------
	// Determina o destinatario do e-mail
	// ---------------------------------------------------------
	oPrcMsgRep:cTo := cMail

	// ---------------------------------------------------------
	// Assunto do e-mail:
	// ---------------------------------------------------------
	oPrcMsgRep:cSubject := cTitle

	// ---------------------------------------------------------
	// Envia e-mail
	// ---------------------------------------------------------
	oPrcMsgRep:Start()

	// ---------------------------------------------------------
	// Finaliza o processo
	// ---------------------------------------------------------
	oPrcMsgRep:Finish()

	// ---------------------------------------------------------
	// Libera o objeto
	// ---------------------------------------------------------
	oPrcMsgRep:Free()
	oPrcMsgRep := Nil

Return(Nil)

/*/{Protheus.doc} f551TOAv
Função executado no TimeOut do processo.
Envia aviso de falta de resposta do aprovador ao solicitante.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@param oProcess, objeto, Processo workflow
@type function
/*/
User Function f551TOAv(oProcess)

	Local aAreas		:= {}

	Local cNumPC		:= ""
	Local cCodAprov		:= ""
	Local cTitle		:= ""
	Local cMsg			:= ""
	Local cMotivo		:= ""
	Local cMailCompr	:= ""

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))

	cNumPC		:= oProcess:oHtml:RetByName('cNumPed')
	cCodAprov	:= oProcess:oHtml:RetByName('cCodAprov')

	//-- Obtem o e-mail do Comprador:
	SC7->(DbSetOrder(1))
	If SC7->(DbSeek(xFilial("SC7") + cNumPC))

		cTitle	:= PRT551025 + cNumPC //"Acompanhamento da aprovação de Pedido de Compra No. "
		cMsg	:= PRT551019 + cNumPC + PRT551026 + AllTrim(UsrFullName(cCodAprov)) + "." //"O Pedido de compra No. " # " está em fila de aprovação aguardando resposta do aprovador: "
		cMotivo	:= ""

		PswOrder(1)
		If PswSeek(SC7->C7_USER) .And. !Empty(PswRet()[1,14])
			cMailCompr := AllTrim(PswRet()[1,14])
		EndIf

		// ---------------------------------------------------------
		// Tratamento da rastreabilidade do workflow
		// ---------------------------------------------------------
		RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '30003')

		f551Msg(cTitle, cMsg, cMotivo, cMailCompr)

	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} f551TORe
Função executado no TimeOut do processo.
Rejeita o pedido de compra por falta de resposta do aprovador.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return Nil, Não há retorno
@param oProcess, objeto, Processo workflow
@type function
/*/
User Function f551TORe(oProcess)

	Local aAreas	:= {}

	Local cNumPC	:= ""
	Local cAprov 	:= ""
	Local cObsRej	:= ""
	Local cCodAprov	:= ""
	Local cChaveSCR	:= ""
	Local cNivel	:= ""
	Local cNomeApro	:= ""

	Local lNivel	:= .F.

	Local nQtdAprov	:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))
	Aadd(aAreas, SAK->(GetArea()))
	Aadd(aAreas, SAL->(GetArea()))
	Aadd(aAreas, SCR->(GetArea()))

	cNumPC		:= oProcess:oHtml:RetByName('cNumPed')
	cCodAprov	:= oProcess:oHtml:RetByName('cCodAprov')
	cAprov		:= "N"
	cObsRej		:= PRT551027 //"[Rejeição por TimeOut] Pedido de compra rejeitado por inatividade no processo de Workflow. "

	DbSelectArea("SC7")
	SC7->(DbSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN
	If SC7->(DbSeek(xFilial("SC7") + cNumPC))

		DbSelectArea("SAK")
		SAK->(DbSetOrder(2)) // AK_FILIAL+AK_USER
		If SAK->(DbSeek(xFilial("SAK") + cCodAprov))

			DbSelectArea("SAL")
			SAL->(DbSetOrder(3) ) // AL_FILIAL+AL_COD+AL_APROV
			If SAL->(DbSeek(xFilial("SAL") + SC7->C7_APROV + SAK->AK_COD))

				// -------------------------------------------------------------------
				// Verifica se o tipo de liberação é por nivel (AL_TPLIBER == "N")
				// -------------------------------------------------------------------
				If SAL->AL_TPLIBER == "N"
					lNivel := .T.
				EndIf
			EndIf
		EndIf
	EndIf

	If lNivel
		cChaveSCR := xFilial("SCR")
		cChaveSCR += PadR("PC"		, TamSX3("CR_TIPO")[1])
		cChaveSCR += PadR(cNumPC	, TamSX3("CR_NUM" )[1])
		cChaveSCR += PadR(cCodAprov	, TamSX3("CR_USER")[1])

		DbSelectArea("SCR")
		SCR->(DbSetOrder(2)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_USER
		If SCR->(DbSeek( cChaveSCR ))
			cNivel := SCR->CR_NIVEL
		EndIf
	EndIf

	If !Empty(cNivel)
		cChaveSCR := xFilial("SCR")
		cChaveSCR += PadR("PC"		, TamSX3("CR_TIPO" )[1])
		cChaveSCR += PadR(cNumPC	, TamSX3("CR_NUM"  )[1])
		cChaveSCR += PadR(cNivel	, TamSX3("CR_NIVEL")[1])

		DbSelectArea("SCR")
		SCR->(DbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
		If SCR->(DbSeek( cChaveSCR ))
			While !SCR->(EoF()) .And. SCR->(CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL) == cChaveSCR
				nQtdAprov++

				cNomeApro += AllTrim(UsrFullName(SCR->CR_USER)) + " / "

				SCR->(DbSkip())
			EndDo
		EndIf
	EndIf

	If Right(cNomeApro, 3) == " / "
		cNomeApro := Left(cNomeApro, Len(cNomeApro) - 3)
	EndIf

	If nQtdAprov > 1
		cObsRej += PRT551028 //"Últimos Aprovadores: "
	Else
		cObsRej += PRT551029 //"Último Aprovador: "
	EndIf

	cObsRej += cNomeApro

	oProcess:oHtml:ValByName('Aprovacao', cAprov )
	oProcess:oHtml:ValByName('cObsApr'  , cObsRej)

	// ---------------------------------------------------------
	// Tratamento da rastreabilidade do workflow
	// ---------------------------------------------------------
	RastreiaWF(oProcess:fProcessID + '.' + oProcess:fTaskID, oProcess:fProcCode, '30004')

	U_f551Ret(oProcess)

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fRestAreas
Executa o RestArea para as áreas passadas no parâmetro.
@author Juliano Fernandes
@since 03/04/2019
@version 1.0
@return Nil, Não há retorno
@param aAreas, Array, Array contendo as areas
@type function
/*/
Static Function fRestAreas(aAreas)

	Local nI := 0

	For nI := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nI])
	Next nI

Return(Nil)

/*/{Protheus.doc} fGetDirTem
Retorna o diretório onde estão localizados os templates para o workflow.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return cDiretorio, Diretório onde estão localizados os templates
@type function
/*/
Static Function fGetDirTem()

	Local cDiretorio := AllTrim(SuperGetMV("PLG_WFPCTE",,""))

	If !Empty(cDiretorio)
		If Right(cDiretorio,1) != cBarra
			cDiretorio += cBarra
		EndIf
	EndIf

Return(cDiretorio)

/*/{Protheus.doc} f551WFPC
Função responsável por indicar se o workflow de Pedidos de Compra está ativo.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return lAtivo, Indica se o workflow de Pedidos de Compra está ativo
@param lMsg, logico, Indica se deve exibir mensagem caso o workflow não esteja ativo
@type function
/*/
Static Function f551WFPC(lMsg)

	Local cMsg		:= ""

	Local lAtivo 	:= .F.

	Default lMsg 	:= .F.

	lAtivo := SuperGetMV("PLG_WFPC",,.F.)

	If !lAtivo .And. lMsg
		cMsg := PRT551030 + CRLF //"Workflow para aprovação de Pedidos de Compra não está ativado."
		cMsg += PRT551031 //"Verifique o parâmetro PLG_WFPC."

		Aviso(NomePrt + PRT551001 + VersaoJedi, cMsg, {PRT551003}, 2) //' - Workflow de Pedido de Compra  - ' # 'OK'
	EndIf

Return(lAtivo)

/*/{Protheus.doc} f551VldWFPC
Valida se os parâmetros necessários para o Workflow de Pedidos de Compra estão configurados.
@author Juliano Fernandes
@since 04/04/2019
@version 1.0
@return lValid, Indica se os parâmetros estão configurados
@param lMsg, logico, Indica se deve exibir mensagem caso o workflow não esteja ativo
@type function
/*/
Static Function f551VldWFPC(lMsg)

	Local aAreas		:= {}
	Local aParams		:= {}
	Local aTemplates	:= {}
	Local aCposCusto	:= {}
	Local aParamTOut	:= {}
	Local aTimeOut		:= {}

	Local cMsg			:= ""
	Local cDirTempl		:= ""
	Local cTimeOut		:= ""

	Local lValid 		:= .T.
	Local lVldAux		:= .T.

	Local nI			:= 0

	Default lMsg 		:= .F.

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SCR->(GetArea()))
	Aadd(aAreas, SC7->(GetArea()))

	// ------------------------------
	// Parâmetros a serem validados
	// ------------------------------
	Aadd(aParams, "PLG_WFPCIP")
	Aadd(aParams, "PLG_WFPCTE")
	Aadd(aParams, "PLG_WFPCTA")
	Aadd(aParams, "PLG_WFPCTR")

	For nI := 1 To Len(aParams)
		If !GetMV(aParams[nI],.T.)
			cMsg   += PRT551032 + aParams[nI] + PRT551033 + CRLF //"Parâmetro " # " não cadastrado."
			lValid := .F.
		ElseIf Empty(GetMV(aParams[nI]))
			cMsg   += PRT551032 + aParams[nI] + PRT551034 + CRLF //"Parâmetro " # " não preenchido."
			lValid := .F.
		EndIf
	Next nI

	// ---------------------------------------
	// Valida se os arquivos de template
	// estão do diretório correspondente
	// ---------------------------------------
	cDirTempl := fGetDirTem()

	If !Empty(cDirTempl)
		Aadd(aTemplates, cDirTempl + cWF0551    )
		Aadd(aTemplates, cDirTempl + cWF0551Link)
		Aadd(aTemplates, cDirTempl + cWF0551Msg )

		For nI := 1 To Len(aTemplates)
			If !File(aTemplates[nI])
				cMsg   += PRT551035 + aTemplates[nI] + CRLF //"Arquivo de template não encontrado: "
				lValid := .F.
			EndIf
		Next nI
	EndIf

	// ------------------------------------------------
	// Valida se os campos customizados foram criados
	// ------------------------------------------------
	Aadd(aCposCusto, {"SCR", "CR_XIDWF"  })
	Aadd(aCposCusto, {"SCR", "CR_XERROWF"})
	Aadd(aCposCusto, {"SC7", "C7_XOBSAPR"})

	For nI := 1 To Len(aCposCusto)
		DbSelectArea(aCposCusto[nI,1])
		If (aCposCusto[nI,1])->(FieldPos(aCposCusto[nI,2])) == 0
			cMsg   += PRT551036 //"Campo customizado não localizado: "
			cMsg   += PRT551037 + aCposCusto[nI,1] + " " //"Tabela: "
			cMsg   += PRT551038 + aCposCusto[nI,2] //"Campo: "
			cMsg   += CRLF
			lValid := .F.
		EndIf
	Next nI

	// --------------------------------------------------------------------------------
	// Valida se os parâmetros de TimeOut do Workflow foram preenchidos corretamente
	// --------------------------------------------------------------------------------
	Aadd(aParamTOut, "PLG_WFPCTA")
	Aadd(aParamTOut, "PLG_WFPCTR")

	For nI := 1 To Len(aParamTOut)
		lVldAux  := .T.
		cTimeOut := SuperGetMV(aParamTOut[nI],,"")

		If !Empty(cTimeOut)
			aTimeOut := Separa(cTimeOut,",",.T.)

			If Len(aTimeOut) < 3 .Or. Len(aTimeOut) > 3
				lValid := .F.
			Else
				AEVal(aTimeOut, {|x| IIf(lVldAux, lVldAux := !Empty(x) .And. IsNumeric(x), Nil)})
			EndIf

			If !lVldAux
				cMsg   += PRT551039 + CRLF //"Parâmetro com cadastro incorreto:"
				cMsg   += PRT551040 + aParamTOut[nI] + CRLF //"Parâmetro: "
				cMsg   += PRT551041 + cTimeOut + CRLF //"Valor cadastrado: "
				cMsg   += PRT551042 + CRLF //"Correto: d,h,m"
				cMsg   += PRT551043 + CRLF //"Exemplo: 1,0,0"
				lValid := .F.
			EndIf
		EndIf
	Next nI

	If !lValid .And. lMsg
		Aviso(NomePrt + PRT551001 + VersaoJedi, cMsg, {PRT551003}, 3,,,,.T.) //' - Workflow de Pedido de Compra - ' # 'OK'
	EndIf

	fRestAreas(aAreas)

Return(lValid)

/*/{Protheus.doc} fExAuto094
Função para a geração da Liberação ou Rejeição do documento utilizando a rotina MATA094 (Liberação de documentos).
@author Juliano Fernandes
@since 05/04/2019
@version 1.0
@return lPedLiber, Não há retorno
@param nOpc, numerico, Indica se é 4=Aprovação ou 7=Rejeição
@param cObs, caracter, Observação informada pelo aprovador
@type function
/*/
Static Function fExAuto094(nOpc, cObs)

	Local aAreas		:= {}
	Local aErro			:= {}
	Local aErroRet		:= {}
	Local aAux			:= {}
	Local aCpoSCR		:= {}

	Local _cFunName		:= FunName()
	Local cErroWF		:= ""

	Local lContinua		:= .T.
	Local lPedLiber		:= .T.

	Local nI			:= 0
	Local nPos			:= 0
	Local nRecSCR		:= SCR->(Recno())

	Local oModel		:= Nil
	Local oAux			:= Nil
	Local oStruct		:= Nil

	Private aCampoSC7	:= {} // Váriavel utilizada no fonte padrão A094FilPrd
	Private cFieldSC7	:= "" // Váriavel utilizada no fonte padrão MATA094

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))
	Aadd(aAreas, SCR->(GetArea()))

	// -------------------------------------------------------
	// Usuario aprovador
	// Necessário para a função RetCodUsr() dentro do MATA094
	// -------------------------------------------------------
	If Empty(cUserName) .And. Empty(__cUserID)
		cUserName := UsrRetName(SCR->CR_USER)
		__cUserID := SCR->CR_USER
	EndIf

	SetFunName("MATA097")
	conout("1238")
	// ---------------------------------------
	// Definição do cOperID no MATA094
	// cOperID == "001" // Aprovação
	// cOperID == "002" // Estorno
	// cOperID == "003" // Superior
	// cOperID == "004" // Transferir Superior
	// cOperID == "005" // Rejeição
	// cOperID == "006" // Bloqueio
	// cOperID == "007" // Visualização
	// ---------------------------------------
	If nOpc == 4 // Aprovação
		A094SetOp("001")
		cOperID := "001"
	Else // Rejeição
		A094SetOp("005")
		cOperID := "005"
	EndIf

	Pergunte("MTA097",.F.)

	// -------------------------------------------
	// Campos que serão gravados na tabela SCR
	// -------------------------------------------
	Aadd( aCpoSCR, { "CR_OBS", cObs } )

	// --------------------------------------
	// Instancia o modelo de dados (Model)
	// --------------------------------------
	oModel := FWLoadModel("MATA094")

	// --------------------------------------------------------------------------
	// Define a operação desejada: 3 – Inclusão / 4 – Alteração / 5 - Exclusão
	// --------------------------------------------------------------------------
	oModel:SetOperation(MODEL_OPERATION_UPDATE)

	// -----------------
	// Ativa o modelo
	// -----------------
	lContinua := oModel:Activate()

	If lContinua
		// -----------------------------------------------------------------------
		// Instancia apenas a parte do modelo referente aos dados da tabela SCR
		// -----------------------------------------------------------------------
		oAux := oModel:GetModel("FieldSCR")

		// ----------------------------------------
		// Obtém a estrutura de dados da SCR
		// ----------------------------------------
		oStruct := oAux:GetStruct()
		aAux := oStruct:GetFields()

		For nI := 1 To Len(aCpoSCR)
			// -------------------------------------------------------------
			// Verifica se os campos passados existem na estrutura da SCR
			// -------------------------------------------------------------
			If ( nPos := AScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCpoSCR[nI][1] ) } ) ) > 0

				// -------------------------------------------------------------
				// É feita a atribuição do dado aos campo do Model do cabeçalho
				// -------------------------------------------------------------
				If !( lContinua := oModel:SetValue("FieldSCR", aCpoSCR[nI][1], aCpoSCR[nI][2]) )
					// -----------------------------------------------------------------------------------
					// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
					// o método SetValue retorna .F.
					// -----------------------------------------------------------------------------------
					Exit
				EndIf
			EndIf
		Next
	EndIf

	If lContinua
		// -----------------------------------------------------------------------------------------------
		// Faz-se a validação dos dados, note que diferentemente das tradicionais "rotinas automáticas"
		// neste momento os dados não são gravados, são somente validados.
		// -----------------------------------------------------------------------------------------------
		If ( lContinua := oModel:VldData() )
			// -----------------------------------------------------------------------------------
			// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
			// -----------------------------------------------------------------------------------
			oModel:CommitData()
		EndIf
	EndIf

	If !lContinua
		lPedLiber := .F.

		// -------------------------------------------------------------------------------------------------
		// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou mensagem de aviso
		// -------------------------------------------------------------------------------------------------

		// ------------------------------------------------
		// A estrutura do vetor com erro é:
		// [1] identificador (ID) do formulário de origem
		// [2] identificador (ID) do campo de origem
		// [3] identificador (ID) do formulário de erro
		// [4] identificador (ID) do campo de erro
		// [5] identificador (ID) do erro
		// [6] mensagem do erro
		// [7] mensagem da solução
		// [8] Valor atribuído
		// [9] Valor anterior
		// ------------------------------------------------
		aErro := oModel:GetErrorMessage()

		aErroRet    := Array(9)
		aErroRet[1] := PRT551044 + ' [' + AllToChar( aErro[1] ) + ']' //"Id do formulário de origem: "
		aErroRet[2] := PRT551045 + ' [' + AllToChar( aErro[2] ) + ']' //"Id do campo de origem: "
		aErroRet[3] := PRT551046 + ' [' + AllToChar( aErro[3] ) + ']' //"Id do formulário de erro: "
		aErroRet[4] := PRT551047 + ' [' + AllToChar( aErro[4] ) + ']' //"Id do campo de erro: "
		aErroRet[5] := PRT551048 + ' [' + AllToChar( aErro[5] ) + ']' //"Id do erro: "
		aErroRet[6] := PRT551049 + ' [' + AllToChar( aErro[6] ) + ']' //"Mensagem do erro: "
		aErroRet[7] := PRT551050 + ' [' + AllToChar( aErro[7] ) + ']' //"Mensagem da solução: "
		aErroRet[8] := PRT551051 + ' [' + AllToChar( aErro[8] ) + ']' //"Valor atribuído: "
		aErroRet[9] := PRT551052 + ' [' + AllToChar( aErro[9] ) + ']' //"Valor anterior: "

		AEVal(aErroRet, {|x| cErroWF += x + CRLF})

		SCR->(DbGoTo(nRecSCR))
		If SCR->(Recno()) == nRecSCR
			SCR->(RecLock("SCR",.F.))
				SCR->CR_XERROWF := cErroWF
			SCR->(MsUnlock())
		EndIf

		Conout(cErroWF)
	EndIf

	// -----------------------
	// Desativamos o Model
	// -----------------------
	oModel:DeActivate()

	SetFunName(_cFunName)

	// ------------------------------------------------------------------------------------
	// Executo o RestArea, pois em caso de aprovação final, a tabela SC7 fica em EoF
	// ------------------------------------------------------------------------------------
	fRestAreas(aAreas)

	// -----------------------------------------------
	// Verifica se o pedido foi totalmente liberado
	// -----------------------------------------------
	lPedLiber := fPedidoLib(SC7->C7_NUM)

	fRestAreas(aAreas)

Return(lPedLiber)

/*/{Protheus.doc} fPedidoLib
Retorna se o Pedido de compra foi totalmente liberado.
Se o pedido de compra continua bloqueado, então o retorno deve ser falso, indicando que o pedido não foi liberado.
- Status bloqueado na legenda do Pedido de compra: C7_ACCPROC <> "1" .And. C7_CONAPRO == "B" .And. C7_QUJE < C7_QUANT
- Status reprovado na legenda do Pedido de compra: C7_ACCPROC <> "1" .And. C7_CONAPRO == "R" .And. C7_QUJE < C7_QUANT
@author Juliano Fernandes
@since 09/04/2019
@version 1.0
@return lPedLiber, Indica se o Pedido de Compra foi totalmente liberado
@type function
/*/
Static Function fPedidoLib(cNumPed)

	Local aAreas	:= {}

	Local lPedLiber	:= .T.

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))

	DbSelectArea("SC7")
	SC7->(DbSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN
	If SC7->(DbSeek(xFilial("SC7") + cNumPed))
		If SC7->C7_ACCPROC <> "1" .And. SC7->C7_QUJE < SC7->C7_QUANT
			If SC7->C7_CONAPRO == "B" .Or. SC7->C7_CONAPRO == "R" // Bloqueado ou Reprovado
				lPedLiber := .F.
			EndIf
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(lPedLiber)

/*/{Protheus.doc} fBscIdent
Função que buscará o Identificador da WF6 a partir do ID do Processo
@type Function
@author Douglas Gregorio
@since 10/04/19
@param cIdProc, Caracter, Identificador do Processo
@return cReturn, Caracter, TimeOut Ids
/*/
Static Function fBscIdent(cIdProc)

	Local cAliasQry	:= ""
	Local cReturn	:= ""

	//Local nPos		:= 0

	cIdProc	+= "%"

	cAliasQry := GetNextAlias()
	BeginSQL Alias cAliasQry
		SELECT		WF6.WF6_IDENT1, WF6.WF6_DTVENC, WF6.WF6_HRVENC, WF6.WF6_DTRESP, WF6.WF6_HRRESP
		FROM 		%Table:WF6% WF6
		WHERE 		WF6.WF6_FILIAL	=  %xFilial:SCR%		AND
					WF6.WF6_IDENT1 LIKE %Exp:cIdProc% 		AND
					WF6.%NotDel%
		ORDER BY	WF6.R_E_C_N_O_
	EndSQL

	While !(cAliasQry)->( EOF() )
		If !Empty((cAliasQry)->WF6_IDENT1)
			cReturn := (cAliasQry)->WF6_IDENT1

			Exit
		EndIf

		(cAliasQry)->( DbSkip() )
	EndDo

	(cAliasQry)->( DbCloseArea() )
Return cReturn

/*/{Protheus.doc} fExistProc
Função que verifica se já existe processo de workflow enviado para pedido de compra posicionado
@type Function
@author Douglas Gregorio
@since 16/04/19
@return lRet, Logico, Retorna se já foi enviado email do processo
/*/
Static Function fExistProc()

	//Local aRegs		:= {}

	Local cAliasQry	:= ""

	Local lRet		:= .F.

	// ----------------------------------------
	// Verifica o controle de alcadas, somente
	// para Pedidos de Compra
	// ---------------------------------------
	cAliasQry := GetNextAlias()

	BeginSQL Alias cAliasQry
		SELECT 		SCR.R_E_C_N_O_ nRecSCR
		FROM 		%Table:SCR% SCR
		WHERE 		SCR.CR_FILIAL	=  %xFilial:SCR%					AND
					SCR.CR_TIPO		=  %Exp:'PC'% 						AND
					SCR.CR_NUM		=  %Exp:SC7->C7_NUM% 				AND
					SCR.CR_XIDWF	<> %Exp:Space(Len(SCR->CR_XIDWF))% 	AND
					SCR.%NotDel%
		ORDER BY	SCR.R_E_C_N_O_
	EndSQL

	(cAliasQry)->(DbEval({|| lRet := .T.},, {|| !Eof()}))
	(cAliasQry)->(DbCloseArea())

Return(lRet)

/*/{Protheus.doc} fGetStPed
Retorna o status atual do pedido (Bloqueado, Rejeitado, Pendente).
@author Juliano Fernandes
@since 25/04/2019
@version 1.0
@return cStatus, Status B=Bloqueado, R=Rejeitado, P=Pendente
@param cPedido, caracter, Pedido de Compra
@type function
/*/
Static Function fGetStPed(cPedido)

	Local aAreas	:= {}

	Local bCondBloq	:= {|| .T.}
	Local bCondReje := {|| .T.}
	Local bCondPend := {|| .T.}

	Local cStatus	:= ""

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))

	// ----------------------------------------------------------------------------------------------------
	// Status do Pedido de compra conforme as legendas do programa padrão MATA120
	// ----------------------------------------------------------------------------------------------------
	// Bloqueado (BR_AZUL)  : 'C7_ACCPROC <> "1" .And. C7_CONAPRO == "B" .And. C7_QUJE < C7_QUANT'
	// Rejeitado (BR_CANCEL): 'C7_ACCPROC <> "1" .And. C7_CONAPRO == "R" .And. C7_QUJE < C7_QUANT'
	// Pendente  (ENABLE)   : 'C7_QUJE == 0 .And. C7_QTDACLA == 0'
	// ----------------------------------------------------------------------------------------------------
	bCondBloq := {|| SC7->C7_ACCPROC <> "1" .And. SC7->C7_CONAPRO == "B" .And. SC7->C7_QUJE < SC7->C7_QUANT}
	bCondReje := {|| SC7->C7_ACCPROC <> "1" .And. SC7->C7_CONAPRO == "R" .And. SC7->C7_QUJE < SC7->C7_QUANT}
	bCondPend := {|| SC7->C7_QUJE == 0 .And. SC7->C7_QTDACLA == 0}

	DbSelectArea("SC7")
	SC7->(DbSetOrder(1))
	If SC7->(DbSeek(xFilial("SC7") + cPedido))
		If Eval(bCondBloq)
			cStatus := "B"
		ElseIf Eval(bCondReje)
			cStatus := "R"
		ElseIf Eval(bCondPend)
			cStatus := "P"
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(cStatus)

/*/{Protheus.doc} fLayoutHtml
Monta campos fixos do arquivo HTML passado por parâmetro e atribui
ao processo conforme o País (variável pública cPaisLoc).
@author Juliano Fernandes
@since 18/04/2019
@version 1.0
@return Nil, Não há retorno
@param oProcess, objeto, Processo do Workflow
@param cArqHtml, caracter, Nome do arquivo HTML
@type function
/*/
Static Function fLayoutHtml(oProcess, cArqHtml)

	Local aHtml		:= {}
	Local aCaracEsp	:= {}

	Local cTitle	:= PRT551053// "Aprovação de Pedido de Compra"
	Local cRodape	:= PRT551054 + CValToChar(Year(Date())) + ". " + PRT551055 //"TOTVS © Copyright " # "Todos os direitos reservados"

	Local lVeloce 	:= SuperGetMV('PLG_WFVELO',,.F.)

	Local nI, nJ

	If cArqHtml == cWF0551

		Aadd( aHtml, { "cFixo001", cTitle		 } )
		Aadd( aHtml, { "cFixo002", Upper(cTitle) } ) // "APROVAÇÃO DE PEDIDO DE COMPRA"
		Aadd( aHtml, { "cFixo003", PRT551056	 } ) // "DADOS DO PEDIDO"
		Aadd( aHtml, { "cFixo004", PRT551057	 } ) // "Pedido de Compra"
		Aadd( aHtml, { "cFixo005", PRT551058	 } ) // "Emissão"
		Aadd( aHtml, { "cFixo006", PRT551059	 } ) // "Fornecedor"
		Aadd( aHtml, { "cFixo007", PRT551060	 } ) // "Comprador"
		Aadd( aHtml, { "cFixo008", PRT551061	 } ) // "Condição de Pagamento"
		Aadd( aHtml, { "cFixo009", PRT551062	 } ) // "Solicitante"
		Aadd( aHtml, { "cFixo010", PRT551063	 } ) // "E-mail do Solicitante"
		Aadd( aHtml, { "cFixo011", PRT551064	 } ) // "Data da Solicitação"
		Aadd( aHtml, { "cFixo012", PRT551065	 } ) // "ITENS DO PEDIDO DE COMPRA"
		Aadd( aHtml, { "cFixo013", PRT551066	 } ) // "Item"
		Aadd( aHtml, { "cFixo014", PRT551067	 } ) // "Produto"
		Aadd( aHtml, { "cFixo015", PRT551068	 } ) // "Descrição"
		//ESSAS DUAS COLUNAS FIXO066 E FIXO067 FORAM ALTERADAS PARA SEREM SEMPRE EXIBIDAS - ICARO 
		Aadd( aHtml, { "cFixo066", PRT551103	 } ) // "Centro de Custo"
		Aadd( aHtml, { "cFixo067", PRT551104	 } ) // "Conta Contábil"
		Aadd( aHtml, { "cFixo016", PRT551069	 } ) // "Quantidade"
		Aadd( aHtml, { "cFixo017", PRT551070	 } ) // "Valor Unitário"
		Aadd( aHtml, { "cFixo018", PRT551071	 } ) // "Valor Total"
		Aadd( aHtml, { "cFixo019", PRT551072	 } ) // "Data de Entrega"
		Aadd( aHtml, { "cFixo020", PRT551073	 } ) // "Valor de Tabela"
		Aadd( aHtml, { "cFixo021", PRT551074	 } ) // "OBSERVAÇÕES"
		Aadd( aHtml, { "cFixo022", PRT551075	 } ) // "TOTAIS"
		Aadd( aHtml, { "cFixo023", PRT551076	 } ) // "Valor Líquido"
		Aadd( aHtml, { "cFixo024", PRT551077	 } ) // "Valor IPI"
		Aadd( aHtml, { "cFixo025", PRT551071	 } ) // "Valor Total"
		Aadd( aHtml, { "cFixo026", PRT551078	 } ) // "Dados da Aprovação / Rejeição do Pedido"
		Aadd( aHtml, { "cFixo027", PRT551079	 } ) // "Quanto à Aprovação?"
		Aadd( aHtml, { "cFixo028", PRT551080	 } ) // "Aprovar"
		Aadd( aHtml, { "cFixo029", PRT551081	 } ) // "Rejeitar"
		Aadd( aHtml, { "cFixo030", PRT551082	 } ) // "Observações"
		Aadd( aHtml, { "cFixo031", PRT551083	 } ) // "Enviar"
		Aadd( aHtml, { "cFixo032", PRT551084	 } ) // "Limpar"
		Aadd( aHtml, { "cFixo033", PRT551085	 } ) // "Aguarde... Processando o envio do formulário..."
		Aadd( aHtml, { "cFixo034", cRodape		 } )

		If lVeloce
			Aadd( aHtml, { "cFixo035", PRT551086 } ) // "ÚLTIMOS 12 PREÇOS"
			Aadd( aHtml, { "cFixo036", PRT551087 } ) // "Produto"
			Aadd( aHtml, { "cFixo037", PRT551088 } ) // "Fornecedor"
			Aadd( aHtml, { "cFixo038", PRT551089 } ) // "Preço 01"
			Aadd( aHtml, { "cFixo039", PRT551090 } ) // "Preço 02"
			Aadd( aHtml, { "cFixo040", PRT551091 } ) // "Preço 03"
			Aadd( aHtml, { "cFixo041", PRT551092 } ) // "Preço 04"
			Aadd( aHtml, { "cFixo042", PRT551093 } ) // "Preço 05"
			Aadd( aHtml, { "cFixo043", PRT551094 } ) // "Preço 06"
			Aadd( aHtml, { "cFixo044", PRT551095 } ) // "Preço 07"
			Aadd( aHtml, { "cFixo045", PRT551096 } ) // "Preço 08"
			Aadd( aHtml, { "cFixo046", PRT551097 } ) // "Preço 09"
			Aadd( aHtml, { "cFixo047", PRT551098 } ) // "Preço 10"
			Aadd( aHtml, { "cFixo048", PRT551099 } ) // "Preço 11"
			Aadd( aHtml, { "cFixo049", PRT551100 } ) // "Preço 12"

			Aadd( aHtml, { "cFixo050", PRT551101 } ) // "OUTROS FORNECEDORES"
			Aadd( aHtml, { "cFixo051", PRT551087 } ) // "Produto"
			Aadd( aHtml, { "cFixo052", PRT551088 } ) // "Fornecedor"
			Aadd( aHtml, { "cFixo053", PRT551089 } ) // "Preço 01"
			Aadd( aHtml, { "cFixo054", PRT551090 } ) // "Preço 02"
			Aadd( aHtml, { "cFixo055", PRT551091 } ) // "Preço 03"
			Aadd( aHtml, { "cFixo056", PRT551092 } ) // "Preço 04"
			Aadd( aHtml, { "cFixo057", PRT551093 } ) // "Preço 05"
			Aadd( aHtml, { "cFixo058", PRT551094 } ) // "Preço 06"
			Aadd( aHtml, { "cFixo059", PRT551095 } ) // "Preço 07"
			Aadd( aHtml, { "cFixo060", PRT551096 } ) // "Preço 08"
			Aadd( aHtml, { "cFixo061", PRT551097 } ) // "Preço 09"
			Aadd( aHtml, { "cFixo062", PRT551098 } ) // "Preço 10"
			Aadd( aHtml, { "cFixo063", PRT551099 } ) // "Preço 11"
			Aadd( aHtml, { "cFixo064", PRT551100 } ) // "Preço 12"

			Aadd( aHtml, { "cFixo065", PRT551102 } ) // "COTAÇÃO: "
			Aadd( aHtml, { "cFixo068", PRT551105 } ) // "FORNECEDOR"
			Aadd( aHtml, { "cFixo069", PRT551106 } ) // "Código"
			Aadd( aHtml, { "cFixo070", PRT551107 } ) // "Loja"
			Aadd( aHtml, { "cFixo071", PRT551108 } ) // "Razão Social"
			Aadd( aHtml, { "cFixo072", PRT551109 } ) // "CPF/CNPJ"
			Aadd( aHtml, { "cFixo073", PRT551087 } ) // "Produto"
			Aadd( aHtml, { "cFixo074", PRT551110 } ) // "Preço"
			Aadd( aHtml, { "cFixo075", PRT551111 } ) // "Data"
			Aadd( aHtml, { "cFixo076", PRT551112 } ) // "Anexos"

			Aadd( aHtml, { "cFixo077", PRT551113 } ) // "FILA DE APROVAÇÃO"
			Aadd( aHtml, { "cFixo078", PRT551114 } ) // "Nível"
			Aadd( aHtml, { "cFixo079", PRT551115 } ) // "Aprovador Responsável"
			Aadd( aHtml, { "cFixo080", PRT551116 } ) // "Situação Atual"
			Aadd( aHtml, { "cFixo081", PRT551117 } ) // "Avaliado por"
			Aadd( aHtml, { "cFixo082", PRT551118 } ) // "Data Liberação"
			Aadd( aHtml, { "cFixo083", PRT551119 } ) // "Observações"

			Aadd( aHtml, { "cFixo084", Upper(PRT551143) } ) // "Arquivos Anexos"
		EndIf

	ElseIf cArqHtml == cWF0551Link

		If lVeloce
			Aadd( aHtml, { "cFixo001", cTitle	 } )
			Aadd( aHtml, { "cFixo002", PRT551120 } ) // "Você está recebendo processos de workflow que aguardam sua ação."
			Aadd( aHtml, { "cFixo003", PRT551121 } ) // "Pedido"
			Aadd( aHtml, { "cFixo004", PRT551088 } ) // "Fornecedor"
			Aadd( aHtml, { "cFixo005", cRodape	 } )
		Else
			Aadd( aHtml, { "cFixo001", cTitle	 } )
			Aadd( aHtml, { "cFixo002", PRT551122 } ) // "Você está recebendo um processo de workflow que aguarda sua ação."
			Aadd( aHtml, { "cFixo003", PRT551123 } ) // "Por favor, "
			Aadd( aHtml, { "cFixo004", PRT551124 } ) // "clique aqui"
			//ALTERADO POR ICARO DIA 24/11/2020
			Aadd( aHtml, { "cFixo005", cRodape   } )
		EndIf

	ElseIf cArqHtml == cWF0551Msg

		Aadd( aHtml, { "cFixo001", cTitle  } )
		Aadd( aHtml, { "cFixo002", cRodape } )

	ElseIf cArqHtml == cWF0551Rep

		Aadd( aHtml, { "cFixo001", cTitle    } )
		Aadd( aHtml, { "cFixo003", PRT551057 } ) // "Pedido de Compra"
		Aadd( aHtml, { "cFixo004", PRT551059 } ) // "Fornecedor"
		Aadd( aHtml, { "cFixo005", PRT551113 } ) // "FILA DE APROVAÇÃO"
		Aadd( aHtml, { "cFixo006", PRT551114 } ) // "Nível"
		Aadd( aHtml, { "cFixo007", PRT551115 } ) // "Aprovador Responsável"
		Aadd( aHtml, { "cFixo008", PRT551116 } ) // "Situação Atual"
		Aadd( aHtml, { "cFixo009", PRT551117 } ) // "Avaliado por"
		Aadd( aHtml, { "cFixo010", PRT551118 } ) // "Data Liberação"
		Aadd( aHtml, { "cFixo011", PRT551119 } ) // "Observações"
		Aadd( aHtml, { "cFixo002", cRodape   } )

	EndIf
/*
	Aadd(aCaracEsp, {"á","&aacute;"}) ; Aadd(aCaracEsp, {"Á","&Aacute;"}) ; Aadd(aCaracEsp, {"ã","&atilde;"}) ; Aadd(aCaracEsp, {"Ã","&Atilde;"})
	Aadd(aCaracEsp, {"â","&acirc;" }) ; Aadd(aCaracEsp, {"Â","&Acirc;" }) ; Aadd(aCaracEsp, {"à","&agrave;"}) ; Aadd(aCaracEsp, {"À","&Agrave;"})
	Aadd(aCaracEsp, {"é","&eacute;"}) ; Aadd(aCaracEsp, {"É","&Eacute;"}) ; Aadd(aCaracEsp, {"ê","&ecirc;" }) ; Aadd(aCaracEsp, {"Ê","&Ecirc;" })
	Aadd(aCaracEsp, {"í","&iacute;"}) ; Aadd(aCaracEsp, {"Í","&Iacute;"}) ; Aadd(aCaracEsp, {"ó","&oacute;"}) ; Aadd(aCaracEsp, {"Ó","&Oacute;"})
	Aadd(aCaracEsp, {"õ","&otilde;"}) ; Aadd(aCaracEsp, {"Õ","&Otilde;"}) ; Aadd(aCaracEsp, {"ô","&ocirc;" }) ; Aadd(aCaracEsp, {"Ô","&Ocirc;" })
	Aadd(aCaracEsp, {"ú","&uacute;"}) ; Aadd(aCaracEsp, {"Ú","&Uacute;"}) ; Aadd(aCaracEsp, {"ç","&ccedil;"}) ; Aadd(aCaracEsp, {"Ç","&Ccedil;"})
*/
	Aadd(aCaracEsp, {"Á","&Aacute;"}) ; Aadd(aCaracEsp, {"Ã","&Atilde;"}) ; Aadd(aCaracEsp, {"Â","&Acirc;" }) ; Aadd(aCaracEsp, {"À","&Agrave;"})
	Aadd(aCaracEsp, {"É","&Eacute;"}) ; Aadd(aCaracEsp, {"Ê","&Ecirc;" })
	Aadd(aCaracEsp, {"Í","&Iacute;"})
	Aadd(aCaracEsp, {"Ó","&Oacute;"}) ; Aadd(aCaracEsp, {"Õ","&Otilde;"}) ; Aadd(aCaracEsp, {"Ô","&Ocirc;" })
	Aadd(aCaracEsp, {"Ú","&Uacute;"})
	Aadd(aCaracEsp, {"Ç","&Ccedil;"})
	Aadd(aCaracEsp, {"©","&copy;"  })
	Aadd(aCaracEsp, {"®","&reg"    })

	For nI := 1 To Len(aHtml)
		aHtml[nI,2] := BSCEncode( aHtml[nI,2] )

		For nJ := 1 To Len(aCaracEsp)
			If aCaracEsp[nJ,1] $ aHtml[nI,2]
				aHtml[nI,2] := StrTran(aHtml[nI,2], aCaracEsp[nJ,1], aCaracEsp[nJ,2])
			EndIf
		Next nJ

		oProcess:oHtml:ValByName( aHtml[nI,1], aHtml[nI,2] )
	Next nI

Return(Nil)

/*/{Protheus.doc} fAdcVeloce
Dados adicionais para o Workflow (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param oProcess, objeto, Processo a ser ajustado
@param cPedido, caracter, Pedido de Compra
@param aProdutos, array, Produtos do pedido de compra
@param cDirRaizAn, caracter, Diretório raiz onde serão armazenados os anexos
@type function
/*/
Static Function fAdcVeloce(oProcess, cPedido, aProdutos, cDirRaizAn)

	Local aAreas		:= {}

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC7->(GetArea()))

	DbSelectArea("SC7")
	SC7->(DbSetOrder(1))
	If SC7->(DbSeek(xFilial('SC7') + cPedido))

		fUlt12Prc(@oProcess, aProdutos, cPedido)

		fOutrosFor(@oProcess, aProdutos)

//		fCotacoes(@oProcess, cPedido, cDirRaizAn)

		fAnexosPed(@oProcess, cPedido, cDirRaizAn)

		fFilaAprov(@oProcess, cPedido)

	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fUlt12Prc
Obtém informações de últimos 12 preços dos produtos (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param oProcess, objeto, Processo a ser ajustado
@param aProduto, array, Produtos do pedido de compra (em formato de array)
@param cPedido, character, Número do pedido de compra
@type function
/*/
Static Function fUlt12Prc(oProcess, aProdutos, cPedido)

	Local aAreas		:= {}
	Local aTam			:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()
	Local cPictPrec		:= PesqPict("SC7","C7_TOTAL")
	Local cVar			:= ""

	Local dFirstDate	:= FirstDate(SC7->C7_EMISSAO) // Primeiro dia do mês do Pedido de Compra

	Local nI			:= 0
	Local nQtdPrc		:= 0
	Local nQtdTotPrc	:= 12

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SA2->(GetArea()))

	If Len(aProdutos) > 0

		// -------------------
		// Exibe a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleU12P", "")

		For nI := 1 To Len(aProdutos)

			cQuery := " SELECT TOP 12 SB1.B1_DESC, SA2.A2_NOME, "											+ CRLF
			cQuery += " 	SUBSTRING(SC7.C7_EMISSAO,1,6) MES, SUM(SC7.C7_TOTAL) C7_TOTAL "					+ CRLF
			cQuery += " FROM " + RetSQLName("SC7") + " SC7 "												+ CRLF
			cQuery += " 	INNER JOIN " + RetSQLName("SA2") + " SA2 "										+ CRLF
			cQuery += " 		ON  SA2.A2_FILIAL = '" + xFilial("SA2") + "' "								+ CRLF
			cQuery += " 		AND SA2.A2_COD = SC7.C7_FORNECE "											+ CRLF
			cQuery += " 		AND SA2.A2_LOJA = SC7.C7_LOJA "												+ CRLF
			cQuery += " 		AND SA2.D_E_L_E_T_ <> '*' "													+ CRLF
			cQuery += " 	INNER JOIN " + RetSQLName("SB1") + " SB1 "										+ CRLF
			cQuery += " 		ON  SB1.B1_FILIAL = '" + xFilial("SB1") + "' "								+ CRLF
			cQuery += " 		AND SB1.B1_COD = SC7.C7_PRODUTO "											+ CRLF
			cQuery += " 		AND SB1.D_E_L_E_T_ <> '*' "													+ CRLF
			cQuery += " WHERE SC7.C7_FILIAL = '" + xFilial("SC7") + "' "									+ CRLF
			cQuery += " 	AND SC7.C7_PRODUTO = '" + aProdutos[nI] + "' "									+ CRLF
			cQuery += " 	AND SC7.C7_FORNECE + SC7.C7_LOJA = '" + SC7->C7_FORNECE + SC7->C7_LOJA + "' "	+ CRLF
			cQuery += " 	AND SC7.C7_EMISSAO < '" + DToS(dFirstDate) + "' "								+ CRLF
			cQuery += " 	AND SC7.C7_RESIDUO <> 'S' "														+ CRLF
			cQuery += " 	AND SC7.D_E_L_E_T_ <> '*' "														+ CRLF
			cQuery += " GROUP BY SB1.B1_DESC, SA2.A2_NOME, SUBSTRING(SC7.C7_EMISSAO,1,6) "					+ CRLF
			cQuery += " ORDER BY SUBSTRING(SC7.C7_EMISSAO,1,6) DESC "										+ CRLF

			If Select(cAliasQry) > 0
				(cAliasQry)->(DbCloseArea())
			EndIf

			DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)

			aTam := TamSX3("C7_TOTAL") ; TcSetField(cAliasQry, "C7_TOTAL", aTam[3], aTam[1], aTam[2])

			If (cAliasQry)->(EoF())
				// ----------------------------------------------------------------------
				// Caso não seja localizado nenhum registro, então insere apenas a
				// linha com o produto, fornecedor e valores zerados
				// ----------------------------------------------------------------------
				DbSelectArea("SB1")
				SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
				If SB1->(DbSeek(xFilial("SB1") + aProdutos[nI]))
					DbSelectArea("SA2")
					SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
					If SA2->(DbSeek(xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA))
						AAdd(oProcess:oHtml:ValByName('U12P.cProd'), SB1->B1_DESC)
						AAdd(oProcess:oHtml:ValByName('U12P.cForn'), SA2->A2_NOME)

						nQtdPrc := 0

						While nQtdPrc < nQtdTotPrc
							nQtdPrc++

							cVar := 'U12P.nPrc' + StrZero(nQtdPrc,2)

							AAdd(oProcess:oHtml:ValByName(cVar), Transform(0,cPictPrec))
						EndDo
					EndIf
				EndIf
			Else
				While !(cAliasQry)->(EoF())
					AAdd(oProcess:oHtml:ValByName('U12P.cProd'), (cAliasQry)->B1_DESC)
					AAdd(oProcess:oHtml:ValByName('U12P.cForn'), (cAliasQry)->A2_NOME)

					nQtdPrc := 0

					While !(cAliasQry)->(EoF()) .And. nQtdPrc < nQtdTotPrc
						nQtdPrc++

						cVar := 'U12P.nPrc' + StrZero(nQtdPrc,2)

						AAdd(oProcess:oHtml:ValByName(cVar), Transform((cAliasQry)->C7_TOTAL,cPictPrec))

						(cAliasQry)->(DbSkip())
					EndDo

					// ---------------------------------------------
					// Ajusta para a quantidade total de preços
					// ---------------------------------------------
					While nQtdPrc < nQtdTotPrc
						nQtdPrc++

						cVar := 'U12P.nPrc' + StrZero(nQtdPrc,2)

						AAdd(oProcess:oHtml:ValByName(cVar), Transform(0,cPictPrec))
					EndDo
				EndDo

				(cAliasQry)->(DbCloseArea())
			EndIf
		Next nI

	Else

		// -------------------
		// Oculta a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleU12P", "style='display:none'")

	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fOutrosFor
Obtém informações de outros fornecedores que venderam o produto (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param oProcess, objeto, Processo a ser ajustado
@param aProdutos, Array, Produtos do pedido de compra (em formato de array)
@type function
/*/
Static Function fOutrosFor(oProcess, aProdutos)

	Local aAreas		:= {}
	Local aTam			:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()
	Local cFornecedor	:= ""
	Local cLojaFornec	:= ""
	Local cPictPrec		:= PesqPict("SC7","C7_TOTAL")
	Local cVar			:= ""

	Local dFirstDate	:= FirstDate(SC7->C7_EMISSAO) // Primeiro dia do mês do Pedido de Compra

	Local lExibeOutF	:= .F.

	Local nI			:= 0
	Local nQtdPrc		:= 0
	Local nQtdTotPrc	:= 12

	Aadd(aAreas, GetArea())

	If Len(aProdutos) > 0

		For nI := 1 To Len(aProdutos)

			cQuery := " SELECT TOP 12 SB1.B1_DESC, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, "					+ CRLF
			cQuery += " 	SUBSTRING(SC7.C7_EMISSAO,1,6) MES, SUM(SC7.C7_TOTAL) C7_TOTAL "					+ CRLF
			cQuery += " FROM " + RetSQLName("SC7") + " SC7 "												+ CRLF
			cQuery += " 	INNER JOIN " + RetSQLName("SA2") + " SA2 "										+ CRLF
			cQuery += " 		ON  SA2.A2_FILIAL = '" + xFilial("SA2") + "' "								+ CRLF
			cQuery += " 		AND SA2.A2_COD = SC7.C7_FORNECE "											+ CRLF
			cQuery += " 		AND SA2.A2_LOJA = SC7.C7_LOJA "												+ CRLF
			cQuery += " 		AND SA2.D_E_L_E_T_ <> '*' "													+ CRLF
			cQuery += " 	INNER JOIN " + RetSQLName("SB1") + " SB1 "										+ CRLF
			cQuery += " 		ON  SB1.B1_FILIAL = '" + xFilial("SB1") + "' "								+ CRLF
			cQuery += " 		AND SB1.B1_COD = SC7.C7_PRODUTO "											+ CRLF
			cQuery += " 		AND SB1.D_E_L_E_T_ <> '*' "													+ CRLF
			cQuery += " WHERE SC7.C7_FILIAL = '" + xFilial("SC7") + "' "									+ CRLF
			cQuery += " 	AND SC7.C7_PRODUTO = '" + aProdutos[nI] + "' "									+ CRLF
			cQuery += " 	AND SC7.C7_FORNECE + SC7.C7_LOJA <> '" + SC7->C7_FORNECE + SC7->C7_LOJA + "' "	+ CRLF
			cQuery += " 	AND SC7.C7_EMISSAO < '" + DToS(dFirstDate) + "' "								+ CRLF
			cQuery += " 	AND SC7.C7_RESIDUO <> 'S' "														+ CRLF
			cQuery += " 	AND SC7.D_E_L_E_T_ <> '*' "														+ CRLF
			cQuery += " GROUP BY SB1.B1_DESC, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, "						+ CRLF
			cQuery += " 	SUBSTRING(SC7.C7_EMISSAO,1,6) "													+ CRLF
			cQuery += " ORDER BY SA2.A2_COD ASC, SA2.A2_LOJA ASC, SUBSTRING(SC7.C7_EMISSAO,1,6) DESC "		+ CRLF

			If Select(cAliasQry) > 0
				(cAliasQry)->(DbCloseArea())
			EndIf

			DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)

			aTam := TamSX3("C7_TOTAL") ; TcSetField(cAliasQry, "C7_TOTAL", aTam[3], aTam[1], aTam[2])

			If !(cAliasQry)->(EoF())

				If !lExibeOutF
					// -------------------
					// Exibe a table
					// -------------------
					oProcess:oHtml:ValByName("cStyleOUTF", "")

					lExibeOutF := .T.
				EndIf

				While !(cAliasQry)->(EoF())
					AAdd(oProcess:oHtml:ValByName('OUTF.cProd'), (cAliasQry)->B1_DESC)
					AAdd(oProcess:oHtml:ValByName('OUTF.cForn'), (cAliasQry)->A2_NOME)

					cFornecedor := (cAliasQry)->A2_COD
					cLojaFornec := (cAliasQry)->A2_LOJA
					nQtdPrc := 0

					While !(cAliasQry)->(EoF()) .And. cFornecedor == (cAliasQry)->A2_COD .And. cLojaFornec == (cAliasQry)->A2_LOJA .And. nQtdPrc < nQtdTotPrc
						nQtdPrc++

						cVar := 'OUTF.nPrc' + StrZero(nQtdPrc,2)

						AAdd(oProcess:oHtml:ValByName(cVar), Transform((cAliasQry)->C7_TOTAL,cPictPrec))

						(cAliasQry)->(DbSkip())
					EndDo

					// ---------------------------------------------
					// Ajusta para a quantidade total de preços
					// ---------------------------------------------
					While nQtdPrc < nQtdTotPrc
						nQtdPrc++

						cVar := 'OUTF.nPrc' + StrZero(nQtdPrc,2)

						AAdd(oProcess:oHtml:ValByName(cVar), Transform(0,cPictPrec))
					EndDo

					If nI < Len(aProdutos) .And. (cAliasQry)->(EoF())
						// --------------------------------------------------------------------
						// Gera linha vazia, apenas para separar os dados de outro produto
						// --------------------------------------------------------------------
						AAdd(oProcess:oHtml:ValByName('OUTF.cProd'), " - ")
						AAdd(oProcess:oHtml:ValByName('OUTF.cForn'), " ")

						nQtdPrc := 0

						While nQtdPrc < nQtdTotPrc
							nQtdPrc++

							cVar := 'OUTF.nPrc' + StrZero(nQtdPrc,2)

							AAdd(oProcess:oHtml:ValByName(cVar), " ")
						EndDo
					EndIf
				EndDo
			EndIf

		Next nI

		If Select(cAliasQry) > 0
			(cAliasQry)->(DbCloseArea())
		EndIf

		// -----------------------------------------------------------------------------
		// A variável lExibeOutF indica se deve ser exibido o box Outros Fornecedores
		// -----------------------------------------------------------------------------
		If !lExibeOutF
			oProcess:oHtml:ValByName("cStyleOUTF", "style='display:none'")
		EndIf

	Else

		// -------------------
		// Oculta a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleOUTF", "style='display:none'")

	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fCotacoes
Obtém informações das cotações (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param oProcess, objeto, Processo a ser ajustado
@param cNumPed, caracter, Pedido de compra
@param cDirRaizAn, caracter, Diretório raiz onde serão armazenados os anexos
@type function
/*/
Static Function fCotacoes(oProcess, cNumPed, cDirRaizAn)

	Local aAreas		:= {}
	Local aTam			:= {}
	Local aAnexos		:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()
	Local cPictPrec		:= PesqPict("SC8","C8_PRECO")
	Local cCPF_CNPJ		:= ""
	Local cFornecedor 	:= ""
	Local cLojaFornec 	:= ""
	Local cDirAnexo		:= ""

	Local nPosAnexo		:= 0

	Aadd(aAreas, GetArea())

	cQuery := " SELECT SC8.C8_NUM, SC8.C8_ITEM, SC8.C8_FORNECE, SC8.C8_LOJA, "	+ CRLF
	cQuery += " 	SA2.A2_NOME, SA2.A2_TIPO, SA2.A2_CGC, SC8.C8_PRODUTO, "		+ CRLF
	cQuery += " 	SB1.B1_DESC, SC8.C8_PRECO, SC8.C8_EMISSAO " 				+ CRLF
	cQuery += " FROM " + RetSQLName("SC8") + " SC8 " 							+ CRLF
	cQuery += " 	INNER JOIN " + RetSQLName("SA2") + " SA2 " 					+ CRLF
	cQuery += " 		ON  SA2.A2_FILIAL = '" + xFilial("SA2") + "' " 			+ CRLF
	cQuery += " 		AND SA2.A2_COD = SC8.C8_FORNECE " 						+ CRLF
	cQuery += " 		AND SA2.A2_LOJA = SC8.C8_LOJA " 						+ CRLF
	cQuery += " 		AND SA2.D_E_L_E_T_ <> '*' " 							+ CRLF
	cQuery += " 	INNER JOIN " + RetSQLName("SB1") + " SB1 " 					+ CRLF
	cQuery += " 		ON  SB1.B1_FILIAL = '" + xFilial("SB1") + "' " 			+ CRLF
	cQuery += " 		AND SB1.B1_COD = SC8.C8_PRODUTO " 						+ CRLF
	cQuery += " 		AND SB1.D_E_L_E_T_ <> '*' " 							+ CRLF
	cQuery += " WHERE SC8.C8_FILIAL = '" + xFilial("SC8") + "' " 				+ CRLF
	cQuery += " 	AND SC8.C8_NUM IN " 										+ CRLF
	cQuery += " 	( " 														+ CRLF
	cQuery += " 	SELECT DISTINCT SC7.C7_NUMCOT " 							+ CRLF
	cQuery += " 	FROM " + RetSQLName("SC7") + " SC7 " 						+ CRLF
	cQuery += " 	WHERE SC7.C7_FILIAL = '" + xFilial("SC7") + "' " 			+ CRLF
	cQuery += " 		AND SC7.C7_NUM = '" + cNumPed + "' " 					+ CRLF
	cQuery += " 		AND SC7.D_E_L_E_T_ <> '*' " 							+ CRLF
	cQuery += " 	) " 														+ CRLF
	//A linha abaixo foi comentada por solicitação Marcos dia 22/07/2019
	//cQuery += " 	AND SC8.C8_NUMPED <> '" + cNumPed + "' " 					+ CRLF
	cQuery += " 	AND SC8.D_E_L_E_T_ <> '*' " 								+ CRLF
	cQuery += " ORDER BY SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_ITEM " 			+ CRLF

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)

	aTam := TamSX3("C8_PRECO")   ; TcSetField(cAliasQry, "C8_PRECO"  , aTam[3], aTam[1], aTam[2])
	aTam := TamSX3("C8_EMISSAO") ; TcSetField(cAliasQry, "C8_EMISSAO", aTam[3], aTam[1], aTam[2])

	If !(cAliasQry)->(EoF())

		cDirAnexo := fNovoDiret(cDirRaizAn)

		aAnexos := fRetAnexo(cDirAnexo, (cAliasQry)->C8_NUM, cNumPed)

		// ----------------------------------------------------------------------
		// Caso não encontre anexos, apaga o diretório criado para o processo
		// ----------------------------------------------------------------------
		If Empty(aAnexos)
			DirRemove(cDirAnexo)
		EndIf

		// -------------------
		// Exibe a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleCOTA", "")

		oProcess:oHtml:ValByName('cNumCot', (cAliasQry)->C8_NUM)

		While !(cAliasQry)->(EoF())
			If !Empty((cAliasQry)->A2_CGC)
				If (cAliasQry)->A2_TIPO == "F"
					cCPF_CNPJ := AllTrim(Transform((cAliasQry)->A2_CGC, "@R 99.999.999/9999-99"))
				Else
					cCPF_CNPJ := AllTrim(Transform((cAliasQry)->A2_CGC, "@R 999.999.999-99"))
				EndIf
			Else
				cCPF_CNPJ := ""
			EndIf

			AAdd(oProcess:oHtml:ValByName("COTA.cCodFornec"), (cAliasQry)->C8_FORNECE)
			AAdd(oProcess:oHtml:ValByName("COTA.cLojaFornec"), (cAliasQry)->C8_LOJA)
			AAdd(oProcess:oHtml:ValByName("COTA.cRazaoSocial"), (cAliasQry)->A2_NOME)
			AAdd(oProcess:oHtml:ValByName("COTA.cCNPJ"), cCPF_CNPJ)
			AAdd(oProcess:oHtml:ValByName("COTA.cProd"), (cAliasQry)->B1_DESC)
			AAdd(oProcess:oHtml:ValByName("COTA.nPreco"), Transform((cAliasQry)->C8_PRECO,cPictPrec))
			AAdd(oProcess:oHtml:ValByName("COTA.dData"), DToC((cAliasQry)->C8_EMISSAO))

			If (nPosAnexo := AScan(aAnexos, {|x| x[1] + x[2] + x[3] == (cAliasQry)->(C8_FORNECE + C8_LOJA + C8_ITEM)})) > 0
				AAdd(oProcess:oHtml:ValByName("COTA.cLinkAnexo"), aAnexos[nPosAnexo,4] + aAnexos[nPosAnexo,5])
				AAdd(oProcess:oHtml:ValByName("COTA.cAnexo"), aAnexos[nPosAnexo,5])
			Else
				AAdd(oProcess:oHtml:ValByName("COTA.cLinkAnexo"), "")
				AAdd(oProcess:oHtml:ValByName("COTA.cAnexo"), "")
			EndIf

			cFornecedor := (cAliasQry)->C8_FORNECE
			cLojaFornec := (cAliasQry)->C8_LOJA

			(cAliasQry)->(DbSkip())

			// --------------------------------------------------------------------
			// Gera linha vazia, apenas para separar os dados de outro fornecedor
			// --------------------------------------------------------------------
			If !(cAliasQry)->(EoF())
				If cFornecedor != (cAliasQry)->C8_FORNECE .Or. cLojaFornec != (cAliasQry)->C8_LOJA
					AAdd(oProcess:oHtml:ValByName("COTA.cCodFornec"), " - ")
					AAdd(oProcess:oHtml:ValByName("COTA.cLojaFornec"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.cRazaoSocial"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.cCNPJ"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.cProd"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.nPreco"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.dData"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.cLinkAnexo"), "")
					AAdd(oProcess:oHtml:ValByName("COTA.cAnexo"), "")
				EndIf
			EndIf
		EndDo
	Else

		// -------------------
		// Oculta a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleCOTA", "style='display:none'")

	EndIf

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fAnexosPed
Obtém informações dos anexos do Pedido de compra (Específico Veloce).
@author Juliano Fernandes
@since 14/08/2019
@param oProcess, objeto, Processo a ser ajustado
@param cNumPed, caracter, Pedido de compra
@param cDirRaizAn, caracter, Diretório raiz onde serão armazenados os anexos
@type function
/*/
Static Function fAnexosPed(oProcess, cNumPed, cDirRaizAn)

	Local aAreas		:= {}
	Local aAnexos		:= {}

	Local cDirAnexo		:= ""

	Local nI			:= 0

	Aadd(aAreas, GetArea())

	cDirAnexo := fNovoDiret(cDirRaizAn, cNumPed)

	aAnexos := fRetAnexPed(cDirAnexo, cNumPed)

	If !Empty(aAnexos)

		// -------------------
		// Exibe a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleANEXO", "")

		For nI := 1 To Len(aAnexos)
			AAdd(oProcess:oHtml:ValByName("ANEXO.cLinkAnexo"), aAnexos[nI,1] + aAnexos[nI,3])
			AAdd(oProcess:oHtml:ValByName("ANEXO.cTexto"), PRT551144) // "Visualizar arquivo"
			AAdd(oProcess:oHtml:ValByName("ANEXO.cAnexo"), aAnexos[nI,2])
		Next nI

	Else

		// ----------------------------------------------------------------------
		// Caso não encontre anexos, apaga o diretório criado para o processo
		// ----------------------------------------------------------------------
		DirRemove(cDirAnexo)

		// -------------------
		// Oculta a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleANEXO", "style='display:none'")

	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fFilaAprov
Obtém informações da fila de aprovação (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param oProcess, objeto, Processo a ser ajustado
@param cNumPed, caracter, Pedido de compra
@type function
/*/
Static Function fFilaAprov(oProcess, cNumPed)

	Local aAreas		:= {}
	Local aTam			:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()
	Local cNivel		:= ""

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SCR->(GetArea()))

	// ---------------------------------------------------------------------------------------
	// Busca as filas de aprovação já respondidas
	// ---------------------------------------------------------------------------------------
	cQuery := " SELECT SCR.CR_NIVEL, SCR.CR_USER, SCR.CR_STATUS, " 						+ CRLF
	cQuery += " 	SCR.CR_USERLIB, SCR.CR_DATALIB, " 									+ CRLF
	cQuery += " 	SCR.R_E_C_N_O_ SCRRECNO " 											+ CRLF
	cQuery += " FROM " + RetSQLName("SCR") + " SCR " 									+ CRLF
	cQuery += " WHERE SCR.CR_FILIAL = '" + xFilial("SCR") + "' " 						+ CRLF
	cQuery += " 	AND SCR.CR_TIPO = 'PC' " 											+ CRLF
	cQuery += " 	AND SCR.CR_NUM = '" + cNumPed + "' " 								+ CRLF
	cQuery += " 	AND SCR.CR_DATALIB <> '" + Space(TamSX3("CR_DATALIB")[1]) + "' "	+ CRLF
	cQuery += " 	AND SCR.CR_USERLIB <> '" + Space(TamSX3("CR_USERLIB")[1]) + "' "	+ CRLF
	cQuery += " 	AND SCR.CR_LIBAPRO <> '" + Space(TamSX3("CR_LIBAPRO")[1]) + "' "	+ CRLF
	cQuery += " 	AND SCR.D_E_L_E_T_ = '*' " 											+ CRLF

	cQuery += " UNION " 																+ CRLF

	// ---------------------------------------------------------------------------------------
	// Busca a fila de aprovação pendente de aprovação / reprovação
	// ---------------------------------------------------------------------------------------
	cQuery += " SELECT SCR.CR_NIVEL, SCR.CR_USER, SCR.CR_STATUS, " 						+ CRLF
	cQuery += " 	SCR.CR_USERLIB, SCR.CR_DATALIB, " 									+ CRLF
	cQuery += " 	SCR.R_E_C_N_O_ SCRRECNO " 											+ CRLF
	cQuery += " FROM " + RetSQLName("SCR") + " SCR " 									+ CRLF
	cQuery += " WHERE SCR.CR_FILIAL = '" + xFilial("SCR") + "' " 						+ CRLF
	cQuery += " 	AND SCR.CR_TIPO = 'PC' " 											+ CRLF
	cQuery += " 	AND SCR.CR_NUM = '" + cNumPed + "' " 								+ CRLF
	cQuery += " 	AND SCR.D_E_L_E_T_ <> '*' " 										+ CRLF
	cQuery += " ORDER BY SCR.R_E_C_N_O_ " 												+ CRLF

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)

	aTam := TamSX3("CR_DATALIB") 	; TcSetField(cAliasQry, "CR_DATALIB", aTam[3], aTam[1], aTam[2])
	aTam := {17, 0, "N"}			; TcSetField(cAliasQry, "SCRRECNO"  , aTam[3], aTam[1], aTam[2])

	If !(cAliasQry)->(EoF())

		// -------------------
		// Exibe a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleFILA", "")

		While !(cAliasQry)->(EoF())
			AAdd(oProcess:oHtml:ValByName("FILA.cNivel"), (cAliasQry)->CR_NIVEL)
			AAdd(oProcess:oHtml:ValByName("FILA.cAprov"), UsrRetName((cAliasQry)->CR_USER))
			AAdd(oProcess:oHtml:ValByName("FILA.cStatus"), fGetSituac((cAliasQry)->CR_STATUS))
			AAdd(oProcess:oHtml:ValByName("FILA.cUserLib"), UsrRetName((cAliasQry)->CR_USERLIB))
			AAdd(oProcess:oHtml:ValByName("FILA.dDtLib"), IIf(!Empty((cAliasQry)->CR_DATALIB), DToC((cAliasQry)->CR_DATALIB), ""))

			SCR->(DbGoto((cAliasQry)->SCRRECNO))
			AAdd(oProcess:oHtml:ValByName("FILA.cObs"), AllTrim(SCR->CR_OBS))

			cNivel := (cAliasQry)->CR_NIVEL

			(cAliasQry)->(DbSkip())

			// ----------------------------------------------------------------------------
			// Gera linha vazia, apenas para separar os dados de outra fila de aprovação
			// ----------------------------------------------------------------------------
			If !(cAliasQry)->(EoF())
				If cNivel > (cAliasQry)->CR_NIVEL
					AAdd(oProcess:oHtml:ValByName("FILA.cNivel"), "")
					AAdd(oProcess:oHtml:ValByName("FILA.cAprov"), "")
					AAdd(oProcess:oHtml:ValByName("FILA.cStatus"), "")
					AAdd(oProcess:oHtml:ValByName("FILA.cUserLib"), "")
					AAdd(oProcess:oHtml:ValByName("FILA.dDtLib"), "")
					AAdd(oProcess:oHtml:ValByName("FILA.cObs"), "")
				EndIf
			EndIf
		EndDo

	Else

		// -------------------
		// Oculta a table
		// -------------------
		oProcess:oHtml:ValByName("cStyleFILA", "style='display:none'")

	EndIf

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fGetSituac
Função de retorno da descrição da situação de um determinado nível da fila de aprovação (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param cStatus, caracter, Status a ser pesquisado
@return cSituaca, Descrição da situação
@type function
/*/
Static function fGetSituac(cStatus)

	Local cSituacao := ""

	Do Case
		Case cStatus == "01"
			cSituacao := PRT551126 // "Aguardando nivel anterior"
		Case cStatus == "02"
			cSituacao := PRT551127 // "Pendente"
		Case cStatus == "03"
			cSituacao := PRT551128 // "Liberado"
		Case cStatus == "04"
			cSituacao := PRT551129 // "Bloqueado"
		Case cStatus == "05"
			cSituacao := PRT551130 // "Liberado outro usuario"
		Case cStatus == "06"
			cSituacao := PRT551131 // "Rejeitado"
	EndCase

Return(cSituacao)

/*/{Protheus.doc} f551Sched
Função de execução via Schedule (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@type function
/*/
User Function f551Sched(aParams)
	Local aAreaSC7		:= {}
	Local aPedidos		:= {}
	Local aAux			:= {}
	Local aSchedWF		:= {}

	Local cSchedEmp		:= ""
	Local cSchedFil		:= ""
	Local cAliasQry		:= ""
	Local cErro			:= ""
	Local cEmailDest	:= ""
	Local cPedido		:= ""
	Local cFornecedor	:= ""
	//Local cUrlHtml		:= ""

	Local lOk			:= .T.
	Local lPrepareEnv	:= .F.
	Local lSchedule		:= .T.

	Local nI 			:= 0
	Local nJ			:= 0

	Default aParams		:= {}

	If !Empty(aParams)
		cSchedEmp := aParams[1]
		cSchedFil := aParams[2]
		If Select("SX2") == 0
			If !fPrepEnv(@cErro, cSchedEmp, cSchedFil)
				lOk := .F.
				ConOut(cErro)
			Else
				lPrepareEnv := .T.
			EndIf
		EndIf

		If lOk

			// ------------------------------------------------------------------------------------------------
			// Busca os Pedidos de Compra ainda não processados, ou seja, que não houve o envio do Workflow
			// ------------------------------------------------------------------------------------------------
			cAliasQry := GetNextAlias()

			BeginSQL Alias cAliasQry
				SELECT 		DISTINCT SC7.C7_NUM
				FROM 		%Table:SC7% SC7
				WHERE 		SC7.C7_FILIAL	=  %xFilial:SC7%	AND
							SC7.C7_XGRPAPR	<> %Exp:'      '%	AND
							SC7.C7_XENVWF	=  %Exp:'N'% 		AND
							SC7.%NotDel%
				ORDER BY	SC7.C7_NUM
			EndSQL

			(cAliasQry)->(DbEval({|| Aadd( aPedidos, (cAliasQry)->C7_NUM )},, {|| !Eof()}))
			(cAliasQry)->(DbCloseArea())

			// -----------------------------------------------------------------
			// Monta todo o processo do Workflow de Pedido de Compra, porém
			// não será gerado o link e o e-mail ainda não será enviado.
			// -----------------------------------------------------------------
			For nI := 1 To Len(aPedidos)
				// -----------------------------------------------------
				// aAux[1] = Endereço de e-mail do destinatário
				// aAux[2] = Url do arquivo Html gerado
				// -----------------------------------------------------
				aAux := AClone( f551Send(aPedidos[nI], lSchedule) )

				For nJ := 1 To Len(aAux)
					Aadd( aSchedWF, {	aAux[nJ,1]		,;  // Email destinatário
										aPedidos[nI]	,; 	// Número do Pedido de Compra
										aAux[nJ,2]		})	// Url do processo workflow
				Next nJ
			Next nI

			// --------------------------------------------------
			// Organiza o array por e-mail do destinatário
			// (Ordem crescente)
			// --------------------------------------------------
			ASort(aSchedWF,,,{|x,y| x[1] + x[2] < y[1] + y[2]})

			DbSelectArea("SC7")
			SC7->(DbSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN

			DbSelectArea("SA2")
			SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA

			nI := 1

			While nI <= Len(aSchedWF)
				aAux := {}
				cEmailDest := ""

				// -------------------------------------------------------------------------------------
				// Separa os dados para envio a montagem do link com os pedidos de mesmo destinatário
				// -------------------------------------------------------------------------------------
				While nI <= Len(aSchedWF) .And. (Empty(cEmailDest) .Or. cEmailDest == aSchedWF[nI,1])
					If Empty(cEmailDest)
						cEmailDest := aSchedWF[nI,1]
					EndIf

					cPedido := aSchedWF[nI,2]
					cFornecedor := ""

					If SC7->(DbSeek(xFilial("SC7") + cPedido))
						If SA2->(DbSeek(xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA))
							cFornecedor := SA2->A2_NOME
						EndIf
					EndIf

					cUrl := aSchedWF[nI,3]

					Aadd(aAux, {cPedido, cFornecedor, cUrl})

					nI++
				EndDo

				// --------------------------------------------------------
				// Monta o link para envio do e-mail ao destinatário
				// --------------------------------------------------------
				If !Empty(aAux) .And. !Empty(cEmailDest)
					f551WFLink( aAux, cEmailDest )
				EndIf
			EndDo

			// -----------------------------------------------------------
			// Atualiza os Pedidos de Compra com o status de "Enviado"
			// -----------------------------------------------------------
			DbSelectArea("SC7")
			SC7->(DbSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN

			For nI := 1 To Len(aPedidos)
				If SC7->(DbSeek(xFilial("SC7") + aPedidos[nI]))
					aAreaSC7 := SC7->(GetArea())

					While !SC7->(EoF()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == aPedidos[nI]
						SC7->(Reclock("SC7", .F.))
							SC7->C7_XENVWF := 'S'
						SC7->(MsUnlock())

						SC7->(DbSkip())
					EndDo

					RestArea(aAreaSC7)

				EndIf
			Next nI
		EndIf

		If lPrepareEnv
			RpcClearEnv()
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fPrepEnv
Realiza a preparação do ambiente para o processamento de registros.
@type function
@author Juliano Fernandes
@since 01/02/2019
@version 1.0
@param cSchedErro, caracter, Variavel para a gravação de erros
@param cSchedEmp, caracter, Código da empresa
@param cSchedFil, caracter, Código da filial
@return lPrepEnv, Indica se obteve sucesso na preparação do ambiente
/*/
Static Function fPrepEnv(cSchedErro, cSchedEmp, cSchedFil)

	Local aSchedTab 	:= {}

	Local cSchedMod		:= "COM"
	Local cSchedUser	:= Nil
	Local cSchedPsw		:= Nil

	Local lPrepEnv		:= .T.

	Aadd(aSchedTab, "SC7")
	Aadd(aSchedTab, "SCR")
	Aadd(aSchedTab, "SA2")
	Aadd(aSchedTab, "SB1")

	RpcSetType(3)
	If !RpcSetEnv(cSchedEmp,cSchedFil,cSchedUser,cSchedPsw,cSchedMod,,aSchedTab)
		lPrepEnv := .F.

		cSchedErro += PRT551132	+ CRLF //"Erro na abertura do ambiente"
		cSchedErro += PRT551133 + cSchedEmp + CRLF //"Empresa: "
		cSchedErro += PRT551134 + cSchedFil + CRLF //"Filial:  "
	EndIf

Return(lPrepEnv)

/*/{Protheus.doc} f551WFLink
Função que realiza a montagem do Link com um ou mais Pedidos de Compra (Específico Veloce).
@author Juliano Fernandes
@since 10/07/2019
@param aDadosLink, array, Array contendo informações para a geração dos links
@param cMailApr, caracter, E-mail do usuário aprovador
@type function
/*/
Static Function f551WFLink(aDadosLink, cMailApr)

	Local cArqLink		:= fGetDirTem() + cWF0551Link
	Local cNumPC		:= ""
	Local cFornecedor	:= ""
	Local cUrl 			:= ""

	Local lVeloce 		:= SuperGetMV('PLG_WFVELO',,.F.)

	Local nI			:= 0

	Local oProcess 		:= Nil

	// -------------------------------
	// Monta processo do link
	// -------------------------------
	oProcess := TWFProcess():New('APR_PC')

	// ---------------------------------------------------------
	// Nova tarefa para envio do e-mail com
	// o link do processo:
	// ---------------------------------------------------------
	oProcess:NewTask('PLGWFPC02', cArqLink)

	// ----------------------------------------------------------------
	// Monta layout HTML conforme o País (variável pública cPaisLoc)
	// ----------------------------------------------------------------
	fLayoutHtml(@oProcess, cWF0551Link)

	For nI := 1 To Len(aDadosLink)
		cNumPC		:= aDadosLink[nI,1]
		cFornecedor	:= aDadosLink[nI,2]
		cUrl 		:= aDadosLink[nI,3]

		If lVeloce
			oProcess:oHtml:ValByName('cTitle', BSCEncode(PRT551135)) //"Aprovação de Pedido de Compra"

			AAdd(oProcess:oHtml:ValByName('PC.cLink'), cUrl)
			AAdd(oProcess:oHtml:ValByName('PC.cPedido'), cNumPC)
			AAdd(oProcess:oHtml:ValByName('PC.cFornecedor'), cFornecedor)

			// ---------------------------------------------------------
			// Titulo para o email:
			// ---------------------------------------------------------
			oProcess:cSubject := PRT551135
		Else
			//Alterado por ICARO dia 24/11/2020 pois o link estava sendo gerado erradamente
			oProcess:oHtml:ValByName('cTitle', BSCEncode(PRT551136 + cNumPC)) //"Aprovação de Pedido de Compra No. "
			AAdd(oProcess:oHtml:ValByName('PC.cLink'), cUrl)
			AAdd(oProcess:oHtml:ValByName('PC.cPedido'), cNumPC)
			AAdd(oProcess:oHtml:ValByName('PC.cFornecedor'), cFornecedor)
			
			// ---------------------------------------------------------
			// Titulo para o email:
			// ---------------------------------------------------------
			oProcess:cSubject := PRT551136 + cNumPC //"Aprovação de Pedido de Compra No. "
		EndIf
	Next nI

	// ---------------------------------------------------------
	// Determina o destinatario do e-mail de
	// aprovacao:
	// ---------------------------------------------------------
	oProcess:cTo := cMailApr

	// ---------------------------------------------------------
	// Envia o e-mail com link para aprovacao
	// ---------------------------------------------------------
	oProcess:Start()

	// ------------------------------
	// Finaliza o processo do link
	// ------------------------------
	oProcess:Finish()

	// ---------------------------------------------------------
	// Libera Objeto
	// ---------------------------------------------------------
	oProcess:Free()
	oProcess := Nil

Return(Nil)

/*/{Protheus.doc} fNovoDiret
Cria novo diretório onde serão armazenados os anexos do processo.
@author Juliano Fernandes
@since 10/07/2019
@param cDirRaiz, caracter, Diretório raiz onde será criada a nova pasta
@return cDiretorio, Diretório gerado
@type function
/*/
Static Function fNovoDiret(cDirRaiz, cNumPed)

	Local aFiles		:= {}
	Local cDiretorio 	:= ""

	cDiretorio := cDirRaiz + cBarra
	cDiretorio += cEmpAnt + cFilAnt + cNumPed

	If ExistDir(cDiretorio)
		aFiles := Directory(cDiretorio + cBarra + "*.*")

		AEval(aFiles,{|x| FErase(cDiretorio + cBarra + x[1])})
	Else
		MakeDir(cDiretorio)
	EndIf

	cDiretorio += cBarra

Return(cDiretorio)

/*/{Protheus.doc} fRetAnexo
Responsável por retornar o anexo da cotação
@author Icaro Laudade
@since 10/07/2019
@return aRetObj, Array com duas posições
@param cPath, characters, caminho a ser salvo o anexo
@param cNumCot, characters, Número da Cotação
@param cNumPed, characters, Número do pedido de compra
@type function
/*/
Static Function fRetAnexo(cPath, cNumCot, cNumPed)
	Local aAreaSA2		:=	SA2->(GetArea())
	Local aAreaAC9		:=	AC9->(GetArea())
	Local aAreaACB		:=	ACB->(GetArea())
	Local aDiretorio	:=	{}
	Local aFiles		:=	{}
	Local aRetObj		:=	{}
	Local cCodEnt		:=	""
	Local cCodObj		:=	""
	Local cCompAnexo	:=	""
	Local cItem			:=	""
	Local cItemGrd		:=	""
	Local cFornece		:=	""
	Local cLoja			:=	""
	Local cPathAnexo	:=	""
	Local cQuery		:=	""
	Local cTmpAlias		:=	GetNextAlias()
	Local nI			:=	0
	Local nMakeDir		:=	0

	If ExistDir(cPath)

		cQuery := " SELECT SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_ITEM, SC8.C8_ITEMGRD "		+ CRLF
		cQuery += " FROM " + RetSQLName("SC8") + " SC8 "									+ CRLF
		cQuery += " WHERE SC8.C8_FILIAL = '" + xFilial("SC8") + "'"							+ CRLF
		cQuery += "   AND SC8.C8_NUM = '" + Padr(cNumCot, TamSX3("C8_NUM")[1]) + "'"		+ CRLF
		//Comentado por solicitação Marcos dia 23/07/2019
		//cQuery += "   AND SC8.C8_NUMPED <> '" + Padr(cNumPed, TamSX3("C8_NUMPED")[1]) + "'"	+ CRLF
		cQuery += "   AND SC8.D_E_L_E_T_ <> '*' "											+ CRLF
		cQuery += " ORDER BY SC8.C8_FORNECE, SC8.C8_LOJA, SC8.C8_ITEM, SC8.C8_ITEMGRD "

		MpSysOpenQuery(cQuery, cTmpAlias)

		While !(cTmpAlias)->(EOF())
			cCompAnexo := cNumCot + "_" + AllTrim((cTmpAlias)->C8_ITEM) + "_" + AllTrim((cTmpAlias)->C8_FORNECE) + "_" + AllTrim((cTmpAlias)->C8_LOJA) + cBarra
			cPathAnexo := cPath + cCompAnexo

			cNumCot := Padr(cNumCot, TamSX3("C8_NUM" )[1])
			cItem := (cTmpAlias)->C8_ITEM
			cItemGrd := (cTmpAlias)->C8_ITEMGRD
			cFornece := (cTmpAlias)->C8_FORNECE
			cLoja := (cTmpAlias)->C8_LOJA

			DbSelectArea("SA2")
			SA2->(DbSetOrder(1)) // A2_FILIAL + A2_COD + A2_LOJA
			If SA2->(DbSeek( xFilial("SA2") + cFornece + cLoja ))
				//Com o nome do fornecedor é criada a entidade com os dados da tabela SC8 - Cotações
				cCodEnt := xFilial("SC8") + cNumCot + cItem + cItemGrd + cFornece + cLoja + SA2->A2_NOME
				cCodEnt := Padr(cCodEnt, TamSX3("AC9_CODENT")[1])
			EndIf

			DbSelectArea("AC9")
			AC9->(DbSetOrder(2)) // AC9_FILIAL + AC9_ENTIDA + AC9_FILENT + AC9_CODENT + AC9_CODOBJ
			If AC9->(DbSeek(xFilial("AC9") + "SC8" + xFilial("SC8") + cCodEnt))
				cCodObj := AC9->AC9_CODOBJ
			EndIf

			If !Empty( cCodObj )
				DbSelectArea("ACB")
				ACB->(DbSetOrder(1)) // ACB_FILIAL + ACB_CODOBJ
				If ACB->(DbSeek(xFilial("ACB") + cCodObj))

					If !ExistDir(cPathAnexo)

						nMakeDir := MakeDir(cPathAnexo)

					Else

						aFiles := Directory(cPathAnexo + "*.*")

						For nI := 1 To Len(aFiles)
							FErase(cPathAnexo + aFiles[nI][1])
						Next nI

					EndIf

					If nMakeDir == 0
						//Copia do arquivo do anexo para pasta de workflow, lembrando que a função MsDocPath não retorna a ultima "\" e por isso ela é incluida
						__CopyFile( MsDocPath() + cBarra + AllTrim(ACB->ACB_OBJETO) , cPathAnexo + AllTrim(ACB->ACB_OBJETO) )

						aDiretorio := Separa(cPath,cBarra,.F.)

						If Len(aDiretorio) > 0
							aAdd(aRetObj, { cFornece, cLoja, cItem, aDiretorio[Len(aDiretorio)] + cBarra + cCompAnexo, AllTrim(ACB->ACB_OBJETO) })
						EndIf

					EndIf

					nMakeDir := 0
				EndIf
			EndIf

			cCodEnt := ""
			cCodObj := ""

			(cTmpAlias)->(DbSkip())
		EndDo
	EndIf

	// -----------------------------------------------------------
	// Ajusta para a barra para direita, pois desta forma o
	// navegador vai conseguir localizar o arquivo no servidor
	// -----------------------------------------------------------
	AEVal(aRetObj, {|x| x[4] := StrTran(x[4],cBarra,"/")})

	RestArea(aAreaACB)
	RestArea(aAreaAC9)
	RestArea(aAreaSA2)

Return aRetObj

/*/{Protheus.doc} fRetAnexPed
Responsável por retornar os anexos do Pedido de Compra
@author Juliano Fernandes
@since 14/08/2019
@return aRetObj, Array com duas posições
@param cPath, characters, Diretório onde será salvo o anexo
@param cNumPed, characters, Número do pedido de compra
@type function
/*/
Static Function fRetAnexPed(cPath, cNumPed)

	Local aArea			:= GetArea()
	Local aAreaAC9		:= AC9->(GetArea())
	Local aAreaACB		:= ACB->(GetArea())
	Local aDiretorio	:= {}
	Local aRetObj		:= {}

	Local cCodEnt		:= ""
	Local cChaveAC9		:= ""
	Local cQuery		:= ""
	Local cTmpAlias		:= GetNextAlias()
	Local cExtensao		:= ""
	Local cNovoArq		:= ""

	If ExistDir(cPath)

		cQuery := " SELECT SC7.C7_ITEM "								+ CRLF
		cQuery += " FROM " + RetSQLName("SC7") + " SC7 "				+ CRLF
		cQuery += " WHERE SC7.C7_FILIAL = '" + xFilial("SC7") + "' "	+ CRLF
		cQuery += " 	AND SC7.C7_NUM = '" + cNumPed + "' "			+ CRLF
		cQuery += " 	AND SC7.D_E_L_E_T_ <> '*' "						+ CRLF
		cQuery += " ORDER BY SC7.C7_ITEM "								+ CRLF

		MpSysOpenQuery(cQuery, cTmpAlias)

		While !(cTmpAlias)->(EOF())
			cCodEnt := xFilial("SC7") + cNumPed + (cTmpAlias)->C7_ITEM
			cCodEnt := PadR(cCodEnt, TamSX3("AC9_CODENT")[1])

			cChaveAC9 := xFilial("AC9")
			cChaveAC9 += "SC7"
			cChaveAC9 += xFilial("SC7")
			cChaveAC9 += cCodEnt

			DbSelectArea("AC9")
			AC9->(DbSetOrder(2)) // AC9_FILIAL + AC9_ENTIDA + AC9_FILENT + AC9_CODENT + AC9_CODOBJ
			If AC9->(DbSeek( cChaveAC9 ))

				While !AC9->(EoF()) .And. AC9->(AC9_FILIAL + AC9_ENTIDA + AC9_FILENT + AC9_CODENT) == cChaveAC9

					DbSelectArea("ACB")
					ACB->(DbSetOrder(1)) // ACB_FILIAL + ACB_CODOBJ
					If ACB->(DbSeek(xFilial("ACB") + AC9->AC9_CODOBJ))

						cNovoArq := Lower(AllTrim(ACB->ACB_OBJETO))

						cExtensao := Substr(cNovoArq, Rat(".", cNovoArq))

						cNovoArq := AllTrim(ACB->ACB_CODOBJ) + cExtensao

						// Copia do arquivo do anexo para pasta de workflow, lembrando que a função MsDocPath não retorna a ultima "\" e por isso ela é incluida
						__CopyFile( MsDocPath() + cBarra + AllTrim(ACB->ACB_OBJETO), cPath + cNovoArq )

						aDiretorio := Separa(cPath,cBarra,.F.)

						If Len(aDiretorio) > 0
							aAdd(aRetObj, { aDiretorio[Len(aDiretorio)] + cBarra, AllTrim(ACB->ACB_OBJETO), cNovoArq })
						EndIf
					EndIf

					AC9->(DbSkip())
				EndDo
			EndIf

			(cTmpAlias)->(DbSkip())
		EndDo

		(cTmpAlias)->(DbCloseArea())
	EndIf

	// -----------------------------------------------------------
	// Ajusta para a barra para direita, pois desta forma o
	// navegador vai conseguir localizar o arquivo no servidor
	// -----------------------------------------------------------
	AEVal(aRetObj, {|x| x[1] := StrTran(x[1],cBarra,"/")})

	RestArea(aAreaACB)
	RestArea(aAreaAC9)
	RestArea(aArea)

Return(aRetObj)

/*/{Protheus.doc} fRetEmail
Retorna o código do usuario através do nome
@author Icaro Laudade
@since 23/07/2019
@return cEmail, Email do Solicitante informado no parâmetro
@param cSolic, characters, Solicitante da solicitação de compra
@type function
/*/
Static Function fRetEmail(cSolic)
	Local aAllUsers :=	FWSFALLUSERS()
	Local cEmail	:=	""
	Local nI		:=	0
	Local nPosLogin	:=	3
	Local nPosNome	:=	4
	Local nPosEmail	:=	5

	If !Empty(cSolic) .And. Len(aAllUsers) > 0

		For nI := 1 To Len(aAllUsers)

			If AllTrim(Upper(aAllUsers[nI][nPosLogin])) == AllTrim(Upper(cSolic)) .Or. AllTrim(Upper(aAllUsers[nI][nPosNome])) == AllTrim(Upper(cSolic))
				cEmail := AllTrim(aAllUsers[nI][nPosEmail])
			EndIf

		Next nI

	EndIf

Return cEmail

/*/{Protheus.doc} fExcAnexos
Exclui os anexos do Pedido de Compra que foram copiados e o diretório gerado para armazenar os anexos.
@author Juliano Fernandes
@since 20/08/2019
@version 1.0
@return Nil, Não há retorno
@param cNumPed, caracter, Número do Pedido de Compra
@type function
/*/
Static Function fExcAnexos(cNumPed)

	Local aFiles	:= {}

	Local cDirAnexo	:= ""

	cDirAnexo := "messenger" + cBarra
	cDirAnexo += "emp" + cEmpAnt + cBarra
	cDirAnexo += "PROCESSOS" + cBarra
	cDirAnexo += cEmpAnt + cFilAnt + cNumPed

	If ExistDir(cDirAnexo)
		aFiles := Directory(cDirAnexo + cBarra + "*.*")

		AEVal(aFiles, {|x| FErase(cDirAnexo + cBarra + x[1])})

		DirRemove(cDirAnexo)
	EndIf

Return(Nil)

/*/{Protheus.doc} fGetEMailApv
Retorna os códigos dos usuários que aprovaram o pedido de compra.
@author Juliano Fernandes
@since 17/01/2020
@version 1.0
@return aEMail, Array com o email dos usuários que aprovaram o pedido de compra
@param cNumPed, caracter, Código do pedido de compra
@type function
/*/
Static Function fGetEMailApv(cNumPed)

	Local aEMail		:= {}

	Local cEMail		:= ""
	Local cAliasQry		:= GetNextAlias()

	BeginSQL Alias cAliasQry
		SELECT 		SCR.CR_USER
		FROM 		%Table:SCR% SCR
		WHERE 		SCR.CR_FILIAL	= %xFilial:SCR%		AND
					SCR.CR_TIPO		= %Exp:'PC'% 		AND
					SCR.CR_NUM		= %Exp:cNumPed%		AND
					SCR.CR_STATUS	= %Exp:'03'% 		AND
					SCR.%NotDel%
		ORDER BY	SCR.R_E_C_N_O_
	EndSQL

	While !(cAliasQry)->(EoF())
		PswOrder(1)
		If PswSeek((cAliasQry)->CR_USER)
			cEMail := AllTrim(PswRet()[1,14])

			If !Empty(cEMail) .And. AScan(aEMail, cEMail) == 0
				Aadd(aEMail, cEMail)
			EndIf
		EndIf

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

Return(aEMail)

/*/{Protheus.doc} f551Reenv
Função para o reenvio de processo de Workflow.
@author Juliano Fernandes
@since 16/03/2020
@version 1.0
@return Nil, Não há retorno
@param cNumPC, caracter, número do pedido de compra
@type function
/*/
Static Function f551Reenv(cNumPC)

	Local aMailApr		:= {}

	Local cHttpSrv		:= AllTrim(SuperGetMV("PLG_WFPCIP",,""))
	Local cPastaHTM		:= "PROCESSOS"
	Local cIDWF			:= ""
	Local cProcessID	:= ""
	Local cTaskID		:= ""
	Local cSeekWFA		:= ""
	Local cSeekSA2		:= ""
	Local cMailID		:= ""
	Local cNomeFor		:= ""
	Local cUrl			:= ""

	Local nI			:= 0

	cIDWF := fGetIDWF(cNumPC)

	If !Empty(cIDWF)
		cProcessID	:= fGetProcID(cIDWF)
		cTaskID		:= fGetTaskID(cIDWF)

		If !Empty(cProcessID) .And. !Empty(cTaskID)
			cSeekWFA := xFilial("WFA")
			cSeekWFA += cProcessID
			cSeekWFA += cTaskID

			DbSelectArea("WFA")
			WFA->(DbSetOrder(2)) // WFA_FILIAL+WFA_IDENT
			If WFA->(DbSeek(cSeekWFA))
				cMailID := WFA->WFA_IDENT
			EndIf

			If !Empty(cMailID)
				cUrl := "http://" + cHttpSrv + IIf(Right(cHttpSrv, 1) != "/", "/", "") + "messenger/emp" + cEmpAnt + "/" + cPastaHTM + "/" + cMailID + ".htm"

				cSeekSA2 := xFilial("SA2")
				cSeekSA2 += SC7->C7_FORNECE
				cSeekSA2 += SC7->C7_LOJA

				DbSelectArea("SA2")
				SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
				If SA2->(DbSeek(cSeekSA2))
					cNomeFor := SA2->A2_NOME
				EndIf

				If !Empty(cNomeFor)
					aMailApr := fGetMailApr(cNumPC)

					If !Empty(aMailApr)
						For nI := 1 To Len(aMailApr)
							If Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551146 + aMailApr[nI] + "?", {PRT551005, PRT551006}, 2) == 1 //' - Workflow de Pedido de Compra - ' # 'Confirma o reenvio do Workflow do pedido de compra selecionado para ' # Sim # Não
								f551WFLink( {{cNumPC, cNomeFor, cUrl}}, aMailApr[nI] )
							EndIf
						Next nI
					Else
						Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551147, {PRT551003}, 2) // ' - Workflow de Pedido de Compra - ' # 'E-mail do aprovador não foi localizado.' # 'OK'
					EndIf
				EndIf
			Else
				Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551148 + " (MailID)", {PRT551003}, 2) // ' - Workflow de Pedido de Compra - ' # 'ID Workflow não foi localizado.' # 'OK'
			EndIf
		EndIf
	Else
		 Aviso(NomePrt + PRT551001 + VersaoJedi, PRT551148 + " (IDWF)" , {PRT551003}, 2) // ' - Workflow de Pedido de Compra - ' # 'ID Workflow não foi localizado.' # 'OK'
	EndIf

Return(Nil)

/*/{Protheus.doc} fGetProcID
Retorna o ProcessID do Workflow do pedido de compra passado por parâmetro.
@author Juliano Fernandes
@since 16/03/2020
@version 1.0
@return cProcessID, ProcessID
@param cIDWF, caracter, Conteúdo do campo CR_XIDWF
@type function
/*/
Static Function fGetProcID(cIDWF)

	Local cProcessID := Lower(Substr(cIDWF, 1, At(".", cIDWF) - 1))

Return(cProcessID)

/*/{Protheus.doc} fGetTaskID
Retorna o TaskID do Workflow do pedido de compra passado por parâmetro.
@author Juliano Fernandes
@since 16/03/2020
@version 1.0
@return cTaskID, TaskID
@param cIDWF, caracter, Conteúdo do campo CR_XIDWF
@type function
/*/
Static Function fGetTaskID(cIDWF)

	Local cTaskID := Lower(Substr(cIDWF, At(".", cIDWF) + 1))

Return(cTaskID)

/*/{Protheus.doc} fGetIDWF
Retorna o conteúdo do campo CR_XIDWF da fila de aprovação do pedido de compra.
@author Juliano Fernandes
@since 16/03/2020
@version 1.0
@return cIDWF, IDWF do pedido de compra
@param cNumPC, caracter, Número do pedido de compra
@type function
/*/
Static Function fGetIDWF(cNumPC)

	Local cIDWF		:= ""
	Local cAliasQry	:= ""

	cAliasQry := GetNextAlias()

	BeginSQL Alias cAliasQry
		SELECT 		SCR.CR_XIDWF
		FROM 		%Table:SCR% SCR
		WHERE 		SCR.CR_FILIAL	= %xFilial:SCR%	AND
					SCR.CR_TIPO		= %Exp:'PC'%	AND
					SCR.CR_NUM		= %Exp:cNumPC%	AND
					SCR.CR_STATUS	= %Exp:'02'%	AND
					SCR.%NotDel%
		ORDER BY	SCR.R_E_C_N_O_
	EndSQL

	(cAliasQry)->(DbEval({|| cIDWF := AllTrim((cAliasQry)->CR_XIDWF)},, {|| !Eof()}))
	(cAliasQry)->(DbCloseArea())

Return(cIDWF)

/*/{Protheus.doc} fGetMailApr
Retorna o e-mail do aprovador.
@author Juliano Fernandes
@since 16/03/2020
@version 1.0
@return aMailApr, Array com E-mail do(s) aprovador(es)
@param cNumPC, caracter, Código do pedido de compra
@type function
/*/
Static Function fGetMailApr(cNumPC)

	Local aMailApr	:= {}

	Local cAliasQry	:= ""

	cAliasQry := GetNextAlias()

	BeginSQL Alias cAliasQry
		SELECT 		SCR.CR_USER
		FROM 		%Table:SCR% SCR
		WHERE 		SCR.CR_FILIAL	= %xFilial:SCR%	AND
					SCR.CR_TIPO		= %Exp:'PC'%	AND
					SCR.CR_NUM		= %Exp:cNumPC%	AND
					SCR.CR_STATUS	= %Exp:'02'%	AND
					SCR.%NotDel%
		ORDER BY	SCR.R_E_C_N_O_
	EndSQL

	While !(cAliasQry)->(EoF())
		PswOrder(1)
		If PswSeek((cAliasQry)->CR_USER) .And. !Empty(PswRet()[1,14])
			Aadd(aMailApr, AllTrim(PswRet()[1,14]))
		EndIf

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

Return(aMailApr)
