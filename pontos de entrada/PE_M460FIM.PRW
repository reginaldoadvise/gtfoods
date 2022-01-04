#INCLUDE "Totvs.ch"

/*/{Protheus.doc} M460FIM
Ponto de entrada utilizado no momento da emissão da nota fiscal de saida.
@type function
@version V.12.1.27
@author Alessandro Afonso
@since 07/11/2018
@return Nil
/*/

User Function M460FIM()

	U_FATLog(SF2->F2_CARGA,SF2->F2_DOC,SF2->F2_SERIE,"M460FIM - Inicio")

	//Rotina utilizado no momento da emissão da nota fiscal de saida, para registro do lote aviário.
	U_F0101910()
	//Utilizado para Geração Automática do Movimento Interno de Requisição da NF de Remessa de Insumo.
	U_F0101501()
	//Função para validação se o cliente tem contrato de desconto Rapel
	U_F0300412()
	//Função para execução de rotina de integração com AVECOM para envio de notas fiscais através de JOB.
	U_F0102103()
	//Funcao para tratativa de Transferencia do armazem padrão do produto para o armazem destino C5_XCDDEP
	U_F0401201()
	//Função para Atualização dos Registros dos Lacres relacionando com a Repectiva Nota Fiscal
	U_G0513602()
	//Rotina para gerar lançamento na tabela PAC e PAE, quando o tipo de nota estiver sendo gerada a partir da integração com o modulo de originação.
	U_F0404552()
	// Escreve a forma de pagamento na SE1
	U_G0517806()
	//Popula as notas de entrada/saída para gravar os dados na movimentação do boletim sanitário.
	// U_G0515114("S")
	//GAP078 - Painel de Gestao Faturamento
	U_G0507805()
	//Geração de comissoes.-GAP029
	//U_F0403708()
	// Grava informações de Volume e Espécie na Nota Fiscal.
	U_F0601601()

	U_FATLog(SF2->F2_CARGA,SF2->F2_DOC,SF2->F2_SERIE,"M460FIM - Fim")

	DbSelectArea("SE1")
	nRecSE1:=SE1->(Recno())
	SE1->(dbSetOrder(1))
	If SE1->(dbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DOC))
		While !SE1->(EOF()) .And. SE1->E1_FILIAL == xFilial("SE1") .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And. SE1->E1_NUM == SF2->F2_DOC
		    If SE1->E1_SERIE == SF2->F2_SERIE
				RecLock("SE1",.F.)
    	    	SE1->E1_XNOME    := Posicione("SA1",1,XFILIAL("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME") 
				SE1->(MsUnLock())
			EndIf	
			SE1->(dbSkip())
		End
		SE1->(dbGoto(nRecSE1))
	EndIf
	
	//Integracao Atua
		IntegAtua()
	//final Integracao Atua
	
Return Nil

/*/{Protheus.doc} IntegAtua
Este Ponto de Entrada é chamado apos a Gravacao da NF de Saida, e fora da transação. Realiza a troca da informação de prefixo de acordo com o tipo de arquivos base para o título.
@author Icaro Laudade
@since 01/03/2019
@return Nil, Nulo
@type function
/*/

Static Function IntegAtua()

	Local aArea			:=	GetArea()
	Local cPrefixo		:=	""
	Local cQuery 		:=	""
	Local cNF			:=	""
	Local cSerieNF		:=	""
	Local cTmpAlias		:=	GetNextAlias()
	Local c2TmpAlias	:=	GetNextAlias()
	Local cParcela		:= 	""
	Local lExecProg		:=	.T.
	Local lExisteTit	:=	.F.
	Local lRepro		:=	.F.
	Local cAxChvRef		:= ""
	Local cAxTpCt		:= ""
	Local aSE1Auto		:= {}

	Private lMsErroAuto := .F.

	If lExecProg	//Programa exclusivo Brasil
		// Verifica se não é um arquivo CTRB através do prefixo atual do título
		If AllTrim(SE1->E1_PREFIXO) <> AllTrim(SuperGetMV("PLG_PFXCTR", .F., "CTR"))
			cNF := AllTrim(SF2->F2_DOC)
			cSerieNF := AllTrim(SF2->F2_SERIE)

			cQuery := " SELECT UQD_TPCON, UQD_SERIE, UQD_CANCEL, UQD_CHVREF, UQD_CCUSTO, UQD_ITEMCT, UQD_CONTAC, UQD_TIPOCT, UQD_CHVREF "	+ CRLF
			cQuery += " FROM " + RetSQLName("UQD") + " UQD "										+ CRLF
			cQuery += " WHERE UQD.UQD_FILIAL = '" + FWXFilial("UQD") + "' "							+ CRLF
			cQuery += "   AND SUBSTR(UQD.UQD_NUMERO,1, " + CValToChar(Len(cNF)) + ") = '" + cNF + "'" 	+ CRLF
			cQuery += "   AND UQD.UQD_CANCEL <> 'C' "												+ CRLF
			cQuery += "   AND (UQD.UQD_STATUS = 'I' OR UQD.UQD_STATUS = 'E') "						+ CRLF
			cQuery += "   AND UQD.D_E_L_E_T_ <> '*' "												+ CRLF

			MPSysOpenQuery(cQuery, cTmpAlias)

			If !(cTmpAlias)->(Eof())

				dbSelectArea("SD2") 
				SD2->(dbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA))	
				While SD2->(!Eof()) .And. SF2->F2_FILIAL + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA == SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA

					RecLock("SD2",.F.)
					SD2->D2_CCUSTO:= (cTmpAlias)->UQD_CCUSTO
					SD2->D2_ITEMCC:= (cTmpAlias)->UQD_ITEMCT
					SD2->D2_CONTA := (cTmpAlias)->UQD_CONTAC
					SD2->( MsUnLock() )

					SD2->(DbSkip())
				EndDo

				cPrefixo := SF2->F2_SERIE
				/*If "ZCRT" $ (cTmpAlias)->UQD_TPCON
					cPrefixo := SuperGetMV("PLG_PFXCRT", .F., "CRT")
				ElseIf "ZTRC" $ (cTmpAlias)->UQD_TPCON
					cPrefixo := SuperGetMV("PLG_PFXCTE", .F., "CTE")
				EndIf*/

				cAxChvRef := (cTmpAlias)->UQD_CHVREF
				cAxTpCt   := (cTmpAlias)->UQD_TIPOCT

				If "R" $ (cTmpAlias)->UQD_CANCEL
					cParcela := PadR(cSerieNF, TamSX3("E1_PARCELA")[1])
					lRepro := .T.
				Else
					cParcela := PadR((cTmpAlias)->UQD_SERIE, TamSX3("E1_PARCELA")[1])
				EndIf

				(cTmpAlias)->(DbSkip())
			EndIf

			(cTmpAlias)->(DbCloseArea())

			If !Empty(cPrefixo)

				If !lRepro
					DbSelectArea("SE1")
					SE1->(DbSetOrder(1)) //E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO

					aAreaSE1 := SE1->(GetArea())
					//Verifica se já existe um titulo com a mesma chave
					If SE1->(DbSeek(xFilial("SE1") + cPrefixo + SE1->E1_NUM + cParcela + SE1->E1_TIPO ))
						lExisteTit := .T.

	 					Reclock("SE1", .F.)
						//SE1->E1_PREFIXO := "ERR"
						SE1->E1_CHVREF	:= cAxChvRef
						SE1->E1_TIPOCT	:= cAxTpCt
						SE1->( MsUnlock() )

					EndIf

					RestArea(aAreaSE1)
				EndIf

				If !lExisteTit

					SE1->(Reclock("SE1", .F.))
					//SE1->E1_PREFIXO := cPrefixo
					SE1->E1_PARCELA := cParcela
					SE1->E1_CHVREF	:= cAxChvRef
					SE1->E1_TIPOCT	:= cAxTpCt
					SE1->(MsUnlock())

					DbSelectArea("SF2")
					SF2->(DbSetOrder(1)) //F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA + F2_FORMUL + F2_TIPO

					//SF2->(Reclock("SF2", .F.))
					//	SF2->F2_PREFIXO := cPrefixo
					//SF2->(MsUnlock())
				EndIf

				If cAxTpCt == "2"

					c2Query := " SELECT UQD_NF, UQD_SERIE "	+ CRLF
					c2Query += " FROM " + RetSQLName("UQD") + " UQD "										+ CRLF
					c2Query += " WHERE UQD.UQD_FILIAL = '" + FWXFilial("UQD") + "' "							+ CRLF
					c2Query += "   AND UQD.UQD_CHVCTE = '" + cAxChvRef + "'" 	+ CRLF
					c2Query += "   AND UQD.D_E_L_E_T_ <> '*' "												+ CRLF

					MPSysOpenQuery(c2Query, c2TmpAlias)

					If (c2TmpAlias)->( !Eof() )

						DbSelectArea("SE1")
						SE1->(DbSetOrder(1)) 
						If SE1->(DbSeek(xFilial("SE1") +  Padr((c2TmpAlias)->UQD_SERIE, TamSX3("E1_PREFIXO")[1]) + Padr((c2TmpAlias)->UQD_NF, TamSX3("E1_NUM")[1]) ))

							aSE1Auto := {{"E1_FILIAL"    , SE1->E1_FILIAL              ,Nil    },;
										{"E1_PREFIXO"    , SE1->E1_PREFIXO        	   ,Nil    },;
										{"E1_NUM"        , SE1->E1_NUM      		   ,Nil    },;
										{"E1_PARCELA"    , SE1->E1_PARCELA    		   ,Nil    },;
										{"E1_TIPO"       , SE1->E1_TIPO			       ,Nil    },;                                        
										{"AUTMOTBX"      , "DAC"                       ,Nil    },;
										{"AUTBANCO"      , "000"                       ,Nil    },;
										{"AUTAGENCIA"    , "00000"                     ,Nil    },;
										{"AUTCONTA"      , "0000000000"                ,Nil    },;
										{"AUTDTBAIXA"    , dDataBase                   ,Nil    },;
										{"AUTDTCREDITO"  , dDataBase                   ,Nil    },;
										{"AUTHIST"       , "BAIXA CTe de Anulação"     ,Nil    },;
										{"AUTJUROS"      , 0                           ,Nil,.T.},;
										{"AUTVALREC"     , SE1->E1_VALOR			   ,Nil    }}        
							
							lMsErroAuto := .F.       		

							MSExecAuto({|x,y| Fina070(x,y)},aSE1Auto,3) 

							If lMsErroAuto
								MostraErro()
							Endif

						EndIf
					Endif
					
					(c2TmpAlias)->( dbclosearea() )

				Endif

				u_GRVCTVEL()   //grava conta contabil, função localizada no PE FA040FIN. Marcos Santos
			EndIf
		EndIf
	EndIf

	RestArea(aArea)

Return Nil
