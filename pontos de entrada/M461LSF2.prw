#Include "TOTVS.ch"

Static NomePrt		:= "M461LSF2"
Static VersaoJedi	:= "V1.01"

/*/{Protheus.doc} M461LSF2
Este ponto de entrada pertence à rotina de geração de notas fiscais, MATA461().
Está localizado na rotina de gravação da nota fiscal, é executado após a gravação dos dados da nota
possibilitando alterar dados da tabela SF2.
O ponto de entrada não recebe parâmetros e as tabelas estão devidamente preparadas para manipulação.
@author Juliano Fernandes
@since 05/09/2019
@version 1.0
@return Nil, Não há retorno
@type function

@Atualizações
	@autor Douglas Gregorio
	@data 10/12/2021
	Conversão do fonte da VELOCE para implantar junto ao TMS da Transbrasa

/*/
User Function M461LSF2()

	Local aArea		:= GetArea()
	Local aAreaUQD	:= {}

	// ----------------------------------------------------------------------
	// Atualização da chave da Nota Fiscal na integração de registros CTE
	// Gravando o campo F2_CHVNFE, os campos F3_CHVNFE e FT_CHVNFE também
	// são gravados automaticamente.
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
