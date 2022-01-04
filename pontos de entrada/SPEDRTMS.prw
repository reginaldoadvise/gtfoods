#Include "TOTVS.ch"

Static NomePrt		:= "SPEDRTMS"
Static VersaoJedi	:= "V1.04"

/*/{Protheus.doc} SPEDRTMS
Este ponto de entrada tem como finalidade retornar um array com as informações dos conhecimentos
de transportes para os clientes que não utilizam o módulo Gestão de Transportes.
É utilizado na geração do "Bloco documentos fiscais II serviço (ICMS)" para os
Registros:D100, D110, D120, D130, D140, D150, D160, D161, D162 e D190.
@author Marcos Santos
@since 01/02/2020
@return vRet, Array com informações dos conhecimentos de transportes
@type function

@Atualização
@data 18/02/2021
@autor Douglas
	Conforme solicitado por Consultora Bete, por Solicitação de Ricardo - Veloce
	Notas de CTE que forem do CFOP 5932 e 6932
	Não devem ter seus impostos gravados no Imposto ICMS os mesmos devem ser 0
	quando estes CFOP, zerar a base e o imposto de ICMS, o mesmo foi retido na fonte

@Atualização
@data 10/12/2021
@autor Douglas
	Alterado para tabelas da TRANSBRASA
		UQD - UQD	-	Cabeçalho Arq. CTE e CRT
			Z1_IDIMP	UQD_IDIMP
			Z1_CHVCTE	UQD_CHVCTE
			Z1_MUNCOL	UQD_MUNCOL
			Z1_VALOR	UQD_VALOR
			Z1_ICMS		UQD_ICMS
			Z1_TPCON	UQD_TPCON
			Z1_UFCOL	UQD_UFCOL
			Z1_UFDES 	UQD_UFDES
			Z1_PEDIDO	UQD_PEDIDO
			Z1_CFOP		UQD_CFOP
			Z1_FILIAL	UQD_FILIAL
			Z1_NF		UQD_NF
			Z1_SERIE	UQD_SERIE
			Z1_CLIENTE	UQD_CLIENT
			Z1_LOJACLI	UQD_LOJACL

		UQE - UQE	-	Itens dos Arquivos CTE/CRT
			Z2_PRCVEN	UQE_PRCVEN
			Z2_IDIMP	UQE_IDIMP
			Z2_FILIAL	UQE_FILIAL
			Z2_PRODUTO	UQE_PRODUT

/*/
User Function SPEDRTMS()

	Local vLinha     := {}
	Local nPos       := ParamIXB[1]
	Local cReg       := ParamIXB[2]
	Local cAlias     := ParamIXB[3]
	Local aCmpAntSFT := ParamIXB[4]
	Local vRet       := {}
	Local aCidade    := {}
	Local cQuery     := ""
	Local nBase      := 0

	//01 - Doc. Fiscal
	//02 - Serie NF
	//03 - Cliente/Fornecedor
	//04 - Codigo Loja
	//05 - Data Docto.
	//06 - Data Emissao
	//07 - Data Canc.
	//08 - Formulario Proprio
	//09 - CFOP
	//10 - Reservado
	//11 - Aliq. ICMS
	//12 - Nro. PDV
	//13 - Base ICMS
	//14 - Aliq. ICMS
	//15 - Valor ICMS
	//16 - Valor Isento ICMS
	//17 - Outros ICMS
	//18 - ICMS Retido ST
	//19 - Conta Contabil
	//20 - Tipo Lancamento
	//21 - Tipo Frete
	//22 - Filial
	//23 - Estado
	//24 - Observacao
	//25 - Chave NFE
	//26 - Tipo Emissao
	//27 - Prefixo
	//28 - Duplicata
	//29 - Cupom Fiscal
	//30 - Transportadora
	//31 - Peso Bruto
	//32 - Peso Liquido
	//33 - Veiculo1
	//34 - Veiculo2
	//35 - Veiculo3
	//36 - Optante Simples Nacional
	//37 - Regime Paraiba

    //Marcos Santos
    //Somente para CTE e Nota de Saida que tem que gerar
    If AllTrim(aCmpAntSFT[42]) == "CTE" .And. AllTrim(aCmpAntSFT[43]) == "S"

    	//vejo se tem chave da nota e se tem cidade de origem e destino informadas dentro da interface
		cQuery := " SELECT UQD_IDIMP, UQD_CHVCTE, UQD_MUNCOL, UQD_VALOR, UQD_ICMS, "	+ CRLF
		cQuery += " 	UQD_TPCON, UQD_UFCOL, UQD_UFDES, UQD_PEDIDO, UQD_CFOP "      	+ CRLF
		cQuery += " FROM " + RetSqlName("UQD")											+ CRLF
		cQuery += " WHERE UQD_FILIAL = '" + aCmpAntSFT[22] + "' "						+ CRLF
		cQuery += " 	AND UQD_NF = '" + aCmpAntSFT[1] + "' "							+ CRLF
		cQuery += " 	AND UQD_SERIE = '" + aCmpAntSFT[2] + "' "						+ CRLF
		cQuery += " 	AND UQD_CLIENT = '" + aCmpAntSFT[3] + "' "						+ CRLF
		cQuery += " 	AND UQD_LOJACL = '" + aCmpAntSFT[4] + "' "						+ CRLF
		cQuery += " 	AND D_E_L_E_T_ <> '*' "											+ CRLF

		VerTabela("SPEDRTMS")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SPEDRTMS",.T.,.T.)

		If Len(SPEDRTMS->UQD_CHVCTE) == 44 .And. At(';',SPEDRTMS->UQD_MUNCOL) <> 0

			If cReg == "D140"
				AAdd( vLinha , "D140" )                                                        // 01 - REG
				AAdd( vLinha , "SA1"+aCmpAntSFT[22]+aCmpAntSFT[3] + aCmpAntSFT[4] )            // 02 - COD_PART_CONSG
				AAdd( vLinha , Formata2(RetCodEst(SA1->A1_EST)+SA1->A1_COD_MUN) )              // 03 - COD_MUN_ORIG
				AAdd( vLinha , Formata2(RetCodEst(SA1->A1_EST)+SA1->A1_COD_MUN) )              // 04 - COD_MUN_DEST
				AAdd( vLinha , "1" )                                                           // 05 - IND_VEIC
				AAdd( vLinha , "")                                                             // 06 - VEIC_ID
				AAdd( vLinha , "0")                                                            // 07 - IND_NAV
				AAdd( vLinha , "" )                                                            // 08 - VIAGEM
				AAdd( vLinha , LTrim(Transform(SF2->F2_VALMERC,"@E 99999999.99")) )            // 09 - VL_FRT_LIQ
				AAdd( vLinha , "" )                                                            // 10 - VL_DESP_PORT
				AAdd( vLinha , "" )                                                            // 11 - VL_DESP_CAR_DESC
				AAdd( vLinha , "" )                                                            // 12 - VL_OUT
				AAdd( vLinha , LTrim(Transform(SF2->F2_VALBRUT,"@E 99999999.99")) )            // 13 - VL_FRT_BRT
				AAdd( vLinha , LTrim(Transform(SF2->(F2_AFRMM1+F2_AFRMM2),"@E 99999999.99")) ) // 14 - VL_FRT_MM
				AAdd( vRet , vLinha )

			ElseIf cReg == "D100"
				nBase := SPEDRTMS->UQD_VALOR

				//para a filial 0102 e se tiver pedagio tem que descontar. Marcos Santos
				If AllTrim(aCmpAntSFT[22]) == '0102'
					cQuery := " SELECT UQE_PRCVEN "									+ CRLF
					cQuery += " FROM " + RetSqlName("UQE")							+ CRLF
					cQuery += " WHERE D_E_L_E_T_ <> '*' "							+ CRLF
					cQuery += " 	AND UQE_IDIMP = '" + SPEDRTMS->UQD_IDIMP + "' "	+ CRLF
					cQuery += " 	AND UQE_FILIAL = '" + aCmpAntSFT[22]+"' "		+ CRLF
					cQuery += " 	AND UQE_PRODUT = 'PEDAGIO' "					+ CRLF

					VerTabela("SPEDRTM2")
					dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SPEDRTM2",.T.,.T.)

					If !Empty(SPEDRTM2->UQE_PRCVEN)
						nBase := nBase - SPEDRTM2->UQE_PRCVEN
					Endif

				// --------------------------------------------------------------------------------
				// Verifica se a NF é do estado do Rio Grande do Sul e a TES utilizada é a 502.
				// Nesse caso é isento de ICMS.
				// Juliano Fernandes - 02/06/2020
				// A mesma regra está codificada no programa PRT0544 na função fGrvImpost
				// --------------------------------------------------------------------------------
				ElseIf AllTrim(aCmpAntSFT[22]) $ "0104|0106|0110"
					If AllTrim(SPEDRTMS->UQD_TPCON) != "ZCRT"
						cQuery := " SELECT A1_EST "									+ CRLF
						cQuery += " FROM " + RetSqlName("SA1")						+ CRLF
						cQuery += " WHERE A1_FILIAL = '" + xFilial("SA1") + "' "	+ CRLF
						cQuery += " 	AND A1_COD = '" + aCmpAntSFT[3] + "' "		+ CRLF
						cQuery += " 	AND A1_LOJA = '" + aCmpAntSFT[4] + "' "		+ CRLF
						cQuery += " 	AND D_E_L_E_T_ <> '*' "						+ CRLF

						VerTabela("SPEDRTM2")
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SPEDRTM2",.T.,.T.)

						If !SPEDRTM2->(EoF())
							If AllTrim(SPEDRTM2->A1_EST) == "RS"
								cQuery := " SELECT C6_TES "										+ CRLF
								cQuery += " FROM " + RetSqlName("SC6")							+ CRLF
								cQuery += " WHERE C6_FILIAL = '" + aCmpAntSFT[22] + "' "		+ CRLF
								cQuery += " 	AND C6_NUM = '" + SPEDRTMS->UQD_PEDIDO + "' "	+ CRLF
								cQuery += " 	AND D_E_L_E_T_ <> '*' "							+ CRLF

								VerTabela("SPEDRTM2")
								dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SPEDRTM2",.T.,.T.)

								If !SPEDRTM2->(EoF())
									If AllTrim(SPEDRTM2->C6_TES) == "502"
										nBase := 0 // Isento
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				Endif

				//tenho que ver se a nota está excluida
				cQuery := " SELECT F2_DOC "									+ CRLF
				cQuery += " FROM " + RetSqlName("SF2")						+ CRLF
				cQuery += " WHERE D_E_L_E_T_ <> '*' "						+ CRLF
				cQuery += " 	AND F2_FILIAL = '" + aCmpAntSFT[22] + "' "	+ CRLF
				cQuery += " 	AND F2_DOC = '" + aCmpAntSFT[1] + "' "		+ CRLF
				cQuery += " 	AND F2_SERIE = '" + aCmpAntSFT[2] + "' "	+ CRLF

				VerTabela("SPEDRTM2")
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SPEDRTM2",.T.,.T.)

				If !Empty(SPEDRTM2->F2_DOC)
					//gravo o D100
					aAdd(vLinha, "D100")                               //01 REG
					aAdd(vLinha, "1")                                  //02 IND_OPER
					aAdd(vLinha, "0")                                  //03 IND_EMIT
					aAdd(vLinha, "SA1"+aCmpAntSFT[22]+aCmpAntSFT[3] + aCmpAntSFT[4])  //04 COD_PART
					aAdd(vLinha, "57")                                 //05 COD_MOD
					aAdd(vLinha, "00")                                 //06 COD_SIT - Inutilizado
					aAdd(vLinha, aCmpAntSFT[2])                        //07 SER
					aAdd(vLinha, "")                                   //08 SUB
					aAdd(vLinha, aCmpAntSFT[1])                        //09 NUM_DOC
					aAdd(vLinha, aCmpAntSFT[25])                       //10 CHV_CTE
					aAdd(vLinha, aCmpAntSFT[5])                        //11 DT_DOC
					aAdd(vLinha, aCmpAntSFT[5])                        //12 DT_A_P
					aAdd(vLinha, 0)                                    //13 TP_CTe
					aAdd(vLinha, "")                                   //14 CHV_CTe_REF
					aAdd(vLinha, SPEDRTMS->UQD_VALOR /*aCmpAntSFT[13]*/)//15 VL_DOC
					aAdd(vLinha, 0)                                    //16 VL_DESC
					aAdd(vLinha, "2")                                  //17 IND_FRT
					aAdd(vLinha, SPEDRTMS->UQD_VALOR /*aCmpAntSFT[13]*/)//18 VL_SERV

					//18/02/21 - Douglas, quando estes CFOP, zerar a base e o imposto de ICMS, o mesmo foi retido na fonta
					If SubStr(SPEDRTMS->UQD_CFOP,1,4) $ "5932/6932"
						aAdd(vLinha, 0 )                                   //19 VL_BC_ICMS
						aAdd(vLinha, 0 )                                   //20 vL_ICMS
					Else
						aAdd(vLinha, nBase /*aCmpAntSFT[13]*/)             //19 VL_BC_ICMS
						aAdd(vLinha, SPEDRTMS->UQD_ICMS  /*aCmpAntSFT[15]*/)//20 vL_ICMS
					EndIf

					aAdd(vLinha, 0)                                    //21 VL_NT
					aAdd(vLinha, "")                                   //22 COD_INF
					aAdd(vLinha, "")                                   //23 COD_CTA

					//Marcos Santos, tem que buscar da tabela da interface
					aCidade := STRTOKARR(SPEDRTMS->UQD_MUNCOL,';')
					aAdd(vLinha,aCidade[1])                            //24 CIDADE ORIGEM
					aAdd(vLinha,aCidade[2])                            //25 CIDADE DESTINO
				Else
					//gravo o D100
					aAdd(vLinha, "D100")                               //01 REG
					aAdd(vLinha, "1")                                  //02 IND_OPER
					aAdd(vLinha, "0")                                  //03 IND_EMIT
					aAdd(vLinha, "")                                   //04 COD_PART
					aAdd(vLinha, "57")                                 //05 COD_MOD
					aAdd(vLinha, "02")                                 //06 COD_SIT - Inutilizado
					aAdd(vLinha, aCmpAntSFT[2])                        //07 SER
					aAdd(vLinha, "")                                   //08 SUB
					aAdd(vLinha, aCmpAntSFT[1])                        //09 NUM_DOC
					aAdd(vLinha, aCmpAntSFT[25])                       //10 CHV_CTE
					aAdd(vLinha, "")                                   //11 DT_DOC
					aAdd(vLinha, "")                                   //12 DT_A_P
					aAdd(vLinha, "")                                   //13 TP_CTe
					aAdd(vLinha, "")                                   //14 CHV_CTe_REF
					aAdd(vLinha, "")                                   //15 VL_DOC
					aAdd(vLinha, "")                                   //16 VL_DESC
					aAdd(vLinha, "")                                   //17 IND_FRT
					aAdd(vLinha, "")                                   //18 VL_SERV
					aAdd(vLinha, "")                                   //19 VL_BC_ICMS
					aAdd(vLinha, "")                                   //20 vL_ICMS
					aAdd(vLinha, "")                                   //21 VL_NT
					aAdd(vLinha, "")                                   //22 COD_INF
					aAdd(vLinha, "")                                   //23 COD_CTA
					aAdd(vLinha, "")                                   //24 CIDADE ORIGEM
					aAdd(vLinha, "")                                   //25 CIDADE DESTINO
				Endif

				aAdd(vRet,vLinha)

			EndIf
		Endif

		VerTabela("SPEDRTMS")
		VerTabela("SPEDRTM2")
	Endif

Return(vRet)

Static Function VerTabela(tab)
	IIf(Select(tab) > 0, (tab)->(dbCloseArea()), Nil)
Return
