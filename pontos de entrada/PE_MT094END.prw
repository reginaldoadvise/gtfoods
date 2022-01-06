#Include 'Protheus.ch'

/*/{Protheus.doc} MT094END

Ponto de entrada apos a liberacao do Pedido de Compra.
	 
@author  Cesar Padovani 
@since   26/12/2021
@version 1.0
@type    Ponto de Entrada

/*/
User Function MT094END()

Local aArea     := GetArea()
Local cMailComp := ""
Local cCodHtm   := ""
Local cNomeArq  := ""

Private cAssunto   := ""
Private cCorpo     := ""
Private aAnexos    := ""
Private lMostraLog := .F.
Private lUsaTLS    := .F.

// ParamIxb[1] Numero PC
// ParamIxb[2] Tipo PC
// ParamIxb[3] 1 Liberado
// ParamIxb[3] 2 Estornar
// ParamIxb[3] 3 Superior
// ParamIxb[3] 4 Transferir Superior
// ParamIxb[3] 5 Rejeitado
// ParamIxb[3] 6 Bloqueio
// ParamIxb[3] 7 Visualizacao
// ParamIxb[4] Filial

DbSelectArea("SC7")
DbSetOrder(1)
DbGoTop()
DbSeek(xFilial("SC7")+Alltrim(ParamIxb[1]))

If ParamIxb[3]==5 // Se rejeitado envia email para o Comprador

	// Email do Comprador
	cMailComp := UsrRetMail(SC7->C7_USER)

	If !Empty(cMailComp)

		cCodHtm  := GeraHtm()
		MemoWrite(cNomeArq,cCodHtm)

		cAssunto := "Pedido de Compra REJEITADO "+Alltrim(ParamIxb[1])
		cCorpo   := cCodHtm
		U_EnvMail(cMailComp)
	EndIf
EndIf

RestArea(aArea)

Return

/*/{Protheus.doc} GeraHtm

Gera codigo Html para o corpo do email
	 
@author  Cesar Padovani 
@since   26/12/2021
@version 1.0
@type    Ponto de Entrada

/*/
Static Function GeraHtm()

Local cHtm    := ''
Local cFilIni := ""
Local cNumIni := ""
Local cCotac  := ""

cHtm += '<html>'
cHtm += '<head>'
cHtm += '<meta http-equiv="Content-Type"'
cHtm += 'content="text/html; charset=iso-8859-1">'
cHtm += '<title>Pedido de Compra Rejeitado</title>'
cHtm += '<style type="text/css">'
cHtm += '<!--'
cHtm += '.style12 {font-family: Arial, Helvetica, sans-serif;'
cHtm += '  font-weight: bold;'
cHtm += '  font-size: 12px;'
cHtm += '}'
cHtm += '.style7 {font-size: 12px;'
cHtm += '  color: #000066;'
cHtm += '  font-weight: bold;'
cHtm += '  font-family: Arial, Helvetica, sans-serif;'
cHtm += '}'
cHtm += '.style8 {color: #FFFFFF;'
cHtm += '  font-size: 14px;'
cHtm += '  font-family: Arial, Helvetica, sans-serif;'
cHtm += '  font-weight: bold;'
cHtm += '}'
cHtm += '.style9 {font-size: 12px; font-family: Arial, Helvetica, sans-serif; }'
cHtm += '.style13 {'
cHtm += '  font-size: 14px;'
cHtm += '  font-weight: bold;'
cHtm += '  color: #000000;'
cHtm += '}'
cHtm += '.style19 {font-size: 12px; font-family: Arial, Helvetica, sans-serif; color: #f3f3f3; }'
cHtm += '-->'
cHtm += '</style>'
cHtm += '</head>'
cHtm += '<body bgcolor="#FFFFFF">'
cHtm += '<br>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0">'
cHtm += '      <tr>'
cHtm += '        <td bgcolor="#727272"><div align="center" class="style8">Pedido de Compra Rejeitado</div></td>    '
cHtm += '      </tr>'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0"">'
cHtm += '      <tr>'
cHtm += '        <td > </td>'
cHtm += '      </tr>'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0"">'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0">'
cHtm += '      <tr>'
cHtm += '        <td width="12%" height="19" bgcolor="#f3f3f3"><span class="style7">Numero do Pedido: </span></td>'
cHtm += '        <td width="21%" bgcolor="#f3f3f3"><span class="style9">'+SC7->C7_NUM+'</span></td>'
cHtm += '        <td width="12%" bgcolor="#f3f3f3"><span class="style7">Data Emissao:</span></td>'
cHtm += '        <td width="21%" bgcolor="#f3f3f3"><span class="style9">'+DTOC(SC7->C7_EMISSAO)+'</span></td>'
cHtm += '      </tr>'
cHtm += '      <tr>'
cHtm += '        <td height="19" bgcolor="#f3f3f3"><span class="style7">Fornecedor:</span></td>'
cHtm += '        <td bgcolor="#f3f3f3"><span class="style9">'+GetAdvfVal("SA2","A2_NOME",xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,1)+'</span></td>'
cHtm += '        <td bgcolor="#f3f3f3"><span class="style7">Codigo/Loja Fornecedor:</span></td>'
cHtm += '        <td bgcolor="#f3f3f3"><span class="style9">'+SC7->C7_FORNECE+'/'+SC7->C7_LOJA+'</span></td>'
cHtm += '      </tr>'
cHtm += '      <tr bgcolor="#f3f3f3">'
cHtm += '        <td height="19"><span class="style7">Aprovador:</span></td>'
cHtm += '        <td bgcolor="#f3f3f3" ><span class="style9">'+UsrFullName(SCR->CR_USERLIB)+'</span></td>'
cHtm += '        <td ><span class="style7">Data/Hora Rejeicao: </span></td>'
cHtm += '        <td bgcolor="#f3f3f3" ><span class="style9">'+DTOC(dDataBase)+' '+Time()+'</span></td>'
cHtm += '      </tr>'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0">'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0"">'
cHtm += '      <tr>'
cHtm += '        <td width="12%" height="19" > </td>'
cHtm += '        <td width="21%" > </td>'
cHtm += '        <td width="12%" height="19" > </td>'
cHtm += '        <td width="21%" > </td>'
cHtm += '        <td width="12%" > </td>'
cHtm += '        <td width="22%" > </td>'
cHtm += '      </tr>'
cHtm += '    </table>'
cHtm += '    <table cellspacing="0" cellpadding="0" width="100%" border="0">'
cHtm += '      <tr>'
cHtm += '        <td bgcolor="#727272"><div align="center" class="style8">Itens</div></td>'
cHtm += '      </tr>'
cHtm += '    </table>'
cHtm += '    <table cellspacing="1" cellpadding="1" width="100%" border="0">'
cHtm += '      <tr>'
cHtm += '        <td width="4%" bordercolor="#CCCCCC"><div align="center"><span class="style12">Item</span></div></td>'
cHtm += '        <td width="10%" bordercolor="#CCCCCC"><div align="left"><span class="style12">Produto</span></div></td>'
cHtm += '        <td width="4%" bordercolor="#CCCCCC" class="style12"><div align="center">U.N.</div></td>'
cHtm += '        <td width="50%" bordercolor="#CCCCCC"><div align="left"><span class="style9"><strong>Descricao</strong></span></div></td>'
cHtm += '        <td width="10%" bordercolor="#CCCCCC"><div align="center"><span class="style9"><strong>Qtde</strong></span></div></td>'
cHtm += '        <td width="11%" bordercolor="#CCCCCC"><div align="center"><span class="style9"><strong>Contrato</strong></span></div></td>'
cHtm += '        <td width="11%" bordercolor="#CCCCCC"><div align="center"><span class="style9"><strong>Cotacao</strong></span></div></td>'
cHtm += '      </tr>'

DbSelectArea("SC7")
cFilIni := SC7->C7_FILIAL
cNumIni := SC7->C7_NUM
Do While !Eof() .and. cFilIni==SC7->C7_FILIAL .and. SC7->C7_NUM==cNumIni
	// Verifica se ha cotacao
	cCotac := ""
	If !Empty(SC7->C7_NUMSC)
		DbSelectArea("SC1")
		DbSetOrder(1)
		DbSeek(SC7->C7_FILIAL+SC7->C7_NUMSC+SC7->C7_ITEMSC)
		cCotac := SC1->C1_COTACAO
	EndIf

	cHtm += '      <tr>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="center"><span class="style9">'+SC7->C7_ITEM+'</span></div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="left"><span class="style9">'+Alltrim(SC7->C7_PRODUTO)+'</span></div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3" class="style9"><div align="center">'+SC7->C7_UM+'</div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="left"><span class="style9">'+Alltrim(SC7->C7_DESCRI)+'</span></div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="center"><span class="style9">'+Transform(SC7->C7_QUANT,GetSX3Cache("C7_QUANT","X3_PICTURE"))+'</span></div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="center"><span class="style9">'+SC7->C7_CONTRA+'</span></div></td>'
	cHtm += '        <td bordercolor="#CCCCCC" bgcolor="#f3f3f3"><div align="center"><span class="style9">'+cCotac+'</span></div></td>'
	cHtm += '      </tr>'
	
	DbSelectArea("SC7")
	DbSkip()
EndDo
cHtm += '    </table><Br>'
cHtm += '    <span class="style13"><font face="Tahoma" size=2>Observacoes</font></span><Br>'
cHtm += '    <font face="Tahoma" size=2><textarea name="S1" rows="4" cols="74">'+Alltrim(SCR->CR_OBS)+'</textarea></font>'
cHtm += '</body>'
cHtm += '</html>'

Return cHtm

