#Include "TOTVS.ch"

Static NomePrt		:= "M461LSF2"
Static VersaoJedi	:= "V1.01"

/*/{Protheus.doc} M461LSF2
Este ponto de entrada pertence � rotina de gera��o de notas fiscais, MATA461().
Est� localizado na rotina de grava��o da nota fiscal, � executado ap�s a grava��o dos dados da nota
possibilitando alterar dados da tabela SF2.
O ponto de entrada n�o recebe par�metros e as tabelas est�o devidamente preparadas para manipula��o.
@author Juliano Fernandes
@since 05/09/2019
@version 1.0
@return Nil, N�o h� retorno
@type function

@Atualiza��es
	@autor Douglas Gregorio
	@data 10/12/2021
	Convers�o do fonte da VELOCE para implantar junto ao TMS da Transbrasa

/*/
User Function M461LSF2()

	Local aArea		:= GetArea()
	Local aAreaUQD	:= {}

	// ----------------------------------------------------------------------
	// Atualiza��o da chave da Nota Fiscal na integra��o de registros CTE
	// Gravando o campo F2_CHVNFE, os campos F3_CHVNFE e FT_CHVNFE tamb�m
	// s�o gravados automaticamente.
	// ----------------------------------------------------------------------
	If IsInCallStack("U_PRT0544") .And. Type("n544RecUQD") != "U"
		aAreaUQD := UQD->(GetArea())

		DbSelectArea("UQD")
		UQD->(DbGoTo(n544RecUQD))
		If UQD->(Recno()) == n544RecUQD
			If AllTrim(UQD->UQD_TPCON) == "ZTRC" // CTE
				If !Empty(UQD->UQD_CHVCTE)
					SF2->F2_CHVNFE := UQD->UQD_CHVCTE
				EndIf
			EndIf
		EndIf

		RestArea(aAreaUQD)
	EndIf

	RestArea(aArea)

Return(Nil)
