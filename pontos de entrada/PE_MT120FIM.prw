#Include "Protheus.ch"
#Include "Topconn.ch"

/*/{Protheus.doc} MT120FIM

Ponto de entrada após a gravacao do pedido de compra
	 
@author  Cesar Padovani 
@since   12/10/2021
@version 1.0
@type    Ponto de entrada
/*/
User Function MT120FIM()

Local nOpcao  := PARAMIXB[1]   // Opção Escolhida pelo usuario 
Local cNumPC  := PARAMIXB[2]   // Numero do Pedido de Compras
Local nOpcA   := PARAMIXB[3]   // Indica se a ação foi Cancelada = 0  ou Confirmada = 1
Local aArAnt  := GetArea()
Local nTLib   := 0
Local cRetGrp := ""
Local cQrySCR := ""
Local cQryHst := ""
Local cQrySAL := ""
Local cQuery  := ""
Local cxIntPA := ""

If nOpcA==1
    If nOpcao==3 .or. nOpcao==4
        aAprov := {}
        nxItem := 1
        cXFilial := SC7->C7_FILIAL
        DbSelectArea("SC7")
        DbSetOrder(1)
        DbGoTop()
        DbSeek(cXFilial+cNumPC,.T.)
        Do While !Eof() .and. SC7->C7_FILIAL==cXFilial .and. SC7->C7_NUM==cNumPC
            // Verifica o Grupo do Produto
            cGrpPrd := Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,"B1_GRUPO")

            // Verifica se o Grupo possui Aprovador
            DbSelectArea("ZA1")
            DbSetOrder(2)
            If DbSeek(xFilial("ZA1")+cGrpPrd)
                Do While !Eof() .and. Alltrim(ZA1->ZA1_GRUPO)==Alltrim(cGrpPrd)
                    aAdd(aAprov,{ZA1->ZA1_APROV})
                    DbSelectArea("ZA1")
                    DbSkip()
                EndDo
            EndIf 

            If SC7->C7_RESIDUO <> "S"	
                nTLib += SC7->C7_TOTAL
            EndIf
            nxItem ++

            DbSelectArea("SC7")
            DbSkip()
        EndDo

        // Se houver aprovadores para o grupo, ajusta o grupo de aprovacao
        If Len(aAprov)<>0
            // Verifica se os aprovadores na SCR constam como aprovadores do grupo
            cQrySCR := "SELECT CR_NUM,CR_APROV,R_E_C_N_O_ FROM "+RetSQLName("SCR")+" WHERE D_E_L_E_T_='' AND CR_FILIAL='"+cXFilial+"' AND LTRIM(RTRIM(CR_NUM))='"+cNumPC+"' "
            If Select("TRBSCR")<>0
                TRBSCR->(DbCloseArea())
            EndIf 
            cQrySCR := ChangeQuery(cQrySCR)
            TCQUERY cQrySCR NEW ALIAS "TRBSCR"
            
            DbSelectArea("TRBSCR")
            DbGoTOp()
            Do While !Eof()
                DbSelectArea("SCR")
                DbGoTo(TRBSCR->R_E_C_N_O_)

                // Se não encontrar o aprovador da SCR como aprovador do grupo, deleta a SCR
                nPos := aScan(aAprov,{|x| Alltrim(x[1])==Alltrim(SCR->CR_APROV) })
                If nPos==0
                    RecLock("SCR",.F.)
                    Delete
                    MsUnLock()
                EndIf 

                DbSelectArea("TRBSCR")
                DbSkip()
            EndDo
        EndIf 
        //confirmação de inclusão na ZA2
        DbSelectArea("ZA2")
        dbSetOrder(1)
        If ZA2->(dbSeek(xFilial("ZA2")+PADL(CA120NUM,15)))
            while ZA2->(!Eof()) .AND. xFilial("ZA2")+PADL(CA120NUM,15)==ZA2->ZA2_FILIAL+ZA2->ZA2_CONTR
                If ZA2->ZA2_STATUS=="X"
                    ZA2->(Reclock("ZA2", .F.))
                    ZA2->ZA2_STATUS:= ""
                    ZA2->(MsUnlock())
                EndIf
                ZA2->(dbSkip())   
            end
        ENDIF
    EndIf 
ElseIf nOpcA==0
// exclui ZA2 incluida na inclusão/alteração quando apertar o botão cancelar
    DbSelectArea("ZA2")
    dbSetOrder(1)
    If ZA2->(dbSeek(xFilial("ZA2")+PADL(CA120NUM,15)))
        while ZA2->(!Eof()) .AND. xFilial("ZA2")+PADL(CA120NUM,15)==ZA2->ZA2_FILIAL+ZA2->ZA2_CONTR
            If ZA2->ZA2_STATUS=="X"
                dbSelectArea("SE2")
                dbSetOrder(6)
                If SE2->(dbSeek(ZA2->ZA2_FILIAL+ZA2->ZA2_FORNEC+ZA2->ZA2_LOJA+ZA2->ZA2_PREFIX+ZA2->ZA2_NUMERO))
                    aExcPr := { { "E2_PREFIXO" , SE2->E2_PREFIXO , NIL },;
                                { "E2_NUM"     , SE2->E2_NUM     , NIL } }
                    MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aExcPr,, 5)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

                    If lMsErroAuto
                        MostraErro()
                    else
                        ZA2->(Reclock("ZA2", .F.))
                        ZA2->(DbDelete())
                        ZA2->(MsUnlock())
                    Endif
                EndIf    
            EndIf
            ZA2->(dbSkip())   
        end
    ENDIF

EndIf

RestArea(aArAnt)

If Type("_lGrpApr")=="L"
	If _lGrpApr
		// Verifica o ultimo historico de alteracao para definicao do Grupo de Aprovadores
		cQryHst := "SELECT * FROM "+RetSQLName("ZA3")+" WHERE D_E_L_E_T_='' AND R_E_C_N_O_ IN(SELECT MAX(R_E_C_N_O_) FROM "+RetSQLName("ZA3")+" WHERE D_E_L_E_T_='' AND ZA3_NUM='"+SC7->C7_NUM+"') "
		cQryHst := ChangeQuery(cQryHst)
		If Select("TRBHST")<>0
			TRBHST->(DbCloseArea())
		EndIf
		TCQUERY cQryHst NEW ALIAS "TRBHST"
		DbSelectArea("TRBHST")
		DbGoTop()
		DbSelectArea("ZA3")
		DbGoTo(TRBHST->R_E_C_N_O_)
		If !Empty(ZA3->ZA3_NUMADT)
			cQrySAL := "SELECT DISTINCT AL_COD,AL_DESC FROM "+RetSQLName("SAL")+" WHERE D_E_L_E_T_='' AND AL_FILIAL='"+xFilial("SAL")+"' AND AL_XADIPED='T'"
		ElseIf Alltrim(DTOS(ZA3->ZA3_ENTRAT))<>"" .or. !Empty(ZA3->ZA3_TPFRAT) .or. !Empty(ZA3->ZA3_CONDAT)
			cQrySAL := "SELECT DISTINCT AL_COD,AL_DESC FROM "+RetSQLName("SAL")+" WHERE D_E_L_E_T_='' AND AL_FILIAL='"+xFilial("SAL")+"' AND AL_XALTPED='T'"
		EndIF

		If !Empty(cQrySAL) 
			cQrySAL := ChangeQuery(cQrySAL)
			If Select("TRBSAL")<>0
				TRBSAL->(DbCloseArea())
			EndIf 
			TCQUERY cQrySAL NEW ALIAS "TRBSAL"
			DbSelecTArea("TRBSAL")
			DbGoTop()
			cRetGrp := TRBSAL->AL_COD

			//FwAlertInfo("Alteração de pedido já aprovado! O pedido sera enviado para aprovação para o Grupo "+Alltrim(TRBSAL->AL_COD)+" | "+Alltrim(TRBSAL->AL_DESC),"Já aprovado.")
		EndIf

        If !Empty(cRetGrp)
            // Envia para o grupo alteracao/adiantamento
            DbSelectArea("SC7")
            DbSetOrder(1)
            DbSeek(xFilial("SC7")+cNumPC)

            // Estorna a liberacao
            cQrySCR := "SELECT R_E_C_N_O_ FROM SCR010 WHERE D_E_L_E_T_=' ' AND CR_FILIAL='"+xFilial("SC7")+"' AND CR_NUM='"+cNumPC+"' "
            If Select("TRBSCR")<>0
                TRBSCR->(DbCloseArea())
            EndiF 
            TCQUERY cQrySCR NEW ALIAS "TRBSCR"
            DbSelectArea("TRBSCR")
            DbGoTop()
            If TRBSCR->(!Eof())
                DbSelecTArea("TRBSCR")
                DbGoTop()
                Do While !Eof()
                    DbSelectArea("SCR")
                    DbGoTo(TRBSCR->R_E_C_N_O_)
                    RecLock("SCR",.F.)
                    Delete
                    MsUnLock()
                    DbSelectArea("TRBSCR")
                    DbSkip()
                EndDo
            EndIf 
            
            // Envia para o grupo de alteração/adiantamento
            MaAlcDoc({cNumPC,"IP",nTLib,,,cRetGrp,,SC7->C7_MOEDA,SC7->C7_TXMOEDA,SC7->C7_EMISSAO},SC7->C7_EMISSAO,1)

            // Altera o campo CR_XPEDALT
            cQuery := " SELECT R_E_C_N_O_ FROM "+RetSqlName("SCR")+" "
            cQuery += " WHERE D_E_L_E_T_ = ' '
            cQuery += " AND CR_FILIAL='"+xFilial("SCR")+"' AND CR_NUM='"+cNumPC+"'
            cQuery := ChangeQuery(cQuery)
            If Select("TRBSCR")<>0
                TRBSCR->(DbCloseArea())
            EndIf
            TCQUERY cQuery NEW ALIAS "TRBSCR"
            DbSelectArea("TRBSCR")
            DbGoTop()
            Do While !Eof()
                DbSelectArea("SCR")
                DbGoTo(TRBSCR->R_E_C_N_O_)
                RecLock("SCR",.F.)
                SCR->CR_ITGRP:= "01"
                SCR->CR_XPEDALT := "S"
                MsUnLock()
                DbSelectArea("TRBSCR")
                DbSkip()
            EndDo
        EndIf 
    EndIf 
    _lGrpApr := .F.
EndIf 

// Na rotina de encerramento da medicao do contrato pergunta se deseja enviar o pedido de compra ao Fornecedor
If Alltrim(FunName())=="CNTA121" .or. Alltrim(FunName())=="CNTA120"
    If FwAlertYesNo("Enviar pedido de compra ao Fornecedor?")
        cxIntPA := "2"
    Else 
        cxIntPA := "5"
    EndIf
    
    DbSelectArea("SC7")
    DbSetOrder(1)
    DbSeek(xFilial("SC7")+cNumPC,.T.)
    Do While !Eof() .and. SC7->C7_FILIAL==xFilial("SC7") .and. SC7->C7_NUM==cNumPC
        RecLock("SC7",.F.)
        SC7->C7_XINTPA := cxIntPA
        MsUnLock()
        DbSelectArea("SC7")
        DbSkip()
    EndDo
EndIf 

RestArea(aArAnt)

Return

